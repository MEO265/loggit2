#' Diagnostic Messages Log Handler
#'
#' This function is identical to base R's [`message`][base::message],
#' but it includes logging of the exception message via `loggit()`.
#'
#' @inherit base::message params return
#'
#' @param .loggit Should loggit function execute? Defaults to `TRUE`.
#' @param echo Should loggit's log entry be echoed to the console, as well? Defaults to `TRUE`.
#'
#' @family handlers
#'
#' @examples
#'   if (2 < 1) message("Don't say such silly things!")
#'
#' @export
message <- function(..., domain = NULL, appendLF = TRUE, .loggit = TRUE, echo = TRUE) {
  args <- paste(list(...), collapse = "")
  if (.loggit) loggit(log_lvl = "INFO", log_msg = args[[1]], echo = echo)

  base::message(unlist(args), domain = domain, appendLF = appendLF)
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
  args <- paste(list(...), collapse = "")
  if (.loggit) loggit(log_lvl = "WARN", log_msg = args[[1L]], echo = echo)
  base::warning(unlist(args), call. = call., immediate. = immediate.,
                noBreaks. = noBreaks., domain = domain)
}


#' Stop Function Log Handler
#'
#' This function is identical to base R's [`stop`][base::stop],
#' but it includes logging of the exception message via `loggit()`.
#'
#' @inherit base::stop params
#' @inheritParams message
#'
#' @family handlers
#'
#' @examples
#'   if (2 < 1) stop("This is a completely false condition, which throws an error")
#'
#' @export
stop <- function(..., call. = TRUE, domain = NULL, .loggit = TRUE, echo = TRUE) {
  args <- paste(list(...), collapse = "")
  if (.loggit) loggit(log_lvl = "ERROR", log_msg = args[[1L]], echo = echo)

  base::stop(unlist(args), call. = call., domain = domain)
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
stopifnot <- function(..., exprObject, local, .loggit = TRUE ,echo = TRUE) {
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
    if(.loggit) loggit(log_lvl = "ERROR", log_msg = cond$message, echo = echo)
    signalCondition(cond = cond)
  })
}
