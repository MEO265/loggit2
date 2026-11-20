# Set up the echo for the application

This function retrieves the echo setting from the environment variable
"ECHO_LOGGIT2". If the environment variable is set, it will be used as
the echo setting. If the environment variable is not set, the echo
setting will be set to the default value.

## Usage

``` r
setup_echo()
```

## Value

Invisible the previous echo setting.

## Details

The environment variable must be set to one of: "TRUE" or "FALSE".
