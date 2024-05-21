# Easy-to-use, dependencyless Logger for R

<!-- badges: start -->

[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/loggit2)](https://cran.r-project.org/package=loggit2)
[![Downloads](https://cranlogs.r-pkg.org/badges/grand-total/loggit2)](https://cran.r-project.org/package=loggit2)
[![R-CMD-check](https://github.com/MEO265/loggit2/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/MEO265/loggit2/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/MEO265/loggit2/graph/badge.svg)](https://codecov.io/gh/MEO265/loggit2)

------------------------------------------------------------------------

<!-- badges: end -->

`loggit2` is an easy-to-use
[`ndJSON`](https://github.com/ndjson/ndjson-spec) logging library for R,
with *zero* external dependencies.

Please see below for some quick examples, and read the
[vignettes](https://cran.r-project.org/web/packages/loggit2/vignettes/)
for more.

## Why use `loggit2`?

`loggit2` takes a minimalistic but powerful approach to logging in R:

- Easy integration, even into existing code
- Flexible logs with automatic field creation
- Logs immediately available as `data.frame` objects and as ndJSON and
  CSV file.
- Simple external logging (e.g., in containers) via ndJSON echo to
  stdout
- *Zero* external dependencies

Additionally, the boilerplate to get going with `loggit2` is minimal at
worst.

## Usage

`loggit2` provides, among other functions, a set of wrappings for base
R’s `message()`, `warning()`, `stop()` and `stopifnot()` functions that
maintain identical functionality, except the additional logging. Thus,
it is sufficient to import the `loggit2` namespace, for example by using
`library("loggit2")`, or by prefixing `loggit2::` at the desired
locations.

``` r
base::message("This is another message")
#> This is another message
base::warning("This is another warning")
#> Warning: This is another warning
base::stop("This is another error")
#> Error in eval(expr, envir, enclos): This is another error
base::stopifnot("This is another condition" = FALSE)
#> Error: This is another condition

loggit2::message("This is a message")
#> {"timestamp": "2024-05-22T08:27:17+0200", "log_lvl": "INFO", "log_msg": "This is a message\n"}
#> This is a message
loggit2::warning("This is a warning")
#> {"timestamp": "2024-05-22T08:27:17+0200", "log_lvl": "WARN", "log_msg": "This is a warning"}
#> Warning: This is a warning
loggit2::stop("This is an error")
#> {"timestamp": "2024-05-22T08:27:17+0200", "log_lvl": "ERROR", "log_msg": "This is an error"}
#> Error in eval(expr, envir, enclos): This is an error
loggit2::stopifnot("This is another condition" = FALSE)
#> {"timestamp": "2024-05-22T08:27:17+0200", "log_lvl": "ERROR", "log_msg": "This is another condition"}
#> Error: This is another condition
```

You can suppress the additional console output by using `echo = FALSE`
and you won’t notice any difference to the base functions (except that
the log will be filled in the background).

You can also directly use the logging function `loggit()` to compose
much more custom logs, e.g. to include custom fields or to prevent
throwing actual conditions.

``` r
loggit2::loggit("ERROR", "This will log an error", anything_else = "you want to include")
#> {"timestamp": "2024-05-22T08:27:17+0200", "log_lvl": "ERROR", "log_msg": "This will log an error", "anything_else": "you want to include"}

# Read log file into data frame to implement logic based on entries
loggit2::read_logs()
#>                  timestamp log_lvl                   log_msg       anything_else
#> 1 2024-05-22T08:27:17+0200    INFO       This is a message\n                <NA>
#> 2 2024-05-22T08:27:17+0200    WARN         This is a warning                <NA>
#> 3 2024-05-22T08:27:17+0200   ERROR          This is an error                <NA>
#> 4 2024-05-22T08:27:17+0200   ERROR This is another condition                <NA>
#> 5 2024-05-22T08:27:17+0200   ERROR    This will log an error you want to include
```

No further configurations are necessary for this: just throw nearly
whatever you want at it, and it’ll become a structured log.

Check out the
[vignettes](https://cran.r-project.org/web/packages/loggit2/vignettes/)
for more details and features.

## Installation

You can install the latest CRAN release of `loggit2` via

    install.packages("loggit2")

or, get the latest development version from GitHub via

    devtools::install_github("MEO265/loggit2")

## Acknowledgments

This package is based on the [“loggit” package by Ryan
Price](https://github.com/ryapric/loggit), specifically version 2.1.1.
