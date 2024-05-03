#' Diagnostic Messages Log Handler
#'
#' This function is identical to base R's [`message`][base::message],
#' but it includes logging of the exception message via `loggit()`.
#'
#' @inherit base::message params
#'
#' @param .loggit Should `loggit()` execute? Defaults to `TRUE`.
#' @param echo Should `loggit()`'s log entry be echoed to the console, as well? Defaults to `TRUE`.
#'
#' @return Invisible `NULL`.
#'
#' @family handlers
#'
#' @examples
#'   if (2 < 1) message("Don't say such silly things!")
#'
#' @export
message <- function(..., domain = NULL, appendLF = TRUE, .loggit = TRUE, echo = TRUE) {
  # If the input is a condition, the base function does not allow additional input
  # If the input is not a condition, the call of the message must be set manually
  # to avoid loggit2::message being displayed as a call
  is_condition <- (...length() == 1L && inherits(..1, "condition"))
  call <- sys.call()

  if (is_condition) {
    tryCatch({
      base::message(..1)
    }, message = function(m) {
      if (.loggit) loggit(log_lvl = "INFO", log_msg = m$message, echo = echo)
      # If signalCondition was used there would be no output to the console
      base::message(m)
    })
  } else {
    tryCatch({
      base::message(..., domain = domain, appendLF = appendLF)
    }, message = function(m) {
      m <- simpleMessage(message = m$message, call = call)
      if (.loggit) loggit(log_lvl = "INFO", log_msg = m$message, echo = echo)
      # If signalCondition was used there would be no output to the console
      base::message(m)
    })
  }
}


#' Warning Messages Log Handler
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
#'   if (2 < 1) warning("You may want to review that math, and so this is your warning")
#'
#' @export
warning <- function(..., call. = TRUE, immediate. = FALSE, noBreaks. = FALSE,
                    domain = NULL, .loggit = TRUE, echo = TRUE) {
  # If the input is a condition, the base function does not allow additional input
  # If the input is not a condition, the call of the warning must be set manually
  # to avoid loggit2::warning being displayed as a call
  is_condition <- (...length() == 1L && inherits(..1, "condition"))
  call <- find_call()

  if (is_condition) {
    tryCatch({
      base::warning(..1)
    }, warning = function(w) {
      if (.loggit) loggit(log_lvl = "WARN", log_msg = w$message, echo = echo)
      # If signalCondition was used there would be no output to the console
      base::warning(w)
    })
  } else {
    tryCatch({
      base::warning(..., call. = call., immediate. = immediate., noBreaks. = noBreaks., domain = domain)
    }, warning = function(w) {
      w <- simpleWarning(message = w$message, call = call)
      if (.loggit) loggit(log_lvl = "WARN", log_msg = w$message, echo = echo)
      # If signalCondition was used there would be no output to the console
      base::warning(w)
    })
  }
}

#' Stop Function Log Handler
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
#'   if (2 < 1) stop("This is a completely false condition, which throws an error")
#'
#' @export
stop <- function(..., call. = TRUE, domain = NULL, .loggit = TRUE, echo = TRUE) {
  # If the input is a condition, the base function does not allow additional input
  # If the input is not a condition, the call of the error must be set manually
  # to avoid loggit2::stop being displayed as a call
  is_condition <- (...length() == 1L && inherits(..1, "condition"))
  call <- find_call()

  if (is_condition) {
    tryCatch({
      base::stop(..1)
    }, error = function(e) {
      if (.loggit) loggit(log_lvl = "ERROR", log_msg = e$message, echo = echo)
      base::stop(e)
    })
  } else {
    tryCatch({
      base::stop(..., call. = call., domain = domain)
    }, error = function(e) {
      e <- simpleError(message = e$message, call = call)
      if (.loggit) loggit(log_lvl = "ERROR", log_msg = e$message, echo = echo)
      signalCondition(e)
    })
  }
}


#' Conditional Stop Function Log Handler
#'
#' This function is identical to base R's [`stopifnot`][base::stopifnot],
#' but it includes logging of the exception message via `loggit()`.
#'
#' @inherit base::stopifnot params return
#' @inheritParams message
#'
#' @family handlers
#'
#' @examples
#'   stopifnot("This is a completely false condition, which throws an error" = TRUE)
#'
#' @export
stopifnot <- function(..., exprObject, local, .loggit = TRUE, echo = TRUE) {
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
    cond <- simpleError(message = e$message, call = call)
    if (.loggit) loggit(log_lvl = "ERROR", log_msg = cond$message, echo = echo)
    signalCondition(cond = cond)
  })
}
