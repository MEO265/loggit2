# Set Call Options

Set Call Options

## Usage

``` r
set_call_options(..., .arg_list, confirm = TRUE)
```

## Arguments

- ...:

  Named arguments to set.

- .arg_list:

  A list of named arguments to set.

- confirm:

  Print confirmation message of call options setting?

## Value

Invisible the previous call options.

## Details

Call options are as follows:

- `log_call`: Log the call of an condition?

- `full_stack`: Log the full stack trace?

Only one of `...` or `.arg_list` can be provided.
