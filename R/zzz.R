# Set all default options on package load
.onLoad <- function(libname, pkgname) {
  setup_echo()
  setup_log_level()
  setup_logfile()
  setup_timestamp_format()
}
