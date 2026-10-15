#include <R.h>
#include <Rinternals.h>
#include <R_ext/Utils.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#endif

/* No nested lock scopes, even through aliases. In particular, never open and
   close a second POSIX descriptor for a lock inode owned by this process. */
static int lock_scope_active = 0;

#ifndef _WIN32
static void io_error(const char *operation, const char *path, int code) {
    Rf_error("%s failed for '%s': %s (OS error %d)",
             operation, path, strerror(code), code);
}
#endif

static const char *path_string(SEXP path) {
    if (TYPEOF(path) != STRSXP || XLENGTH(path) != 1 ||
        STRING_ELT(path, 0) == NA_STRING)
        Rf_error("Expected one file path");
#ifdef _WIN32
    return Rf_translateCharUTF8(STRING_ELT(path, 0));
#else
    return Rf_translateChar(STRING_ELT(path, 0));
#endif
}

#ifdef _WIN32
static void windows_error(const char *operation, const char *path, DWORD code) {
    WCHAR wide[512];
    char message[2048] = "Windows API error";
    if (FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                       NULL, code, 0, wide, 512, NULL))
        WideCharToMultiByte(CP_UTF8, 0, wide, -1, message, sizeof(message), NULL, NULL);
    Rf_error("%s failed for '%s': %s (OS error %lu)",
             operation, path, message, (unsigned long) code);
}

static WCHAR *wide_path(const char *path) {
    int size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path, -1, NULL, 0);
    WCHAR *wide;
    if (!size) windows_error("Path conversion", path, GetLastError());
    wide = (WCHAR *) R_alloc(size, sizeof(WCHAR));
    if (!MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, path, -1, wide, size))
        windows_error("Path conversion", path, GetLastError());
    return wide;
}
#endif

typedef struct {
    const char *path;
    int entered;
    int locked;
    unsigned long cleanup_error;
    const char *cleanup_operation;
#ifdef _WIN32
    const WCHAR *wide;
    HANDLE handle;
    OVERLAPPED range;
#else
    int fd;
    struct flock range;
#endif
} lock_data;

/* Cleanup must not allocate, signal conditions, or check R interrupts. Always
   close after an unlock failure; report cleanup errors only on normal return. */
static void release_lock(void *data, Rboolean jump) {
    lock_data *d = (lock_data *) data;
    (void) jump;
#ifdef _WIN32
    if (d->handle != INVALID_HANDLE_VALUE) {
        if (d->locked && !UnlockFileEx(d->handle, 0, 1, 0, &d->range)) {
            d->cleanup_error = GetLastError();
            d->cleanup_operation = "Unlock";
        }
        d->locked = 0;
        if (!CloseHandle(d->handle) && !d->cleanup_error) {
            d->cleanup_error = GetLastError();
            d->cleanup_operation = "Close lock";
        }
        d->handle = INVALID_HANDLE_VALUE;
    }
#else
    if (d->fd >= 0) {
        if (d->locked) {
            int result;
            d->range.l_type = F_UNLCK;
            do { result = fcntl(d->fd, F_SETLK, &d->range); }
            while (result < 0 && errno == EINTR);
            if (result < 0) {
                d->cleanup_error = errno;
                d->cleanup_operation = "Unlock";
            }
        }
        d->locked = 0;
        /* Do not retry close on EINTR: the descriptor may already be closed. */
        if (close(d->fd) < 0 && !d->cleanup_error) {
            d->cleanup_error = errno;
            d->cleanup_operation = "Close lock";
        }
        d->fd = -1;
    }
#endif
    if (d->entered) {
        lock_scope_active = 0;
        d->entered = 0;
    }
}

static SEXP acquire_lock(void *data) {
    lock_data *d = (lock_data *) data;
    lock_scope_active = d->entered = 1;
    R_CheckUserInterrupt();
#ifdef _WIN32
    /* A synchronous, shared-open handle; byte zero exists logically even in
       an empty file. Never delete or replace this persistent sidecar. */
    d->handle = CreateFileW(d->wide, GENERIC_READ | GENERIC_WRITE,
                           FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
                           OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (d->handle == INVALID_HANDLE_VALUE)
        windows_error("Open lock", d->path, GetLastError());
    if (!LockFileEx(d->handle, LOCKFILE_EXCLUSIVE_LOCK, 0, 1, 0, &d->range))
        windows_error("Lock", d->path, GetLastError());
#else
    do {
        d->fd = open(d->path, O_CREAT | O_RDWR, 0666);
        if (d->fd >= 0) break;
        if (errno != EINTR) io_error("Open lock", d->path, errno);
        R_CheckUserInterrupt();
    } while (1);
    d->range.l_type = F_WRLCK;
    d->range.l_whence = SEEK_SET;
    d->range.l_start = 0;
    d->range.l_len = 1;
    while (fcntl(d->fd, F_SETLKW, &d->range) < 0) {
        if (errno != EINTR) io_error("Lock", d->path, errno);
        R_CheckUserInterrupt();
    }
#endif
    d->locked = 1;
    R_CheckUserInterrupt();
    return R_NilValue;
}

static void finalize_lock(SEXP token) {
    lock_data *d = (lock_data *) R_ExternalPtrAddr(token);
    if (!d) return;
    release_lock(d, FALSE);
    R_Free(d);
    R_ClearExternalPtr(token);
}

/* Allocate only a resource-free token. R registers on.exit before acquisition;
   the finalizer is a fallback, never the normal unlocking mechanism. */
SEXP new_log_lock(SEXP path) {
    SEXP token;
    lock_data *d;
    path_string(path);
    token = PROTECT(R_MakeExternalPtr(NULL, Rf_install("loggit2_lock"), path));
    d = R_Calloc(1, lock_data);
#ifdef _WIN32
    d->handle = INVALID_HANDLE_VALUE;
#else
    d->fd = -1;
#endif
    R_SetExternalPtrAddr(token, d);
    R_RegisterCFinalizerEx(token, finalize_lock, TRUE);
    UNPROTECT(1);
    return token;
}

static lock_data *lock_pointer(SEXP token) {
    if (TYPEOF(token) != EXTPTRSXP ||
        R_ExternalPtrTag(token) != Rf_install("loggit2_lock"))
        Rf_error("Expected a log lock token");
    return (lock_data *) R_ExternalPtrAddr(token);
}

static void failed_acquisition(void *data, Rboolean jump) {
    if (jump) release_lock(data, jump);
}

SEXP lock_log(SEXP token) {
    lock_data *d = lock_pointer(token);
    if (!d) Rf_error("Log lock token has already been released");
    if (lock_scope_active)
        Rf_error("Recursive log locking is not allowed: %s",
                 path_string(R_ExternalPtrProtected(token)));
    d->path = path_string(R_ExternalPtrProtected(token));
#ifdef _WIN32
    d->wide = wide_path(d->path);
#endif
    return R_UnwindProtect(acquire_lock, d, failed_acquisition, d, NULL);
}

SEXP unlock_log(SEXP token) {
    lock_data *d = lock_pointer(token);
    unsigned long code;
    const char *operation;
    if (!d) return R_NilValue;
    release_lock(d, FALSE);
    code = d->cleanup_error;
    operation = d->cleanup_operation;
    R_Free(d);
    R_ClearExternalPtr(token);
    if (code) {
        const char *path = path_string(R_ExternalPtrProtected(token));
#ifdef _WIN32
        windows_error(operation, path, (DWORD) code);
#else
        io_error(operation, path, (int) code);
#endif
    }
    return R_NilValue;
}

#ifdef _WIN32
static SEXP follow_log_alias(void *data) {
    lock_data *d = (lock_data *) data;
    /* Follow the reparse point: attributes and R's file.exists() can describe
       the link itself even when its target is missing. A zero-access handle
       permits concurrent log writers and also supports directory aliases. */
    d->handle = CreateFileW(d->wide, 0, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                           NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
    if (d->handle == INVALID_HANDLE_VALUE)
        windows_error("Resolve log alias (create its target directly first)", d->path, GetLastError());
    return R_NilValue;
}
#endif

/* Stable dangling aliases must not select a sidecar whose identity changes
   after target creation. POSIX stat calls open no descriptor and thus cannot
   disturb a record lock. Any Windows handle is covered by unwind cleanup. */
SEXP check_log_alias(SEXP path) {
    const char *target = path_string(path);
#ifdef _WIN32
    lock_data d;
    DWORD attributes;
    memset(&d, 0, sizeof(d));
    d.path = target;
    d.wide = wide_path(target);
    d.handle = INVALID_HANDLE_VALUE;
    attributes = GetFileAttributesW(d.wide);
    if (attributes == INVALID_FILE_ATTRIBUTES) {
        DWORD code = GetLastError();
        if (code != ERROR_FILE_NOT_FOUND && code != ERROR_PATH_NOT_FOUND)
            windows_error("Inspect log alias", target, code);
    } else if (attributes & FILE_ATTRIBUTE_REPARSE_POINT) {
        R_UnwindProtect(follow_log_alias, &d, release_lock, &d, NULL);
        if (d.cleanup_error) windows_error("Close log alias", target, (DWORD) d.cleanup_error);
    }
#else
    struct stat info;
    while (lstat(target, &info) < 0) {
        int code = errno;
        if (code == ENOENT) return R_NilValue;
        if (code != EINTR) io_error("Inspect log alias", target, code);
        R_CheckUserInterrupt();
    }
    if (S_ISLNK(info.st_mode)) {
        while (stat(target, &info) < 0) {
            int code = errno;
            if (code != EINTR)
                io_error("Resolve log alias (create its target directly first)", target, code);
            R_CheckUserInterrupt();
        }
    }
#endif
    return R_NilValue;
}
