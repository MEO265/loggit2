# Debug Log Handler

This function works like base R's
[`warning`](https://rdrr.io/r/base/warning.html) , but is silent,
includes logging of the exception message via
[`loggit()`](https://r-loggit.org/reference/loggit.md) and does not
allow conditions as input.

## Usage

``` r
debuginfo(..., call. = TRUE, .loggit = NA, echo = get_echo())
```

## Arguments

- ...:

  zero or more objects which can be coerced to character (and which are
  pasted together with no separator) or a single condition object.

- call.:

  logical, indicating if the call should become part of the warning
  message.

- .loggit:

  Should the condition message be added to the log? If `NA` the log
  level set by
  [`set_log_level()`](https://r-loggit.org/reference/set_log_level.md)
  is used to determine if the condition should be logged.

- echo:

  Should the log entry (json) be echoed to `stdout` as well?

## Value

No return value.

## Details

This function is more than just a wrapper around
[`loggit()`](https://r-loggit.org/reference/loggit.md) with a log level
of "DEBUG". It has the ability to track the call stack and log it if
`call.` is set to `TRUE` and to automatically translate the input into a
message using [`.makeMessage()`](https://rdrr.io/r/base/message.html),
like [`warning()`](https://r-loggit.org/reference/warning.md) does.

## See also

Other handlers:
[`message()`](https://r-loggit.org/reference/message.md),
[`stop()`](https://r-loggit.org/reference/stop.md),
[`stopifnot()`](https://r-loggit.org/reference/stopifnot.md),
[`warning()`](https://r-loggit.org/reference/warning.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  debuginfo("This is a completely false condition")

  debuginfo("This is a completely false condition", echo = FALSE)
} # }
```
