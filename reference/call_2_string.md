# Convert Call to String

Converts a call object to a string and optionally determines the full
call stack.

## Usage

``` r
call_2_string(call, full_stack = FALSE, default_cutoff = 4L)
```

## Arguments

- call:

  Call object.

- full_stack:

  Include the full call stack?

- default_cutoff:

  Number of calls to cut from the end of the call stack if no matching
  call is found.

## Value

Deparsed call as string.

## Details

The full call stack can only be determined if the call is in the current
context. The default cutoff is 4 because the only known case is an
primitive error in
[`with_loggit()`](https://r-loggit.org/reference/with_loggit.md) which
adds 4 calls to the stack.
