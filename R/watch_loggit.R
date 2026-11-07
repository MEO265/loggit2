#' Log Changes to a Variable
#'
#' Register DEBUG log entries for subsequent changes to an existing variable,
#' using [base::makeActiveBinding()].
#'
#' @param variable A bare variable name, such as `counter`. Character strings and
#'   expressions such as `state$counter` are not supported; use `where = state`
#'   to watch a binding in an environment.
#' @param message `NULL` (the default) to describe the changes automatically, or
#'   a single message template. Supported placeholders are `{name}`, `{oldValue}`,
#'   and `{newValue}`. Double braces (`{{` and `}}`) produce literal braces.
#'   Surrounding whitespace in placeholders is ignored. Expressions and other
#'   placeholders are rejected before the binding is changed.
#' @param where The environment containing the variable. Defaults to the calling
#'   environment. The variable must exist directly in this environment.
#'
#' @details
#' Registration replaces an ordinary, unlocked binding with an active binding.
#' Reads return its current value without logging. Assignments using `<-`, `<<-`,
#' [base::assign()], or replacement operations such as `x[1] <- 2` log a change
#' when the old and new values differ according to [base::identical()]. The initial
#' value is not logged. Registering a delayed binding or a function argument forces
#' its initial value. Existing active bindings and locked environments or bindings
#' are rejected.
#'
#' Entries use the current session-wide `loggit()` configuration with
#' `echo = FALSE`; local settings of [with_loggit()] do not apply. With DEBUG
#' disabled, the active binding reads or stores the value and returns before
#' comparing, formatting or logging. Access still goes through the active binding,
#' and R can copy objects during replacement operations. Turning DEBUG back on
#' uses the latest stored value.
#'
#' The default message lists changes to type, class, attributes, and values.
#' Changes within equally sized vectors, arrays, lists, and data frames can
#' include an element path, such as `[2]` or `[["count"]][2]`. Paths describe the
#' resulting difference between values, regardless of the assignment syntax.
#' The message shows up to five differences and summarizes deep or resized
#' values. Value previews are abbreviated for large objects.
#'
#' With a custom template, `NULL` is rendered as `"NULL"`; nonempty atomic vectors
#' are converted using [base::as.character()] and collapsed with `", "`. Other
#' objects are rendered using [base::deparse()]. Formatting or logging errors
#' propagate after the new value has been stored. Recursive changes made while
#' this watch is logging update the variable without generating another entry
#' from the same watch.
#'
#' Only assignments to the registered binding can be observed. Changes inside
#' environments, external pointers, or other objects with reference semantics
#' without assigning a new value to the binding cannot be detected. A local
#' variable that shadows the watched binding is a different variable.
#'
#' Call the returned cleanup function before removing or locking the binding or
#' its environment. Cleanup restores an ordinary binding containing the latest
#' value and can be called repeatedly. If the binding has been removed or replaced,
#' cleanup leaves it alone. A binding locked after registration must be unlocked
#' before cleanup. Locking the environment prevents restoration permanently.
#'
#' @return Invisibly, a function with no arguments that stops watching.
#'
#' @examples
#' \dontrun{
#' set_log_level("DEBUG")
#' counter <- 0L
#' stop_watch <- watch_loggit(counter)
#' counter <- counter + 1L # DEBUG: counter: value 0L -> 1L
#' counter <- 1L          # No change, so no entry
#' stop_watch()           # counter remains 1L
#'
#' state <- new.env()
#' state$status <- "waiting"
#' stop_watch <- watch_loggit(status, "{name}: {oldValue} => {newValue}", where = state)
#' state$status <- "ready"
#' stop_watch()
#' }
#' @export
watch_loggit <- function(variable, message = NULL, where = parent.frame()) {
  reference <- substitute(variable)
  if (missing(variable) || !is.symbol(reference)) {
    base::stop("Supply a bare variable name.", call. = FALSE)
  }
  name <- as.character(reference)
  if (!is.environment(where)) {
    base::stop("'where' must be an environment.", call. = FALSE)
  }
  formatter <- if (is.null(message)) describe_watch_changes else compile_watch_message(message)
  if (!exists(name, envir = where, inherits = FALSE)) {
    base::stop("Variable '", name, "' must exist directly in 'where'.", call. = FALSE)
  }
  if (environmentIsLocked(where) || bindingIsLocked(name, where)) {
    base::stop("Cannot watch a locked binding or environment.", call. = FALSE)
  }
  if (bindingIsActive(name, where)) {
    base::stop("Cannot replace an existing active binding.", call. = FALSE)
  }

  state <- new.env(parent = emptyenv())
  state$value <- get(name, envir = where, inherits = FALSE)
  state$busy <- FALSE
  binding <- function(value) {
    if (.config$level < 4L) {
      state$retained <- NULL
      if (missing(value)) return(state$value)
      return(invisible(state$value <- value))
    }
    if (missing(value)) {
      # Keep the old value shared so R copies it before a replacement at DEBUG.
      state$retained <- state$value
      return(state$value)
    }
    force(value)
    previous <- state$value
    state$value <- value
    state$retained <- NULL
    if (!state$busy && !identical(previous, value)) {
      state$busy <- TRUE
      on.exit(state$busy <- FALSE)
      loggit("DEBUG", formatter(name, previous, value), echo = FALSE)
    }
    invisible(value)
  }
  rm(list = name, envir = where)
  makeActiveBinding(name, binding, where)
  state$active <- TRUE

  invisible(function() {
    if (!state$active) return(invisible(NULL))
    if (exists(name, envir = where, inherits = FALSE) && bindingIsActive(name, where) &&
          identical(activeBindingFunction(name, where), binding)) {
      if (environmentIsLocked(where) || bindingIsLocked(name, where)) {
        base::stop("Cannot restore a locked binding or environment.", call. = FALSE)
      }
      rm(list = name, envir = where)
      assign(name, state$value, envir = where)
    }
    state$active <- FALSE
    state$value <- NULL
    state$retained <- NULL
    invisible(NULL)
  })
}

compile_watch_message <- function(template) {
  if (!is.character(template) || length(template) != 1L || is.na(template)) {
    base::stop("'message' must be a single, non-missing character string.", call. = FALSE)
  }
  parts <- regmatches(template, gregexpr("\\{\\{|\\}\\}|\\{[^{}]*\\}|[^{}]+|[{}]", template, perl = TRUE))[[1L]]
  if (any(parts %in% c("{", "}"))) {
    base::stop("Unmatched brace in 'message' template.", call. = FALSE)
  }
  slots <- startsWith(parts, "{") & parts != "{{"
  fields <- trimws(substring(parts[slots], 2L, nchar(parts[slots]) - 1L))
  unknown <- setdiff(fields, c("name", "oldValue", "newValue"))
  if (length(unknown) > 0L) {
    base::stop("Invalid placeholders in 'message': ", toString(unknown), call. = FALSE)
  }
  parts[parts == "{{"] <- "{"
  parts[parts == "}}"] <- "}"

  function(name, old, new) {
    values <- list(name = name, oldValue = old, newValue = new)
    result <- parts
    # Format each requested value once, even when its placeholder is repeated.
    formatted <- vapply(unique(fields), function(field) {
      value <- values[[field]]
      if (is.null(value)) return("NULL")
      if (is.atomic(value) && length(value) > 0L) return(toString(as.character(value)))
      deparse1(value, width.cutoff = 500L)
    }, character(1L))
    result[slots] <- formatted[fields]
    paste(result, collapse = "")
  }
}
