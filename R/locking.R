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
  .Call(c_check_log_alias, target)
  if (file.exists(target)) {
    target <- normalizePath(target, winslash = "/", mustWork = TRUE)
  }
  target
}

# Register cleanup before acquisition. The token initially owns no OS resource;
# native unwind cleanup also protects the blocking acquisition itself.
with_log_lock <- function(logfile, code) {
  if (!get_safe_multi_process()) return(force(code))
  if (inherits(logfile, "file")) logfile <- summary(logfile)$description
  logfile <- normalize_logfile(logfile)
  lock <- .Call(c_new_log_lock, paste0(logfile, ".lock"))
  # Fallback cleanup must not replace the original error or interrupt.
  on.exit(tryCatch(.Call(c_unlock_log, lock), error = function(e) NULL), add = TRUE)
  .Call(c_lock_log, lock)
  result <- force(code)
  .Call(c_unlock_log, lock)
  result
}
