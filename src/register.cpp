#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include "loggit.h"

static const R_CallMethodDef CallEntries[] = {
    {"split_ndjson", (DL_FUNC) &split_ndjson, 1},
    {NULL, NULL, 0}
};

void R_init_loggit2(DllInfo *dll) {
    R_useDynamicSymbols(dll, FALSE);
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
}
