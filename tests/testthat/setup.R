# Each test context needs to wipe the log file etc., so define cleanup()
# function here
cleanup <- function() {
  file.remove(.config$logfile)
}

expect_identical_error <- function(actual, expected) {
  actual <- testthat::capture_error(actual)
  expected <- testthat::capture_error(expected)

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