# Set Timestamp Format

Set timestamp format for use in output logs.

## Usage

``` r
set_timestamp_format(ts_format = "%Y-%m-%dT%H:%M:%S%z", confirm = TRUE)
```

## Arguments

- ts_format:

  ISO date format.

- confirm:

  Print confirmation message of timestamp format?

## Value

Invisible the previous timestamp format.

## Details

This function performs no time format validations, but will echo out the
current time in the provided format for manual validation.

This function provides no means of setting a timezone, and instead
relies on the host system's time configuration to provide this. This is
to enforce consistency across software running on the host.

## Examples

``` r
if (FALSE) { # \dontrun{
  set_timestamp_format("%Y-%m-%d %H:%M:%S")
} # }
```
