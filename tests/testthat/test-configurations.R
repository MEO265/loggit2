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

