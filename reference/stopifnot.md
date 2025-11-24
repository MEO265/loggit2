# Conditional Stop Log Handler

This function is identical to base R's
[`stopifnot`](https://rdrr.io/r/base/stopifnot.html), but it includes
logging of the exception message via
[`loggit()`](https://r-loggit.org/reference/loggit.md).

## Usage

``` r
stopifnot(..., exprs, exprObject, local, .loggit = NA, echo = get_echo())
```

## Arguments

- ..., exprs:

  any number of `R` expressions, which should each evaluate to (a
  logical vector of all) `TRUE`. Use *either* `...` *or* `exprs`, the
  latter typically an unevaluated expression of the form

      {
        expr1
        expr2
        ....
      }

  Note that e.g., positive numbers are not `TRUE`, even when they are
  coerced to `TRUE`, e.g., inside `if(.)` or in arithmetic computations
  in `R`. If names are provided to `...`, they will be used in lieu of
  the default error message.

- exprObject:

  alternative to `exprs` or `...`: an ‘expression-like’ object,
  typically an [`expression`](https://rdrr.io/r/base/expression.html),
  but also a [`call`](https://rdrr.io/r/base/call.html), a
  [`name`](https://rdrr.io/r/base/name.html), or atomic constant such as
  `TRUE`.

- local:

  (only when `exprs` is used:) indicates the
  [`environment`](https://rdrr.io/r/base/environment.html) in which the
  expressions should be evaluated; by default the one from where
  `stopifnot()` has been called.

- .loggit:

  Should the condition message be added to the log? If `NA` the log
  level set by
  [`set_log_level()`](https://r-loggit.org/reference/set_log_level.md)
  is used to determine if the condition should be logged.

- echo:

  Should the log entry (json) be echoed to `stdout` as well?

## See also

Other handlers:
[`debuginfo()`](https://r-loggit.org/reference/debuginfo.md),
[`message()`](https://r-loggit.org/reference/message.md),
[`stop()`](https://r-loggit.org/reference/stop.md),
[`warning()`](https://r-loggit.org/reference/warning.md)

## Examples

``` r
if (FALSE) { # \dontrun{
 stopifnot("This is a completely false condition" = FALSE)

 stopifnot(5L == 5L, "This is a completely false condition" = FALSE, echo = FALSE)
} # }
```
