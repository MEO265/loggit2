# Write ndJSON-formatted log file

Write ndJSON-formatted log file

## Usage

``` r
write_ndjson(
  log_df,
  logfile = get_logfile(),
  echo = get_echo(),
  overwrite = FALSE
)
```

## Arguments

- log_df:

  A `data.frame`. Entries are converted to `ndjson`, with the columns as
  the fields.

- logfile:

  A `connection`, or a character string naming the file to write to.

- echo:

  Should the log entry (json) be echoed to `stdout` as well?

- overwrite:

  Overwrite previous log file?

## Value

Invisible `NULL`.
