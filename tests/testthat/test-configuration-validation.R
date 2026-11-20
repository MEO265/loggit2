test_that("invalid setter flags report their names before making changes", {
  old_echo <- get_echo()
  old_logfile <- get_logfile()
  old_format <- get_timestamp_format()
  old_level <- get_log_level()
  old_options <- get_call_options()
  new_logfile <- tempfile()

  for (value in list(NA, NULL, logical(), c(TRUE, FALSE), 1L, "TRUE")) {
    expect_error(set_echo(value), "`echo` must be TRUE or FALSE.", fixed = TRUE)
  }
  expect_error(set_echo(!old_echo, confirm = NA), "`confirm`", fixed = TRUE)
  expect_error(set_logfile(new_logfile, confirm = NA), "`confirm`", fixed = TRUE)
  expect_error(set_logfile(new_logfile, create = NA), "`create`", fixed = TRUE)
  expect_error(set_timestamp_format("new format", confirm = NA), "`confirm`", fixed = TRUE)
  expect_error(set_log_level((old_level + 1L) %% 5L, confirm = NA), "`confirm`", fixed = TRUE)
  expect_error(set_call_options(log_call = !old_options$log_call, confirm = NA), "`confirm`", fixed = TRUE)

  expect_identical(get_echo(), old_echo)
  expect_identical(get_logfile(), old_logfile)
  expect_identical(get_timestamp_format(), old_format)
  expect_identical(get_log_level(), old_level)
  expect_identical(get_call_options(), old_options)
  expect_false(file.exists(new_logfile))
})


test_that("logfile configuration reports invalid paths and creation failures", {
  old_logfile <- get_logfile()
  for (path in list("", NA_character_, character(), 10L, c(tempfile(), tempfile()))) {
    expect_error(set_logfile(path), "`logfile` must be a non-empty file path.", fixed = TRUE)
  }
  expect_error(set_logfile(tempdir(), create = FALSE), "is a directory.", fixed = TRUE)
  missing_parent <- file.path(tempfile(), "test.log")
  expect_error(set_logfile(missing_parent), "Cannot open `logfile`", fixed = TRUE)
  expect_identical(get_logfile(), old_logfile)
  expect_false(file.exists(missing_parent))
})


test_that("invalid timestamp formats and log levels are rejected", {
  old_format <- get_timestamp_format()
  for (value in list(123L, NULL, NA_character_, character(), c("%Y", "%m"))) {
    expect_error(set_timestamp_format(value, confirm = FALSE), "`ts_format`", fixed = TRUE)
  }
  expect_identical(get_timestamp_format(), old_format)

  old_level <- get_log_level()
  for (value in list("BAD", NA_real_, NaN, Inf, NULL, character(), c("INFO", "WARN"), -0.5, 4.9)) {
    expect_error(set_log_level(value, confirm = FALSE), "`level` must be one of", fixed = TRUE)
  }
  expect_identical(get_log_level(), old_level)
})


test_that("call options reject invalid values and duplicate names before updating", {
  old_options <- get_call_options()
  expect_error(set_call_options(log_call = NA), "`log_call`", fixed = TRUE)
  expect_error(set_call_options(log_call = !old_options$log_call, full_stack = NULL), "`full_stack`", fixed = TRUE)
  expect_error(set_call_options(.arg_list = list(full_stack = "TRUE")), "`full_stack`", fixed = TRUE)
  duplicate <- setNames(list(TRUE, FALSE), rep("log_call", 2L))
  expect_error(set_call_options(.arg_list = duplicate), "Call option names must be unique.", fixed = TRUE)
  expect_identical(get_call_options(), old_options)
})


test_that("with_loggit validates options before evaluating or opening the log", {
  evaluated <- FALSE
  log <- tempfile()
  expect_error(with_loggit(evaluated <- TRUE, logfile = log, echo = NA), "`echo`", fixed = TRUE)
  expect_error(with_loggit(evaluated <- TRUE, logfile = log, log_level = c(3L, 2L)), "`log_level`", fixed = TRUE)
  expect_error(with_loggit(evaluated <- TRUE, logfile = tempdir()), "is a directory.", fixed = TRUE)
  expect_false(evaluated)
  expect_false(file.exists(log))
})
