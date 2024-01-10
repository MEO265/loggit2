# Each test context needs to wipe the log file etc., so define cleanup()
# function here
cleanup <- function() {
  file.remove(.config$logfile)
}

expect_identical_condition <- function(actual, expected, type = c("message", "warning", "error")) {
  type <- match.arg(type)

  capture <- switch(
    type,
    message = testthat::capture_message,
    warning = testthat::capture_warning,
    error = testthat::capture_error
  )

  actual <- capture(actual)
  expected <- capture(expected)

  if(is.null(actual)){
    testthat::fail("Actual don't throws an error.")
  }
  if(is.null(expected)){
    testthat::fail("Expected don't throws an error.")
  }

  if(actual$message != expected$message){
    testthat::fail(sprintf("Actual message is '%s' and expected is '%s'.", actual$message, expected$message))
  }

  if(xor(is.null(actual$call), is.null(expected$call))){
    if(is.null(actual$call)) {
      fail(sprintf("Actual has no call, but expected has '%s'.", deparse(expected$call)))
    } else {
      fail(sprintf("Actual has call '%s', and expected has non.", deparse(actual$call)))
    }
  }

  if(actual$call != expected$call) {
    fail(sprintf("Actual has call '%s', but expected has '%s'", deparse(actual$call), deparse(expected$call)))
  }

  testthat::succeed()
  return(invisible())
}

expect_identical_error <- function (actual, expected) expect_identical_condition(actual, expected, type = "error")

expect_identical_warning <- function (actual, expected) expect_identical_condition(actual, expected, type = "warning")

expect_identical_message <- function (actual, expected) expect_identical_condition(actual, expected, type = "message")