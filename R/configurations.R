# Configuration Environment, to be used as needed.
.config <- new.env(parent = emptyenv())


#' Set Log File
#'
#' Set the log file that loggit will write to.
#'
#' @param logfile Absolut or relative path to log file.
#' An attempt is made to convert the path into a canonical absolute form using [normalizePath()].
#' If `NULL` will set to `<tmpdir>/loggit.log`.
#' @param confirm Print confirmation of log file setting? Defaults to `TRUE`.
#' @param create Create the log file if it does not exist? Defaults to `TRUE`.
#'
#' @details No logs outside of a temporary directory will be written until this is set explicitly, as per CRAN policy.
#' Therefore, the default behavior is to create a file named `loggit.log` in your system's temporary directory.
#'
#' @return Invisible `NULL`.
#'
#' @examples set_logfile(file.path(tempdir(), "loggit.log"))
#'
#' @export
set_logfile <- function(logfile = NULL, confirm = TRUE, create = TRUE) {
  if (is.null(logfile)) {
    logfile <- file.path(tempdir(), "loggit.log")
  }
  if (create && !file.exists(logfile)) file.create(logfile)
  .config$logfile <- normalizePath(logfile, winslash = "/", mustWork = FALSE)
  if (confirm) base::message("Log file set to ", .config$logfile)
  invisible(NULL)
}


#' Get Log File
#'
#' Return the log file that `loggit()` will write to.
#'
#' @return The log file path.
#'
#' @examples get_logfile()
#'
#' @export
get_logfile <- function() {
  .config$logfile
}


#' Set Timestamp Format
#'
#' Set timestamp format for use in output logs.
#'
#' @details This function performs no time format validations, but will echo out the current time in
#' the provided format for manual validation.
#'
#' This function provides no means of setting a timezone, and instead relies on
#' the host system's time configuration to provide this. This is to enforce
#' consistency across software running on the host.
#'
#' @param ts_format ISO date format. Defaults to ISO-8601 (e.g.
#'   "2020-01-01T00:00:00+0000").
#' @param confirm Print confirmation message of timestamp format? Defaults to
#'   `TRUE`.
#'
#' @return Invisible `NULL`.
#'
#' @examples set_timestamp_format("%Y-%m-%d %H:%M:%S")
#'
#' @export
set_timestamp_format <- function(ts_format = "%Y-%m-%dT%H:%M:%S%z", confirm = TRUE) {
  .config$ts_format <- ts_format
  if (confirm) {
    base::message(
      "Timestamp format set to ", ts_format, ".\n",
      "Current time in this format: ", format(Sys.time(), format = ts_format)
    )
  }
  invisible(NULL)
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
  .config$ts_format
}
