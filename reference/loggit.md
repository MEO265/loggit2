# Log messages and R objects

Log messages and R objects to a [ndjson](https://github.com/ndjson) log
file.

## Usage

``` r
loggit(
  log_lvl,
  log_msg,
  ...,
  echo = get_echo(),
  custom_log_lvl = FALSE,
  logfile = get_logfile(),
  ignore_log_level = FALSE
)
```

## Arguments

- log_lvl:

  Log level. A atomic vector of length one (usually `character`). Will
  be coerced to `character`.

- log_msg:

  Log message. A atomic vector of length one (usually `character`). Will
  be coerced to `character`.

- ...:

  Named arguments, each a atomic vector of length one, you wish to log.
  Will be coerced to `character`. The names of the arguments are treated
  as column names in the log.

- echo:

  Should the log entry (json) be echoed to `stdout` as well?

- custom_log_lvl:

  Allow log levels other than "DEBUG", "INFO", "WARN", and "ERROR"?

- logfile:

  Path of log file to write to.

- ignore_log_level:

  Ignore the log level set by
  [`set_log_level()`](https://r-loggit.org/reference/set_log_level.md)?

## Value

Invisible `NULL`.

## Examples

``` r
if (FALSE) { # \dontrun{
  loggit("DEBUG", "This is a message")

  loggit("INFO", "This is a message", echo = FALSE)

  loggit("CUSTOM", "This is a message of a custom log_lvl", custom_log_lvl = TRUE)

  loggit(
   "INFO", "This is a message", but_maybe = "you want more fields?",
    sure = "why not?", like = 2, or = 10, what = "ever"
  )
} # }
```
