#' Set up the logfile for the application
#'
#' This function retrieves the logfile path from the environment variable "FILE_LOGGIT2".
#' If the environment variable is set, it will be used as the logfile path.
#' If the environment variable is not set, the logfile path will be set to the default value.
#'
#' @inherit set_logfile return
#'
#' @keywords internal
setup_logfile <- function() {
  logfile <- Sys.getenv(x = "FILE_LOGGIT2", unset = "")
  call_arg <- list(confirm = FALSE, create = FALSE)
  if (nchar(logfile) != 0L) call_arg <- c(logfile = logfile, call_arg)
  do.call(set_logfile, call_arg)
}

#' Set up the timestamp format for the application
#'
#' This function retrieves the timestamp format from the environment variable "TIMESTAMP_LOGGIT2".
#' If the environment variable is set, it will be used as the timestamp format.
#' If the environment variable is not set, the timestamp format will be set to the default value.
#'
#' @inherit set_timestamp_format return
#'
#' @keywords internal
setup_timestamp_format <- function() {
  ts_format <- Sys.getenv(x = "TIMESTAMP_LOGGIT2", unset = "")
  call_arg <- list(confirm = FALSE)
  if (nchar(ts_format) != 0L) call_arg <- c(ts_format = ts_format, call_arg)
  do.call(set_timestamp_format, call_arg)
}

#' Set up the echo for the application
#'
#' This function retrieves the echo setting from the environment variable "ECHO_LOGGIT2".
#' If the environment variable is set, it will be used as the echo setting.
#' If the environment variable is not set, the echo setting will be set to the default value.
#'
#' @details The environment variable must be set to one of: "TRUE" or "FALSE".
#'
#' @inherit set_echo return
#'
#' @keywords internal
setup_echo <- function() {
  echo <- Sys.getenv(x = "ECHO_LOGGIT2", unset = "")
  call_arg <- list(confirm = FALSE)
  if (nchar(echo) != 0L) {
    echo <- as.logical(echo)
    if (!is.na(echo)) call_arg <- c(echo = echo, call_arg)
  }
  do.call(set_echo, call_arg)
}

#' Set up the log level for the application
#'
#' This function retrieves the log level from the environment variable "LEVEL_LOGGIT2".
#' If the environment variable is set, it will be used as the log level.
#' If the environment variable is not set, the log level will be set to the default value.
#'
#' @details The environment variable must be set to one of: "DEBUG", "INFO", "WARN", "ERROR" or "NONE".
#'
#' @inherit set_log_level return
#'
#' @keywords internal
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
