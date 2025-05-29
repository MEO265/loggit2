test_that("loggit writes handler messages to file", {
  msg <- "this is a message"
  warn <- "this is a warning"
  err <- "this is an error"

  expect_message(message(msg, echo = FALSE, appendLF = FALSE), regexp = msg)
  expect_warning(warning(warn, echo = FALSE), regexp = warn)
  expect_error(stop(err, echo = FALSE), regexp = err)
  logs_json <- read_logs()

  expect_identical(nrow(logs_json), 3L)
  expect_identical(logs_json[["log_lvl"]], c("INFO", "WARN", "ERROR"))
  expect_identical(logs_json[["log_msg"]], c(msg, warn, err))
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

  expect_warning(
    loggit(log_lvl = "INFO", log_msg = c("foo", "bar"), value = 1L, echo = FALSE),
    regexp = "^log_msg should be of length one, only the first element will be used.$"
  )

  expect_warning(
    loggit(log_lvl = c("INFO", "DEBUG"), log_msg = "foo", value = 3L, echo = FALSE),
    regexp = "^log_lvl should be of length one, only the first element will be used.$"
  )

  expect_error(
    loggit(log_lvl = "INFO", log_msg = "foo", value = 1L, "4", echo = FALSE),
    regexp = "^All custom log fields should be named.$"
  )

})
cleanup()


test_that("Log file is returned via read_logs()", {
  message("msg", echo = FALSE)
  log_df <- read_logs()
  expect_true(is.data.frame(log_df))
})
cleanup()

test_that("loggit warns on use of reserved fields", {
  expect_warning(
    loggit(log_lvl = "INFO", log_msg = "foo", timestamp = "2023-01-01", echo = FALSE),
    regexp = "^The 'timestamp' and 'log_call' fields are reserved and will be ignored.$"
  )

  expect_warning(
    loggit(log_lvl = "INFO", log_msg = "foo", log_call = "some call", echo = FALSE),
    regexp = "^The 'timestamp' and 'log_call' fields are reserved and will be ignored.$"
  )

  expect_warning(
    loggit(log_lvl = "INFO", log_msg = "foo", timestamp = "2023-01-01", log_call = "some call", echo = FALSE),
    regexp = "^The 'timestamp' and 'log_call' fields are reserved and will be ignored.$"
  )
})
cleanup()

test_that("loggit handles call options correctly", {
  old_options <- get_call_options()
  on.exit(set_call_options(.arg_list = old_options, confirm = FALSE), add = TRUE)
  set_call_options(log_call = TRUE, full_stack = FALSE, confirm = FALSE)
  loggit(log_lvl = "INFO", log_msg = "test call options", echo = FALSE)
  log_df <- read_logs()
  expect_true("log_call" %in% names(log_df))
  expect_true(is.na((log_df[["log_call"]])))
})
cleanup()

test_that("loggit handles call options correctly (with ...)", {
  old_options <- get_call_options()
  on.exit(set_call_options(.arg_list = old_options, confirm = FALSE), add = TRUE)
  set_call_options(log_call = TRUE, full_stack = FALSE, confirm = FALSE)
  loggit(log_lvl = "INFO", log_msg = "test call options with dots", echo = FALSE, custom_field = "value")
  log_df <- read_logs()
  expect_true("custom_field" %in% names(log_df))
  expect_identical(log_df[["custom_field"]], "value")
})
cleanup()
