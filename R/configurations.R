# Configuration Environment, to be used as needed.
.config <- new.env(parent = emptyenv())


#' Set Log File
#'
#' Set the log file that loggit will write to by default.
#'
#' @param logfile Absolut or relative path to log file.
#' An attempt is made to convert the path into a canonical absolute form using [normalizePath()].
#' If `NULL` will set to `<tmpdir>/loggit.log`.
#' @param confirm Print confirmation of log file setting?
#' @param create Create the log file if it does not exist?
#'
#' @details No logs outside of a temporary directory will be written until this is set explicitly, as per CRAN policy.
#' Therefore, the default behavior is to create a file named `loggit.log` in your system's temporary directory.
#'
#' @return Invisible the previous log file path.
#'
#' @examples
#' \dontrun{
#'   set_logfile("path/to/logfile.log")
#' }
#' @export
set_logfile <- function(logfile = NULL, confirm = TRUE, create = TRUE) {
  old <- get_logfile()
  if (is.null(logfile)) {
    logfile <- file.path(tempdir(), "loggit.log")
  }
  if (create && !file.exists(logfile)) file.create(logfile)
  .config[["logfile"]] <- normalizePath(logfile, winslash = "/", mustWork = FALSE)
  if (confirm) base::message("Log file set to ", .config[["logfile"]])
  return(invisible(old))
}


#' Get Log File
#'
#' Return the log file that `loggit()` will write to by default.
#'
#' @return The log file path.
#'
#' @examples get_logfile()
#'
#' @export
get_logfile <- function() {
  .config[["logfile"]]
}


#' Set Timestamp Format
#'
#' Set timestamp format for use in output logs.
#'
#' @param ts_format ISO date format.
#' @param confirm Print confirmation message of timestamp format?
#'
#' @return Invisible the previous timestamp format.
#'
#' @details This function performs no time format validations, but will echo out the current time in
#' the provided format for manual validation.
#'
#' This function provides no means of setting a timezone, and instead relies on
#' the host system's time configuration to provide this. This is to enforce
#' consistency across software running on the host.
#'
#' @examples
#' \dontrun{
#'   set_timestamp_format("%Y-%m-%d %H:%M:%S")
#' }
#'
#' @export
set_timestamp_format <- function(ts_format = "%Y-%m-%dT%H:%M:%S%z", confirm = TRUE) {
  old <- get_timestamp_format()
  .config[["ts_format"]] <- ts_format
  if (confirm) {
    base::message(
      "Timestamp format set to ", ts_format, ".\n",
      "Current time in this format: ", format(Sys.time(), format = ts_format)
    )
  }
  return(invisible(old))
}


#' Get Timestamp Format
#'
#' Get timestamp format for use in output logs.
#'
#' @return The timestamp format.
#'
#' @examples get_timestamp_format()
#'
#' @export
get_timestamp_format <- function() {
  .config[["ts_format"]]
}


#' Set Log Level
#'
#' @param level Log level to set, as a string or integer.
#' @param confirm Print confirmation message of log level?
#'
#' @return Invisible the previous log level.
#'
#' @details Log levels are as follows:
#'  DEBUG: 4
#'  INFO: 3
#'  WARNING: 2
#'  ERROR: 1
#'  NONE: 0
#'
#' @examples
#' \dontrun{
#'  set_log_level("DEBUG")
#'  set_log_level("INFO")
#'
#'  set_log_level(4)
#'  set_log_level(3)
#' }
#'
#' @export
set_log_level <- function(level = "DEBUG", confirm = TRUE) {
  old <- get_log_level()
  level <- convert_lvl_input(level)
  .config[["level"]] <- level
  if (confirm) base::message("Log level set to ", level, " (", get_lvl_name(level), ")")
  return(invisible(old))
}

#' Get Log Level
#'
#' @return The log level.
#'
#' @export
get_log_level <- function() {
  .config[["level"]]
}

#' Set echo
#'
#' @param echo Should log messages be echoed to `stdout`?
#' @param confirm Print confirmation message of echo setting?
#'
#' @return Invisible the previous echo setting.
#'
#' @examples
#' \dontrun{
#'  set_echo(TRUE)
#'  set_echo(FALSE)
#' }
#'
#' @export
set_echo <- function(echo = TRUE, confirm = TRUE) {
  old <- get_echo()
  .config[["echo"]] <- echo
  if (confirm) base::message("Echo set to ", echo)
  return(invisible(old))
}

#' Get echo
#'
#' @return Logical. Are log messages echoed to `stdout`?
#'
#' @export
get_echo <- function() {
  .config[["echo"]]
}

#' Set Call Options
#'
#' @param ... Named arguments to set.
#' @param .arg_list A list of named arguments to set.
#' @param confirm Print confirmation message of call options setting?
#'
#' @return Invisible the previous call options.
#'
#' @export
set_call_options <- function(..., .arg_list, confirm = TRUE) {
  base::stopifnot(
    "Only one of `...` or `.arg_list` can be provided." = xor(...length() > 0L, !missing(.arg_list))
  )

  if (...length() > 0L) return(set_call_options(.arg_list = list(...), confirm = confirm))

  base::stopifnot(
    ".arg_list must be a list" = is.list(.arg_list),
    # Avoid using ...names() to remain compatible with versions earlier than 4.1.0
    "All arguments must be named." =
      length(.arg_list) == 0L || !is.null(names(.arg_list)) && all(names(.arg_list) != "")
  )

  old <- get_call_options()

  default <- list(log_call = FALSE, full_stack = FALSE)

  to_default <- setdiff(c("log_call", "full_stack"), names(.arg_list))
  .arg_list[to_default] <- default[to_default]

  .config[["log_call"]] <- .arg_list[["log_call"]]
  .config[["full_stack"]] <- .arg_list[["full_stack"]]

  if (confirm) {
    base::message(
      "Call options set to log_call = ", .config[["log_call"]], ", full_stack = ", .config[["full_stack"]], "."
    )
  }

  return(invisible(old))
}

#' Get Call Options
#'
#' @return The call options.
#'
#' @export
get_call_options <- function() {
  list(log_call = .config[["log_call"]], full_stack = .config[["full_stack"]])
}
