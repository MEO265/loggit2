#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>
#include "loggit.h"

extern "C" {
static const R_CallMethodDef CallEntries[] = {
    {"c_split_ndjson", (DL_FUNC) &split_ndjson, 1},
    {"c_check_log_alias", (DL_FUNC) &check_log_alias, 1},
    {"c_new_log_lock", (DL_FUNC) &new_log_lock, 1},
    {"c_lock_log", (DL_FUNC) &lock_log, 1},
    {"c_unlock_log", (DL_FUNC) &unlock_log, 1},
    {NULL, NULL, 0}
};
}

extern "C" attribute_visible void R_init_loggit2(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}
