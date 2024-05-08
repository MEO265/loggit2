#' @useDynLib loggit2, .registration=TRUE
NULL

#' Log messages and R objects
#'
#' Log messages and R objects to a [ndjson](https://github.com/ndjson) log file.
#'
#' @param log_lvl Log level. A atomic vector of length one (usually `character`). Will be coerced to `character`.
#' @param log_msg Log message. A atomic vector of length one (usually `character`). Will be coerced to `character`.
#' @param ... Named arguments, each a atomic vector of length one, you wish to log. Will be coerced to `character`.
#'   The names of the arguments are treated as column names in the log.
#' @param custom_log_lvl Allow log levels other than "DEBUG", "INFO", "WARN", and "ERROR"?
#' @param ignore_log_level Ignore the log level set by `set_log_level()`?
#' @inheritParams write_ndjson
#'
#' @return Invisible `NULL`.
#'
#' @examples
#' \dontrun{
#'   loggit("DEBUG", "This is a message")
#'
#'   loggit("INFO", "This is a message", echo = FALSE)
#'
#'   loggit("CUSTOM", "This is a message of a custom log_lvl", custom_log_lvl = TRUE)
#'
#'   loggit(
#'    "INFO", "This is a message", but_maybe = "you want more fields?",
#'     sure = "why not?", like = 2, or = 10, what = "ever"
#'   )
#' }
#' @export
loggit <- function(log_lvl, log_msg, ..., echo = get_echo(), custom_log_lvl = FALSE, logfile = get_logfile(),
                   ignore_log_level = FALSE) {

  if (length(log_msg) > 1L) {
    base::warning("log_msg should be of length one, only the first element will be used.")
    log_msg <- log_msg[[1L]]
  }
  if (length(log_lvl) > 1L) {
    base::warning("log_lvl should be of length one, only the first element will be used.")
    log_lvl <- log_lvl[[1L]]
  }
  # Try to suggest limited log levels to prevent typos by users
  log_lvls <- c("DEBUG", "INFO", "WARN", "ERROR")
  if (!ignore_log_level || !custom_log_lvl) {
    is_default_log_lvl <- log_lvl %in% log_lvls
  }
  if (!custom_log_lvl && !is_default_log_lvl) {
    base::stop(
      "Nonstandard log_lvl ('", log_lvl, "').\n",
      "Should be one of DEBUG, INFO, WARN, or ERROR. Please check if you made a typo.\n",
      "If you insist on passing a custom level, please set 'custom_log_lvl = TRUE' in the call to 'loggit()'."
    )
  }

  if (!ignore_log_level && is_default_log_lvl && get_log_level() < get_lvl_int(log_lvl)) {
    return(invisible(NULL))
  }

  timestamp <- format(Sys.time(), format = .config[["ts_format"]])

  if (...length() > 0L) {
    dots <- list(...)
    # Avoid using ...names() to remain compatible with versions earlier than 4.1.0
    if (is.null(names(dots)) || any(nchar(names(dots)) == 0L) || anyNA(names(dots))) {
      base::stop("All custom log fields should be named.")
    }
    if (any(lengths(dots) > 1L)) {
      base::warning("Each custom log field should be of length one, or else your logs will be multiplied!")
    }
    log_df <- data.frame(
      timestamp = timestamp, log_lvl = as.character(log_lvl), log_msg = as.character(log_msg), dots,
      stringsAsFactors = FALSE, check.names = FALSE, fix.empty.names = FALSE
    )
  } else {
    log_df <- data.frame(
      timestamp = timestamp, log_lvl = as.character(log_lvl), log_msg = as.character(log_msg),
      stringsAsFactors = FALSE
    )
  }

  write_ndjson(log_df, echo = echo, logfile = logfile)
}
