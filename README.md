# Modern Logging for the R Ecosystem

Ryan Price <ryapric@gmail.com>

<!-- badges: start -->

[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/loggit)](https://cran.r-project.org/package=loggit)
[![Monthly
downloads](https://cranlogs.r-pkg.org/badges/loggit)](https://cran.r-project.org/package=loggit)
[![R-CMD-check](https://github.com/MEO265/loggit_private/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/MEO265/loggit_private/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/MEO265/loggit_private/graph/badge.svg?token=DGPQGD4DUH)](https://codecov.io/gh/MEO265/loggit_private)
<!-- badges: end -->

------------------------------------------------------------------------

`loggit` is an [`ndJSON`](https://github.com/ndjson/ndjson-spec) logging
library for R software, with *zero* external dependencies.

Please see below for some quick examples, and read the
[vignettes](https://cran.r-project.org/web/packages/loggit/vignettes/)
for the Getting Started guide.

## Why use `loggit`?

`loggit` takes a modern approach to logging in R:

- Opting to use the JSON format, which is parsable by most modern
  software
- Designed with highly flexible log streams in mind
- Ability to log data, then analyze that log data on the same host.
- *Zero* external dependencies

Additionally, the boilerplate to get going with `loggit` is minimal at
worst. If deploying your R code in a container ecosystem, you don’t even
need to do that, since `loggit` will echo its formatted logs to
`stdout`. No need to write custom formatters, handlers, levels, etc. –
***just loggit!***

## Usage

The quickest way to get up & running with `loggit` is to do nearly
nothing.

`loggit` provides a set of wrappings for base R’s `message()`,
`warning()`, and `stop()` functions that maintain identical
functionality, making it sufficient to import the `loggit` namespace,
for example by using `library("loggit")`, or by prefixing `loggit::` at
the desired locations.

``` r
loggit::message("This is a message")
#> {"timestamp": "2023-12-19T15:37:20+0100", "log_lvl": "INFO", "log_msg": "This is a message"}
#> This is a message
loggit::warning("This is a warning")
#> {"timestamp": "2023-12-19T15:37:20+0100", "log_lvl": "WARN", "log_msg": "This is a warning"}
#> Warning in loggit::warning("This is a warning"): This is a warning
loggit::stop("This is an error")
#> {"timestamp": "2023-12-19T15:37:20+0100", "log_lvl": "ERROR", "log_msg": "This is an error"}
#> Error in loggit::stop("This is an error"): This is an error
```

You can suppress the additional console output by using `echo = FALSE`
and you won’t notice any difference to the base functions (except that
the log will be filled in the background).

``` r
loggit::message("This is another message", echo = FALSE)
#> This is another message
loggit::warning("This is another warning", echo = FALSE)
#> Warning in loggit::warning("This is another warning", echo = FALSE): This is another warning
loggit::stop("This is another error", echo = FALSE)
#> Error in loggit::stop("This is another error", echo = FALSE): This is another error
```

You can also use the `loggit()` function directly to compose much more
custom logs, including ***entirely custom fields*** (and prevent
throwing actual conditions). `loggit` doesn’t require that you set
custom logger objects or anything like that: just throw whatever you
want at it, and it’ll become a structured log.

``` r
loggit::loggit("ERROR", "This will log an error", anything_else = "you want to include")
#> {"timestamp": "2023-12-19T15:37:20+0100", "log_lvl": "ERROR", "log_msg": "This will log an error", "anything_else": "you want to include"}

# Read log file into data frame to implement logic based on entries
loggit::read_logs()
#>                  timestamp log_lvl                 log_msg       anything_else
#> 1 2023-12-19T15:37:20+0100    INFO       This is a message                    
#> 2 2023-12-19T15:37:20+0100    WARN       This is a warning                    
#> 3 2023-12-19T15:37:20+0100   ERROR        This is an error                    
#> 4 2023-12-19T15:37:20+0100    INFO This is another message                    
#> 5 2023-12-19T15:37:20+0100    WARN This is another warning                    
#> 6 2023-12-19T15:37:20+0100   ERROR   This is another error                    
#> 7 2023-12-19T15:37:20+0100   ERROR  This will log an error you want to include
```

Check out the
[vignettes](https://cran.r-project.org/web/packages/loggit/vignettes/)
for more details.

## Installation

You can install the latest CRAN release of `loggit` via

    install.packages("loggit")

Or, to get the latest development version from GitHub via
[devtools](https://github.com/hadley/devtools):

    devtools::install_github("ryapric/loggit")
