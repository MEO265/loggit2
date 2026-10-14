#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>
#include "loggit.h"

extern "C" {
static const R_CallMethodDef CallEntries[] = {
    {"c_split_ndjson", (DL_FUNC) &split_ndjson, 1},
    {"c_with_log_lock", (DL_FUNC) &with_log_lock, 2},
    {"c_write_log", (DL_FUNC) &write_log, 3},
    {"c_rotate_log", (DL_FUNC) &rotate_log, 2},
    {NULL, NULL, 0}
};
}

extern "C" attribute_visible void R_init_loggit2(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}
