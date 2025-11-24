# Read ndJSON-formatted log file

Read ndJSON-formatted log file

## Usage

``` r
read_ndjson(logfile, unsanitize = TRUE, last_first = FALSE)
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
