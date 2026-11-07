# loggit2: structured logging for R

<!-- badges: start -->

[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/loggit2)](https://cran.r-project.org/package=loggit2)
[![R-CMD-check](https://github.com/MEO265/loggit2/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/MEO265/loggit2/actions/workflows/R-CMD-check.yaml)
[![codecov](https://codecov.io/gh/MEO265/loggit2/graph/badge.svg)](https://codecov.io/gh/MEO265/loggit2)
<!-- badges: end -->

Add logging to existing R code with one call, or write events with your
own context fields. `loggit2` writes newline-delimited JSON (NDJSON) and
reads it back as a data frame, with no additional R runtime
dependencies.

## Install

``` r
install.packages("loggit2")
```

## Log existing code in one call

Wrap the function you already run:

``` r
loggit2::with_loggit(your_function())
```

Messages, warnings and errors are added to the log. The function keeps
its return value and its normal condition behavior: warnings still warn
and errors still stop execution. No changes inside the function are
needed.

By default, logs go to `loggit2::get_logfile()` in R’s temporary
directory. JSON entries are also echoed to stdout; use `echo = FALSE` to
turn off that additional output.

## Write and read a structured event

This complete example uses its own temporary file:

``` r
logfile <- tempfile(fileext = ".ndjson")

loggit2::loggit(
  "INFO", "Import completed",
  run_id = "demo-001", rows = 120L,
  logfile = logfile, echo = FALSE
)

loggit2::read_logs(logfile)[c("log_lvl", "log_msg", "run_id", "rows")]
#>   log_lvl          log_msg   run_id rows
#> 1    INFO Import completed demo-001  120
```

Each named field becomes a column. Non-missing values are stored as
strings; `NA` is stored as JSON `null`. Use named scalar values for
custom fields. `loggit()` records an event without signaling a
condition, even at level `"ERROR"`.

## Choose how to log

| What you want to do                                     | Use                                                          |
|---------------------------------------------------------|--------------------------------------------------------------|
| Log conditions from existing or third-party code        | `with_loggit(your_function())`                               |
| Write an event with fields such as a run ID or filename | `loggit("INFO", "Finished", run_id = "run-1")`               |
| Signal a condition and log it in your own code          | `loggit2::message()`, `warning()`, `stop()` or `stopifnot()` |
| Add a debug entry, optionally with its call or stack    | `debuginfo()` and `set_call_options()`                       |
| Log function entry and exit at DEBUG level              | `trace_loggit()`                                             |
| Log changes to a variable at DEBUG level                | `watch_loggit()`                                             |

Use explicit `loggit2::` calls to select the condition wrappers.
Attaching the package with `library(loggit2)` also masks their Base R
counterparts for ordinary calls; it does not replace calls inside other
packages. Avoid combining the wrappers with `with_loggit()` for the same
condition, as this can log it twice.

## Configure only what you need

No configuration is required to start. For a persistent log, choose a
path in an existing directory:

``` r
loggit2::set_logfile("logs/application.ndjson")
loggit2::set_log_level("INFO")  # omit DEBUG entries
loggit2::set_echo(FALSE)        # keep file logging; disable the extra JSON output
```

`echo = FALSE` does not suppress R messages, warnings or errors. You can
also pass `logfile` and `echo` directly to `loggit()` or `with_loggit()`
for a single call.

Multiple R processes can share a local log file with the default locking
enabled. See [sharing a log file between
processes](https://r-loggit.org/articles/further_configurations.html#share-a-log-file-between-processes)
for the locking settings and filesystem requirements.

## Follow your use case

- [Get your first log](https://r-loggit.org/articles/loggit2.html): a
  short tour of the three ways to log.
- [Log existing code in one
  call](https://r-loggit.org/articles/logging-existing-code.html):
  capture conditions, handle errors and investigate calls and stacks.
- [Analyze logs from a data
  pipeline](https://r-loggit.org/articles/structured-logs.html): add
  context fields, filter events and export CSV.
- [Configure logging and understand
  scope](https://r-loggit.org/articles/further_configurations.html):
  environment variables, session defaults and per-call settings.
- [Function reference](https://r-loggit.org/reference/index.html): all
  arguments and return values.

The tutorials are also included with the package:
`browseVignettes("loggit2")`.

## Development version

``` r
# Requires the remotes package.
remotes::install_github("MEO265/loggit2")
```

## Acknowledgments

`loggit2` is based on Ryan Price’s
[loggit](https://github.com/ryapric/loggit), version 2.1.1. See [Why the
fork?](https://r-loggit.org/articles/fork.html) for background.
