#' Message Log Handler
#'
#' This function is identical to base R's [`message`][base::message],
#' but it includes logging of the exception message via `loggit()`.
#'
#' @param .loggit Should the condition message be added to the log?
#'   If `NA` the log level set by `set_log_level()` is used to determine if the condition should be logged.
#'
#' @inheritParams base::message
#' @inheritParams loggit
#'
#' @return Invisible `NULL`.
#'
#' @family handlers
#'
#' @examples
#' \dontrun{
#'   message("Don't say such silly things!")
#'
#'   message("Don't say such silly things!", appendLF = FALSE, echo = FALSE)
#' }
#' @export
message <- function(..., domain = NULL, appendLF = TRUE, .loggit = NA, echo = get_echo()) {
  # If the input is a condition, the base function does not allow additional input
  # If the input is not a condition, the call of the message must be set manually
  # to avoid loggit2::message being displayed as a call
  is_condition <- (...length() == 1L && inherits(..1, "condition"))
  call <- sys.call()

  if (is_condition) {
    tryCatch({
      base::message(..1)
    }, message = function(m) {
      if (!isFALSE(.loggit)) {
        loggit(log_lvl = "INFO", log_msg = m[["message"]], echo = echo, ignore_log_level = isTRUE(.loggit))
      }
      # If signalCondition was used there would be no output to the console
      base::message(m)
    })
  } else {
    tryCatch({
      base::message(..., domain = domain, appendLF = appendLF)
    }, message = function(m) {
      m <- simpleMessage(message = m[["message"]], call = call)
      if (!isFALSE(.loggit)) {
        loggit(log_lvl = "INFO", log_msg = m[["message"]], echo = echo, ignore_log_level = isTRUE(.loggit))
      }
      # If signalCondition was used there would be no output to the console
      base::message(m)
    })
  }
}


#' Warning Log Handler
#'
#' This function is identical to base R's [`warning`][base::warning],
#' but it includes logging of the exception message via `loggit()`.
#'
#' @inherit base::warning params return
#' @inheritParams message
#'
#' @family handlers
#'
#' @examples
#' \dontrun{
#'   warning("You may want to review that math")
#'
#'   warning("You may want to review that math", immediate = FALSE, echo = FALSE)
#' }
#'
#' @export
warning <- function(..., call. = TRUE, immediate. = FALSE, noBreaks. = FALSE,
                    domain = NULL, .loggit = NA, echo = get_echo()) {
  # If the input is a condition, the base function does not allow additional input
  # If the input is not a condition, the call of the warning must be set manually
  # to avoid loggit2::warning being displayed as a call
  is_condition <- (...length() == 1L && inherits(..1, "condition"))
  call <- find_call()

  if (is_condition) {
    tryCatch({
      base::warning(..1)
    }, warning = function(w) {
      if (!isFALSE(.loggit)) {
        loggit(log_lvl = "WARN", log_msg = w[["message"]], echo = echo, ignore_log_level = isTRUE(.loggit))
      }
      # If signalCondition was used there would be no output to the console
      base::warning(w)
    })
  } else {
    tryCatch({
      base::warning(..., call. = call., immediate. = immediate., noBreaks. = noBreaks., domain = domain)
    }, warning = function(w) {
      w <- simpleWarning(message = w[["message"]], call = call)
      if (!isFALSE(.loggit)) {
        loggit(log_lvl = "WARN", log_msg = w[["message"]], echo = echo, ignore_log_level = isTRUE(.loggit))
      }
      # If signalCondition was used there would be no output to the console
      base::warning(w)
    })
  }
}

#' Stop Log Handler
#'
#' This function is identical to base R's [`stop`][base::stop],
#' but it includes logging of the exception message via `loggit()`.
#'
#' @inherit base::stop params
#' @inheritParams message
#'
#' @return No return value.
#'
#' @family handlers
#'
#' @examples
#' \dontrun{
#'   stop("This is a completely false condition")
#'
#'   stop("This is a completely false condition", echo = FALSE)
#' }
#'
#' @export
stop <- function(..., call. = TRUE, domain = NULL, .loggit = NA, echo = get_echo()) {
  # If the input is a condition, the base function does not allow additional input
  # If the input is not a condition, the call of the error must be set manually
  # to avoid loggit2::stop being displayed as a call
  is_condition <- (...length() == 1L && inherits(..1, "condition"))
  call <- find_call()

  if (is_condition) {
    tryCatch({
      base::stop(..1)
    }, error = function(e) {
      if (!isFALSE(.loggit)) {
        loggit(log_lvl = "ERROR", log_msg = e[["message"]], echo = echo, ignore_log_level = isTRUE(.loggit))
      }
      base::stop(e)
    })
  } else {
    tryCatch({
      base::stop(..., call. = call., domain = domain)
    }, error = function(e) {
      e <- simpleError(message = e[["message"]], call = call)
      if (!isFALSE(.loggit)) {
        loggit(log_lvl = "ERROR", log_msg = e[["message"]], echo = echo, ignore_log_level = isTRUE(.loggit))
      }
      signalCondition(e)
    })
  }
}


#' Conditional Stop Log Handler
#'
#' This function is identical to base R's [`stopifnot`][base::stopifnot],
#' but it includes logging of the exception message via `loggit()`.
#'
#' @param ...,exprs any number of `R` expressions, which should each evaluate to (a logical vector of all) `TRUE`.
#' Use *either* `...` *or* `exprs`, the latter typically an unevaluated expression of the form
#' ```
#' {
#'   expr1
#'   expr2
#'   ....
#' }
#' ```
#' Note that e.g., positive numbers are not `TRUE`, even when they are coerced to `TRUE`, e.g., inside `if(.)` or
#' in arithmetic computations in `R`.
#' If names are provided to `...`, they will be used in lieu of the default error message.
#'
#' @inheritParams base::stopifnot
#' @inheritParams message
#'
#' @family handlers
#'
#' @examples
#' \dontrun{
#'  stopifnot("This is a completely false condition" = FALSE)
#'
#'  stopifnot(5L == 5L, "This is a completely false condition" = FALSE, echo = FALSE)
#' }
#'
#' @export
stopifnot <- function(..., exprs, exprObject, local, .loggit = NA, echo = get_echo()) {
  # Since no calling function can be detected within tryCatch from base::stopifnot
  call <- if (p <- sys.parent(1L)) sys.call(p)
  # Required to avoid early (and simultaneous) evaluation of the arguments.
  # Also handles the case of 'missing' at the same time.
  call_args <- as.list(match.call()[-1L])
  if (!is.null(names(call_args))) call_args <- call_args[!names(call_args) %in% c("echo", ".loggit")]
  stop_call <- as.call(c(quote(base::stopifnot), call_args))
  tryCatch({
    eval.parent(stop_call, 1L)
  }, error = function(e) {
    cond <- simpleError(message = e[["message"]], call = call)
    if (!isFALSE(.loggit)) {
      loggit(log_lvl = "ERROR", log_msg = cond[["message"]], echo = echo, ignore_log_level = isTRUE(.loggit))
    }
    signalCondition(cond = cond)
  })
}
