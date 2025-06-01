#' Debug Log Handler
#'
#' This function works like base R's [`warning`][base::warning] ,
#' but is silent, includes logging of the exception message via `loggit()` and does not allow conditions as input.
#'
#' @inherit base::warning params
#' @inherit message params
#' @inheritParams loggit
#'
#' @return No return value.
#'
#' @family handlers
#'
#' @examples
#' \dontrun{
#'   debuginfo("This is a completely false condition")
#'
#'   debuginfo("This is a completely false condition", echo = FALSE)
#' }
#'
#' @details This function is more than just a wrapper around `loggit()` with a log level of "DEBUG".
#' It has the ability to track the call stack and log it if `call.` is set to `TRUE` and to automatically
#' translate the input into a message using `.makeMessage()`, like `warning()` does.
#'
#' @export
debuginfo <- function(..., call. = TRUE, .loggit = NA, echo = get_echo()) {
  # The call of the error must be set manually for loggit_internal
  call <- if (call.) find_call()
  if (isTRUE(.loggit) || (!isFALSE(.loggit) && get_log_level() >= 4L)) {
    loggit_internal(log_lvl = "DEBUG", log_msg = .makeMessage(..., domain = NULL), log_call = call, echo = echo)
  }
}

