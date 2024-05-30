# Testing both the ability to write to, and read from ndjson here, since it
# would be hard to test that the file is ndjson without reading it back in
# anyway
test_that("write_logs() and read_logs() work in tandem", {
  loggit("INFO", "msg1", echo = FALSE)
  loggit("INFO", "msg2", echo = FALSE)
  loggit("INFO", "msg3", echo = FALSE)
  loggit("INFO", "msg4: should: be :displayed:", extra = "fields", echo = FALSE)

  log_df_want <- data.frame(
    log_lvl = "INFO",
    log_msg = c("msg1", "msg2", "msg3", "msg4: should: be :displayed:"),
    extra = c(NA_character_, NA_character_, NA_character_, "fields"),
    stringsAsFactors = FALSE
  )

  log_df_got <- read_logs()

  # jk, set timestamps equal, since CRAN tests started failing because of
  # just-barely-different results
  log_df_got[["timestamp"]] <- NULL

  expect_identical(log_df_want, log_df_got)
})
cleanup()

test_that("read_logs() works with unsanitizers", {
  loggit("INFO", 'default { } , " \r \n unsanitizer', echo = FALSE)

  expect_identical('default { } , " \r \n unsanitizer', read_logs()[1L, "log_msg"])
})
cleanup()


test_that("write_logs() special cases", {
  # Ignore NAs
  log_data <- data.frame(log_lvl = c("foo", "bar"), log_msg = NA_character_, stringsAsFactors = FALSE)
  write_ndjson(log_data, echo = FALSE)
  log_file <- read_logs()
  expect_identical(log_file, data.frame(log_lvl = c("foo", "bar"), log_msg = NA_character_, stringsAsFactors = FALSE))
})
cleanup()
