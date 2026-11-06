configure_trace_test <- function() {
  logfile <- tempfile(fileext = ".log")
  old_file <- set_logfile(logfile, confirm = FALSE)
  old_level <- set_log_level("DEBUG", confirm = FALSE)
  function() {
    set_logfile(old_file, confirm = FALSE, create = FALSE)
    set_log_level(old_level, confirm = FALSE)
    unlink(logfile)
  }
}

test_that("entry templates log explicit arguments and preserve results", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  target <- function(x, append = FALSE, unused) invisible(x * 2)
  original <- target
  registration <- withVisible(trace_loggit(
    target, "x={ x }; append={append}; literal={{x}}", where = environment()
  ))
  stop_trace <- registration$value
  on.exit(stop_trace(), add = TRUE)
  expect_false(registration$visible)
  expect_output(result <- withVisible(target(21, unused = base::stop("must stay lazy"))), NA)
  expect_identical(result, list(value = 42, visible = FALSE))
  expect_identical(read_logs()$log_msg, "x=21; append=FALSE; literal={x}")
  expect_identical(read_logs()$log_lvl, "DEBUG")

  stop_trace()
  expect_identical(target, original)
  target(1)
  expect_identical(nrow(read_logs()), 1L)
})

test_that("templates are validated before changing the function", {
  target <- function(x, ...) x
  original <- target
  for (template in c("{unknown}", "{...}", "{nrow(x)}", "{}", "{x + 1}")) {
    expect_error(trace_loggit(target, template, where = environment()), "Invalid placeholders")
    expect_identical(target, original)
  }
  for (template in c("{x", "x}", "{{x}")) {
    expect_error(trace_loggit(target, template, where = environment()), "Unmatched brace")
  }
  for (template in list(NA_character_, character(), c("a", "b"), 1, list("a"))) {
    expect_error(trace_loggit(target, template, where = environment()), "single, non-missing character")
  }
  expect_error(trace_loggit(target, "ok", exit = "{x}", where = environment()), "Invalid placeholders in 'exit'")
  expect_error(trace_loggit(target, exit = "{returnValue()}", where = environment()), "Invalid placeholders")
  expect_error(trace_loggit(target, exit = NA_character_, where = environment()), "single, non-missing character")
  expect_error(trace_loggit(target, where = environment()), "at least one")
  expect_error(trace_loggit("target", "ok", where = environment()), "function reference")
  expect_error(trace_loggit(function(x) x, "ok", where = environment()), "name of a function")
  expect_identical(target, original)
})

test_that("vectors, NULL, repeated fields and empty templates form single entries", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  target <- function(x, y = NULL) invisible(NULL)
  stop_trace <- trace_loggit(target, "{x}; {y}; {x}", exit = "", where = environment())
  on.exit(stop_trace(), add = TRUE)
  target(c("a", "b"))
  expect_identical(read_logs()$log_msg, c("a, b; NULL; a, b", ""))
})

test_that("entry templates evaluate a selected argument only once", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  count <- 0L
  target <- function(file) file
  stop_trace <- trace_loggit(target, "{file} {file}", where = environment())
  on.exit(stop_trace(), add = TRUE)
  result <- target({ count <- count + 1L; paste0("file-", count) })
  expect_identical(count, 1L)
  expect_identical(result, "file-1")
  expect_identical(read_logs()$log_msg, "file-1 file-1")
})

test_that("exit templates preserve values and visibility on every normal return", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  target <- function(x, hidden = FALSE) {
    if (hidden) return(invisible(x))
    x
  }
  stop_trace <- trace_loggit(target, "start {x}", exit = "end {returnValue}", where = environment())
  on.exit(stop_trace(), add = TRUE)
  expect_identical(withVisible(target(2)), list(value = 2, visible = TRUE))
  expect_identical(withVisible(target(c(3, 4), hidden = TRUE)), list(value = c(3, 4), visible = FALSE))
  expect_identical(withVisible(target(NULL)), list(value = NULL, visible = TRUE))
  expect_identical(read_logs()$log_msg, c("start 2", "end 2", "start 3, 4", "end 3, 4", "start NULL", "end NULL"))
})

test_that("exit-only tracing reports unavailable values without swallowing errors", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  target <- function() base::stop("original failure")
  stop_trace <- trace_loggit(target, exit = "end {returnValue}", where = environment())
  on.exit(stop_trace(), add = TRUE)
  expect_error(target(), "original failure")
  expect_identical(read_logs()$log_msg, "end <unavailable>")
})

test_that("exit hooks respect the target's on.exit handlers", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  cleaned <- FALSE
  target <- function() {
    on.exit(cleaned <<- TRUE, add = TRUE)
    invisible(7)
  }
  stop_trace <- trace_loggit(target, exit = "end {returnValue}", where = environment())
  on.exit(stop_trace(), add = TRUE)
  expect_identical(withVisible(target()), list(value = 7, visible = FALSE))
  expect_true(cleaned)
  expect_identical(read_logs()$log_msg, "end 7")
  stop_trace()

  target <- function() {
    on.exit(invisible(NULL), add = FALSE)
    8
  }
  stop_trace <- trace_loggit(target, exit = "replaced", where = environment())
  expect_identical(target(), 8)
  expect_identical(read_logs()$log_msg, "end 7")
})

test_that("disabled DEBUG logging does not force template arguments", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  target <- function(x) 1L
  stop_trace <- trace_loggit(target, "{x}", exit = "{returnValue}", where = environment())
  on.exit(stop_trace(), add = TRUE)
  set_log_level("INFO", confirm = FALSE)
  expect_identical(target(base::stop("must stay lazy")), 1L)
  expect_identical(nrow(read_logs()), 0L)
  set_log_level("DEBUG", confirm = FALSE)
  target("enabled")
  expect_identical(read_logs()$log_msg, c("enabled", "1"))
})

test_that("qualified references and cleanup use trace's package resolution", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  original <- utils::write.table
  stop_trace <- trace_loggit(utils::write.table, "file={file}; append={append}", where = emptyenv())
  on.exit(stop_trace(), add = TRUE)
  destination <- tempfile(fileext = ".csv")
  on.exit(unlink(destination), add = TRUE)
  utils::write.csv(data.frame(x = 1), destination, row.names = FALSE)
  expect_true(file.exists(destination))
  expect_identical(read_logs()$log_msg, paste0("file=", destination, "; append=FALSE"))
  stop_trace()
  expect_identical(utils::write.table, original)
})

test_that("triple-colon references resolve and clean up as in trace", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  original <- utils::write.table
  stop_trace <- trace_loggit(utils:::write.table, "write", where = emptyenv())
  on.exit(stop_trace(), add = TRUE)
  destination <- tempfile()
  on.exit(unlink(destination), add = TRUE)
  utils::write.table(1, destination)
  expect_identical(read_logs()$log_msg, "write")
  stop_trace()
  expect_identical(utils::write.table, original)
})

test_that("where and bare aliases behave as in trace", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  expect_identical(formals(trace_loggit)$where, formals(base::trace)$where)
  scope <- new.env(parent = environment())
  scope$target <- function(x) x
  original <- scope$target
  stop_trace <- evalq(trace_loggit(target, "{x}", where = environment()), envir = scope)
  on.exit(stop_trace(), add = TRUE)
  expect_identical(scope$target(5), 5)
  expect_identical(read_logs()$log_msg, "5")
  stop_trace()
  expect_identical(scope$target, original)

  alias <- utils::write.table
  stop_trace <- trace_loggit(alias, "alias", where = environment())
  expect_s4_class(alias, "functionWithTrace")
  expect_false(inherits(utils::write.table, "functionWithTrace"))
})

test_that("functions exposing only dots support literal messages", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  expect_error(trace_loggit(utils::write.csv, "{file}"), "Invalid placeholders")
  target <- function(...) invisible(NULL)
  stop_trace <- trace_loggit(target, "called {{...}}", where = environment())
  on.exit(stop_trace(), add = TRUE)
  target(base::stop("must stay lazy"))
  expect_identical(read_logs()$log_msg, "called {...}")
})

test_that("tracing a logging dependency does not recurse", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  output <- character()
  connection <- textConnection("output", open = "w", local = TRUE)
  on.exit(close(connection), add = TRUE)
  stop_trace <- trace_loggit(base::cat, "cat called")
  on.exit(stop_trace(), add = TRUE)
  cat("user output\n", file = connection)
  stop_trace()
  expect_identical(output, "user output")
  expect_identical(read_logs()$log_msg, "cat called")
  expect_true(tracingState())
})

test_that("tracer errors restore R's tracing state", {
  restore <- configure_trace_test()
  on.exit(restore(), add = TRUE)
  target <- function(x) x
  stop_trace <- trace_loggit(target, "{x}", where = environment())
  on.exit(stop_trace(), add = TRUE)
  expect_error(target(base::stop("argument failed")), "argument failed")
  expect_true(tracingState())
  target("recovered")
  expect_identical(read_logs()$log_msg, "recovered")
})
