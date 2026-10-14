#define _FILE_OFFSET_BITS 64
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Utils.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
#include <io.h>
typedef __int64 log_offset;
#define log_seek _fseeki64
#define log_tell _ftelli64
#else
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
typedef off_t log_offset;
#define log_seek fseeko
#define log_tell ftello
#endif

/* No nested lock scopes, even through aliases. In particular, never open and
   close a second POSIX descriptor for a lock inode owned by this process. */
static int lock_scope_active = 0;

static void io_error(const char *operation, const char *path, int code) {
    Rf_error("%s failed for '%s': %s (OS error %d)",
             operation, path, strerror(code), code);
}

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
    SEXP call;
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

static SEXP acquire_and_call(void *data) {
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
    return Rf_eval(d->call, R_GlobalEnv);
}

SEXP with_log_lock(SEXP path, SEXP callback) {
    lock_data d;
    SEXP result;
    memset(&d, 0, sizeof(d));
    d.path = path_string(path);
    if (lock_scope_active) Rf_error("Recursive log locking is not allowed: %s", d.path);
    if (!Rf_isFunction(callback)) Rf_error("Expected a lock callback");
#ifdef _WIN32
    d.handle = INVALID_HANDLE_VALUE;
    d.wide = wide_path(d.path);
#else
    d.fd = -1;
#endif
    d.call = PROTECT(Rf_lang1(callback));
    result = R_UnwindProtect(acquire_and_call, &d, release_lock, &d, NULL);
    if (d.cleanup_error) {
#ifdef _WIN32
        windows_error(d.cleanup_operation, d.path, (DWORD) d.cleanup_error);
#else
        io_error(d.cleanup_operation, d.path, (int) d.cleanup_error);
#endif
    }
    UNPROTECT(1);
    return result;
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

typedef struct {
    const char *path;
#ifdef _WIN32
    const WCHAR *wide;
#endif
    FILE *file;
    const unsigned char *bytes;
    size_t size;
    int append;
    double keep;
} file_data;

static void close_file(void *data, Rboolean jump) {
    file_data *d = (file_data *) data;
    (void) jump;
    if (d->file) {
        fclose(d->file);
        d->file = NULL;
    }
}

static void prepare_file(file_data *d, SEXP path) {
    memset(d, 0, sizeof(*d));
    d->path = path_string(path);
    if (!lock_scope_active) Rf_error("Log I/O requires a lock: %s", d->path);
#ifdef _WIN32
    d->wide = wide_path(d->path);
#endif
}

static void open_file(file_data *d, const char *mode) {
#ifdef _WIN32
    const WCHAR *wide_mode = strcmp(mode, "ab") == 0 ? L"ab" :
                             strcmp(mode, "wb") == 0 ? L"wb" : L"r+b";
    d->file = _wfopen(d->wide, wide_mode);
#else
    d->file = fopen(d->path, mode);
#endif
    if (!d->file) io_error("Open log", d->path, errno);
}

static void finish_file(file_data *d) {
    int error = 0;
    const char *operation = "Flush log";
    if (fflush(d->file)) error = errno ? errno : EIO;
    if (fclose(d->file) && !error) {
        error = errno ? errno : EIO;
        operation = "Close log";
    }
    d->file = NULL;
    if (error) io_error(operation, d->path, error);
}

static void write_bytes(file_data *d, const unsigned char *bytes, size_t size) {
    if (size && fwrite(bytes, 1, size, d->file) != size)
        io_error("Write log", d->path, errno ? errno : EIO);
}

static SEXP write_body(void *data) {
    file_data *d = (file_data *) data;
    open_file(d, d->append ? "ab" : "wb");
    write_bytes(d, d->bytes, d->size);
    finish_file(d);
    return R_NilValue;
}

SEXP write_log(SEXP path, SEXP bytes, SEXP append) {
    file_data d;
    if (TYPEOF(bytes) != RAWSXP) Rf_error("Expected serialized log bytes");
    prepare_file(&d, path);
    d.bytes = RAW(bytes);
    d.size = (size_t) XLENGTH(bytes);
    d.append = Rf_asLogical(append);
    return R_UnwindProtect(write_body, &d, close_file, &d, NULL);
}

static void seek_file(file_data *d, log_offset offset, int origin) {
    if (log_seek(d->file, offset, origin)) io_error("Seek log", d->path, errno);
}

static void read_bytes(file_data *d, unsigned char *bytes, size_t size) {
    if (fread(bytes, 1, size, d->file) != size)
        io_error("Read log", d->path, errno ? errno : EIO);
}

static SEXP rotate_body(void *data) {
    file_data *d = (file_data *) data;
    unsigned char buffer[65536];
    log_offset end, pos, start = 0, written = 0;
    double lines = 0;
    int final_newline = 1;
    open_file(d, "r+b");
    seek_file(d, 0, SEEK_END);
    end = log_tell(d->file);
    if (end < 0) io_error("Tell log", d->path, errno);
    pos = end;
    if (d->keep == 0) start = end;
    /* Search only the retained suffix, not the full file, when possible. */
    while (d->keep > 0 && pos > 0) {
        size_t n = pos > (log_offset) sizeof(buffer) ? sizeof(buffer) : (size_t) pos;
        size_t i = n;
        pos -= n;
        seek_file(d, pos, SEEK_SET);
        read_bytes(d, buffer, n);
        while (i > 0) {
            --i;
            if (pos + (log_offset) i == end - 1) {
                final_newline = buffer[i] == '\n';
                if (final_newline) continue;
            }
            if (buffer[i] == '\n' && ++lines >= d->keep) {
                start = pos + (log_offset) i + 1;
                break;
            }
        }
        if (start) break;
        R_CheckUserInterrupt();
    }
    if (start == 0) {
        finish_file(d);
        return R_NilValue;
    }
    R_CheckUserInterrupt();
    /* Copy forward in bounded chunks; each chunk is read before overwriting
       its destination. Defer interrupts from the first write through truncation
       and close: unwinding midway would leave copied and original bytes mixed.
       No log connection survives the enclosing lock scope. */
    pos = start;
    while (pos < end) {
        size_t n = end - pos > (log_offset) sizeof(buffer) ? sizeof(buffer) : (size_t) (end - pos);
        seek_file(d, pos, SEEK_SET);
        read_bytes(d, buffer, n);
        seek_file(d, written, SEEK_SET);
        write_bytes(d, buffer, n);
        written += n;
        pos += n;
    }
    if (written && !final_newline) {
        write_bytes(d, (const unsigned char *) "\n", 1);
        ++written;
    }
    if (fflush(d->file)) io_error("Flush rotation", d->path, errno ? errno : EIO);
#ifdef _WIN32
    {
        int code = _chsize_s(_fileno(d->file), written);
        if (code) io_error("Truncate log", d->path, code);
    }
#else
    while (ftruncate(fileno(d->file), written) < 0) {
        if (errno != EINTR) io_error("Truncate log", d->path, errno);
    }
#endif
    finish_file(d);
    R_CheckUserInterrupt();
    return R_NilValue;
}

SEXP rotate_log(SEXP path, SEXP lines) {
    file_data d;
    prepare_file(&d, path);
    d.keep = Rf_asReal(lines);
    if (ISNAN(d.keep) || d.keep < 0) Rf_error("Invalid retained line count");
    return R_UnwindProtect(rotate_body, &d, close_file, &d, NULL);
}
