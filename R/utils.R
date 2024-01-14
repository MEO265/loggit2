#' Return log file as an R data frame
#'
#' This function returns a `data.frame` containing all the logs in the provided
#' `ndjson` log file. If no explicit log file is provided, calling this function
#' will return a data frame of the log file currently pointed to by the `loggit`
#' functions.
#'
#' @param logfile Path to log file. Will default to currently-set log file.
#' @param unsanitizer Unsanitizer function to use. For more info on sanitizers,
#'   please see the [sanitizers] section of the package documentation.
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
#' `loggit` makes no assumptions nor enforcement of calling this function; that
#' is to say, the onus of log rotation is up to the developer.
#'
#' @param rotate_lines The number of log entries to keep in the logfile.
#'   Defaults to 100,000.
#' @param logfile Log file to truncate. Defaults to the currently-configured log
#'   file.
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
  base::stopifnot(rotate_lines >= 0L)
  log_df <- read_logs(logfile)
  if (nrow(log_df) <= rotate_lines) return(invisible(NULL))
  log_df <- log_df[seq.int(from = nrow(log_df) - rotate_lines + 1L, length.out = rotate_lines),]
  write_ndjson(log_df, logfile, echo = FALSE, overwrite = TRUE)
}
