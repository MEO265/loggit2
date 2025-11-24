# Internal logging function

This function is used internally by the `loggit` function to log
messages and levels. No checks are performed on the input, so it should
used with caution.

## Usage

``` r
loggit_internal(
  log_lvl,
  log_msg,
  log_call = NULL,
  echo = get_echo(),
  logfile = get_logfile(),
  call_options = get_call_options()
)
```

## Arguments

- log_lvl:

  Log level. A atomic vector of length one (usually `character`). Will
  be coerced to `character`.

- log_msg:

  Log message. A atomic vector of length one (usually `character`). Will
  be coerced to `character`.

- log_call:

  Call object to log as call leading to the log message.

- echo:

  Should the log entry (json) be echoed to `stdout` as well?

- logfile:

  A `connection`, or a character string naming the file to write to.

- call_options:

  List of options regarding logging of call objects. As set by
  [`set_call_options()`](https://r-loggit.org/reference/set_call_options.md).

## Value

Invisible `NULL`.
