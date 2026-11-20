# Log any expressions

Log code without having to explicitly use the `loggit2` handlers. This
is particularly useful for code that cannot be customized, e.g. from
third-party packages.

## Usage

``` r
with_loggit(
  exp,
  logfile = get_logfile(),
  echo = get_echo(),
  log_level = get_log_level()
)
```

## Arguments

- exp:

  An `expression` to evaluate.

- logfile:

  Path of log file to write to.

- echo:

  Should the log entry (json) be echoed to `stdout` as well?

- log_level:

  The log level to use.

## Value

The result of the expression.

## Details

If `loggit2` handlers are already used in the expression, this can lead
to conditions being logged twice (in the same or different files).

## Examples

``` r
if (FALSE) { # \dontrun{
 x <- with_loggit(5L + 5L)

 with_loggit(base::message("Test log message"))

 with_loggit(base::warning("Test log message"), echo = FALSE, logfile = "my_log.log")

 x <- with_loggit({
    y <- 5L
    base::message("Test log message")
    base::warning("Test log message")
    1L + y
 })
} # }
```
