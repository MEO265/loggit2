# loggit2 2.2.2

## Breaking changes
* Custom sanitizers and unsanitizers must be able to process character vectors. 
  Previously, only the processing of vectors of length one was explicitly required.

## New features
* `message()`, `warning()`, and `stop()` now accept conditions as input like their base R equivalents.
* New `stopifnot()` handler. 
* `set_logfile()` has a new argument `create` that allows the user to create the file if it does not exist.

## Bugfixes 
* `read_logs()` processes entries with `": "` correctly. 
  Previously, entries were truncated and/or assigned to incorrect columns.
* `message()`, `warning()`, and `stop()` now use the same call in their messages and 
  their condition objects as their base R equivalents and no longer give themselves as the call.  
  For `warning()` and `stop()`, there can be deviations in very rare cases, as the function that 
  determines the call for these in base R is not provided at the R or C level, nor the necessary C header.
* `set_logfile()` now attempts to convert relative paths to absolute paths.  
  This prevents the logfile from being inadvertently changed when switching
  (even temporarily) the Working Directory. If this unintended side effect was used
  intentionally, the same effect can be achieved by explicitly resetting the path.
* `set_logfile()` now correctly outputs the randomly generated temporary file as 
  the new path in its confirmation message, when `NULL` is given as an argument.
* `rotate_logs(rotate_lines = 0L)` now empties the log as expected. 
  Additionally, an error is thrown for negative values.

## Minor changes
* All `set_*` functions use `message` instead of `print` for confirmation.
  This ensures that the confirmations no longer interfere with the log via echo.
* `default_ndjson_sanitizer()`, which was not exported but is visible in the documentation, 
  now follows the rules for sanitizer

## Documentation
* Functions that were only for internal use (and were not exported) were marked as such
  and are no longer visible in the index

## Fork
* The name changed from `loggit` to `loggit2`
* The maintainership has been transferred from "Ryan Price" to "Matthias Ollech"
* For news of older versions, see Ryan Price's `loggit` package
