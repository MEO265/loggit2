test_that("setup_logfile", {
  is_set <- "FILE_LOGGIT2" %in% names(Sys.getenv())
  old_env <- Sys.getenv("FILE_LOGGIT2")
  old_logfile <- get_logfile()
  on.exit({
    if (is_set) Sys.setenv(FILE_LOGGIT2 = old_env) else Sys.unsetenv("FILE_LOGGIT2")
    set_logfile(old_logfile, confirm = FALSE)
  })

  # Test that the logfile is set correctly
  Sys.setenv(FILE_LOGGIT2 = "my_log.log")
  expect_silent(setup_logfile())
  expect_true(grepl(get_logfile(), pattern = "my_log\\.log$"))

  # Test that the default logfile is set correctly
  Sys.unsetenv("FILE_LOGGIT2")
  expect_silent(setup_logfile())
  expect_true(grepl(get_logfile(), pattern = "loggit\\.log$"))
})


test_that("setup_timestamp_format", {
  is_set <- "TIMESTAMP_LOGGIT2" %in% names(Sys.getenv())
  old_env <- Sys.getenv("TIMESTAMP_LOGGIT2")
  old_ts_format <- get_timestamp_format()
  on.exit({
    if (is_set) Sys.setenv(TIMESTAMP_LOGGIT2 = old_env) else Sys.unsetenv("TIMESTAMP_LOGGIT2")
    set_timestamp_format(old_ts_format, confirm = FALSE)
  })

  # Test that the timestamp format is set correctly
  Sys.setenv(TIMESTAMP_LOGGIT2 = "%Y-%m-%d")
  expect_silent(setup_timestamp_format())
  expect_identical(get_timestamp_format(), expected = "%Y-%m-%d")

  # Test that the default timestamp format is set correctly
  Sys.unsetenv("TIMESTAMP_LOGGIT2")
  expect_silent(setup_timestamp_format())
  expect_identical(get_timestamp_format(), expected = "%Y-%m-%dT%H:%M:%S%z")
})


test_that("setup_echo", {
  is_set <- "ECHO_LOGGIT2" %in% names(Sys.getenv())
  old_env <- Sys.getenv("ECHO_LOGGIT2")
  old_echo <- get_echo()
  on.exit({
    if (is_set) Sys.setenv(ECHO_LOGGIT2 = old_env) else Sys.unsetenv("ECHO_LOGGIT2")
    set_echo(old_echo, confirm = FALSE)
  })

  # Test that the echo setting is set correctly
  Sys.setenv(ECHO_LOGGIT2 = "FALSE")
  expect_silent(setup_echo())
  expect_false(get_echo())

  # Test that the default echo setting is set correctly
  Sys.unsetenv("ECHO_LOGGIT2")
  expect_silent(setup_echo())
  expect_true(get_echo())

  # Test that the echo setting is set correctly for invalid input
  set_echo(echo = FALSE, confirm = FALSE)
  Sys.setenv(ECHO_LOGGIT2 = "invalid")
  expect_silent(setup_echo())
  expect_true(get_echo())
})


test_that("setup_log_level", {
  is_set <- "LEVEL_LOGGIT2" %in% names(Sys.getenv())
  old_env <- Sys.getenv("LEVEL_LOGGIT2")
  old_log_level <- get_log_level()
  on.exit({
    if (is_set) Sys.setenv(LEVEL_LOGGIT2 = old_env) else Sys.unsetenv("LEVEL_LOGGIT2")
    set_log_level(old_log_level, confirm = FALSE)
  })

  # Test that the log level is set correctly
  Sys.setenv(LEVEL_LOGGIT2 = "INFO")
  expect_silent(setup_log_level())
  expect_identical(get_log_level(), expected = 3L)

  # Test that the default log level is set correctly
  Sys.unsetenv("LEVEL_LOGGIT2")
  expect_silent(setup_log_level())
  expect_identical(get_log_level(), expected = 4L)

  # Test that the log level is set correctly for invalid input
  set_log_level(level = 3L, confirm = FALSE)
  Sys.setenv(LEVEL_LOGGIT2 = "invalid")
  expect_silent(setup_log_level())
  expect_identical(get_log_level(), expected = 4L)

})

test_that("setup_call_options", {
  old_call_options <- get_call_options()
  on.exit(set_call_options(.arg_list = old_call_options, confirm = FALSE))
  expect_silent(setup_call_options())
  expect_identical(get_call_options(), expected = list(log_call = FALSE, full_stack = FALSE))
})
