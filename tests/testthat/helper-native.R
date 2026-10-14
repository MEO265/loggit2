# Compile the current C implementation with deterministic interrupt injection.
# R CMD check retains source in 00_pkg_src; installed binary-only tests cannot
# build this fixture and skip it explicitly. No production test hooks are used.
with_log_native_fixture <- function(code) {
  candidates <- c(test_path("..", "..", "src", "file_lock.c"),
                  test_path("..", "..", "00_pkg_src", "loggit2", "src", "file_lock.c"))
  source <- candidates[file.exists(candidates)]
  skip_if(!length(source), "Native source is unavailable in this installed package")
  root <- tempfile("loggit-native-")
  dir.create(root)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  dll <- NULL
  native <- NULL
  on.exit({
    if (!is.null(dll)) {
      try(.Call(native$arm, 0L, NULL), silent = TRUE)
      try(dyn.unload(dll[["path"]]), silent = TRUE)
    }
    unlink(root, recursive = TRUE)
  }, add = TRUE)
  expect_true(file.copy(source[[1L]], file.path(root, "file_lock.c")))
  expect_true(file.copy(test_path("native", "interrupt_fixture.c"), root))
  build_log <- file.path(root, "build.log")
  previous <- setwd(root)
  status <- tryCatch(system2(file.path(R.home("bin"), "R"), c("CMD", "SHLIB", "interrupt_fixture.c"),
                             stdout = build_log, stderr = build_log, timeout = 30L),
                     finally = setwd(previous))
  if (status != 0L) base::stop(paste(readLines(build_log), collapse = "\n"))
  dll <- dyn.load(file.path(root, paste0("interrupt_fixture", .Platform$dynlib.ext)))
  native <- list(arm = getNativeSymbolInfo("fixture_arm", dll)$address,
                 lock = getNativeSymbolInfo("with_log_lock", dll)$address,
                 rotate = getNativeSymbolInfo("rotate_log", dll)$address,
                 symlink = getNativeSymbolInfo("fixture_symlink", dll)$address)
  code(native)
}
