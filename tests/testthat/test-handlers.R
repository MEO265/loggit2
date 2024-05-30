test_that("message works as it does in base R", {
  # message works as in base R (with echo = TRUE)
  expect_identical_message(message(), base::message())
  expect_identical_message(message("this is a message test"), base::message("this is a message test"))
  expect_identical_message(message("this", "is a", "message test"), base::message("this", "is a", "message test"))
  expect_identical_message(message("Some numbers", 3L, 1:5, "!"), base::message("Some numbers", 3L, 1:5, "!"))

  # message works as in base R (with echo = FALSE)
  expect_identical_message(message(echo = FALSE), base::message(), ignore_call = TRUE)
  expect_identical_message(
    message("this is a message test", echo = FALSE),
    base::message("this is a message test"),
    ignore_call = TRUE
  )
  expect_identical_message(
    message("this", "is a", "message test", echo = FALSE),
    base::message("this", "is a", "message test"),
    ignore_call = TRUE
  )
  expect_identical_message(
    message("Some numbers", c(3.12, 1L, 2L), 1:5, "!", echo = FALSE),
    base::message("Some numbers", c(3.12, 1L, 2L), 1:5, "!"),
    ignore_call = TRUE
  )

  # Multiple args are concatenated
  # Test looks different to get around the message() call
  expect_output(suppressMessages(message("this should be ", "concatenated ", "in the log")))
  expect_silent(suppressMessages(message("this should be ", "concatenated ", "in the log", echo = FALSE)))
  logdata <- read_logs()
  logdata <- logdata[nrow(logdata),]
  expect_identical(logdata[["log_lvl"]], "INFO")
  expect_identical(logdata[["log_msg"]], "this should be concatenated in the log\n")

  # Condition is accepted as input
  sm <- simpleMessage(message = "Test message", call = str2lang("base::print(x)"))
  expect_identical_message(message(sm), base::message(sm))
})

cleanup()

test_that("warning works as it does in base R", {
  # warning works as in base R (with echo = TRUE)
  expect_identical_warning(warning(), base::warning())
  expect_identical_warning(warning("this is a warning test"), base::warning("this is a warning test"))
  expect_identical_warning(warning("this", "is a", "warning test"), base::warning("this", "is a", "warning test"))
  expect_identical_warning(warning("Some numbers", 3L, 1:5, "!"), base::warning("Some numbers", 3L, 1:5, "!"))

  # warning works as in base R (with echo = FALSE)
  expect_identical_warning(warning(echo = FALSE), base::warning())
  expect_identical_warning(warning("this is a warning test", echo = FALSE), base::warning("this is a warning test"))
  expect_identical_warning(
    warning("this", "is a", "warning test", echo = FALSE),
    base::warning("this", "is a", "warning test")
  )
  expect_identical_warning(
    warning("Some numbers", c(3.12, 1L, 2L), 1:5, "!", echo = FALSE),
    base::warning("Some numbers", c(3.12, 1L, 2L), 1:5, "!")
  )

  # Multiple args are concatenated
  # Test looks different to get around the warning() call
  expect_output(suppressWarnings(warning("this should be ", "concatenated ", "in the log")))
  expect_silent(suppressWarnings(warning("this should be ", "concatenated ", "in the log", echo = FALSE)))
  logdata <- read_logs()
  logdata <- logdata[nrow(logdata),]
  expect_identical(logdata[["log_lvl"]], "WARN")
  expect_identical(logdata[["log_msg"]], "this should be concatenated in the log")

  # Condition is accepted as input
  sw <- simpleWarning(message = "Test message", call = str2lang("base::print(x)"))
  expect_identical_warning(warning(sw), base::warning(sw))
})

cleanup()


test_that("stop works as it does in base R", {
  # stop works as in base R (with echo = TRUE)
  expect_identical_error(stop(), base::stop())
  expect_identical_error(stop("this is a stop test"), base::stop("this is a stop test"))
  expect_identical_error(stop("this", "is a", "stop test"), base::stop("this", "is a", "stop test"))
  expect_identical_error(stop("Some numbers", 3L, 1:5, "!"), base::stop("Some numbers", 3L, 1:5, "!"))

  # stop works as in base R (with echo = FALSE)
  expect_identical_error(stop(echo = FALSE), base::stop())
  expect_identical_error(stop("this is a stop test", echo = FALSE), base::stop("this is a stop test"))
  expect_identical_error(stop("this", "is a", "stop test", echo = FALSE), base::stop("this", "is a", "stop test"))
  expect_identical_error(
    stop("Some numbers", c(3.12, 1L, 2L), 1:5, "!", echo = FALSE),
    base::stop("Some numbers", c(3.12, 1L, 2L), 1:5, "!")
  )

  # Multiple args are concatenated
  # Test looks different to get around the stop() call
  expect_output(try(stop("this should be ", "concatenated ", "in the log"), silent = TRUE))
  expect_silent(try(stop("this should be ", "concatenated ", "in the log", echo = FALSE), silent = TRUE))
  logdata <- read_logs()
  logdata <- logdata[nrow(logdata),]
  expect_identical(logdata[["log_lvl"]], "ERROR")
  expect_identical(logdata[["log_msg"]], "this should be concatenated in the log")

  # Condition is accepted as input
  se <- simpleError(message = "Test message", call = str2lang("base::print(x)"))
  expect_identical_error(stop(se), base::stop(se))
})

cleanup()

test_that("stopifnot", {
  # stopifnot works as in base R (with echo = TRUE)
  expect_no_error(stopifnot())
  expect_identical_error(stopifnot(FALSE), base::stopifnot(FALSE))
  f <- function(x, ...) x
  expect_identical_error(stopifnot(f(x = FALSE)), base::stopifnot(f(x = FALSE)))
  g <- function() f(FALSE)
  expect_identical_error(stopifnot(4L == 4L, g()), base::stopifnot(4L == 4L, g()))
  expect_identical_error(stopifnot(4L == 4L, Test = g()), base::stopifnot(4L == 4L, Test = g()))
  expect_identical_error(stopifnot(exprs = { TRUE; FALSE }), base::stopifnot(exprs = { TRUE; FALSE }))
  expect_identical_error(stopifnot(exprObject = { TRUE; FALSE }), base::stopifnot(exprObject = { TRUE; FALSE }))
  expect_no_error(stopifnot(TRUE, 3L == 3L))

  # stopifnot works as in base R (with echo = FALSE)
  expect_no_error(stopifnot(echo = FALSE))
  expect_identical_error(stopifnot(FALSE, echo = FALSE), base::stopifnot(FALSE))
  f <- function(x, ...) x
  expect_identical_error(stopifnot(f(x = FALSE), echo = FALSE), base::stopifnot(f(x = FALSE)))
  g <- function() f(FALSE)
  expect_identical_error(stopifnot(4L == 4L, g(), echo = FALSE), base::stopifnot(4L == 4L, g()))
  expect_identical_error(stopifnot(4L == 4L, "A Test" = g(), echo = FALSE), base::stopifnot(4L == 4L, "A Test" = g()))
  expect_identical_error(stopifnot(exprs = { TRUE; FALSE }, echo = FALSE), base::stopifnot(exprs = { TRUE; FALSE }))
  expect_identical_error(
    stopifnot(exprObject = { TRUE; FALSE }, echo = FALSE),
    base::stopifnot(exprObject = { TRUE; FALSE })
  )
  expect_no_error(stopifnot(TRUE, 3L == 3L, echo = FALSE))

  cleanup()

  # Test for logging
  expect_output(try(stopifnot("This is a stop if not error" = FALSE), silent = TRUE))
  expect_silent(try(stopifnot("Should not echo" = FALSE, echo = FALSE), silent = TRUE))
  stopifnot("Should not show" = TRUE)
  log_actual <- read_logs()
  expect_setequal(names(log_actual), c("timestamp", "log_lvl", "log_msg"))
  log_actual[["timestamp"]] <- NULL
  log_expected <- data.frame(
    log_lvl = "ERROR", log_msg = c("This is a stop if not error", "Should not echo"), stringsAsFactors = FALSE
  )
  expect_identical(log_actual, log_expected)
})

cleanup()

test_that("split_ndjson error", {
  expect_error(split_ndjson(3L), "Input must be a character vector.")
})
