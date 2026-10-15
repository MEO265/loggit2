# Set all default options on package load
.onLoad <- function(libname, pkgname) {
  set_safe_multi_process(TRUE, confirm = FALSE)
  setup_echo()
  setup_log_level()
  setup_logfile()
  setup_timestamp_format()
  setup_call_options()
}
