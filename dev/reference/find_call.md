# Find the Call of a Parent Function in the Call Hierarchy

This function is designed to inspect the call hierarchy and identify the
call of a parent function. Any wrapper environments above the global R
environment that some IDEs cause are ignored.

## Usage

``` r
find_call()
```

## Value

Returns the call of the parent function, or `NULL` if no such call is
found.
