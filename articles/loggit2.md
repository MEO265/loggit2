# Getting Started

`loggit2` is an easy-to-use, yet powerful,
[`ndjson`](https://github.com/ndjson) logger. It is very fast, has zero
external dependencies, and can be as straightforward or as integral as
you want to make it.

## Preparation

No preparations are needed to use `loggit2`. However, it is recommended
to explicitly set a log file using
`loggit2::set_logfile("path/to/your/file")`, as `loggit2` defaults to
creating a file in your temporary directory.[¹](#fn1)

In order to use the full potential of `loggit2`, it is advisable to take
a look at the [further
configurations](https://r-loggit.org/articles/further_configurations.md)
after reading this vignette.

## Logging

There are three ways to populate the log in `loggit2`. First, through
wrapper functions of the base `R` condition handler, second, via the
[`loggit()`](https://r-loggit.org/reference/loggit.md) log function, and
third, by logging (external) expressions using
[`with_loggit()`](https://r-loggit.org/reference/with_loggit.md).

Each function of these three methods has the parameter `echo`, which
determines whether the log entries should also be echoed to `stdout`.

### Condition Log Handling

`loggit2` provides a set of wrappings for base R’s
[`message()`](https://r-loggit.org/reference/message.md),
[`warning()`](https://r-loggit.org/reference/warning.md),
[`stop()`](https://r-loggit.org/reference/stop.md) and
[`stopifnot()`](https://r-loggit.org/reference/stopifnot.md) functions
that maintain identical functionality[²](#fn2), except the additional
logging. Thus, it is sufficient to import the `loggit2` namespace, for
example by using
[`library("loggit2")`](https://github.com/MEO265/loggit2), or by
prefixing `loggit2::` at the desired locations.

``` r
base::message("This is another message")
#> This is another message
loggit2::message("This is a message")
#> {"timestamp": "2025-11-24T02:49:09+0000", "log_lvl": "INFO", "log_msg": "This is a message\n"}
#> This is a message

base::warning("This is another warning")
#> Warning: This is another warning
loggit2::warning("This is a warning")
#> {"timestamp": "2025-11-24T02:49:09+0000", "log_lvl": "WARN", "log_msg": "This is a warning"}
#> Warning: This is a warning

base::stop("This is another error")
#> Error: This is another error
loggit2::stop("This is an error")
#> {"timestamp": "2025-11-24T02:49:09+0000", "log_lvl": "ERROR", "log_msg": "This is an error"}
#> Error: This is an error

base::stopifnot("This is another condition" = FALSE)
#> Error: This is another condition
loggit2::stopifnot("This is another condition" = FALSE)
#> {"timestamp": "2025-11-24T02:49:09+0000", "log_lvl": "ERROR", "log_msg": "This is another condition"}
#> Error: This is another condition
```

Besides the `echo` parameter, the functions have an additional parameter
`.loggit`, which allows to deactivate the logging such that the function
behaves exactly like the base `R` equivalents.

``` r
loggit2::warning("This is a alternative warning", echo = FALSE)
#> Warning: This is a alternative warning

loggit2::warning("This is not part of the log", .loggit = FALSE)
#> Warning: This is not part of the log
```

Click here to see the generated log

    #>                  timestamp log_lvl                       log_msg
    #> 1 2025-11-24T02:49:09+0000    INFO           This is a message\n
    #> 2 2025-11-24T02:49:09+0000    WARN             This is a warning
    #> 3 2025-11-24T02:49:09+0000   ERROR              This is an error
    #> 4 2025-11-24T02:49:09+0000   ERROR     This is another condition
    #> 5 2025-11-24T02:49:09+0000    WARN This is a alternative warning

### Explicit Log Function

`loggit2` allows direct access to the core logging function
[`loggit()`](https://r-loggit.org/reference/loggit.md). This enables
setting the log level directly during the call and creating arbitrary
fields in the log.

This function does not trigger any conditions; it only populates the
log.

``` r
loggit2::loggit("INFO", "This is a message", ID = 1L, boole = TRUE)
#> {"timestamp": "2025-11-24T02:49:10+0000", "log_lvl": "INFO", "log_msg": "This is a message", "ID": "1", "boole": "TRUE"}

loggit2::loggit("WARN", "This is a alternative warning", echo = FALSE)

loggit2::loggit("DEBUG", "This is a message", Why = "Because", echo = FALSE)
```

To allow log levels other than “DEBUG”, “INFO”, “WARN” or “ERROR” the
`custom_log_lvl` parameter must be set.

``` r
loggit2::loggit("CRITICAL", "Critical error")
#> Error in loggit2::loggit("CRITICAL", "Critical error"): Nonstandard log_lvl ('CRITICAL').
#> Should be one of DEBUG, INFO, WARN, or ERROR. Please check if you made a typo.
#> If you insist on passing a custom level, please set 'custom_log_lvl = TRUE' in the call to 'loggit()'.

loggit2::loggit("CRITICAL", "Critical error 2", custom_log_lvl = TRUE)
#> {"timestamp": "2025-11-24T02:49:10+0000", "log_lvl": "CRITICAL", "log_msg": "Critical error 2"}
```

Click here to see the generated log

    #>                  timestamp  log_lvl                       log_msg   ID boole     Why
    #> 1 2025-11-24T02:49:10+0000     INFO             This is a message    1  TRUE    <NA>
    #> 2 2025-11-24T02:49:10+0000     WARN This is a alternative warning <NA>  <NA>    <NA>
    #> 3 2025-11-24T02:49:10+0000    DEBUG             This is a message <NA>  <NA> Because
    #> 4 2025-11-24T02:49:10+0000 CRITICAL              Critical error 2 <NA>  <NA>    <NA>

### Log Expressions

One will repeatedly encounter situations where conditions need to be
logged from code without wanting to or being able to modify it (e.g.,
when dealing with functions from external packages). In this case,
[`with_loggit()`](https://r-loggit.org/reference/with_loggit.md) comes
into play. This function allows logging conditions from arbitrary
expressions without restricting functionality[³](#fn3) or needing to
modify the code.

``` r
fun_a <- function(x) {
  base::warning("This is a warning")
  base::message("This is a message")
  base::stopifnot("This is true" = 3L == 1L + 2L, "This is not TRUE" = FALSE)
}

fun_b <- function(x) {
  base::warning("This is a second warning")
  5L + 5L
}
```

``` r
x <- loggit2::with_loggit(fun_b())
#> {"timestamp": "2025-11-24T02:49:10+0000", "log_lvl": "WARN", "log_msg": "This is a second warning"}
#> Warning in fun_b(): This is a second warning
print(x)
#> [1] 10
```

``` r
loggit2::with_loggit({
  x <- fun_b()
  fun_a()
}, echo = FALSE)
#> Warning in fun_b(): This is a second warning
#> Warning in fun_a(): This is a warning
#> This is a message
#> Error in fun_a(): This is not TRUE
```

Additionally,
[`with_loggit()`](https://r-loggit.org/reference/with_loggit.md) allows
alternative settings (logfile, echo, etc.) to be used for a specific
section of code.

Click here to see the generated log

    #>                  timestamp log_lvl                  log_msg
    #> 1 2025-11-24T02:49:10+0000    WARN This is a second warning
    #> 2 2025-11-24T02:49:10+0000    WARN This is a second warning
    #> 3 2025-11-24T02:49:10+0000    WARN        This is a warning
    #> 4 2025-11-24T02:49:10+0000    INFO      This is a message\n
    #> 5 2025-11-24T02:49:10+0000   ERROR         This is not TRUE

## Post-Processing

A log is of little use without the ability to access and modify it. Here
are a few possibilities.

### Accessing the Log

As seen above, the log can be queried as a `data.frame` using
[`read_logs()`](https://r-loggit.org/reference/read_logs.md).

``` r
loggit2::read_logs()
#>                  timestamp log_lvl                  log_msg
#> 1 2025-11-24T02:49:10+0000    WARN This is a second warning
#> 2 2025-11-24T02:49:10+0000    WARN This is a second warning
#> 3 2025-11-24T02:49:10+0000    WARN        This is a warning
#> 4 2025-11-24T02:49:10+0000    INFO      This is a message\n
#> 5 2025-11-24T02:49:10+0000   ERROR         This is not TRUE
```

Alternatively, the log can also be saved as a CSV file using
[`convert_to_csv()`](https://r-loggit.org/reference/convert_to_csv.md).

``` r
loggit2::convert_to_csv("path/to/your/file.csv")
```

### Rotating the Log

To maintain a clear log even in long-running sessions (e.g., in a Shiny
app hosted on a server), the log can be restricted to the last `n`
entries using `rotate_logs(n)`.

``` r
loggit2::rotate_logs(2L)
```

Click here to see the generated log

    #>                  timestamp log_lvl             log_msg
    #> 1 2025-11-24T02:49:10+0000    INFO This is a message\n
    #> 2 2025-11-24T02:49:10+0000   ERROR    This is not TRUE

``` r
loggit2::rotate_logs(0L)
```

Click here to see the generated log

    #> [1] timestamp log_lvl   log_msg  
    #> <0 rows> (or 0-length row.names)

------------------------------------------------------------------------

1.  This is done to [CRAN Repository
    Policy](https://cran.r-project.org/web/packages/policies.html):

    > Packages should not write in the user’s home filespace (including
    > clipboards), nor anywhere else on the file system apart from the R
    > session’s temporary directory `[...]`.

2.  This means in particular that `tryCatch` and similar functions can
    be used as usual.

3.  Just like with the direct use of the wrappers for condition
    handlers, `tryCatch` and similar mechanisms can be used as usual.
