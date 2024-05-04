.onLoad <- function(libname, pkgname) {
  set_log_level(confirm = FALSE, level = 3L)
  set_logfile(confirm = FALSE, create = FALSE)
  set_timestamp_format(confirm = FALSE)
}
