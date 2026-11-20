# Set up the logfile for the application

This function retrieves the logfile path from the environment variable
"FILE_LOGGIT2". If the environment variable is set, it will be used as
the logfile path. If the environment variable is not set, the logfile
path will be set to the default value.

## Usage

``` r
setup_logfile()
```

## Value

Invisible the previous log file path.
