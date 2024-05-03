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
  log_df_got$timestamp <- NULL

  expect_identical(log_df_want, log_df_got)
})
cleanup()


test_that("write_logs() and read_logs() work with disallowed JSON characters via santizers", {
  loggit("INFO", 'default { } , " \r \n sanitizer', echo = FALSE)

  comma_replacer <- function(string) {
    string <- gsub(",", " - ", string, fixed = TRUE)
    string
  }

  loggit("INFO", "custom,sanitizer", echo = FALSE, sanitizer = comma_replacer)

  log_df_want <- data.frame(
    log_lvl = "INFO",
    log_msg = c(
      "default __LEFTBRACE__ __RIGHTBRACE__ __COMMA__ __DBLQUOTE__ __CR__ __LF__ sanitizer",
      "custom - sanitizer"
    ),
    stringsAsFactors = FALSE
  )

  # Need to pass in a dummy unsanitizer, to return the sanitized strings as-is
  # for checking
  log_df_got <- read_logs(unsanitizer = identity)

  # jk, set timestamps equal, since CRAN tests started failing because of
  # just-barely-different results
  log_df_got$timestamp <- NULL

  expect_identical(log_df_want, log_df_got)
})
cleanup()


test_that("read_logs() works with unsanitizers", {
  loggit("INFO", 'default { } , " \r \n unsanitizer', echo = FALSE)

  comma_replacer <- function(string) gsub(",", " - ", string, fixed = TRUE)

  dash2comma_replacer <- function(string) gsub(" - ", ",", string, fixed = TRUE)

  loggit("INFO", "custom,unsanitizer", echo = FALSE, sanitizer = comma_replacer)

  expect_identical('default { } , " \r \n unsanitizer', read_logs()[1L, "log_msg"])
  expect_identical("custom,unsanitizer", read_logs(unsanitizer = dash2comma_replacer)[2L, "log_msg"])
})
cleanup()


test_that("write_logs() special cases", {
  # Ignore NAs
  log_data <- data.frame(log_lvl = c("foo", "bar"), log_msg = NA_character_)
  write_ndjson(log_data, echo = FALSE)
  log_file <- read_logs()
  expect_identical(log_file, data.frame(log_lvl = c("foo", "bar")))

  # Warn about unsanitized line breaks
  log_data <- data.frame(log_lvl = "fo\no")
  expect_warning(write_ndjson(log_data, echo = FALSE))
})
cleanup()
