#ifndef LOGGIT
#define LOGGIT

extern "C"  SEXP split_ndjson(SEXP strVecSEXP);
extern "C" SEXP check_new_logfile(SEXP path);
extern "C" SEXP with_log_lock(SEXP path, SEXP callback);
extern "C" SEXP write_log(SEXP path, SEXP bytes, SEXP append);
extern "C" SEXP rotate_log(SEXP path, SEXP lines);

#endif
