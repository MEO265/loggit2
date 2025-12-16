# Why the Fork?

Ideally, I would have preferred to further develop
[loggit](https://github.com/ryapric/loggit), as I consider the concept
highly commendable and worthy of recognition. Unfortunately, this was
not possible because the maintainer was unresponsive to messages or pull
requests at the time of the fork (the last release was over three years
ago). Additionally, CRAN’s rules do not permit the takeover of the
package without the maintainer’s consent as long as the package passes
the checks.

Therefore, I ultimately decided to create a fork
([loggit2](https://github.com/MEO265/loggit2)) to address some
fundamental issues and implement necessary improvements. In the
following, I will discuss the most pressing points.

## Call of conditions

In [loggit](https://github.com/ryapric/loggit), all “condition log
handlers” (`loggit::message()`, `loggit::warning()`, `loggit::stop()`)
presented themselves as the call of the condition. This, combined with
the fact that [loggit](https://github.com/ryapric/loggit) does not allow
passing a condition to the “condition log handlers” (e.g., in
[`tryCatch()`](https://rdrr.io/r/base/conditions.html)), made it
significantly more difficult to trace the origin of a condition.

``` r
loggit::message("This is a message")
#> {"timestamp": "2022-04-12T10:55:02-0500", "log_lvl": "INFO", "log_msg": "This is a message"}
#> This is a message
loggit::warning("This is a warning")
#> {"timestamp": "2022-04-12T10:55:02-0500", "log_lvl": "WARN", "log_msg": "This is a warning"}
#> Warning in loggit::warning("This is a warning"): This is a warning
loggit::stop("This is an error")
#> {"timestamp": "2020-05-31T20:59:33-0500", "log_lvl": "ERROR", "log_msg": "This is an error"}
#> Error in loggit::stop("This is an error"): This is an error
```

In [loggit2](https://github.com/MEO265/loggit2), each condition handler
shows the same call as its base equivalent.

``` r
base::message("This is another message")
#> This is another message
loggit2::message("This is another message")
#> {"timestamp": "2025-12-16T18:13:12+0000", "log_lvl": "INFO", "log_msg": "This is another message\n"}
#> This is another message

base::warning("This is another warning")
#> Warning: This is another warning
loggit2::warning("This is another warning")
#> {"timestamp": "2025-12-16T18:13:12+0000", "log_lvl": "WARN", "log_msg": "This is another warning"}
#> Warning: This is another warning

base::stop("This is another error")
#> Error: This is another error
loggit2::stop("This is another error")
#> {"timestamp": "2025-12-16T18:13:12+0000", "log_lvl": "ERROR", "log_msg": "This is another error"}
#> Error: This is another error
```

For further information and comparisons look
[here](#further-comparisons).

## Missing `stopifnot()`

In [loggit](https://github.com/ryapric/loggit), there are no “condition
log handlers” (i.e., functions that work like their base equivalents but
also write to the log) for
[`base::stopifnot()`](https://rdrr.io/r/base/stopifnot.html). This makes
the migration of existing code (without logs) unnecessarily complicated.

In `loggit2`, this has been added:

``` r
base::stopifnot("TRUE is not true" = TRUE, "This is an error" = 3L < 1L, "This is another error" = FALSE)
#> Error: This is an error
loggit2::stopifnot("TRUE is not true" = TRUE, "This is an error" = 3L < 1L, "This is another error" = FALSE)
#> {"timestamp": "2025-12-16T18:13:12+0000", "log_lvl": "ERROR", "log_msg": "This is an error"}
#> Error: This is an error
```

## Log entries containing `:`

In [loggit](https://github.com/ryapric/loggit), log entries containing
`:` are not correctly parsed by `loggit::read_logs()`. In the best case,
the log messages are truncated after the `:`. See also
[here](https://github.com/ryapric/loggit/issues/26). This bug is fixed
in `loggit2`.

## Clearing the log

In [loggit](https://github.com/ryapric/loggit), clearing the log with
`loggit::rotate_logs(0L)` results in the log being unreadable by
`loggit::read_logs()`, even with new entries. See also
[here](https://github.com/ryapric/loggit/issues/30). This bug is fixed
in `loggit2`.

## Conclusion

In addition to these issues, there are several others, but these are the
most pressing and can all be easily fixed.

Apart from the aforementioned bugs and missing features, there is
significant untapped potential in the control settings (e.g., global
settings regarding log levels) that can be implemented without
complicating [loggit](https://github.com/ryapric/loggit).

All of these aspects will be addressed in
[loggit2](https://github.com/MEO265/loggit2). I welcome any suggestions
for new features, bug reports, or even a direct pull request on either
topic.

## Further comparisons

In [loggit](https://github.com/ryapric/loggit), each condition handler
shows itself as the call of the condition.

``` r
f <- function() {
  loggit::message("This is another message")
  loggit::warning("This is another warning")
  loggit::stop("This is another error")
}

f()
#> {"timestamp": "2022-04-12T10:55:02-0500", "log_lvl": "INFO", "log_msg": "This is a message"}
#> This is a message
#> {"timestamp": "2022-04-12T10:55:02-0500", "log_lvl": "WARN", "log_msg": "This is a warning"}
#> Warning in loggit::warning("This is a warning"): This is a warning
#> {"timestamp": "2020-05-31T20:59:33-0500", "log_lvl": "ERROR", "log_msg": "This is an error"}
#> Error in loggit::stop("This is an error"): This is an error
```

In [loggit2](https://github.com/MEO265/loggit2), each condition handler
shows the same call as its `{base}` equivalent.

``` r
f <- function() {
  base::message("This is another message")
  base::warning("This is another warning")
  base::stop("This is another error")
}

f()
#> This is another message
#> Warning in f(): This is another warning
#> Error in f(): This is another error

f <- function() {
  loggit2::message("This is another message")
  loggit2::warning("This is another warning")
  loggit2::stop("This is another error")
}

f()
#> {"timestamp": "2025-12-16T18:13:12+0000", "log_lvl": "INFO", "log_msg": "This is another message\n"}
#> This is another message
#> {"timestamp": "2025-12-16T18:13:12+0000", "log_lvl": "WARN", "log_msg": "This is another warning"}
#> Warning in f(): This is another warning
#> {"timestamp": "2025-12-16T18:13:12+0000", "log_lvl": "ERROR", "log_msg": "This is another error"}
#> Error in f(): This is another error
```
