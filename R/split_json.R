split_json <- function(x) {
  .Call("split_json", x)
}

split_ndjson <- function(x) {
  .Call("split_ndjson", x)
}