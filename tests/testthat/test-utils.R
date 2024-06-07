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

test_that("read_logs on empty log", {
  set_logfile(get_logfile(), confirm = FALSE, create = TRUE)
  log_df <- read_logs()
  expect_identical(
    log_df,
    data.frame(timestamp = character(), log_lvl = character(), log_msg = character(), stringsAsFactors = FALSE)
  )
})
cleanup()

test_that("convert_to_csv", {
  tmp_dir <- tempdir()
  convert_to_csv(file = file.path(tmp_dir, "test.csv"), logfile = "testdata/test.loggit")
  convert_to_csv(file = file.path(tmp_dir, "test_reverse.csv"), logfile = "testdata/test.loggit", last_first = TRUE)
  convert_to_csv(
    file = file.path(tmp_dir, "test_with_lf.csv"), unsanitize = TRUE, logfile = "testdata/test.loggit"
  )

  expect_snapshot_file(file.path(tmp_dir, "test.csv"))
  expect_snapshot_file(file.path(tmp_dir, "test_reverse.csv"))
  expect_snapshot_file(file.path(tmp_dir, "test_with_lf.csv"))
})

library(testthat)

# Test for get_lvl_name function
test_that("get_lvl_name", {
  expect_identical(get_lvl_name(0L), "NONE")
  expect_identical(get_lvl_name(1L), "ERROR")
  expect_identical(get_lvl_name(2L), "WARN")
  expect_identical(get_lvl_name(3L), "INFO")
  expect_identical(get_lvl_name(4L), "DEBUG")

  expect_error(get_lvl_name(1.0), "is.integer(level) is not TRUE", fixed = TRUE)
  expect_error(get_lvl_name(TRUE), "is.integer(level) is not TRUE", fixed = TRUE)

  expect_error(get_lvl_name(-1L), "level >= 0L is not TRUE")
  expect_error(get_lvl_name(5L), "level <= 4L is not TRUE")
})

test_that("get_lvl_int", {
  expect_identical(get_lvl_int("NONE"), 0L)
  expect_identical(get_lvl_int("ERROR"), 1L)
  expect_identical(get_lvl_int("WARN"), 2L)
  expect_identical(get_lvl_int("INFO"), 3L)
  expect_identical(get_lvl_int("DEBUG"), 4L)

  expect_error(get_lvl_int(TRUE), "is.character(level) is not TRUE", fixed = TRUE)
  expect_error(get_lvl_int(1.0), "is.character(level) is not TRUE", fixed = TRUE)

  expect_error(get_lvl_int("INVALID"), "level %in% .* is not TRUE")
})

test_that("convert_lvl_input", {
  expect_identical(convert_lvl_input(level = 0L), 0L)
  expect_identical(convert_lvl_input(level = 1L), 1L)
  expect_identical(convert_lvl_input(level = 4L), 4L)

  expect_identical(convert_lvl_input(level = 0.0), 0L)
  expect_identical(convert_lvl_input(level = 1.0), 1L)
  expect_identical(convert_lvl_input(level = 4.0), 4L)

  expect_identical(convert_lvl_input(level = "NONE"), 0L)
  expect_identical(convert_lvl_input(level = "ERROR"), 1L)
  expect_identical(convert_lvl_input(level = "DEBUG"), 4L)

  expect_error(convert_lvl_input(level = -1L))
  expect_error(convert_lvl_input(level = 5.0))

  expect_error(convert_lvl_input(level = "INVALID"))
})
