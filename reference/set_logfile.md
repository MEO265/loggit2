# Set Log File

Set the log file that loggit will write to by default.

## Usage

``` r
set_logfile(logfile = NULL, confirm = TRUE, create = TRUE)
```

## Arguments

- logfile:

  Absolut or relative path to log file. An attempt is made to convert
  the path into a canonical absolute form using
  [`normalizePath()`](https://rdrr.io/r/base/normalizePath.html). If
  `NULL` will set to `<tmpdir>/loggit.log`.

- confirm:

  Print confirmation of log file setting?

- create:

  Create the log file if it does not exist?

## Value

Invisible the previous log file path.

## Details

No logs outside of a temporary directory will be written until this is
set explicitly, as per CRAN policy. Therefore, the default behavior is
to create a file named `loggit.log` in your system's temporary
directory.

## Examples

``` r
if (FALSE) { # \dontrun{
  set_logfile("path/to/logfile.log")
} # }
```
