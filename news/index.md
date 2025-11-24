# Changelog

## loggit2 2.4.0

CRAN release: 2025-06-01

### New Features

- [`set_call_options()`](https://r-loggit.org/reference/set_call_options.md)
  offers new option to log condition calls or even the full call stack.
  [`get_call_options()`](https://r-loggit.org/reference/get_call_options.md)
  returns the current settings.
- All condition log handlers
  e.g. [`warning()`](https://r-loggit.org/reference/warning.md) and
  [`with_loggit()`](https://r-loggit.org/reference/with_loggit.md) now
  support call logging.
- Added [`debuginfo()`](https://r-loggit.org/reference/debuginfo.md) as
  an additional log handler for debugging purposes.

### Minor Changes

- [`loggit()`](https://r-loggit.org/reference/loggit.md) now checks the
  `...` arguments for use of reserved names, currently `log_call` and
  `timestamp`.

### Internals

- Added fallback for
  [`find_call()`](https://r-loggit.org/reference/find_call.md).

## loggit2 2.3.1

CRAN release: 2024-07-25

### Bugfixes

- [`warning()`](https://r-loggit.org/reference/warning.md) and
  [`stop()`](https://r-loggit.org/reference/stop.md) now respect
  `call. = FALSE`.

### Minor Changes

- Some small changes to increase logging speed
- `wìth_loggit()` now opens a connection to the log file at the
  beginning of the block and closes it at the end. This increases the
  speed of logging noticeably, especially for many log entries.  
  The log file will be created during logging, but will automatically be
  removed if no log entries were made.
- [`conditionMessage()`](https://rdrr.io/r/base/conditions.html) is now
  used to extract the message from conditions. This is more robust than
  `con[["message"]]` and should work for all conditions, especially also
  for `rlang` conditions.

## loggit2 2.3.0

CRAN release: 2024-06-08

### Breaking Changes

- Custom `sanitizer`s and `unsanitizer`s are no longer supported. This
  decision was made because no active user is known, and this
  functionality severely limits further development. If custom
  `sanitizer`s were previously used, they can simply be executed before
  or after [`loggit()`](https://r-loggit.org/reference/loggit.md) or
  [`read_logs()`](https://r-loggit.org/reference/read_logs.md).  
  If custom sanitizers were used to circumvent bugs, please report them,
  so they can be fixed.
- Special characters are no longer escaped by replacement, but rather by
  `"\"`.

### New Features

- Added
  [`convert_to_csv()`](https://r-loggit.org/reference/convert_to_csv.md)
  to convert log files to CSV format.
- Added [`with_loggit()`](https://r-loggit.org/reference/with_loggit.md)
  to log third-party code or to easily use different
  [`loggit()`](https://r-loggit.org/reference/loggit.md) parameters for
  a chunk of code.
- `NA`s are now stored as `null` in the JSON log, and
  [`read_logs()`](https://r-loggit.org/reference/read_logs.md) also
  restores these as `NA`. This was previously (unintentionally)
  guaranteed by replacing the `NA` with `"__NA__"`.
- [`read_logs()`](https://r-loggit.org/reference/read_logs.md) now
  allows reading the logs in reverse order using the `last_first`
  argument.
- A global log level can now be set using
  [`set_log_level()`](https://r-loggit.org/reference/set_log_level.md),
  which is used by all functions unless otherwise stated. The log levels
  are: `"DEBUG"`, `"INFO"`, `"WARN"`, `"ERROR"`, and `"NONE"`.
- Added [`set_echo()`](https://r-loggit.org/reference/set_echo.md) to
  control globally whether log messages are echoed to the console.
- All condition log handlers (e.g.,
  [`warning()`](https://r-loggit.org/reference/warning.md)) allow `NA`
  for the parameter `.loggit`. If `NA`, the log level set by
  [`set_log_level()`](https://r-loggit.org/reference/set_log_level.md)
  is used to determine if the condition should be logged. This is the
  new default behavior, but since the default log level is `"DEBUG"`,
  this should not change the behavior of existing code.
- All `set_*` functions now return the previous value of the setting.
- The default settings can now be controlled by the system environment
  variables `FILE_LOGGIT2`, `TIMESTAMP_LOGGIT2`, `ECHO_LOGGIT2` and
  `LEVEL_LOGGIT2`.

### Bugfixes

- [`read_logs()`](https://r-loggit.org/reference/read_logs.md) now
  correctly reads empty character values `""`, as in `{"key": ""}`.
  Previously, empty fields were read as `NA`. This meant that when
  [`rotate_logs()`](https://r-loggit.org/reference/rotate_logs.md) was
  used, these entries could completely disappear from the respective
  JSON object.
- [`loggit()`](https://r-loggit.org/reference/loggit.md) now does not
  unintentionally “repair” argument names of log entries. Previously,
  the names were replaced by `check.names` of
  [`data.frame()`](https://rdrr.io/r/base/data.frame.html), which could
  lead to unexpected behavior. Names that are not valid JSON keys are
  now escaped according to the JSON standard.

### Minor Changes

- [`read_logs()`](https://r-loggit.org/reference/read_logs.md) now
  returns a `data.frame` with the empty character columns “timestamp”,
  “log_lvl”, and “log_msg” instead of an empty (0x0) `data.frame` if the
  log file has no entries.
- The JSON reading functions are more tolerant of manual changes to the
  log.
- The parameter `exprs` was added to
  [`stopifnot()`](https://r-loggit.org/reference/stopifnot.md) and
  included in the documentation. This has no impact on functionality due
  to the specific way
  [`base::stopifnot()`](https://rdrr.io/r/base/stopifnot.html) is called
  internally.
- [`loggit()`](https://r-loggit.org/reference/loggit.md) now throws an
  error if there are unnamed `...` arguments. Previously, these were
  silently named by `fix.empty.names` of `data.frame`, which could lead
  to unexpected behavior.
- [`loggit()`](https://r-loggit.org/reference/loggit.md) now also checks
  the length of the `log_lvl` and `log_msg` arguments and only uses the
  first element. Previously, the log entry had been multiplied, leading
  to unintended consequences regarding `custom_log_lvl`.

### Internals

- `write_ndjson` no longer warns if the log contains unsanitized line
  breaks. This warning could only be generated by package-internal
  errors (therefore nonsensical in the CRAN package) or by a custom
  `sanitizer`, but in this case only this one character was specifically
  tested and thus provides a false sense of security.
- The package now requires compilation. This is necessary because the
  JSON parser was written in C++ for faster reading.
- `loggit2` now requires at least R 4.0.0.

## loggit2 2.2.2

CRAN release: 2024-05-03

### Breaking Changes

- Custom `sanitizer`s and `unsanitizer`s must be able to process
  character vectors. Previously, only the processing of vectors of
  length one was explicitly required.

### New Features

- [`message()`](https://r-loggit.org/reference/message.md),
  [`warning()`](https://r-loggit.org/reference/warning.md), and
  [`stop()`](https://r-loggit.org/reference/stop.md) now accept
  conditions as input like their base R equivalents.
- New [`stopifnot()`](https://r-loggit.org/reference/stopifnot.md)
  handler.
- [`set_logfile()`](https://r-loggit.org/reference/set_logfile.md) has a
  new argument `create` that allows the user to create the file if it
  does not exist.

### Bugfixes

- [`read_logs()`](https://r-loggit.org/reference/read_logs.md) processes
  entries with `": "` correctly. Previously, entries were truncated
  and/or assigned to incorrect columns.
- [`message()`](https://r-loggit.org/reference/message.md),
  [`warning()`](https://r-loggit.org/reference/warning.md), and
  [`stop()`](https://r-loggit.org/reference/stop.md) now use the same
  call in their messages and their condition objects as their base R
  equivalents and no longer give themselves as the call. For
  [`warning()`](https://r-loggit.org/reference/warning.md) and
  [`stop()`](https://r-loggit.org/reference/stop.md), there can be
  deviations in very rare cases, as the function that determines the
  call for these in base R is not provided at the R or C level, nor is
  the necessary C header.
- [`set_logfile()`](https://r-loggit.org/reference/set_logfile.md) now
  attempts to convert relative paths to absolute paths. This prevents
  the logfile from being inadvertently changed when switching (even
  temporarily) the working directory. If this unintended side effect was
  used intentionally, the same effect can be achieved by explicitly
  resetting the path.
- [`set_logfile()`](https://r-loggit.org/reference/set_logfile.md) now
  correctly outputs the randomly generated temporary file as the new
  path in its confirmation message when `NULL` is given as an argument.
- `rotate_logs(rotate_lines = 0L)` now empties the log as expected.
  Additionally, an error is thrown for negative values.
- [`rotate_logs()`](https://r-loggit.org/reference/rotate_logs.md)
  preserves the original sanitization of the log entries. Previously,
  the sanitization was lost when the log was rotated for values between
  0 and the number of log entries.
- [`read_logs()`](https://r-loggit.org/reference/read_logs.md) now
  correctly reads empty log fields as `NA_character_`. Previously, empty
  fields were read as `""` when the first entry of the field was empty.

### Minor Changes

- All `set_*` functions use
  [`message()`](https://r-loggit.org/reference/message.md) instead of
  [`print()`](https://rdrr.io/r/base/print.html) for confirmation. This
  ensures that the confirmations no longer interfere with the log via
  echo.
- [`default_ndjson_sanitizer()`](https://r-loggit.org/reference/sanitizers.md),
  which was not exported but is visible in the documentation, now
  follows the rules for sanitizers.

### Documentation

- Functions that were only for internal use (and were not exported) were
  marked as such and are no longer visible in the index.

### Fork

- The name changed from `loggit` to `loggit2`.
- The maintainership has been transferred from “Ryan Price” to “Matthias
  Ollech”.
- For news of older versions, see Ryan Price’s `loggit` package.
