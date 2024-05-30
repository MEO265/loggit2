split_ndjson <- function(x) {
  .Call(c_split_ndjson, x)
}