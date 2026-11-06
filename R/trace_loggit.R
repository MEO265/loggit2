#' Log Function Calls
#'
#' Register DEBUG log entries at the beginning and/or end of subsequent calls to
#' a function using [base::trace()].
#'
#' @param fun A function reference, such as `utils::write.table` or `my_function`.
#'   Character names are not supported. The reference is passed to `trace()`
#'   without changing its function or namespace resolution.
#' @param message An entry message template, or `NULL` to disable entry logging.
#'   Placeholders such as `{file}` must name explicit formal arguments of `fun`.
#'   The `...` argument and expressions such as `{nrow(x)}` are not supported.
#' @param exit An exit message template, or `NULL` to disable exit logging.
#'   The only supported placeholder is `{returnValue}`.
#' @param where Where to look for the function, as in [base::trace()].
#'
#' @details
#' Templates consist of literal text and placeholders. Double braces (`{{` and
#' `}}`) produce literal braces. Surrounding whitespace in placeholders is ignored.
#' Templates are checked before tracing is installed. At least one template must
#' be supplied.
#'
#' Referenced arguments are evaluated on entry, including their default values.
#' Unreferenced arguments are not evaluated by the tracer. Vectors are collapsed
#' with `", "`, and `NULL` is rendered as `"NULL"`. On exit, `{returnValue}` is
#' obtained from [base::returnValue()]; it is rendered as `"<unavailable>"` when
#' no return value is available, for example after an error.
#'
#' Entries use the current `loggit()` configuration with `echo = FALSE`. When the
#' current log level excludes DEBUG, templates and argument values are not
#' evaluated. Local settings of [with_loggit()] do not apply to these direct
#' `loggit()` calls.
#'
#' The restrictions of `trace()` also apply: tracing replaces an existing trace,
#' and the cleanup function restores the untraced function. An `on.exit()` call
#' with `add = FALSE` in the target function can replace the exit hook. Only calls
#' through the traced binding are affected; previously saved function copies are
#' unchanged. Entry logs record attempted calls, including calls that later fail.
#' Trace expressions do not recursively trigger other tracers.
#'
#' Functions such as `utils::write.csv()` expose only `...`, so their entry
#' templates cannot contain argument placeholders. Trace `utils::write.table()`
#' to log the actual `file` argument used by `write.csv()` and `write.csv2()`.
#'
#' @return Invisibly, a function with no arguments that removes the trace.
#'
#' @examples
#' \dontrun{
#' set_log_level("DEBUG")
#' double_value <- function(x) x * 2
#' stop_trace <- trace_loggit(
#'   double_value,
#'   message = "Start: x={x}",
#'   exit = "End: result={returnValue}"
#' )
#' double_value(21)
#' stop_trace()
#'
#' stop_writes <- trace_loggit(
#'   utils::write.table,
#'   message = "Writing to {file}; append={append}"
#' )
#' utils::write.csv(iris, file = tempfile(fileext = ".csv"))
#' stop_writes()
#' }
#' @export
trace_loggit <- function(fun, message = NULL, exit = NULL, where = topenv(parent.frame())) {
  if (!is.function(fun)) {
    base::stop("Expected a function reference, not a name.", call. = FALSE)
  }
  if (is.null(message) && is.null(exit)) {
    base::stop("Supply at least one of 'message' or 'exit'.", call. = FALSE)
  }

  caller <- parent.frame()
  force(where)
  reference <- substitute(fun)
  entry_formatter <- compile_log_message(message, setdiff(names(formals(fun)), "..."), "message")
  exit_formatter <- compile_log_message(exit, "returnValue", "exit")

  entry_tracer <- if (!is.null(entry_formatter)) substitute(
    if (LEVEL() >= 4L) LOGGER("DEBUG", FORMAT(base::environment()), echo = FALSE),
    list(LEVEL = get_log_level, LOGGER = loggit, FORMAT = entry_formatter)
  )
  exit_tracer <- if (!is.null(exit_formatter)) substitute(
    if (LEVEL() >= 4L) LOGGER(
      "DEBUG", FORMAT(base::list(returnValue = base::returnValue(default = "<unavailable>"))), echo = FALSE
    ),
    list(LEVEL = get_log_level, LOGGER = loggit, FORMAT = exit_formatter)
  )

  trace_call <- substitute(
    base::trace(FUN, tracer = quote(ENTRY), exit = quote(EXIT), where = WHERE, print = FALSE),
    list(FUN = reference, ENTRY = entry_tracer, EXIT = exit_tracer, WHERE = where)
  )
  untrace_call <- substitute(
    base::untrace(FUN, where = WHERE),
    list(FUN = reference, WHERE = where)
  )
  eval(trace_call, envir = caller)
  active <- TRUE

  invisible(function() {
    if (active) {
      eval(untrace_call, envir = caller)
      active <<- FALSE
    }
    invisible(NULL)
  })
}

compile_log_message <- function(template, allowed, argument) {
  if (is.null(template)) return(NULL)
  if (!is.character(template) || length(template) != 1L || is.na(template)) {
    base::stop("'", argument, "' must be a single, non-missing character string or NULL.", call. = FALSE)
  }

  parts <- regmatches(template, gregexpr("\\{\\{|\\}\\}|\\{[^{}]*\\}|[^{}]+|[{}]", template, perl = TRUE))[[1L]]
  if (any(parts %in% c("{", "}"))) {
    base::stop("Unmatched brace in '", argument, "' template.", call. = FALSE)
  }
  slots <- startsWith(parts, "{") & parts != "{{"
  fields <- trimws(substring(parts[slots], 2L, nchar(parts[slots]) - 1L))
  unknown <- setdiff(fields, allowed)
  if (length(unknown) > 0L) {
    base::stop("Invalid placeholders in '", argument, "': ", paste(unknown, collapse = ", "), call. = FALSE)
  }

  parts[parts == "{{"] <- "{"
  parts[parts == "}}"] <- "}"

  function(values) {
    result <- parts
    result[slots] <- vapply(fields, function(name) {
      value <- if (is.environment(values)) get(name, envir = values, inherits = FALSE) else values[[name]]
      if (is.null(value)) "NULL" else paste(as.character(value), collapse = ", ")
    }, character(1L))
    paste0(result, collapse = "")
  }
}
