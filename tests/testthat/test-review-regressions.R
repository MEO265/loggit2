test_that("dangling aliases are rejected before concurrent first use creates sidecars", {
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  path <- file.path(root, "target-\u65e5\u672c.log")
  alias <- file.path(root, "alias.log")
  expected_alias <- file.path(normalizePath(root, winslash = "/", mustWork = TRUE), basename(alias))
  # Windows needs an existing target to choose the file-symlink type correctly.
  expect_true(file.create(path))
  linked <- suppressWarnings(file.symlink(path, alias))
  skip_if_not(isTRUE(linked), "File symlinks are unavailable")
  expect_identical(unlink(path), 0L)
  expect_false(file.exists(path))
  expect_error(loggit("INFO", "must be rejected", logfile = alias, echo = FALSE), "Resolve log alias.*OS error")
  expect_error(rotate_logs(0L, alias), "Resolve log alias.*OS error")
  with_log_workers(2L, function(cl, pids) {
    start <- as.numeric(Sys.time()) + 0.2
    errors <- parallel::clusterCall(cl, function(alias, start) {
      Sys.sleep(max(0L, start - as.numeric(Sys.time())))
      tryCatch({
        loggit2::set_logfile(alias, confirm = FALSE, create = TRUE)
        loggit2::loggit("INFO", "must be rejected", logfile = alias, echo = FALSE)
        "unexpected success"
      }, error = conditionMessage)
    }, alias, start)
    expect_true(all(grepl("Resolve log alias.*OS error", unlist(errors))))
    expect_true(all(grepl(expected_alias, unlist(errors), fixed = TRUE)))
    expect_false(file.exists(path))
    expect_false(file.exists(paste0(alias, ".lock")))
    expect_false(file.exists(paste0(path, ".lock")))
    # Once created through its target, the unchanged alias resolves consistently.
    loggit("INFO", "seed", id = "seed", logfile = path, echo = FALSE)
    expect_identical(normalize_logfile(alias), normalize_logfile(path))
    start <- as.numeric(Sys.time()) + 0.2
    parallel::clusterApply(cl, 1:2, function(worker, path, alias, start) {
      Sys.sleep(max(0L, start - as.numeric(Sys.time())))
      logfile <- if (worker == 1L) alias else path
      for (i in 1:20) {
        loggit2::loggit("INFO", strrep("payload", 10000L), id = paste(worker, i, sep = ":"),
                        logfile = logfile, echo = FALSE)
      }
    }, path, alias, start)
  })
  expect_length(expect_valid_log_json(path), 41L)
  expected <- c("seed", paste(1L, 1:20, sep = ":"), paste(2L, 1:20, sep = ":"))
  expect_identical(sort(read_logs(path)$id), sort(expected))
  expect_false(file.exists(paste0(alias, ".lock")))
})
