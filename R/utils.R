#' Get log as `data.frame`
#'
#' Returns a `data.frame` containing all the logs in the provided `ndjson` log file.
#'
#' @inherit read_ndjson return params
#'
#' @details `read_logs()` returns a `data.frame` with the empty character columns "timestamp", "log_lvl" and "log_msg"
#' if the log file has no entries.
#'
#' @examples
#' \dontrun{
#'   read_logs()
#'
#'   read_logs(last_first = TRUE)
#' }
#' @export
read_logs <- function(logfile = get_logfile(), unsanitize = TRUE, last_first = FALSE) {

  base::stopifnot("Log file does not exist" = file.exists(logfile))

  log <- read_ndjson(logfile, unsanitize = unsanitize, last_first = last_first)

  if (nrow(log) == 0L) {
    log <- data.frame(timestamp = character(), log_lvl = character(), log_msg = character(), stringsAsFactors = FALSE)
  }

  return(log)
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
#' \dontrun{
#'   rotate_logs()
#'
#'   rotate_logs(rotate_lines = 0L)
#'
#'   rotate_logs(rotate_lines = 1000L, logfile = "my_log.log")
#' }
#' @export
rotate_logs <- function(rotate_lines = 100000L, logfile = get_logfile()) {
  base::stopifnot(rotate_lines >= 0L, "Log file does not exist" = file.exists(logfile))
  if (rotate_lines == 0L) {
    cat(NULL, file = logfile)
    return(invisible(NULL))
  }
  log_df <- readLines(logfile)
  if (length(log_df) <= rotate_lines) {
    return(invisible(NULL))
  }
  log_df <- log_df[seq.int(from = length(log_df) - rotate_lines + 1L, length.out = rotate_lines)]
  write(log_df, logfile, append = FALSE)
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

#' Write log to csv file
#'
#' Creates a csv file from the ndjson log file.
#'
#' @param file Path to write csv file to.
#' @param ... Additional arguments to pass to `utils::write.csv()`.
#' @inheritParams read_logs
#'
#' @return Invisible `NULL`.
#'
#' @details Unescaping of special characters can lead to unexpected results. Use `unsanitize = TRUE` with caution.
#'
#' @examples
#' \dontrun{
#'   convert_to_csv("my_log.csv")
#'
#'   convert_to_csv("my_log.csv", logfile = "my_log.log", last_first = TRUE)
#' }
#'
#' @export
convert_to_csv <- function(file, logfile = get_logfile(), unsanitize = FALSE, last_first = FALSE, ...) {
  if (!requireNamespace(package = "utils", quietly = TRUE)) {
    stop("Package 'utils' is not available. Please install it, if you want to use this function.") # nocov
  }

  log <- read_logs(logfile = logfile, unsanitize = unsanitize, last_first = last_first)

  utils::write.csv(log, file = file, row.names = FALSE, ...)

  return(invisible(NULL))
}

#' Get Log Level Name
#'
#' @param level Log level as integer.
#'
#' @return The log level name.
#'
#' @keywords internal
get_lvl_name <- function(level) {
  base::stopifnot(is.integer(level), level >= 0L, level <= 4L)
  lvl <- c("NONE", "ERROR", "WARN", "INFO", "DEBUG")
  lvl[level + 1L]
}

#' Get Log Level Integer
#'
#' @param level Log level as character.
#'
#' @return The log level integer.
#'
#' @keywords internal
get_lvl_int <- function(level) {
  base::stopifnot(is.character(level), level %in% c("NONE", "ERROR", "WARN", "INFO", "DEBUG"))
  match(level, c("NONE", "ERROR", "WARN", "INFO", "DEBUG")) - 1L
}

#' Convert Log Level Input to Integer
#'
#' @param level Log level as character or numeric.
#'
#' @return The log level integer.
#'
#' @keywords internal
convert_lvl_input <- function(level) {
  if (is.numeric(level)) {
    level <- as.integer(level)
    base::stopifnot(level >= 0L, level <= 4L)
  } else {
    level <- get_lvl_int(level)
  }
  level
}
