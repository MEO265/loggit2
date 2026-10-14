# Socket timeouts bound failed receives. On every exit, terminate only the
# workers created here before closing their sockets (also handles blocked locks).
with_log_workers <- function(n, code) {
  cl <- parallel::makePSOCKcluster(n, timeout = 20, setup_timeout = 20,
                                  outfile = tempfile("loggit-workers-"))
  pids <- integer()
  on.exit({
    for (pid in pids) try(tools::pskill(pid), silent = TRUE)
    for (node in cl) try(close(node$con), silent = TRUE)
  }, add = TRUE)
  pids <- unlist(parallel::clusterCall(cl, Sys.getpid), use.names = FALSE)
  lib <- dirname(find.package("loggit2"))
  parallel::clusterCall(cl, function(lib) {
    .libPaths(c(lib, .libPaths()))
    loadNamespace("loggit2")
    NULL
  }, lib)
  code(cl, pids)
}

send_log_job <- function(node, fun, ...) {
  parallel:::sendCall(node, fun, list(...))
}

receive_log_job <- function(node) {
  result <- parallel:::recvResult(node)
  if (inherits(result, "try-error")) base::stop(as.character(result))
  result
}

wait_for_log_marker <- function(path) {
  deadline <- Sys.time() + 10
  while (!file.exists(path)) {
    if (Sys.time() > deadline) base::stop("Timed out waiting for ", path)
    Sys.sleep(0.01)
  }
}

# Validate the flat string/null JSON grammar independently of the package parser.
# Runs of ordinary characters keep long messages cheap to validate with PCRE.
expect_valid_log_json <- function(path) {
  lines <- readLines(path, encoding = "UTF-8", warn = TRUE)
  string <- '"(?:[^"\\\\\\x00-\\x1f]++|\\\\(?:["\\\\/bfnrt]|u[0-9a-fA-F]{4}))*"'
  field <- paste0(string, ': (?:', string, '|null)')
  pattern <- paste0('^\\{', field, '(?:, ', field, ')*\\}$')
  expect_true(all(grepl(pattern, lines, perl = TRUE)))
  invisible(lines)
}
