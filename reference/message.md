# Message Log Handler

This function is identical to base R's
[`message`](https://rdrr.io/r/base/message.html), but it includes
logging of the exception message via
[`loggit()`](https://r-loggit.org/reference/loggit.md).

## Usage

``` r
message(..., domain = NULL, appendLF = TRUE, .loggit = NA, echo = get_echo())
```

## Arguments

- ...:

  zero or more objects which can be coerced to character (and which are
  pasted together with no separator) or (for `message` only) a single
  condition object.

- domain:

  see [`gettext`](https://rdrr.io/r/base/gettext.html). If `NA`,
  messages will not be translated, see also the note in
  [`stop`](https://rdrr.io/r/base/stop.html).

- appendLF:

  logical: should messages given as a character string have a newline
  appended?

- .loggit:

  Should the condition message be added to the log? If `NA` the log
  level set by
  [`set_log_level()`](https://r-loggit.org/reference/set_log_level.md)
  is used to determine if the condition should be logged.

- echo:

  Should the log entry (json) be echoed to `stdout` as well?

## Value

Invisible `NULL`.

## See also

Other handlers:
[`debuginfo()`](https://r-loggit.org/reference/debuginfo.md),
[`stop()`](https://r-loggit.org/reference/stop.md),
[`stopifnot()`](https://r-loggit.org/reference/stopifnot.md),
[`warning()`](https://r-loggit.org/reference/warning.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  message("Don't say such silly things!")

  message("Don't say such silly things!", appendLF = FALSE, echo = FALSE)
} # }
```
