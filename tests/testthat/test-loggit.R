test_that("loggit writes handler messages to file", {
  msg <- "this is a message"
  warn <- "this is a warning"
  err <- "this is an error"

  expect_message(message(msg, echo = FALSE, appendLF = FALSE), regexp = msg)
  expect_warning(warning(warn, echo = FALSE), regexp = warn)
  expect_error(stop(err, echo = FALSE), regexp = err)
  logs_json <- read_logs()

  expect_identical(nrow(logs_json), 3L)
  expect_identical(logs_json$log_lvl, c("INFO", "WARN", "ERROR"))
  expect_identical(logs_json$log_msg, c(msg, warn, err))
})
cleanup()


test_that("loggit custom levels behave as expected", {
  expect_error(
    loggit(log_lvl = "foo", log_msg = "bar", echo = FALSE),
    regexp = "^Nonstandard log_lvl .*"
  )
  # There isn't really anything to test here, so just run it and let it succeed
  expect_no_error(loggit(log_lvl = "foo", log_msg = "bar", echo = FALSE, custom_log_lvl = TRUE))
})


test_that("loggit multiplies values with warning", {
  expect_warning(
    loggit(log_lvl = "INFO", log_msg = "foo", value = 1:3, echo = FALSE),
    regexp = "^Each custom log field should be of length one, or else your logs will be multiplied!$"
  )
})
cleanup()


test_that("Log file is returned via read_logs()", {
  message("msg", echo = FALSE)
  log_df <- read_logs()
  expect_true("data.frame" %in% class(log_df))
})
cleanup()
