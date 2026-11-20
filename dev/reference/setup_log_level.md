# Set up the log level for the application

This function retrieves the log level from the environment variable
"LEVEL_LOGGIT2". If the environment variable is set, it will be used as
the log level. If the environment variable is not set, the log level
will be set to the default value.

## Usage

``` r
setup_log_level()
```

## Value

Invisible the previous log level.

## Details

The environment variable must be set to one of: "DEBUG", "INFO", "WARN",
"ERROR" or "NONE".
