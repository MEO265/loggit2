# Each test context needs to wipe the log file etc., so define cleanup()
# function here
cleanup <- function() {
  file.remove(.config$logfile)
}

expect_identical_condition <- function(actual, expected, type = c("message", "warning", "error"), remove_namespace = FALSE, ignore_call = FALSE) {
  type <- match.arg(type)

  capture <- switch(
    type,
    message = testthat::capture_message,
    warning = testthat::capture_warning,
    error = testthat::capture_error
  )

  capture.output({
    actual <- capture(actual)
    expected <- capture(expected)
  })

  if (is.null(actual)) {
    testthat::fail("Actual don't throws an error.")
  }
  if (is.null(expected)) {
    testthat::fail("Expected don't throws an error.")
  }

  if (actual$message != expected$message) {
    testthat::fail(sprintf("Actual message is '%s' and expected is '%s'.", actual$message, expected$message))
  }

  if (ignore_call) {
    testthat::succeed()
    return(invisible())
  }

  if (xor(is.null(actual$call), is.null(expected$call))) {
    if (is.null(actual$call)) {
      fail(sprintf("Actual has no call, but expected has '%s'.", deparse(expected$call)))
    } else {
      fail(sprintf("Actual has call '%s', and expected has non.", deparse(actual$call)))
    }
  }

  actual_call <- deparse(actual$call)
  expected_call <- deparse(expected$call)

  if (remove_namespace) {
    actual_call <- sub(pattern = "^[A-Za-z0-9]*::", replacement = "", actual_call)
    expected_call <- sub(pattern = "^[A-Za-z0-9]*::", replacement = "", expected_call)
  }

  if (actual_call != expected_call) {
    fail(sprintf("Actual has call '%s', but expected has '%s'", actual_call, expected_call))
  }

  testthat::succeed()
  return(invisible())
}

expect_identical_error <- function(actual, expected, ignore_call = FALSE) {
  expect_identical_condition(actual, expected, type = "error", ignore_call = ignore_call)
}

expect_identical_warning <- function(actual, expected, ignore_call = FALSE) {
  expect_identical_condition(actual, expected, type = "warning", ignore_call = ignore_call)
}

expect_identical_message <- function(actual, expected, ignore_call = FALSE) {
  expect_identical_condition(actual, expected, type = "message", remove_namespace = TRUE, ignore_call = ignore_call)
}