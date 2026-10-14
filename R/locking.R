# Resolve the parent even before the target exists. Resolving an existing target
# also supports stable symlinks; replacing symlinks during logging is unsupported.
normalize_logfile <- function(logfile) {
  base::stopifnot("logfile must be a non-empty path" =
                    is.character(logfile) && length(logfile) == 1L &&
                    !is.na(logfile) && nzchar(logfile))
  logfile <- path.expand(logfile)
  parent <- normalizePath(dirname(logfile), winslash = "/", mustWork = TRUE)
  target <- file.path(parent, basename(logfile))
  if (file.exists(target)) target <- normalizePath(target, winslash = "/", mustWork = TRUE)
  enc2utf8(target)
}

.log_lock_state <- new.env(parent = emptyenv())
.log_lock_state$busy <- FALSE

# Exiting handlers run before an enclosing with_loggit handler can log this
# failure again. Preserve its message and call, and mark it for outer handlers.
with_log_io <- function(code) {
  tryCatch(force(code), error = function(e) {
    class(e) <- unique(c("loggit_io_error", class(e)))
    base::stop(e)
  })
}

# The native scope owns the descriptor throughout acquisition, evaluation and
# cleanup. No acquired resource crosses a .Call return or relies on a finalizer.
with_log_lock <- function(logfile, code) {
  if (.log_lock_state$busy) base::stop("Recursive log locking is not allowed: ", logfile)
  lockfile <- paste0(logfile, ".lock")
  callback <- function() force(code)
  on.exit(.log_lock_state$busy <- FALSE, add = TRUE)
  .log_lock_state$busy <- TRUE
  with_log_io(.Call(c_with_log_lock, lockfile, callback))
}

# All conversion, including the final newline, happens before locking.
ndjson_bytes <- function(lines) {
  if (!length(lines)) return(raw())
  charToRaw(enc2utf8(paste0(paste(lines, collapse = "\n"), "\n")))
}

write_log_bytes <- function(logfile, bytes, append = TRUE) {
  .Call(c_write_log, logfile, bytes, append)
  invisible(NULL)
}
