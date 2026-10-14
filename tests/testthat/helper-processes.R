# Socket timeouts bound failed receives. Let successful workers exit normally;
# terminate this cluster on failure, including workers blocked on a lock.
with_log_workers <- function(n, code) {
  worker_root <- tempfile("loggit-workers-")
  dir.create(worker_root)
  worker_root <- normalizePath(worker_root, winslash = "/", mustWork = TRUE)
  cl <- NULL
  pids <- integer()
  completed <- FALSE
  on.exit({
    if (completed) {
      # A deliberately killed holder must not prevent other workers' shutdown.
      for (i in seq_along(cl)) {
        node_cluster <- structure(cl[i], class = class(cl))
        stopped <- try(parallel::stopCluster(node_cluster), silent = TRUE)
        if (inherits(stopped, "try-error")) {
          try(tools::pskill(pids[[i]]), silent = TRUE)
          try(close(cl[[i]]$con), silent = TRUE)
        }
      }
    } else {
      for (pid in pids) try(tools::pskill(pid), silent = TRUE)
      for (node in cl) try(close(node$con), silent = TRUE)
    }
    # This private root also contains Rscript's -e files, which a forcibly
    # terminated process cannot remove. Never sweep shared temporary files.
    unlink(worker_root, recursive = TRUE)
  }, add = TRUE)
  cl <- make_log_cluster(n, worker_root)
  pids <- unlist(parallel::clusterCall(cl, Sys.getpid), use.names = FALSE)
  lib <- dirname(find.package("loggit2"))
  parallel::clusterCall(cl, function(lib) {
    .libPaths(c(lib, .libPaths()))
    loadNamespace("loggit2")
    NULL
  }, lib)
  result <- code(cl, pids)
  completed <- TRUE
  result
}

# Confine all child startup files and temporary directories to an owned root.
# Restore the parent's environment immediately after cluster initialization.
make_log_cluster <- function(n, worker_root) {
  variables <- c("TMPDIR", "TMP", "TEMP")
  old <- Sys.getenv(variables, unset = NA_character_)
  on.exit({
    Sys.unsetenv(variables[is.na(old)])
    if (!all(is.na(old))) do.call(Sys.setenv, as.list(old[!is.na(old)]))
  }, add = TRUE)
  Sys.setenv(TMPDIR = worker_root, TMP = worker_root, TEMP = worker_root)
  parallel::makePSOCKcluster(n, timeout = 20L, setup_timeout = 20L,
                             outfile = file.path(worker_root, "output"))
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
  deadline <- Sys.time() + 10L
  while (!file.exists(path)) {
    if (Sys.time() > deadline) base::stop("Timed out waiting for ", path)
    Sys.sleep(0.01)
  }
}

# Validate the flat string/null JSON grammar independently of the package parser.
# Runs of ordinary characters keep long messages cheap to validate with PCRE.
expect_valid_log_json <- function(path) {
  lines <- readLines(path, encoding = "UTF-8", warn = TRUE)
  string <- "\"(?:[^\"\\\\\\x00-\\x1f]++|\\\\(?:[\"\\\\/bfnrt]|u[0-9a-fA-F]{4}))*\""
  field <- paste0(string, ": (?:", string, "|null)")
  json_regex <- paste0("^\\{", field, "(?:, ", field, ")*\\}$")
  expect_true(all(grepl(json_regex, lines, perl = TRUE)))
  invisible(lines)
}
