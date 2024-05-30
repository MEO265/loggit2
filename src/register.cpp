#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>
#include "loggit.h"

extern "C" {
static const R_CallMethodDef CallEntries[] = {
    {"c_split_ndjson", (DL_FUNC) &split_ndjson, 1},
    {NULL, NULL, 0}
};
}

extern "C" attribute_visible void R_init_loggit2(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}
