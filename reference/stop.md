# Stop Log Handler

This function is identical to base R's
[`stop`](https://rdrr.io/r/base/stop.html), but it includes logging of
the exception message via
[`loggit()`](https://r-loggit.org/reference/loggit.md).

## Usage

``` r
stop(..., call. = TRUE, domain = NULL, .loggit = NA, echo = get_echo())
```

## Arguments

- ...:

  zero or more objects which can be coerced to character (and which are
  pasted together with no separator) or a single condition object.

- call.:

  logical, indicating if the call should become part of the error
  message.

- domain:

  see [`gettext`](https://rdrr.io/r/base/gettext.html). If `NA`,
  messages will not be translated.

- .loggit:

  Should the condition message be added to the log? If `NA` the log
  level set by
  [`set_log_level()`](https://r-loggit.org/reference/set_log_level.md)
  is used to determine if the condition should be logged.

- echo:

  Should the log entry (json) be echoed to `stdout` as well?

## Value

No return value.

## See also

Other handlers:
[`debuginfo()`](https://r-loggit.org/reference/debuginfo.md),
[`message()`](https://r-loggit.org/reference/message.md),
[`stopifnot()`](https://r-loggit.org/reference/stopifnot.md),
[`warning()`](https://r-loggit.org/reference/warning.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  stop("This is a completely false condition")

  stop("This is a completely false condition", echo = FALSE)
} # }
```
