#' Log any expressions
#'
#' Log code without having to explicitly use the `loggit2` handlers.
#' This is particularly useful for code that cannot be customized, e.g. from third-party packages.
#'
#' @param exp An `expression` to evaluate.
#' @param log_level The log level to use.
#' @param logfile Path of log file to write to.
#' @inheritParams loggit
#'
#' @details If `loggit2` handlers are already used in the expression, this can lead to conditions being logged
#' twice (in the same or different files).
#' The first logged condition opens an append connection, reused until `exp`
#' finishes. Each entry is written and flushed under the shared process lock.
#' Opening and closing also use that lock; evaluating `exp` does not hold it.
#' If no condition is logged, a missing log file is not created.
#'
#' @return The result of the expression.
#'
#' @examples
#' \dontrun{
#'  x <- with_loggit(5L + 5L)
#'
#'  with_loggit(base::message("Test log message"))
#'
#'  with_loggit(base::warning("Test log message"), echo = FALSE, logfile = "my_log.log")
#'
#'  x <- with_loggit({
#'     y <- 5L
#'     base::message("Test log message")
#'     base::warning("Test log message")
#'     1L + y
#'  })
#' }
#'
#' @export
with_loggit <- function(exp, logfile = get_logfile(), echo = get_echo(), log_level = get_log_level()) {
  log_level <- convert_lvl_input(log_level)
  log_error <- log_level >= 1L
  log_warn <- log_level >= 2L
  log_info <- log_level >= 3L

  logfile <- normalize_logfile(logfile)
  lockfile <- paste0(logfile, ".lock")
  log_con <- NULL
  on.exit({
    if (!is.null(log_con)) {
      tryCatch(with_log_lock(logfile, close(log_con), lockfile = lockfile), error = function(e) NULL)
    }
  }, add = TRUE)
  # Open lazily so an empty scope need not create or delete a shared file.
  get_log_con <- function() {
    if (is.null(log_con)) with_log_lock(logfile, log_con <<- file(logfile, open = "a"), lockfile = lockfile)
    log_con
  }

  result <- withVisible(withCallingHandlers(
    exp,
    error = function(e) {
      if (log_error) {
        loggit_internal(
          log_lvl = "ERROR", log_msg = conditionMessage(e), log_call = conditionCall(e),
          echo = echo, logfile = get_log_con(), lockfile = lockfile
        )
      }
    },
    warning = function(w) {
      if (log_warn) {
        loggit_internal(
          log_lvl = "WARN", log_msg = conditionMessage(w), log_call = conditionCall(w),
          echo = echo, logfile = get_log_con(), lockfile = lockfile
        )
      }
    },
    message = function(m) {
      if (log_info) {
        loggit_internal(
          log_lvl = "INFO", log_msg = conditionMessage(m), log_call = conditionCall(m),
          echo = echo, logfile = get_log_con(), lockfile = lockfile
        )
      }
    }
  ))
  if (!is.null(log_con)) {
    with_log_lock(logfile, close(log_con), lockfile = lockfile)
    log_con <- NULL
  }
  if (result$visible) result$value else invisible(result$value)
}
