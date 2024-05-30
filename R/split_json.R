#' Convert a ndJSON object
#'
#' Split a vector of JSON strings into a list of R objects.
#'
#' @param x A vector of JSON strings.
#'
#' @return A list with the same length as `x`, each containing two character vectors: `keys` and `values`.
#'
#' @examples
#' \dontrun{
#'   split_ndjson(c('{"a": "1", "b": "2"}', '{"a": "3", "b": "4", "c": "5"}'))
#' }
#' @keywords internal
split_ndjson <- function(x) {
  .Call(c_split_ndjson, x)
}
