# Set Log Level

Set Log Level

## Usage

``` r
set_log_level(level = "DEBUG", confirm = TRUE)
```

## Arguments

- level:

  Log level to set, as a string or integer.

- confirm:

  Print confirmation message of log level?

## Value

Invisible the previous log level.

## Details

Log levels are as follows: DEBUG: 4 INFO: 3 WARNING: 2 ERROR: 1 NONE: 0

## Examples

``` r
if (FALSE) { # \dontrun{
 set_log_level("DEBUG")
 set_log_level("INFO")

 set_log_level(4)
 set_log_level(3)
} # }
```
