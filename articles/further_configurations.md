# Further Configurations

`loggit2` can be used immediately and fully without configuration after
installation. However, to fully utilize the potential of `loggit2`, some
configurations can be made.

## Configuration System

`loggit2` uses a three-tier configuration system:

1.  Meta/System-wide Configuration
2.  Global/Session-wide[¹](#fn1) Configuration
3.  Local/Function-specific Configuration

The first tier is the Meta or System-wide Configuration. It is defined
by environment variables that are read by `loggit2` when the package is
loaded. These settings then serve as default values for the session-wide
configuration.

The second tier is the Global or Session-wide Configuration. It is
defined by the `set_*()` functions of `loggit2`.

The third tier is the Local or Function-specific Configuration,
implemented through the arguments of the functions. For a quick overview
of the functions, refer to the [Getting Started
Vignette](https://r-loggit.org/articles/loggit2.md).

Each time a function of `loggit2` is called, the settings from the three
tiers are combined. A higher tier/specificity configuration always takes
precedence over a lower tier/specificity configuration.

## Configuration Options

The configuration options of `loggit2` are described below. For details,
refer to the function documentation.

### Log file

The log file can be set either via the environment variable
`FILE_LOGGIT2`, the function `set_log_file()`, or the `logfile` argument
of the logging functions
[`loggit()`](https://r-loggit.org/reference/loggit.md) and
[`with_loggit()`](https://r-loggit.org/reference/with_loggit.md). The
wrappers of the base R condition handler always use the session-wide
configuration.

``` r
old_log <- loggit2::set_logfile(logfile = "logfile.log")
#> Log file set to /tmp/Rtmp5eArLr/logfile.log
loggit2::loggit(
  log_lvl = "DEBUG",
  log_msg = "This message will be logged to `logfile.log`."
)
#> {"timestamp": "2025-12-16T17:57:31+0000", "log_lvl": "DEBUG", "log_msg": "This message will be logged to `logfile.log`."}


loggit2::loggit(
  log_lvl = "DEBUG",
  log_msg = "This message will be logged to `otherlogfile.log`.",
  logfile = "otherlogfile.log"
)
#> {"timestamp": "2025-12-16T17:57:31+0000", "log_lvl": "DEBUG", "log_msg": "This message will be logged to `otherlogfile.log`."}


loggit2::with_loggit(logfile = "logfile2.log", {
  base::message("This message will be logged to `logfile2.log`.")
})
#> {"timestamp": "2025-12-16T17:57:31+0000", "log_lvl": "INFO", "log_msg": "This message will be logged to `logfile2.log`.\n"}
#> This message will be logged to `logfile2.log`.

loggit2::set_logfile(old_log)
#> Log file set to /tmp/Rtmp5eArLr/loggit.log
```

### Log level

The log level can be set either via the environment variable
`LEVEL_LOGGIT2` or the function
[`set_log_level()`](https://r-loggit.org/reference/set_log_level.md).
The `.loggit` argument can also be passed to the wrappers of the base R
condition handler to enforce logging (`TRUE`) or suppress it (`FALSE`).
The logging function
[`loggit()`](https://r-loggit.org/reference/loggit.md) can enforce
logging through the `ignore_log_level` argument.
[`with_loggit()`](https://r-loggit.org/reference/with_loggit.md) allows
setting a log level for the code block being executed.

``` r
old_log_lvl <- loggit2::set_log_level("INFO")
#> Log level set to 3 (INFO)
loggit2::message("This message will be logged, since the log level is INFO.")
#> {"timestamp": "2025-12-16T17:57:31+0000", "log_lvl": "INFO", "log_msg": "This message will be logged, since the log level is INFO.\n"}
#> This message will be logged, since the log level is INFO.
loggit2::loggit(
  log_lvl = "DEBUG",
  log_msg = "This message will not be logged, since the log level is INFO."
)
loggit2::loggit(
  log_lvl = "DEBUG", "This message will be logged because the log level is ignored.",
  ignore_log_level = TRUE
)
#> {"timestamp": "2025-12-16T17:57:31+0000", "log_lvl": "DEBUG", "log_msg": "This message will be logged because the log level is ignored."}
loggit2::warning(
  "This warning message will not be logged, since .loggit = FALSE.",
  .loggit = FALSE
)
#> Warning: This warning message will not be logged, since .loggit = FALSE.

loggit2::set_log_level("ERROR")
#> Log level set to 1 (ERROR)
loggit2::warning("This warning will not be logged, since the log level is set to ERROR.")
#> Warning: This warning will not be logged, since the log level is set to ERROR.
loggit2::message("This message will be logged, since .loggit = TRUE.", .loggit = TRUE)
#> {"timestamp": "2025-12-16T17:57:31+0000", "log_lvl": "INFO", "log_msg": "This message will be logged, since .loggit = TRUE.\n"}
#> This message will be logged, since .loggit = TRUE.
loggit2::stop("This error message will be logged because the log level is set to ERROR.")
#> {"timestamp": "2025-12-16T17:57:31+0000", "log_lvl": "ERROR", "log_msg": "This error message will be logged because the log level is set to ERROR."}
#> Error: This error message will be logged because the log level is set to ERROR.

loggit2::with_loggit(log_level = "DEBUG", {
  base::message("This message will be logged because the log level is set to DEBUG.")
})
#> {"timestamp": "2025-12-16T17:57:31+0000", "log_lvl": "INFO", "log_msg": "This message will be logged because the log level is set to DEBUG.\n"}
#> This message will be logged because the log level is set to DEBUG.

loggit2::set_log_level(old_log_lvl)
#> Log level set to 4 (DEBUG)
```

### Echo

Whether log messages should also be output to `stdout` can be controlled
via the environment variable `ECHO_LOGGIT2` or the function
[`set_echo()`](https://r-loggit.org/reference/set_echo.md).
Additionally, all logging functions and wrappers of the base R condition
handler allow direct control via the `echo` argument.

``` r
old_echo <- loggit2::set_echo(FALSE)
#> Echo set to FALSE
loggit2::message("This message will not be logged, but it will be output to the console.")
#> This message will not be logged, but it will be output to the console.
loggit2::message("This message will be logged and output to the console.", echo = TRUE)
#> {"timestamp": "2025-12-16T17:57:31+0000", "log_lvl": "INFO", "log_msg": "This message will be logged and output to the console.\n"}
#> This message will be logged and output to the console.

loggit2::set_echo(TRUE, confirm = FALSE)
loggit2::message("This message will be logged and output to the console.")
#> {"timestamp": "2025-12-16T17:57:31+0000", "log_lvl": "INFO", "log_msg": "This message will be logged and output to the console.\n"}
#> This message will be logged and output to the console.
loggit2::message("This message will be logged, but it will not be echoed.", echo = FALSE)
#> This message will be logged, but it will not be echoed.

loggit2::with_loggit(echo = FALSE, {
  base::message("This message will be logged, but it will not be output to the console.")
})
#> This message will be logged, but it will not be output to the console.

loggit2::set_echo(old_echo)
#> Echo set to TRUE
```

### Timestamp format

The format of the timestamp can be controlled via the environment
variable `TIMESTAMP_LOGGIT2` or the function
[`set_timestamp_format()`](https://r-loggit.org/reference/set_timestamp_format.md).

``` r
old_ts <- loggit2::set_timestamp_format("%H:%M:%S")
#> Timestamp format set to %H:%M:%S.
#> Current time in this format: 17:57:31
loggit2::message("This message will be logged with a timestamp in the format HH:MM:SS.")
#> {"timestamp": "17:57:31", "log_lvl": "INFO", "log_msg": "This message will be logged with a timestamp in the format HH:MM:SS.\n"}
#> This message will be logged with a timestamp in the format HH:MM:SS.

loggit2::set_timestamp_format(old_ts)
#> Timestamp format set to %Y-%m-%dT%H:%M:%S%z.
#> Current time in this format: 2025-12-16T17:57:31+0000
```

## Temporary Configuration

Depending on the use case, it may be useful to change temporary
configurations, e.g., to log to a different file in a specific code
block or to log a particular part of the code with more details (higher
log level).

One way is to manually set and reset the configurations (e.g., by using
[`on.exit()`](https://rdrr.io/r/base/on.exit.html)), but this is
cumbersome and error-prone.

An alternative is to use
[`with_loggit()`](https://r-loggit.org/reference/with_loggit.md). As
mentioned above, almost all configurations can be adjusted directly in
[`with_loggit()`](https://r-loggit.org/reference/with_loggit.md).

------------------------------------------------------------------------

1.  Note: “Session-wide” means that (unless locally configured
    otherwise) calls to `loggit2` functions in other packages will use
    the same settings. Consider this when using `loggit2` in a package
    that will be used elsewhere.
