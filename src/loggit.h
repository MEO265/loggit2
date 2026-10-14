#ifndef LOGGIT
#define LOGGIT

extern "C"  SEXP split_ndjson(SEXP strVecSEXP);
extern "C" SEXP check_log_alias(SEXP path);
extern "C" SEXP new_log_lock(SEXP path);
extern "C" SEXP lock_log(SEXP token);
extern "C" SEXP unlock_log(SEXP token);

#endif
