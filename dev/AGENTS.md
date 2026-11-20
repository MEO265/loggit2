# AGENTS.md

`loggit2` is an R package for newline-delimited JSON (NDJSON) logging.
It provides direct logging, base R condition wrappers, and tools to
read, rotate, and export logs.

## Repository layout

- `R/loggit.R` is the main logging entry point. `R/handlers.R` wraps
  base R conditions, and `R/whit_loggit.R` implements
  [`with_loggit()`](https://r-loggit.org/dev/reference/with_loggit.md).
- `R/configurations.R` and `R/setup.R` manage settings. `R/utils.R`
  provides log file utilities.
- `R/json.R` handles NDJSON I/O. `R/split_json.R` calls the C++ parser
  in `src/split_json.cpp`.
- `tests/testthat/` contains tests, fixtures, and snapshots. Usage
  guides live in `vignettes/`.

## Compatibility and checks

- Support R 4.0 and keep runtime dependencies limited to the standard R
  distribution.
- Preserve base R condition behavior in the wrappers. For handler
  changes, reuse the comparison helpers in `tests/testthat/setup.R`.
- Keep existing NDJSON logs readable. For format changes, check
  write/read round trips for quotes, backslashes, and line breaks.
- From the repo root, run `Rscript -e "testthat::test_local()"` for
  tests and `Rscript -e "lintr::lint_package()"` for lint. For a full
  package check, run `Rscript -e "rcmdcheck::rcmdcheck()"`. Use matching
  Rtools for native builds on Windows.

## Documentation

- Use Markdown formatting in roxygen comments, with backticks for inline
  code and Markdown syntax for links. Leave `\code{}` to generated `.Rd`
  files.
- Edit roxygen comments in `R/` and regenerate `man/` and `NAMESPACE`
  with `roxygen2::roxygenise()` when help or exports change.
- Render `README.md` from `README.Rmd` for README changes. Record
  user-visible changes in `NEWS.md`.
