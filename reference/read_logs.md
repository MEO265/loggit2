# Get log as `data.frame`

Returns a `data.frame` containing all the logs in the provided `ndjson`
log file.

## Usage

``` r
read_logs(logfile = get_logfile(), unsanitize = TRUE, last_first = FALSE)
```

## Arguments

- logfile:

  Path to log file to read from.

- unsanitize:

  Should escaped special characters be unescaped?

- last_first:

  Should the last log entry be the first row of the data frame?

## Value

A `data.frame`, with the columns as the fields in the log file.

## Details

`read_logs()` returns a `data.frame` with the empty character columns
"timestamp", "log_lvl" and "log_msg" if the log file has no entries.

## Examples

``` r
if (FALSE) { # \dontrun{
  read_logs()

  read_logs(last_first = TRUE)
} # }
```
