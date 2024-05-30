test_that("Message, warning, and error get writen to the log file", {

  test_function <- function(x) {
    base::message("A message")
    base::warning("A warning")
  }

  expect_warning(
    expect_message(
      with_loggit(test_function(y), echo = FALSE),
      "A message"
    ),
    "A warning"
  )

  expect_error(
    with_loggit({
      base::message("A message")
      base::stop("An error")
    }, echo = FALSE),
    "An error"
  )

  logs_json <- read_logs()
  expect_identical(nrow(logs_json), 4L)
  expect_identical(logs_json[["log_lvl"]], c("INFO", "WARN", "INFO", "ERROR"))
  expect_identical(logs_json[["log_msg"]], c("A message\n", "A warning", "A message\n", "An error"))
})
cleanup()

test_that("Different log files for handler and with_loggit", {

  default_logfile <- get_logfile()
  with_logfile <- file.path(tempdir(), "with_loggit.log")

  test_function <- function(x) {
    with_loggit({
      base::message("A message")
      base::warning("A warning")
    }, echo = FALSE, logfile = default_logfile)
  }

  expect_warning(
    expect_message(
      with_loggit(test_function(y), echo = FALSE, logfile = with_logfile),
      "A message"
    ),
    "A warning"
  )

  expect_identical(get_logfile(), default_logfile)
  default_log <- read_logs(logfile = default_logfile)
  with_log <- read_logs(logfile = with_logfile)
  expect_identical(default_log[["log_lvl"]], with_log[["log_lvl"]])
  expect_identical(default_log[["log_msg"]], with_log[["log_msg"]])

})
cleanup()

test_that("Combination of tryCatch and with_loggit", {
  # Message
  expect_message(
    tryCatch({
      with_loggit(base::message("A message"), echo = FALSE)
    }, message = function(e)  base::message("tryCatch")
    ),
    "tryCatch"
  )

  # Warning
  expect_message(
    tryCatch({
      with_loggit(base::warning("A message"), echo = FALSE)
    }, warning = function(e)  base::message("tryCatch")
    ),
    "tryCatch"
  )
})
cleanup()
