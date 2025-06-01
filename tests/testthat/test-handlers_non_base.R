test_that("debuginfo echos", {
  expect_output(debuginfo("This is a debug test", echo = TRUE), "This is a debug test")
})
cleanup()

test_that("debuginfo logs message at DEBUG level", {
  # silent output
  expect_silent(debuginfo("This is a debug test", echo = FALSE))

  logdata <- read_logs()
  logdata <- logdata[nrow(logdata),]

  expect_identical(logdata[["log_lvl"]], "DEBUG")
  expect_identical(logdata[["log_msg"]], "This is a debug test")
})
cleanup()

test_that("debuginfo concatenates multiple arguments", {
  expect_silent(debuginfo("This ", "is ", "a debug test", echo = FALSE))

  logdata <- read_logs()
  logdata <- logdata[nrow(logdata),]

  expect_identical(logdata[["log_lvl"]], "DEBUG")
  expect_identical(logdata[["log_msg"]], "This is a debug test")
})
cleanup()

test_that("debuginfo respects call. argument without error", {
  # call. = TRUE should not error
  f <- function() debuginfo("call test", call. = TRUE, echo = FALSE)
  expect_silent(f())

  # call. = FALSE should not error and still log
  expect_silent(debuginfo("no call", call. = FALSE, echo = FALSE))
  logdata <- read_logs()
  expect_identical(logdata[["log_lvl"]], c("DEBUG", "DEBUG"))
  expect_identical(logdata[["log_msg"]], c("call test", "no call"))
})
cleanup()

test_that("debuginfo does not log on log level below DEBUG", {
  old_level <- set_log_level(3L, confirm = FALSE)
  expect_silent(debuginfo("This should not log"))
  expect_error(read_logs(), "Log file does not exist", fixed = TRUE)
  set_log_level(old_level, confirm = FALSE)
})
