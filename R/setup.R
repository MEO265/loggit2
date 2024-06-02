setup_logfile <- function() {
  logfile <- Sys.getenv(x = "FILE_LOGGIT2", unset = "")
  call_arg <- list(confirm = FALSE, create = FALSE)
  if (nchar(logfile) != 0L) call_arg <- c(logfile = logfile, call_arg)
  do.call(set_logfile, call_arg)
}

setup_timestamp_format <- function() {
  ts_format <- Sys.getenv(x = "TIMESTAMP_LOGGIT2", unset = "")
  call_arg <- list(confirm = FALSE)
  if (nchar(ts_format) != 0L) call_arg <- c(ts_format = ts_format, call_arg)
  do.call(set_timestamp_format, call_arg)
}

setup_echo <- function() {
  echo <- Sys.getenv(x = "ECHO_LOGGIT2", unset = "")
  call_arg <- list(confirm = FALSE)
  if (nchar(echo) != 0L) {
    echo <- as.logical(echo)
    if (!is.na(echo)) call_arg <- c(echo = echo, call_arg)
  }
  do.call(set_echo, call_arg)
}

setup_log_level <- function() {
  log_level <- Sys.getenv(x = "LEVEL_LOGGIT2", unset = "")
  call_arg <- list(confirm = FALSE)
  if (nchar(log_level) != 0L) {
    log_level <- tryCatch({
      convert_lvl_input(log_level)
    }, error = function(e) {
      NULL
    })
    call_arg <- c(level = log_level, call_arg)
  }
  do.call(set_log_level, call_arg)
}
