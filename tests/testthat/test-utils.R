test_that("rotate_logs works on default log file", {
  for (i in seq_len(100L)) {
    loggit("INFO", paste0("log_", i), echo = FALSE)
  }

  rotate_lines <- 150L
  rotate_logs(rotate_lines = rotate_lines)
  log_df <- read_logs()
  expect_identical(nrow(log_df), 100L)

  rotate_lines <- 50L
  rotate_logs(rotate_lines = rotate_lines)
  log_df <- read_logs()
  expect_identical(nrow(log_df), rotate_lines)

  rotate_lines <- 0L
  rotate_logs(rotate_lines = rotate_lines)
  log_df <- read_logs()

  expect_identical(nrow(log_df), rotate_lines)

  expect_error(rotate_logs(-1L))
})
cleanup()


test_that("rotate_logs works on non-default log file", {
  other_logfile <- file.path(tempdir(), "another.log")
  set_logfile(other_logfile, confirm = FALSE)

  for (i in 1:100) {
    loggit("INFO", paste0("log_", i), echo = FALSE)
  }

  # Now loggit is pointing to default log file, and has a dummy message
  set_logfile(confirm = FALSE)
  loggit("INFO", "shouldn't be seen", echo = FALSE)

  rotate_lines <- 150L
  rotate_logs(rotate_lines = rotate_lines, other_logfile)
  log_df <- read_logs(other_logfile)
  expect_identical(nrow(log_df), 100L)

  rotate_lines <- 50L
  rotate_logs(rotate_lines = rotate_lines, other_logfile)
  log_df <- read_logs(other_logfile)
  expect_identical(nrow(log_df), rotate_lines)

  rotate_lines <- 0L
  rotate_logs(rotate_lines = rotate_lines, other_logfile)
  log_df <- read_logs(other_logfile)
  expect_identical(nrow(log_df), rotate_lines)

  #Check untouched log
  log_df <- read_logs()
  expect_identical(nrow(log_df), 1L)
})
cleanup()

test_that("rotate_logs preserves sanitization", {

  tmp_log <- file.path(tempdir(), "test.loggit")
  file.copy("testdata/test.loggit", tmp_log)
  on.exit(file.remove(tmp_log))

  bevor <- read_logs(tmp_log)

  rotate_lines <- 3L
  rotate_logs(rotate_lines = rotate_lines, logfile = tmp_log)
  expect_snapshot_file(tmp_log)

})