configure_watch_test <- function() {
  logfile <- tempfile(fileext = ".log")
  old_file <- set_logfile(logfile, confirm = FALSE)
  old_level <- set_log_level("DEBUG", confirm = FALSE)
  function() {
    set_logfile(old_file, confirm = FALSE, create = FALSE)
    set_log_level(old_level, confirm = FALSE)
    unlink(logfile)
  }
}

register_watch_formatter <- function(class, method) {
  table <- get(".__S3MethodsTable__.", envir = baseenv())
  name <- paste0("as.character.", class)
  previous <- get0(name, envir = table, inherits = FALSE)
  registerS3method("as.character", class, method, envir = baseenv())
  function() {
    if (is.null(previous)) rm(list = name, envir = table) else assign(name, previous, envir = table)
  }
}

test_that("watching logs changes without changing reads or assignment results", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  counter <- 0L
  registration <- withVisible(watch_loggit(counter))
  stop_watch <- registration$value
  on.exit(stop_watch(), add = TRUE)
  expect_false(registration$visible)
  expect_true(bindingIsActive("counter", environment()))
  expect_identical(counter, 0L)
  expect_identical(nrow(read_logs()), 0L)
  expect_output(result <- withVisible(counter <- counter + 1L), NA)
  expect_identical(result, list(value = 1L, visible = FALSE))
  counter <- 1L
  expect_identical(read_logs()$log_msg, "counter: value 0L -> 1L")
  expect_identical(read_logs()$log_lvl, "DEBUG")
  stop_watch()
  expect_false(bindingIsActive("counter", environment()))
  expect_identical(counter, 1L)
  counter <- 2L
  expect_null(stop_watch())
  expect_identical(counter, 2L)
  expect_identical(nrow(read_logs()), 1L)
})

test_that("identity checks distinguish type, attributes, and missing values", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  value <- 1L
  stop_watch <- watch_loggit(value, "changed {name}")
  on.exit(stop_watch(), add = TRUE)
  value <- 1.0
  names(value) <- "a"
  value <- NA_real_
  value <- NA_real_
  value <- NaN
  value <- NaN
  expect_identical(read_logs()$log_msg, rep("changed value", 4L))
})

test_that("the default message distinguishes type, class, attribute and value changes", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  value <- "42"
  stop_watch <- watch_loggit(value)
  on.exit(stop_watch(), add = TRUE)
  value <- 42L
  class(value) <- "tagged"
  attr(value, "label") <- "score"
  value[1L] <- 43L
  expect_identical(read_logs()$log_msg, c(
    'value: type character -> integer; value "42" -> 42L',
    "value: class integer -> tagged",
    'value: attribute "label" NULL -> "score"',
    "value: value 42L -> 43L"
  ))
})

test_that("the default message combines metadata and a changed nested value", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  item <- structure(list(count = c(1L, 2L)), class = "before", label = "old")
  stop_watch <- watch_loggit(item)
  on.exit(stop_watch(), add = TRUE)
  item <- structure(list(count = c(1L, 9L)), class = "after", label = "new")
  expect_identical(read_logs()$log_msg, paste0(
    'item: class before -> after; attribute "label" "old" -> "new"; ',
    'value at [["count"]][2] 2L -> 9L'
  ))
})

test_that("default messages show data frame and matrix coordinates", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  frame <- data.frame(count = 1:3)
  mat <- matrix(1:4, nrow = 2L)
  stop_frame <- watch_loggit(frame)
  stop_mat <- watch_loggit(mat)
  on.exit(stop_frame(), add = TRUE)
  on.exit(stop_mat(), add = TRUE)
  frame$count[2L] <- 9L
  mat[1L, 2L] <- 9L
  expect_identical(read_logs()$log_msg, c(
    'frame: value at [["count"]][2] 2L -> 9L',
    "mat: value at [1, 2] 3L -> 9L"
  ))
})

test_that("the default message bounds the number of differences", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  x <- rep.int(0L, 8L)
  stop_watch <- watch_loggit(x)
  on.exit(stop_watch(), add = TRUE)
  x <- 1:8
  expect_identical(read_logs()$log_msg, paste0(
    "x: value at [1] 0L -> 1L; value at [2] 0L -> 2L; value at [3] 0L -> 3L; ",
    "value at [4] 0L -> 4L; value at [5] 0L -> 5L; more changes"
  ))
})

test_that("failed right-hand sides leave the value and log untouched", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  value <- 1L
  stop_watch <- watch_loggit(value)
  on.exit(stop_watch(), add = TRUE)
  expect_error(value <- base::stop("assignment failed"), "assignment failed")
  expect_identical(value, 1L)
  expect_identical(nrow(read_logs()), 0L)
  value <- 2L
  expect_identical(read_logs()$log_msg, "value: value 1L -> 2L")
})

test_that("assign, superassignment, and replacements target the watched binding", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  scope <- new.env()
  scope$x <- c(1L, 2L)
  stop_watch <- watch_loggit(x, where = scope)
  on.exit(stop_watch(), add = TRUE)
  assign("x", c(3L, 4L), envir = scope)
  scope$x[2L] <- 5L
  updater <- evalq(function() x <<- c(6L, 7L), envir = scope)
  updater()
  expect_identical(scope$x, c(6L, 7L))
  expect_identical(read_logs()$log_msg, c(
    "x: value at [1] 1L -> 3L; value at [2] 2L -> 4L",
    "x: value at [2] 4L -> 5L",
    "x: value at [1] 3L -> 6L; value at [2] 5L -> 7L"
  ))
  stop_watch()
  expect_identical(scope$x, c(6L, 7L))
})

test_that("templates escape braces and render vectors, NULL, and other objects", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  value <- NULL
  stop_watch <- watch_loggit(value, "{{{ name }}}: {oldValue} => {newValue}; {newValue}")
  on.exit(stop_watch(), add = TRUE)
  value <- c("a", "b")
  value <- character()
  value <- list(x = 1L)
  value <- NULL
  expect_identical(read_logs()$log_msg, c(
    "{value}: NULL => a, b; a, b",
    "{value}: a, b => character(0); character(0)",
    "{value}: character(0) => list(x = 1L); list(x = 1L)",
    "{value}: list(x = 1L) => NULL; NULL"
  ))
})

test_that("literal and empty templates do not format unreferenced values", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  restore_method <- register_watch_formatter("watch_unprintable", function(...) base::stop("must not format"))
  on.exit(restore_method(), add = TRUE)
  value <- structure(1L, class = "watch_unprintable")
  stop_watch <- watch_loggit(value, "")
  on.exit(stop_watch(), add = TRUE)
  value <- structure(2L, class = "watch_unprintable")
  expect_identical(read_logs()$log_msg, "")
})

test_that("disabled DEBUG logging still tracks the most recent value", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  restore_method <- register_watch_formatter("watch_unprintable", function(...) base::stop("must not format"))
  on.exit(restore_method(), add = TRUE)
  value <- 0L
  stop_watch <- watch_loggit(value, "{name}: {oldValue} -> {newValue}")
  on.exit(stop_watch(), add = TRUE)
  set_log_level("INFO", confirm = FALSE)
  value <- structure(1L, class = "watch_unprintable")
  expect_identical(value, structure(1L, class = "watch_unprintable"))
  value <- 2L
  expect_identical(nrow(read_logs()), 0L)
  set_log_level("DEBUG", confirm = FALSE)
  value <- 3L
  expect_identical(read_logs()$log_msg, "value: 2 -> 3")
})

test_that("the default formatter resumes from the last value stored with DEBUG disabled", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  x <- rep.int(0L, 100000L)
  stop_watch <- watch_loggit(x)
  on.exit(stop_watch(), add = TRUE)
  set_log_level("INFO", confirm = FALSE)
  x[100000L] <- 1L
  expect_identical(nrow(read_logs()), 0L)
  set_log_level("DEBUG", confirm = FALSE)
  x[100000L] <- 2L
  expect_identical(read_logs()$log_msg, "x: value at [100000] 1L -> 2L")
})

test_that("invalid templates and references leave the original binding intact", {
  value <- 1L
  for (template in c("{unknown}", "{value}", "{newValue + 1}", "{}")) {
    expect_error(watch_loggit(value, template), "Invalid placeholders")
  }
  for (template in c("{name", "name}", "{{name}")) {
    expect_error(watch_loggit(value, template), "Unmatched brace")
  }
  for (template in list(NA_character_, character(), c("a", "b"), 1L)) {
    expect_error(watch_loggit(value, template), "single, non-missing character")
  }
  expect_error(watch_loggit("value"), "bare variable name")
  expect_error(watch_loggit(value[1L]), "bare variable name")
  expect_error(watch_loggit(), "bare variable name")
  expect_error(watch_loggit(value, where = list()), "must be an environment")
  expect_false(bindingIsActive("value", environment()))
  expect_identical(value, 1L)
})

test_that("watching never silently selects or creates an inherited binding", {
  scope <- new.env(parent = emptyenv())
  scope$value <- 1L
  child <- new.env(parent = scope)
  expect_error(watch_loggit(value, where = child), "must exist directly")
  expect_error(watch_loggit(absent, where = scope), "must exist directly")
  expect_false(exists("value", envir = child, inherits = FALSE))
  expect_false(bindingIsActive("value", scope))
  expect_identical(scope$value, 1L)
})

test_that("locked and existing active bindings are rejected without evaluating them", {
  scope <- new.env()
  scope$value <- 1L
  lockBinding("value", scope)
  expect_error(watch_loggit(value, where = scope), "locked")
  expect_true(bindingIsLocked("value", scope))
  unlockBinding("value", scope)
  calls <- 0L
  original <- function(value) {
    calls <<- calls + 1L
    2L
  }
  rm("value", envir = scope)
  makeActiveBinding("value", original, scope)
  expect_error(watch_loggit(value, where = scope), "existing active binding")
  expect_identical(activeBindingFunction("value", scope), original)
  expect_identical(calls, 0L)
  scope <- new.env()
  scope$value <- 3L
  lockEnvironment(scope, bindings = FALSE)
  expect_error(watch_loggit(value, where = scope), "locked")
  expect_identical(scope$value, 3L)
})

test_that("registration forces delayed values once and leaves failed promises intact", {
  scope <- new.env()
  calls <- 0L
  delayedAssign("value", { calls <- calls + 1L; 7L }, eval.env = environment(), assign.env = scope)
  stop_watch <- watch_loggit(value, where = scope)
  on.exit(stop_watch(), add = TRUE)
  expect_identical(calls, 1L)
  expect_identical(scope$value, 7L)
  expect_identical(scope$value, 7L)
  expect_identical(calls, 1L)
  delayedAssign("failed", base::stop("initial value failed"), assign.env = scope)
  expect_error(watch_loggit(failed, where = scope), "initial value failed")
  expect_true(exists("failed", envir = scope, inherits = FALSE))
  expect_false(bindingIsActive("failed", scope))
})

test_that("function arguments and non-syntactic variable names can be watched", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  target <- function(value) {
    stop_watch <- watch_loggit(value)
    on.exit(stop_watch(), add = TRUE)
    value <- value + 1L
    value
  }
  expect_identical(target(1L), 2L)
  scope <- new.env()
  scope[["odd name"]] <- 3L
  stop_watch <- watch_loggit(`odd name`, where = scope)
  on.exit(stop_watch(), add = TRUE)
  scope[["odd name"]] <- 4L
  expect_identical(read_logs()$log_msg, c("value: value 1L -> 2L", "odd name: value 3L -> 4L"))
})

test_that("shadowed variables and in-place reference changes are not binding assignments", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  scope <- new.env()
  scope$value <- new.env()
  stop_watch <- watch_loggit(value, where = scope)
  on.exit(stop_watch(), add = TRUE)
  reference <- scope$value
  reference$x <- 1L
  shadow <- evalq(function() { value <- 9L; value }, envir = scope)
  expect_identical(shadow(), 9L)
  expect_identical(scope$value$x, 1L)
  expect_identical(nrow(read_logs()), 0L)
  scope$value <- new.env()
  expect_identical(nrow(read_logs()), 1L)
})

test_that("cleanup does not overwrite removed or replacement bindings", {
  scope <- new.env()
  scope$value <- 1L
  stop_watch <- watch_loggit(value, where = scope)
  rm("value", envir = scope)
  stop_watch()
  expect_false(exists("value", envir = scope, inherits = FALSE))
  scope$value <- 2L
  stop_watch <- watch_loggit(value, where = scope)
  rm("value", envir = scope)
  scope$value <- 3L
  stop_watch()
  expect_identical(scope$value, 3L)
  first_watch <- watch_loggit(value, where = scope)
  rm("value", envir = scope)
  scope$value <- 4L
  second_watch <- watch_loggit(value, where = scope)
  on.exit(second_watch(), add = TRUE)
  first_watch()
  expect_true(bindingIsActive("value", scope))
  expect_identical(scope$value, 4L)
})

test_that("cleanup can be retried after unlocking a binding", {
  scope <- new.env()
  scope$value <- 1L
  stop_watch <- watch_loggit(value, where = scope)
  lockBinding("value", scope)
  expect_error(stop_watch(), "Cannot restore a locked")
  expect_true(bindingIsActive("value", scope))
  unlockBinding("value", scope)
  stop_watch()
  expect_false(bindingIsActive("value", scope))
  expect_identical(scope$value, 1L)
})

test_that("formatting failures keep the new value and reset recursion protection", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  restore_method <- register_watch_formatter("watch_unprintable", function(...) base::stop("format failed"))
  on.exit(restore_method(), add = TRUE)
  value <- 0L
  stop_watch <- watch_loggit(value, "{newValue}")
  on.exit(stop_watch(), add = TRUE)
  expect_error(value <- structure(1L, class = "watch_unprintable"), "format failed")
  expect_identical(value, structure(1L, class = "watch_unprintable"))
  value <- 2L
  expect_identical(read_logs()$log_msg, "2")
})

test_that("logging failures keep the new value and allow subsequent changes", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  value <- 0L
  stop_watch <- watch_loggit(value)
  on.exit(stop_watch(), add = TRUE)
  good_file <- get_logfile()
  set_logfile(file.path(tempfile(), "missing.log"), confirm = FALSE, create = FALSE)
  expect_warning(expect_error(value <- 1L), "cannot open file")
  expect_identical(value, 1L)
  set_logfile(good_file, confirm = FALSE)
  value <- 2L
  expect_identical(read_logs()$log_msg, "value: value 1L -> 2L")
})

test_that("formatters run once per field and recursive changes do not loop", {
  restore <- configure_watch_test()
  on.exit(restore(), add = TRUE)
  scope <- new.env()
  scope$value <- 0L
  calls <- 0L
  restore_method <- register_watch_formatter("watch_recursive", function(x, ...) {
    calls <<- calls + 1L
    scope$value <- 9L
    "formatted"
  })
  on.exit(restore_method(), add = TRUE)
  stop_watch <- watch_loggit(value, "{newValue} {newValue}", where = scope)
  on.exit(stop_watch(), add = TRUE)
  scope$value <- structure(1L, class = "watch_recursive")
  expect_identical(calls, 1L)
  expect_identical(scope$value, 9L)
  expect_identical(read_logs()$log_msg, "formatted formatted")
  scope$value <- 10L
  expect_identical(read_logs()$log_msg, c("formatted formatted", "10 10"))
  stop_watch()
  expect_identical(scope$value, 10L)
})
