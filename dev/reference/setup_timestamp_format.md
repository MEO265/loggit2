# Set up the timestamp format for the application

This function retrieves the timestamp format from the environment
variable "TIMESTAMP_LOGGIT2". If the environment variable is set, it
will be used as the timestamp format. If the environment variable is not
set, the timestamp format will be set to the default value.

## Usage

``` r
setup_timestamp_format()
```

## Value

Invisible the previous timestamp format.
