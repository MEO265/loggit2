# Warning Log Handler

This function is identical to base R's
[`warning`](https://rdrr.io/r/base/warning.html), but it includes
logging of the exception message via
[`loggit()`](https://r-loggit.org/reference/loggit.md).

## Usage

``` r
warning(
  ...,
  call. = TRUE,
  immediate. = FALSE,
  noBreaks. = FALSE,
  domain = NULL,
  .loggit = NA,
  echo = get_echo()
)
```

## Arguments

- ...:

  zero or more objects which can be coerced to character (and which are
  pasted together with no separator) or a single condition object.

- call.:

  logical, indicating if the call should become part of the warning
  message.

- immediate.:

  logical, indicating if the call should be output immediately, even if
  [`getOption`](https://rdrr.io/r/base/options.html)`("warn") <= 0`.

- noBreaks.:

  logical, indicating as far as possible the message should be output as
  a single line when `options(warn = 1)`.

- domain:

  see [`gettext`](https://rdrr.io/r/base/gettext.html). If `NA`,
  messages will not be translated, see also the note in
  [`stop`](https://rdrr.io/r/base/stop.html).

- .loggit:

  Should the condition message be added to the log? If `NA` the log
  level set by
  [`set_log_level()`](https://r-loggit.org/reference/set_log_level.md)
  is used to determine if the condition should be logged.

- echo:

  Should the log entry (json) be echoed to `stdout` as well?

## Value

The warning message as
[`character`](https://rdrr.io/r/base/character.html) string, invisibly.

## See also

Other handlers:
[`debuginfo()`](https://r-loggit.org/reference/debuginfo.md),
[`message()`](https://r-loggit.org/reference/message.md),
[`stop()`](https://r-loggit.org/reference/stop.md),
[`stopifnot()`](https://r-loggit.org/reference/stopifnot.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  warning("You may want to review that math")

  warning("You may want to review that math", immediate = FALSE, echo = FALSE)
} # }
```
