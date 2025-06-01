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

test_that("test call option configuration", {
  old <- get_call_options()
  on.exit(set_call_options(.arg_list = old, confirm = FALSE))

  # error when both ... and .arg_list provided
  expect_error(
    set_call_options(a = TRUE, .arg_list = list(a = TRUE)),
    "Only one of `...` or `.arg_list` can be provided"
  )

  # error when .arg_list is not a list
  expect_error(
    set_call_options(.arg_list = "notalist"),
    ".arg_list must be a list"
  )

  # error when .arg_list is not named
  bad_list <- list(TRUE, named = 1L)
  expect_error(
    set_call_options(.arg_list = bad_list),
    "All arguments must be named"
  )

  # warnig when .arg_list has unexpected arguments
  expect_warning(
    set_call_options(.arg_list = list(log_call = TRUE, full_stack = TRUE, unexpected = TRUE), confirm = FALSE),
    "Unexpected arguments provided: unexpected"
  )

  # no args: returns old, sets defaults, and prints message
  set <- set_call_options(confirm = FALSE, log_call = TRUE, full_stack = FALSE) # Init for test
  expect_message(
    old <- set_call_options(),
    "Call options set to log_call = FALSE, full_stack = FALSE."
  )
  expect_identical(old, list(log_call = TRUE, full_stack = FALSE))

  # sets options via ... and returns old
  set_call_options(log_call = TRUE, full_stack = TRUE, confirm = FALSE) # Init for test
  expect_message(
    old <- set_call_options(log_call = FALSE, full_stack = TRUE),
    "Call options set to log_call = FALSE, full_stack = TRUE."
  )
  expect_identical(old, list(log_call = TRUE, full_stack = TRUE))

  # set options via .arg_list and returns old
  set_call_options(log_call = TRUE, full_stack = FALSE, confirm = FALSE) # Init for test
  expect_message(
    old <- set_call_options(.arg_list = list(log_call = TRUE, full_stack = TRUE)),
    "Call options set to log_call = TRUE, full_stack = TRUE."
  )
  expect_identical(old, list(log_call = TRUE, full_stack = FALSE))

  # call confirm = FALSE, no message, returns old
  set_call_options(log_call = FALSE, full_stack = TRUE, confirm = FALSE) # Init for test
  expect_silent(old <- set_call_options(.arg_list = list(log_call = FALSE, full_stack = FALSE), confirm = FALSE))
  expect_identical(old, list(log_call = FALSE, full_stack = TRUE))
})
cleanup()

test_that("test call option configuration (effect on call handlers)", {
  old <- set_call_options(log_call = TRUE, full_stack = FALSE, confirm = FALSE)
  on.exit(set_call_options(.arg_list = old, confirm = FALSE))
  # Test loggit (via function call to garantee a call object)
  f <- function() loggit(log_lvl = "DEBUG", log_msg = "Test message with call", echo = FALSE)
  g <- function() f()
  g()
  log_tmp <- read_logs()
  expect_true(is.na(log_tmp[["log_call"]]))
  cleanup()
  # Test debuginfo
  f <- function() debuginfo("Test message with call", echo = FALSE)
  g <- function() f()
  g()
  log_tmp <- read_logs()
  expect_identical(log_tmp[["log_call"]], "f()")
  cleanup()
  # Test message
  f <- function() message("Test message with call", echo = FALSE)
  g <- function() f()
  suppressMessages(g())
  log_tmp <- read_logs()
  # Message uses an alternative call approach
  expect_identical(log_tmp[["log_call"]], "message(\"Test message with call\", echo = FALSE)")
  cleanup()
  # Test warning
  f <- function() warning("Test message with call", echo = FALSE)
  g <- function() f()
  suppressWarnings(g())
  log_tmp <- read_logs()
  expect_identical(log_tmp[["log_call"]], "f()")
  cleanup()
  # Test error
  f <- function() stop("Test message with call", echo = FALSE)
  g <- function() f()
  try(g(), silent = TRUE)
  log_tmp <- read_logs()
  expect_identical(log_tmp[["log_call"]], "f()")
  cleanup()
  # Test stopifnot
  f <- function() stopifnot(FALSE, "Test message with call", echo = FALSE)
  g <- function() f()
  try(g(), silent = TRUE)
  log_tmp <- read_logs()
  expect_identical(log_tmp[["log_call"]], "f()")
})
cleanup()

test_that("test call option configuration (effect on call handlers) II", {
  old <- set_call_options(log_call = FALSE, confirm = FALSE)
  on.exit(set_call_options(.arg_list = old, confirm = FALSE))
  # Test loggit (via function call to garantee a call object)
  loggit(log_lvl = "DEBUG", log_msg = "Test message with call", echo = FALSE)
  debuginfo("Test message with call", echo = FALSE)
  suppressMessages(message("Test message with call", echo = FALSE))
  suppressWarnings(warning("Test message with call", echo = FALSE))
  try(stop("Test message with call", echo = FALSE), silent = TRUE)
  try(stopifnot(FALSE, "Test message with call", echo = FALSE), silent = TRUE)
  log_tmp <- read_logs()
  expect_false("log_call" %in% names(log_tmp))
})
cleanup()


test_that("test call option configuration (effect on call handlers) III", {
  old <- set_call_options(log_call = TRUE, full_stack = TRUE, confirm = FALSE)
  on.exit(set_call_options(.arg_list = old, confirm = FALSE))
  # Test loggit (via function call to garantee a call object)
  f <- function() loggit(log_lvl = "DEBUG", log_msg = "Test message with call", echo = FALSE)
  g <- function() f()
  g()
  log_tmp <- read_logs()
  expect_true(is.na(log_tmp[["log_call"]]))
  cleanup()
  # Test debuginfo
  f <- function() debuginfo("Test message with call", echo = FALSE)
  g <- function() f()
  g()
  log_tmp <- read_logs()
  expect_true(grepl(log_tmp[["log_call"]], pattern = "\ng().*\nf()"))
  cleanup()
  # Test message
  f <- function() message("Test message with call", echo = FALSE)
  g <- function() f()
  suppressMessages(g())
  log_tmp <- read_logs()
  # Message uses an alternative call approach
  expect_true(grepl(
    log_tmp[["log_call"]], pattern = "\ng\\(\\).*\nmessage\\(\"Test message with call\", echo = FALSE\\)"
  ))
  cleanup()
  # Test warning
  f <- function() warning("Test message with call", echo = FALSE)
  g <- function() f()
  suppressWarnings(g())
  log_tmp <- read_logs()
  expect_true(grepl(log_tmp[["log_call"]], pattern = "\ng().*\nf()"))
  cleanup()
  # Test error
  f <- function() stop("Test message with call", echo = FALSE)
  g <- function() f()
  try(g(), silent = TRUE)
  log_tmp <- read_logs()
  expect_true(grepl(log_tmp[["log_call"]], pattern = "\ng().*\nf()"))
  cleanup()
  # Test stopifnot
  f <- function() stopifnot(FALSE, "Test message with call", echo = FALSE)
  g <- function() f()
  try(g(), silent = TRUE)
  log_tmp <- read_logs()
  expect_true(grepl(log_tmp[["log_call"]], pattern = "\ng().*\nf()"))
})
cleanup()
