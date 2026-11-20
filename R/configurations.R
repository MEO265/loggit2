# Configuration Environment, to be used as needed.
.config <- new.env(parent = emptyenv())


check_logical_flag <- function(value, argument) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    base::stop("`", argument, "` must be TRUE or FALSE.", call. = FALSE)
  }
}


check_logfile <- function(logfile) {
  if (!is.character(logfile) || length(logfile) != 1L || is.na(logfile) || !nzchar(logfile)) {
    base::stop("`logfile` must be a non-empty file path.", call. = FALSE)
  }
  if (dir.exists(logfile)) {
    base::stop("`logfile` must refer to a file. ", sQuote(logfile), " is a directory.", call. = FALSE)
  }
}


open_logfile <- function(logfile) {
  # Prefix bare names so file() treats names such as "clipboard" as paths.
  if (dirname(logfile) == ".") logfile <- file.path(".", logfile)

  report_failure <- function(condition) {
    base::stop(
      "Cannot open `logfile` ", sQuote(logfile), ". ", conditionMessage(condition),
      call. = FALSE
    )
  }
  tryCatch(file(description = logfile, open = "a"), warning = report_failure, error = report_failure)
}


#' Set Log File
#'
#' Set the log file that loggit will write to by default.
#'
#' @param logfile A single absolute or relative file path.
#' An attempt is made to convert the path into a canonical absolute form using [normalizePath()].
#' Use `NULL` to set the path to `<tmpdir>/loggit.log`.
#' @param confirm `TRUE` to print a confirmation message, or `FALSE` to suppress it.
#' @param create `TRUE` to create the log file if it does not exist, or `FALSE` to only set the path.
#'   If the file cannot be created, the function reports an error.
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
  check_logical_flag(confirm, "confirm")
  check_logical_flag(create, "create")
  old <- get_logfile()
  if (is.null(logfile)) {
    logfile <- file.path(tempdir(), "loggit.log")
  }
  check_logfile(logfile)
  if (create && !file.exists(logfile)) close(open_logfile(logfile))
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
#' @param ts_format A single character string passed to [format()] for timestamps.
#' @inheritParams set_logfile
#'
#' @return Invisible the previous timestamp format.
#'
#' @details When `confirm = TRUE`, the confirmation includes the current time in the supplied format.
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
  check_logical_flag(confirm, "confirm")
  if (!is.character(ts_format) || length(ts_format) != 1L || is.na(ts_format)) {
    base::stop("`ts_format` must be a single character string.", call. = FALSE)
  }
  current_time <- tryCatch(
    format(Sys.time(), format = ts_format),
    error = function(e) {
      base::stop("Invalid `ts_format`. ", conditionMessage(e), call. = FALSE)
    }
  )
  if (is.na(current_time)) {
    base::stop("`ts_format` must produce a timestamp.", call. = FALSE)
  }
  old <- get_timestamp_format()
  .config[["ts_format"]] <- ts_format
  if (confirm) {
    base::message(
      "Timestamp format set to ", ts_format, ".\n",
      "Current time in this format: ", current_time
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
#' @param level One log level name or a whole number from 0 to 4.
#' @inheritParams set_logfile
#'
#' @return Invisible the previous log level.
#'
#' @details Log levels are as follows:
#'  DEBUG: 4
#'  INFO: 3
#'  WARN: 2
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
  check_logical_flag(confirm, "confirm")
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
#' @param echo `TRUE` to echo log messages to `stdout`, or `FALSE` to suppress the echo.
#' @inheritParams set_logfile
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
  check_logical_flag(confirm, "confirm")
  check_logical_flag(echo, "echo")
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
#' @param ... Named arguments to set. Provide each option at most once.
#' @param .arg_list A list of named arguments to set with unique names.
#' @inheritParams set_logfile
#'
#' @return Invisible the previous call options.
#'
#' @details Call options are as follows:
#'  * `log_call`: Log the call of a condition?
#'  * `full_stack`: Log the full stack trace?
#'
#'  Options take a single `TRUE` or `FALSE`. Only one of `...` or `.arg_list` can be provided.
#'
#' @export
set_call_options <- function(..., .arg_list, confirm = TRUE) {
  check_logical_flag(confirm, "confirm")
  base::stopifnot(
    "Only one of `...` or `.arg_list` can be provided." = !(...length() > 0L && !missing(.arg_list))
  )

  if (missing(.arg_list)) .arg_list <- list(...)

  base::stopifnot(
    ".arg_list must be a list" = is.list(.arg_list),
    "All arguments must be named." =
      length(.arg_list) == 0L || !is.null(names(.arg_list)) && all(nzchar(names(.arg_list), keepNA = TRUE)),
    "Call option names must be unique." = anyDuplicated(names(.arg_list)) == 0L
  )

  default <- list(log_call = FALSE, full_stack = FALSE)
  to_default <- setdiff(names(default), names(.arg_list))
  .arg_list[to_default] <- default[to_default]
  check_logical_flag(.arg_list[["log_call"]], "log_call")
  check_logical_flag(.arg_list[["full_stack"]], "full_stack")

  # Warn if unexpected arguments are provided
  if (!all(names(.arg_list) %in% c("log_call", "full_stack"))) {
    base::warning(
      "Unexpected arguments provided: ", toString(setdiff(names(.arg_list), c("log_call", "full_stack")))
    )
  }

  old <- get_call_options()
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
