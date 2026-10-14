#define _FILE_OFFSET_BITS 64
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Utils.h>
#include <R_ext/Rdynload.h>
#include <stdio.h>
#include <errno.h>
#ifndef _WIN32
#include <unistd.h>
#endif

static int phase = 0, pending = 0, checks = 0, injected = 0;
static SEXP handler = NULL;

/* Queue an interrupt after the first actual write. It is delivered only at
   the implementation's own R interrupt checkpoints, without timing races. */
static size_t fixture_fwrite(const void *bytes, size_t size, size_t n, FILE *file) {
    size_t result = fwrite(bytes, size, n, file);
    if (phase == 1 && !injected) pending = injected = 1;
    return result;
}

#ifndef _WIN32
static int fixture_ftruncate(int fd, off_t length) {
    if (phase == 2 && !injected) {
        pending = injected = 1;
        errno = EINTR;
        return -1;
    }
    return ftruncate(fd, length);
}
#endif

static void fixture_interrupt(void) {
    ++checks;
    /* Acquisition has two checkpoints. The next is in the backward scan. */
    if (pending || (phase == 3 && checks == 3)) {
        SEXP call = PROTECT(Rf_lang1(handler));
        pending = 0;
        Rf_eval(call, R_GlobalEnv);
        UNPROTECT(1);
    }
}

#define fwrite fixture_fwrite
#define R_CheckUserInterrupt fixture_interrupt
#ifndef _WIN32
#define ftruncate fixture_ftruncate
#endif
/* The R helper copies the current implementation alongside this fixture. */
#include "file_lock.c"

SEXP fixture_arm(SEXP mode, SEXP callback) {
    if (callback != R_NilValue && !Rf_isFunction(callback)) Rf_error("Expected an interrupt handler");
    if (handler) R_ReleaseObject(handler);
    handler = callback == R_NilValue ? NULL : callback;
    if (handler) R_PreserveObject(handler);
    phase = Rf_asInteger(mode);
    pending = checks = injected = 0;
    return R_NilValue;
}

void R_init_interrupt_fixture(DllInfo *dll) {
    static const R_CallMethodDef entries[] = {
        {"fixture_arm", (DL_FUNC) &fixture_arm, 2},
        {"with_log_lock", (DL_FUNC) &with_log_lock, 2},
        {"rotate_log", (DL_FUNC) &rotate_log, 2},
        {NULL, NULL, 0}
    };
    R_registerRoutines(dll, NULL, entries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}
