# Resolve the parent even before the target exists. Resolving an existing target
# also supports stable symlinks. Reject unresolved aliases before creating a
# sidecar; replacing symlinks during logging is unsupported.
normalize_logfile <- function(logfile) {
  base::stopifnot("logfile must be a non-empty path" =
                    is.character(logfile) && length(logfile) == 1L &&
                    !is.na(logfile) && nzchar(logfile))
  logfile <- path.expand(logfile)
  parent <- normalizePath(dirname(logfile), winslash = "/", mustWork = TRUE)
  target <- file.path(parent, basename(logfile))
  # Windows file.exists() can report a dangling link as existing.
  .Call(c_check_log_alias, enc2utf8(target))
  if (file.exists(target)) {
    target <- normalizePath(target, winslash = "/", mustWork = TRUE)
  }
  enc2utf8(target)
}

# Exiting handlers run before an enclosing with_loggit handler can log this
# failure again. Preserve its message and call, and mark it for outer handlers.
with_log_io <- function(code) {
  tryCatch(force(code), error = function(e) {
    class(e) <- unique(c("loggit_io_error", class(e)))
    base::stop(e)
  })
}

# Register cleanup before acquisition. The token initially owns no OS resource;
# native unwind cleanup also protects the blocking acquisition itself.
with_log_lock <- function(logfile, code) {
  lock <- .Call(c_new_log_lock, paste0(logfile, ".lock"))
  completed <- FALSE
  on.exit({
    if (completed) {
      with_log_io(.Call(c_unlock_log, lock))
    } else {
      # Cleanup must not replace the original error or interrupt.
      tryCatch(.Call(c_unlock_log, lock), error = function(e) NULL)
    }
  }, add = TRUE)
  with_log_io(withCallingHandlers({
    .Call(c_lock_log, lock)
    result <- force(code)
    completed <- TRUE
    result
  }, warning = function(w) {
    base::stop("Log I/O failed for '", logfile, "': ", conditionMessage(w))
  }))
}
