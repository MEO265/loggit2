#' @useDynLib loggit2, .registration=TRUE
NULL

#' Log entries to file
#'
#' Log entries to a [ndjson](https://github.com/ndjson) log file, defined by [set_logfile()].
#'
#' @param log_lvl Log level coerceable to `character`. For details see parameter `custom_log_lvl`.
#' @param log_msg Main log message. Will be coerced to class `character`.
#' @param ... Named arguments, each a atomic vector of length one, you wish to log.
#'   The names of the arguments are treated as column names in the log.
#' @param echo Should the log file entry be printed to the console as well?
#'   Defaults to `TRUE`.
#' @param custom_log_lvl Allow log levels other than "DEBUG", "INFO", "WARN",
#'   and "ERROR"? Defaults to `FALSE`.
#' @inheritParams write_ndjson
#'
#' @return Invisible `NULL`.
#'
#' @examples
#'   loggit("INFO", "This is a message", but_maybe = "you want more fields?",
#'   sure = "why not?", like = 2, or = 10, what = "ever")
#'
#' @export
loggit <- function(log_lvl, log_msg, ..., echo = TRUE, custom_log_lvl = FALSE, logfile = get_logfile()) {
  # Try to suggest limited log levels to prevent typos by users
  log_lvls <- c("DEBUG", "INFO", "WARN", "ERROR")
  if (!custom_log_lvl && !(log_lvl %in% log_lvls)) {
    base::stop(
      "Nonstandard log_lvl ('", log_lvl, "').\n",
      "Should be one of DEBUG, INFO, WARN, or ERROR. Please check if you made a typo.\n",
      "If you insist on passing a custom level, please set 'custom_log_lvl = TRUE' in the call to 'loggit()'."
    )
  }

  if (length(log_msg) > 1L) {
    base::warning("log_msg should be of length one, only the first element will be used.")
    log_msg <- log_msg[1L]
  }
  if (length(log_lvl) > 1L) {
    base::warning("log_lvl should be of length one, only the first element will be used.")
    log_lvl <- log_lvl[1L]
  }

  timestamp <- format(Sys.time(), format = .config$ts_format)

  if (...length() > 0L) {
    dots <- list(...)
    if (any(lengths(dots) > 1L)) {
      base::warning("Each custom log field should be of length one, or else your logs will be multiplied!")
    }
    log_df <- data.frame(
      timestamp = timestamp,
      log_lvl = as.character(log_lvl),
      log_msg = as.character(log_msg),
      dots,
      stringsAsFactors = FALSE
    )
  } else {
    log_df <- data.frame(
      timestamp = timestamp,
      log_lvl = as.character(log_lvl),
      log_msg = as.character(log_msg),
      stringsAsFactors = FALSE
    )
  }

  write_ndjson(log_df, echo = echo, logfile = logfile)
}
