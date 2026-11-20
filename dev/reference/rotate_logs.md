# Rotate log file

Truncates the log file to the line count provided as `rotate_lines`.

## Usage

``` r
rotate_logs(rotate_lines = 100000L, logfile = get_logfile())
```

## Arguments

- rotate_lines:

  The number of log entries to keep in the logfile.

- logfile:

  Log file to truncate.

## Value

Invisible `NULL`.

## Examples

``` r
if (FALSE) { # \dontrun{
  rotate_logs()

  rotate_logs(rotate_lines = 0L)

  rotate_logs(rotate_lines = 1000L, logfile = "my_log.log")
} # }
```
