# Sanitization for ndJSON.

*Sanitizer* and *unsanitizer* are needed because the `ndjson` format
requires that each line be a valid JSON object, thus special characters
must be escaped. The functions worke in such a way that the
concatenation `unsanitizer(sanitizer())` corresponds to the identity
function.

## Usage

``` r
default_ndjson_sanitizer(string)

default_ndjson_unsanitizer(string)
```

## Arguments

- string:

  A character vector.

## Value

A character vector.

## Details

The default sanatizer and unsanatizer are based on the following
mapping:

|           |             |
|-----------|-------------|
| Character | Replacement |
| `\`       | `\\`        |
| `"`       | `\"`        |
| `\r`      | `\\r`       |
| `\n`      | `\\n`       |

## Examples

``` r
if (FALSE) { # \dontrun{
  default_ndjson_sanitizer('This is \n an "example"')
  default_ndjson_unsanitizer('This is \\n an \\"example\\"')
} # }
```
