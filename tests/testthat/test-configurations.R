test_that("test logfile configuration", {
  old <- get_logfile()
  tmp_log <- normalizePath(tempfile("log_test_", fileext = ".loggit"), winslash = "/", mustWork = FALSE)
  expect_silent(set_logfile(tmp_log, confirm = FALSE, create = FALSE))
  expect_false(file.exists(tmp_log))
  expect_identical(get_logfile(), expected = tmp_log)
  set_logfile(old, confirm = FALSE, create = FALSE)
  expect_silent(set_logfile(tmp_log, confirm = FALSE, create = TRUE))
  expect_true(file.exists(tmp_log))
  expect_message(
    set_logfile(old, confirm = TRUE),
    regexp = "^Log file set to .*\n$"
  )
  expect_identical(get_logfile(), expected = normalizePath(old, mustWork = FALSE, winslash = "/"))
})

cleanup()

test_that("test timestamp configuration", {
  old <- get_timestamp_format()
  tmp_ts <- "%Y-%m"
  expect_message(
    set_timestamp_format(ts_format = tmp_ts),
    regexp = sprintf("^Timestamp format set to %s\\.\nCurrent time in this format: \\d{4}-\\d{2}\n$", tmp_ts)
  )
  expect_identical(get_timestamp_format(), tmp_ts)
  expect_silent(set_timestamp_format(ts_format = old, confirm = FALSE))
  expect_identical(get_timestamp_format(), old)
})

test_that("test echo configuration", {
  old <- get_echo()
  on.exit(set_echo(old, confirm = FALSE))

  expect_message(set_echo(echo = TRUE), regexp = "Echo set to TRUE.")
  expect_output(suppressMessages(message("test")), regexp = "\"test\\n\"", fixed = TRUE)
  expect_output(suppressMessages(message("test", echo = FALSE)), regexp = NA)

  expect_silent(set_echo(echo = FALSE, confirm = FALSE))
  expect_output(suppressMessages(message("test", echo = TRUE)), regexp = "\"test\\n\"", fixed = TRUE)
  expect_output(suppressMessages(message("test")), regexp = NA)
})

test_that("test log_lvl configuration", {
  old <- get_log_level()
  on.exit(set_log_level(old, confirm = FALSE))

  # Test log level DEBUG
  expect_message(set_log_level(level = "DEBUG"), regexp = "Log level set to 4 (DEBUG)", fixed = TRUE)
  expect_output(loggit(log_lvl = "DEBUG", log_msg = "test"))
  expect_output(suppressMessages(message("test")))
  expect_output(suppressWarnings(warning("test")))
  expect_output(try(stop("test"), silent = TRUE))

  # Test log level INFO
  expect_message(set_log_level(level = "INFO"), regexp = "Log level set to 3 (INFO)", fixed = TRUE)
  expect_output(loggit(log_lvl = "DEBUG", log_msg = "test"), regexp = NA)
  expect_output(suppressMessages(message("test")))
  expect_output(suppressWarnings(warning("test")))
  expect_output(try(stop("test"), silent = TRUE))

  # Test log level WARNING
  expect_message(set_log_level(level = "WARN"), regexp = "Log level set to 2 (WARN)", fixed = TRUE)
  expect_output(loggit(log_lvl = "DEBUG", log_msg = "test"), regexp = NA)
  expect_output(suppressMessages(message("test")), regexp = NA)
  expect_output(suppressWarnings(warning("test")))
  expect_output(try(stop("test"), silent = TRUE))

  # Test log level ERROR
  expect_message(set_log_level(level = "ERROR"), regexp = "Log level set to 1 (ERROR)", fixed = TRUE)
  expect_output(loggit(log_lvl = "DEBUG", log_msg = "test"), regexp = NA)
  expect_output(suppressMessages(message("test")), regexp = NA)
  expect_output(suppressWarnings(warning("test")), regexp = NA)
  expect_output(try(stop("test"), silent = TRUE))

  # Test log level NONE
  expect_message(set_log_level(level = "NONE"), regexp = "Log level set to 0 (NONE)", fixed = TRUE)
  expect_output(loggit(log_lvl = "DEBUG", log_msg = "test"), regexp = NA)
  expect_output(suppressMessages(message("test")), regexp = NA)
  expect_output(suppressWarnings(warning("test")), regexp = NA)
  expect_output(try(stop("test"), silent = TRUE), regexp = NA)

  # Test ignore log level
  expect_silent(set_log_level(level = "NONE", confirm = FALSE))
  expect_output(loggit(log_lvl = "DEBUG", log_msg = "test", ignore_log_level = TRUE))
  expect_output(suppressMessages(message("test", .loggit = TRUE)))
  expect_output(suppressWarnings(warning("test", .loggit = TRUE)))
  expect_output(try(stop("test", .loggit = TRUE), silent = TRUE))

  expect_silent(set_log_level(level = "DEBUG", confirm = FALSE))
  expect_output(suppressMessages(message("test", .loggit = FALSE)), regexp = NA)
  expect_output(suppressWarnings(warning("test", .loggit = FALSE)), regexp = NA)
  expect_output(try(stop("test", .loggit = FALSE), silent = TRUE), regexp = NA)
})
