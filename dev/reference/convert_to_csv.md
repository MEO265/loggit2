# Write log to csv file

Creates a csv file from the ndjson log file.

## Usage

``` r
convert_to_csv(
  file,
  logfile = get_logfile(),
  unsanitize = FALSE,
  last_first = FALSE,
  ...
)
```

## Arguments

- file:

  Path to write csv file to.

- logfile:

  Path to log file to read from.

- unsanitize:

  Should escaped special characters be unescaped?

- last_first:

  Should the last log entry be the first row of the data frame?

- ...:

  Additional arguments to pass to
  [`utils::write.csv()`](https://rdrr.io/r/utils/write.table.html).

## Value

Invisible `NULL`.

## Details

Unescaping of special characters can lead to unexpected results. Use
`unsanitize = TRUE` with caution.

## Examples

``` r
if (FALSE) { # \dontrun{
  convert_to_csv("my_log.csv")

  convert_to_csv("my_log.csv", logfile = "my_log.log", last_first = TRUE)
} # }
```
