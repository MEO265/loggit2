# Internal logging function for custom log fields

This function is used internally by the `loggit` function to log
messages, levels, and custom fields. Similar to `loggit_internal`, but
with additional custom fields, and checks on those fields.

## Usage

``` r
loggit_dots(log_lvl, log_msg, ..., echo, logfile = get_logfile())
```

## Arguments

- log_lvl:

  Log level. A atomic vector of length one (usually `character`). Will
  be coerced to `character`.

- log_msg:

  Log message. A atomic vector of length one (usually `character`). Will
  be coerced to `character`.

- ...:

  Named arguments, each a atomic vector of length one, you wish to log.
  Will be coerced to `character`. The names of the arguments are treated
  as column names in the log.

- echo:

  Should the log entry (json) be echoed to `stdout` as well?

- logfile:

  A `connection`, or a character string naming the file to write to.

## Value

Invisible `NULL`.
