#' Return log file as an R data frame
#'
#' This function returns a `data.frame` containing all the logs in the provided `ndjson` log file.
#'
#' @param logfile Path to log file.
#' @param unsanitizer [Unsanitizer function][sanitizers] to run over elements in log.
#'   Defaults to [default_ndjson_unsanitizer()]
#'
#' @return A `data.frame`.
#'
#' @examples
#'   set_logfile(file.path(tempdir(), "loggit.log"), confirm = FALSE)
#'   message("Test log message")
#'   read_logs()
#'
#' @export
read_logs <- function(logfile = get_logfile(), unsanitizer = default_ndjson_unsanitizer) {

  base::stopifnot("Log file does not exist" = file.exists(logfile))

  read_ndjson(logfile, unsanitizer = unsanitizer)
}


#' Rotate log file
#'
#' Truncates the log file to the line count provided as `rotate_lines`.
#'
#' @param rotate_lines The number of log entries to keep in the logfile.
#' @param logfile Log file to truncate.
#'
#' @return Invisible `NULL`.
#'
#' @examples
#'   # Truncate "default" log file to 100 lines
#'   set_logfile()
#'   for (i in 1:150) {loggit("INFO", i, echo = FALSE)}
#'   rotate_logs(100)
#'
#'   # Truncate a different log file to 250 lines
#'   another_log <- file.path(tempdir(), "another.log")
#'   set_logfile(another_log)
#'   for (i in 1:300) {loggit("INFO", i, echo = FALSE)}
#'   set_logfile() # clears pointer to other log file
#'   rotate_logs(250, another_log)
#'
#' @export
rotate_logs <- function(rotate_lines = 100000L, logfile = get_logfile()) {
  base::stopifnot(rotate_lines >= 0L, "Log file does not exist" = file.exists(logfile))
  if (rotate_lines == 0L) {
    cat(NULL, file = logfile)
    return(invisible(NULL))
  }
  log_df <- read_logs(logfile, unsanitizer = identity)
  if (nrow(log_df) <= rotate_lines) {
    return(invisible(NULL))
  }
  log_df <- log_df[seq.int(from = nrow(log_df) - rotate_lines + 1L, length.out = rotate_lines),]
  write_ndjson(log_df, logfile, echo = FALSE, overwrite = TRUE)
}

#' Find the Call of a Parent Function in the Call Hierarchy
#'
#' This function is designed to inspect the call hierarchy and identify the call of a parent function.
#' Any wrapper environments above the global R environment that some IDEs cause are ignored.
#'
#' @return Returns the call of the parent function, or `NULL` if no such call is found.
#'
#' @keywords internal
# Some parts cannot be tested in testthat
find_call <- function() {
  parents <- sys.parents()
  # If there are fewer than 3 calls, it means there's no parent call to return
  if (length(parents) <= 2L) return(NULL) # nocov
  # Ignore any wrapper environments above the global R environment
  # For example necessary in JetBrains IDEs
  id <- match(0L, parents)
  if (id >= length(parents) - 1L) return(NULL) # nocov
  return(sys.call(-2L))
}