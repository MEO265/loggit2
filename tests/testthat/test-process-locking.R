test_that("concurrent first use and long appends preserve every ID exactly once", {
  path <- paste0(tempfile(), "-\u65e5\u672c.log")
  n <- 30L
  with_log_workers(2L, function(cl, pids) {
    start <- as.numeric(Sys.time()) + 0.5
    result <- parallel::clusterApply(cl, seq_along(cl), function(worker, path, n, start) {
      Sys.sleep(max(0L, start - as.numeric(Sys.time())))
      # Alternate equivalent paths, including before the first file exists.
      if (worker %% 2L) path <- file.path(dirname(path), ".", basename(path))
      payload <- paste0(strrep("long payload ", 6000L), "\nquoted \"text\"\\\r", "\u00e4\u65e5\U0001f600")
      for (i in seq_len(n)) {
        loggit2::set_logfile(path, confirm = FALSE, create = TRUE)
        loggit2::loggit("INFO", payload, id = paste(worker, i, sep = ":"), echo = FALSE)
      }
      loggit2::get_logfile()
    }, path, n, start)
    expect_length(unique(unlist(result)), 1L)
  })
  expect_length(expect_valid_log_json(path), 2L * n)
  logs <- read_logs(path)
  expected <- unlist(lapply(1:2, function(i) paste(i, seq_len(n), sep = ":")))
  expect_identical(sort(logs$id), sort(expected))
  expect_true(all(endsWith(logs$log_msg, "\nquoted \"text\"\\\r\u00e4\u65e5\U0001f600")))
  expect_true(file.exists(paste0(path, ".lock")))
})

test_that("append and explicit rotation use one continuous lock", {
  path <- tempfile(fileext = ".log")
  loggit("INFO", "seed", id = "seed", logfile = path, echo = FALSE)
  with_log_workers(2L, function(cl, pids) {
    # Repeated coordinated starts exercise state rechecking. Retain all records
    # for completeness; destructive retention is checked separately below.
    for (round in 1:4) {
      start <- as.numeric(Sys.time()) + 0.1
      parallel::clusterApply(cl, 1:2, function(worker, path, round, start) {
        Sys.sleep(max(0L, start - as.numeric(Sys.time())))
        for (i in 1:20) {
          if (worker == 2L) {
            loggit2::rotate_logs(10000L, path)
          } else {
            loggit2::loggit("INFO", "entry\nwith newline", id = paste(round, worker, i, sep = ":"),
                            logfile = path, echo = FALSE)
          }
        }
      }, path, round, start)
    }
  })
  expect_length(expect_valid_log_json(path), 81L)
  expected <- c("seed", unlist(lapply(1:4, paste, 1L, 1:20, sep = ":")))
  expect_identical(sort(read_logs(path)$id), sort(expected))
})

test_that("small retention races keep complete ordered suffixes", {
  path <- tempfile(fileext = ".log")
  loggit("INFO", "seed", logfile = path, echo = FALSE)
  with_log_workers(2L, function(cl, pids) {
    start <- as.numeric(Sys.time()) + 0.2
    parallel::clusterApply(cl, 1:2, function(worker, path, start) {
      Sys.sleep(max(0L, start - as.numeric(Sys.time())))
      for (i in 1:50) {
        if (worker == 2L) {
          loggit2::rotate_logs(i %% 5L, path)
        } else {
          loggit2::loggit("INFO", strrep("x", 2000L), worker = worker, id = i, logfile = path, echo = FALSE)
        }
      }
    }, path, start)
  })
  lines <- expect_valid_log_json(path)
  before <- read_logs(path)
  ids <- as.integer(before$id[which(before$worker == "1")])
  expect_identical(anyDuplicated(ids), 0L)
  expect_true(all(diff(ids) == 1L))
  rotate_logs(3L, path)
  expect_identical(readLines(path), tail(lines, 3L))
  rotate_logs(0L, path)
  expect_identical(file.info(path)$size, 0.0)
  expect_true(file.exists(paste0(path, ".lock")))
})

test_that("repeated destructive rotation accounts for every appended ID", {
  path <- normalize_logfile(tempfile())
  loggit("INFO", "seed", id = "seed", logfile = path, echo = FALSE)
  removed <- with_log_workers(2L, function(cl, pids) {
    start <- as.numeric(Sys.time()) + 0.2
    results <- parallel::clusterApply(cl, 1:2, function(worker, path, start) {
      Sys.sleep(max(0L, start - as.numeric(Sys.time())))
      removed <- character()
      for (i in 1:40) {
        if (worker == 2L) {
          # Record intentional retention losses inside the same lock as the
          # unlocked rotation primitive. These are test records, not archives.
          dropped <- loggit2:::with_log_lock(path, {
            before <- readLines(path, encoding = "UTF-8")
            loggit2:::rotate_logs_unlocked(2L, path)
            head(before, max(0L, length(before) - 2L))
          })
          removed <- c(removed, dropped)
        } else {
          loggit2::loggit("INFO", strrep("entry", 2000L), id = paste(worker, i, sep = ":"),
                          logfile = path, echo = FALSE)
        }
        Sys.sleep(0.002)
      }
      removed
    }, path, start)
    results[[2L]]
  })
  expect_gt(length(removed), 0L)
  combined <- tempfile()
  writeLines(c(removed, readLines(path, encoding = "UTF-8")), combined, useBytes = TRUE)
  expect_length(expect_valid_log_json(combined), 41L)
  expected <- c("seed", paste(1L, 1:40, sep = ":"))
  expect_identical(sort(read_logs(combined)$id), sort(expected))
})

test_that("a waiter blocks and appends only after the holder closes its scope", {
  path <- normalize_logfile(tempfile(fileext = ".log"))
  ready <- tempfile()
  started <- tempfile()
  release <- tempfile()
  with_log_workers(2L, function(cl, pids) {
    send_log_job(cl[[1L]], function(path, ready, release) {
      loggit2:::with_log_lock(path, {
        file.create(ready)
        deadline <- Sys.time() + 10L
        while (!file.exists(release)) {
          if (Sys.time() > deadline) base::stop("Holder timed out")
          Sys.sleep(0.01)
        }
      })
      TRUE
    }, path, ready, release)
    wait_for_log_marker(ready)
    send_log_job(cl[[2L]], function(path, started) {
      file.create(started)
      loggit2::loggit("INFO", "waited", logfile = path, echo = FALSE)
      TRUE
    }, path, started)
    wait_for_log_marker(started)
    expect_false(socketSelect(list(cl[[2L]]$con), timeout = 0.2))
    expect_false(file.exists(path))
    file.create(release)
    expect_true(receive_log_job(cl[[1L]]))
    expect_true(receive_log_job(cl[[2L]]))
  })
  expect_identical(read_logs(path)$log_msg, "waited")
})

test_that("native unwind and R on.exit release errors and interrupts", {
  path <- normalize_logfile(tempfile(fileext = ".log"))
  with_log_workers(1L, function(cl, pids) {
    fail <- function(condition) base::stop(condition)
    expect_error(with_log_lock(path, fail("injected failure")), "injected failure")
    expect_error(with_log_lock(path, with_log_lock(path, NULL)), "Recursive")
    # Also exercise the native guard directly, bypassing the R wrapper.
    token <- .Call(c_new_log_lock, paste0(path, ".lock"))
    on.exit(.Call(c_unlock_log, token), add = TRUE)
    expect_error(with_log_lock(path, .Call(c_lock_log, token)), "Recursive")
    condition <- structure(list(message = "injected interrupt", call = NULL),
                           class = c("interrupt", "condition"))
    interrupted <- tryCatch(with_log_lock(path, fail(condition)), interrupt = function(e) TRUE)
    expect_true(interrupted)
    expect_true(parallel::clusterCall(cl, function(path) {
      loggit2::loggit("INFO", "recovered", logfile = path, echo = FALSE)
      TRUE
    }, path)[[1L]])
  })
})

test_that("readers wait for the shared lock even during first initialization", {
  path <- normalize_logfile(tempfile())
  ready <- tempfile()
  started <- tempfile()
  release <- tempfile()
  with_log_workers(2L, function(cl, pids) {
    send_log_job(cl[[1L]], function(path, ready, release) {
      loggit2:::with_log_lock(path, {
        file.create(ready)
        deadline <- Sys.time() + 10L
        while (!file.exists(release)) {
          if (Sys.time() > deadline) base::stop("Holder timed out")
          Sys.sleep(0.01)
        }
        writeLines("{\"log_msg\": \"seed\"}", path, useBytes = TRUE)
      })
    }, path, ready, release)
    wait_for_log_marker(ready)
    send_log_job(cl[[2L]], function(path, started) {
      file.create(started)
      loggit2::read_logs(path)$log_msg
    }, path, started)
    wait_for_log_marker(started)
    expect_false(socketSelect(list(cl[[2L]]$con), timeout = 0.2))
    expect_false(file.exists(path))
    file.create(release)
    receive_log_job(cl[[1L]])
    expect_identical(receive_log_job(cl[[2L]]), "seed")
  })
})

test_that("concurrent reads see complete records during appends and rotation", {
  path <- normalize_logfile(tempfile())
  payload <- paste0(strrep("payload", 10000L), "\n\u65e5\u672c")
  loggit("INFO", payload, id = 0L, logfile = path, echo = FALSE)
  result <- with_log_workers(2L, function(cl, pids) {
    start <- as.numeric(Sys.time()) + 0.2
    parallel::clusterApply(cl, 1:2, function(worker, path, payload, start) {
      Sys.sleep(max(0L, start - as.numeric(Sys.time())))
      for (i in 1:60) {
        if (worker == 1L) {
          loggit2::loggit("INFO", payload, id = i, logfile = path, echo = FALSE)
          loggit2::rotate_logs(5L, path)
        } else {
          snapshot <- loggit2::read_logs(path)
          base::stopifnot(nrow(snapshot) >= 1L, nrow(snapshot) <= 6L,
                          all(snapshot$log_msg == payload), !anyNA(snapshot$id),
                          anyDuplicated(snapshot$id) == 0L)
        }
      }
      TRUE
    }, path, payload, start)
  })
  expect_true(all(unlist(result)))
  expect_length(expect_valid_log_json(path), 5L)
  expect_identical(read_logs(path)$id, as.character(56:60))
})

test_that("JSON parsing runs after releasing the read lock", {
  path <- normalize_logfile(tempfile())
  loggit("INFO", "seed", logfile = path, echo = FALSE)
  parse <- split_ndjson
  local_mocked_bindings(split_ndjson = function(lines) {
    with_log_lock(path, NULL)
    parse(lines)
  })
  expect_identical(read_logs(path)$log_msg, "seed")
})

test_that("unlocking is idempotent and acquisition errors release the token", {
  path <- normalize_logfile(tempfile())
  token <- .Call(c_new_log_lock, paste0(path, ".lock"))
  on.exit(.Call(c_unlock_log, token), add = TRUE)
  .Call(c_lock_log, token)
  expect_null(.Call(c_unlock_log, token))
  expect_null(.Call(c_unlock_log, token))
  expect_error(.Call(c_lock_log, token), "already been released")
  expect_silent(with_log_lock(path, NULL))
})

test_that("terminating a holder releases its OS lock", {
  path <- normalize_logfile(tempfile(fileext = ".log"))
  ready <- tempfile()
  with_log_workers(2L, function(cl, pids) {
    send_log_job(cl[[1L]], function(path, ready) {
      loggit2:::with_log_lock(path, {
        file.create(ready)
        Sys.sleep(15L)
      })
    }, path, ready)
    wait_for_log_marker(ready)
    send_log_job(cl[[2L]], function(path) {
      loggit2::loggit("INFO", "after termination", logfile = path, echo = FALSE)
      TRUE
    }, path)
    expect_false(socketSelect(list(cl[[2L]]$con), timeout = 0.2))
    tools::pskill(pids[[1L]])
    expect_true(receive_log_job(cl[[2L]]))
  })
  expect_identical(read_logs(path)$log_msg, "after termination")
})

test_that("a real POSIX interrupt during acquisition cleans the waiting descriptor", {
  skip_on_os("windows")
  path <- normalize_logfile(tempfile(fileext = ".log"))
  ready <- tempfile()
  started <- tempfile()
  release <- tempfile()
  on.exit(file.create(release), add = TRUE)
  with_log_workers(2L, function(cl, pids) {
    send_log_job(cl[[1L]], function(path, ready, release) {
      loggit2:::with_log_lock(path, {
        file.create(ready)
        deadline <- Sys.time() + 10L
        while (!file.exists(release)) {
          if (Sys.time() > deadline) base::stop("Holder timed out")
          Sys.sleep(0.01)
        }
      })
      TRUE
    }, path, ready, release)
    wait_for_log_marker(ready)
    # PSOCK workers inherit SIGINT ignored from their background shell. Send
    # the signal to this foreground process, which owns the waiting descriptor.
    send_log_job(cl[[2L]], function(pid, started, release) {
      deadline <- Sys.time() + 10L
      while (!file.exists(started)) {
        if (Sys.time() > deadline) base::stop("Waiter timed out")
        Sys.sleep(0.01)
      }
      Sys.sleep(0.2)
      tools::pskill(pid, tools::SIGINT)
      # Also bound platforms whose syscall is restarted by the signal.
      Sys.sleep(0.2)
      file.create(release)
    }, Sys.getpid(), started, release)
    interrupted <- tryCatch({
      file.create(started)
      loggit("INFO", "must be interrupted", logfile = path, echo = FALSE)
      FALSE
    }, interrupt = function(e) TRUE)
    expect_true(interrupted)
    expect_true(receive_log_job(cl[[1L]]))
    expect_true(receive_log_job(cl[[2L]]))
    loggit("INFO", "resumed after interrupt", logfile = path, echo = FALSE)
    expect_true(parallel::clusterCall(cl, function(path) {
      loggit2::loggit("INFO", "after interrupt", logfile = path, echo = FALSE)
      TRUE
    }, path)[[1L]])
  })
  expect_false("must be interrupted" %in% read_logs(path)$log_msg)
})

test_that("I/O failures include the path and never leave a lock held", {
  path <- normalize_logfile(tempfile())
  dir.create(paste0(path, ".lock"))
  expect_error(loggit("INFO", "blocked", logfile = path, echo = FALSE), "Open lock.*OS error")
  expect_false(file.exists(path))
  unlink(paste0(path, ".lock"), recursive = TRUE)
  dir.create(path)
  expect_error(loggit("INFO", "cannot write directory", logfile = path, echo = FALSE), "Log I/O.*")
  expect_error(rotate_logs(0L, path), "Log I/O.*")
  unlink(path, recursive = TRUE)
  expect_error(rotate_logs(0L, path), "Log file does not exist")
  with_log_workers(1L, function(cl, pids) {
    expect_true(parallel::clusterCall(cl, function(path) {
      loggit2::loggit("INFO", "after I/O errors", logfile = path, echo = FALSE)
      TRUE
    }, path)[[1L]])
  })
  expect_identical(read_logs(path)$log_msg, "after I/O errors")
})

test_that("rotation copies large suffixes and preserves exact retention rules", {
  path <- tempfile()
  payload <- vapply(1:20, function(i) paste0(i, strrep("x", 10000L)), character(1L))
  writeLines(payload, path, useBytes = TRUE)
  rotate_logs(12L, path)
  expect_identical(readLines(path), tail(payload, 12L))
  rotate_logs(100L, path)
  expect_identical(readLines(path), tail(payload, 12L))
  rotate_logs(1L, path)
  expect_identical(readLines(path), tail(payload, 1L))
  rotate_logs(0L, path)
  expect_length(readLines(path), 0L)
  # Existing readLines/write semantics add a newline to an incomplete tail.
  writeChar("a\nb\nc", path, eos = NULL)
  rotate_logs(2L, path)
  expect_identical(readLines(path), c("b", "c"))
})

test_that("overwrites also take the shared lock and retain the sidecar", {
  path <- tempfile()
  write_ndjson(data.frame(value = "first", stringsAsFactors = FALSE), path, echo = FALSE)
  lock <- paste0(path, ".lock")
  before <- file.info(lock)$mtime
  write_ndjson(data.frame(value = "replacement", stringsAsFactors = FALSE), path, echo = FALSE, overwrite = TRUE)
  expect_identical(read_logs(path)$value, "replacement")
  expect_identical(file.info(lock)$mtime, before)
})

test_that("Unicode bytes and paths work in a non-UTF-8 Windows locale", {
  skip_if(.Platform$OS.type != "windows")
  old <- Sys.getlocale("LC_CTYPE")
  on.exit(Sys.setlocale("LC_CTYPE", old), add = TRUE)
  Sys.setlocale("LC_CTYPE", "C")
  path <- paste0(tempfile(), "-\u65e5\u672c.log")
  payload <- "\u00e4\u65e5\U0001f600\n"
  loggit("INFO", payload, logfile = path, echo = FALSE)
  loggit("INFO", payload, logfile = path, echo = FALSE)
  rotate_logs(1L, path)
  expect_identical(enc2utf8(read_logs(path)$log_msg), enc2utf8(payload))
})

test_that("with_loggit does not hold a stale connection across rotation", {
  path <- tempfile()
  expect_identical(with_loggit(42L, logfile = path), 42L)
  expect_false(file.exists(path))
  suppressMessages(with_loggit({
    base::message("first")
    rotate_logs(0L, path)
    base::message("second")
  }, logfile = path, echo = FALSE))
  expect_identical(read_logs(path)$log_msg, "second\n")
})

test_that("condition-handler failures release an acquired lock", {
  path <- normalize_logfile(tempfile())
  # read_logs acquires the lock before rejecting the missing file. Its enclosing
  # handler can fail while trying to log that error, but must release the lock.
  expect_error(with_loggit(read_logs(path), logfile = path, echo = FALSE))
  expect_false(file.exists(path))
  with_log_workers(1L, function(cl, pids) {
    expect_true(parallel::clusterCall(cl, function(path) {
      loggit2::loggit("INFO", "after handler failure", logfile = path, echo = FALSE)
      TRUE
    }, path)[[1L]])
  })
  expect_identical(read_logs(path)$log_msg, "after handler failure")
})

test_that("existing symlink aliases share a canonical target", {
  skip_on_os("windows")
  dir <- tempfile()
  dir.create(dir)
  alias <- tempfile()
  expect_true(file.symlink(dir, alias))
  path <- file.path(dir, "new.log")
  expect_identical(normalize_logfile(file.path(alias, "new.log")), normalize_logfile(path))
  loggit("INFO", "first", logfile = file.path(alias, "new.log"), echo = FALSE)
  link <- tempfile()
  expect_true(file.symlink(path, link))
  expect_identical(normalize_logfile(link), normalize_logfile(path))
  loggit("INFO", "second", logfile = link, echo = FALSE)
  expect_identical(read_logs(path)$log_msg, c("first", "second"))
})

test_that("a real write or flush error closes the stream and releases the lock", {
  full_device <- "/dev/full" # nolint: absolute_path_linter. Use the OS full device to force an I/O error.
  skip_if_not(file.exists(full_device))
  path <- normalize_logfile(tempfile())
  lock_scope <- with_log_lock
  # Use an owned sidecar instead of trying to create one in /dev.
  local_mocked_bindings(with_log_lock = function(logfile, code) {
    lock_scope(path, withCallingHandlers(force(code), warning = function(w) {
      # Ignore only the device-type warning to reach the failing write/close.
      if (grepl("not a regular file", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning")
    }))
  })
  expect_error(loggit("INFO", "entry", logfile = full_device, echo = FALSE),
               "Log I/O.*(No space left|close/flush|problem writing)")
  with_log_workers(1L, function(cl, pids) {
    expect_true(parallel::clusterCall(cl, function(path) {
      loggit2::loggit("INFO", "after flush error", logfile = path, echo = FALSE)
      TRUE
    }, path)[[1L]])
  })
})
