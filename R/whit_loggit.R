#' Log any expressions
#'
#' Log code without having to explicitly use the `loggit2` handlers.
#' This is particularly useful for code that cannot be customized, e.g. from third-party packages.
#'
#' @param exp An `expression` to evaluate.
#' @inheritParams loggit
#'
#' @details If `loggit2` handlers are already used in the expression, this can lead to conditions being logged
#' twice (in the same or different files).
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
with_loggit <- function(exp, logfile = get_logfile(), echo = TRUE) {
  withCallingHandlers(
    exp,
    error = function(e) {
      loggit(log_lvl = "ERROR", log_msg = e[["message"]], echo = echo, logfile = logfile)
    },
    warning = function(w) {
      loggit(log_lvl = "WARN", log_msg = w[["message"]], echo = echo, logfile = logfile)
    },
    message = function(m) {
      loggit(log_lvl = "INFO", log_msg = m[["message"]], echo = echo, logfile = logfile)
    }
  )
}
