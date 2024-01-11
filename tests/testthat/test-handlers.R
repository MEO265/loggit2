test_that("message works as it does in base R", {
  expect_message(base::message("this is a message test"))
  expect_message(loggit::message("this is also a message test", echo = FALSE))

  # Multiple args are concatenated
  captured_output <- capture_output(
    loggit::message("this should be ", "concatenated ", "in the log")
  )
  expect_true(grepl("this should be concatenated in the log", captured_output))
})


test_that("warning works as it does in base R", {
  expect_warning(base::warning("this is a warning test"))
  expect_warning(loggit::warning("this is also a warning test", echo = FALSE))

  # Multiple args are concatenated
  suppressWarnings(
    captured_output <- capture_output(
      loggit::warning("this should be ", "concatenated ", "in the log")
    )
  )
  expect_true(grepl("this should be concatenated in the log", captured_output))
})


test_that("stop works as it does in base R", {
  expect_error(base::stop("this is a stop test"))
  expect_error(loggit::stop("this is also a stop test", echo = FALSE))

  # Multiple args are concatenated
  # Test looks different to get around the stop() call
  expect_error(loggit::stop("this should be ", "concatenated ", "in the log", echo = FALSE))
  logdata <- read_logs()
  logdata <- logdata[logdata$log_lvl == "ERROR",]
  logdata <- logdata[nrow(logdata),]
  expect_true(logdata$log_msg == "this should be concatenated in the log")
})

cleanup()

test_that("stopifnot", {
  # stopifnot works as in base R (with echo = TRUE)
  expect_no_error(stopifnot())
  expect_identical_error(stopifnot(FALSE), base::stopifnot(FALSE))
  f <- function(x, ...) x
  expect_identical_error(stopifnot(f(x = FALSE)), base::stopifnot(f(x = FALSE)))
  g <- function() f(FALSE)
  expect_identical_error(stopifnot(4 == 4, g()), base::stopifnot(4 == 4, g()))
  expect_identical_error(stopifnot(4 == 4, "Test" = g()), base::stopifnot(4 == 4, "Test" = g()))
  expect_identical_error(stopifnot(exprs = { TRUE; FALSE }), base::stopifnot(exprs = { TRUE; FALSE }))
  expect_identical_error(stopifnot(exprObject = { TRUE; FALSE }), base::stopifnot(exprObject = { TRUE; FALSE }))
  expect_no_error(stopifnot(TRUE, 3 == 3))

  # stopifnot works as in base R (with echo = FALSE)
  expect_no_error(stopifnot(echo = FALSE))
  expect_identical_error(stopifnot(FALSE, echo = FALSE), base::stopifnot(FALSE))
  f <- function(x, ...) x
  expect_identical_error(stopifnot(f(x = FALSE), echo = FALSE), base::stopifnot(f(x = FALSE)))
  g <- function() f(FALSE)
  expect_identical_error(stopifnot(4 == 4, g(), echo = FALSE), base::stopifnot(4 == 4, g()))
  expect_identical_error(stopifnot(4 == 4, "A Test" = g(), echo = FALSE), base::stopifnot(4 == 4, "A Test" = g()))
  expect_identical_error(stopifnot(exprs = { TRUE; FALSE }, echo = FALSE), base::stopifnot(exprs = { TRUE; FALSE }))
  expect_identical_error(stopifnot(exprObject = { TRUE; FALSE }, echo = FALSE), base::stopifnot(exprObject = { TRUE; FALSE }))
  expect_no_error(stopifnot(TRUE, 3 == 3, echo = FALSE))

  cleanup()

  # Test for logging
  expect_output(try(stopifnot("This is a stop if not error" = FALSE), silent = TRUE))
  expect_silent(try(stopifnot("Should not echo" = FALSE, echo = FALSE), silent = TRUE))
  stopifnot("Should not show" = TRUE)
  log_actual <- read_logs()
  expect_setequal(names(log_actual), c("timestamp", "log_lvl", "log_msg"))
  log_actual$timestamp <- NULL
  log_expected <- data.frame(log_lvl = "ERROR", log_msg = c("This is a stop if not error", "Should not echo"))
  expect_equal(log_actual, log_expected)
})

cleanup()
