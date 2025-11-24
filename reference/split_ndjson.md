# Convert a ndJSON object

Split a vector of JSON strings into a list of R objects.

## Usage

``` r
split_ndjson(x)
```

## Arguments

- x:

  A vector of JSON strings.

## Value

A list with the same length as `x`, each containing two character
vectors: `keys` and `values`.

## Examples

``` r
if (FALSE) { # \dontrun{
  split_ndjson(c('{"a": "1", "b": "2"}', '{"a": "3", "b": "4", "c": "5"}'))
} # }
```
