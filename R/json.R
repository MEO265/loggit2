sanitizer_map <- list(
  "{" = "__LEFTBRACE__",
  "}" = "__RIGHTBRACE__",
  '"' = "__DBLQUOTE__",
  "," = "__COMMA__",
  "\r" = "__CR__",
  "\n" = "__LF__"
)


#' Sanitization for ndJSON.
#'
#' *Sanitizers* and *unsanitizers* are functions, with one parameter, that convert a
#' character vector (of any length) into another (of the same length).
#' Associated *sanitizer* and *unsanitizer* should be constructed in such a way that the concatenation
#' `unsanitizer(sanitizer())` corresponds to the identity function.
#'
#'
#' @details
#' The default sanatizer and unsanatizer are based on the following mapping:
#'
#'  | Character | Replacement |
#'  |:--------- | :---------------------- |
#'  | `{`       | `__LEFTBRACE__`         |
#'  | `}`       | `__RIGHTBRACE__`        |
#'  | `"`       | `__DBLQUOTE__`          |
#'  | `,`       | `__COMMA__`             |
#'  | `\r`      | `__CR__`                |
#'  | `\n`      | `__LF__`                |
#'
#' This type of function is needed because because some characters in a JSON cannot appear unescaped and
#' since `loggit2` reimplements its own very simple string-based JSON parser.
#'
#' @param string A character vector
#'
#' @return A character vector
#'
#' @name sanitizers
NULL


#' @rdname sanitizers
default_ndjson_sanitizer <- function(string) {
  for (k in names(sanitizer_map)) {
    string <- gsub(pattern = k, replacement = sanitizer_map[[k]], string, fixed = TRUE)
  }

  # Explicit NAs must be marked so that no new ones are inserted when rotating the log
  string[is.na(string)] <- "__NA__"

  string
}

#' @rdname sanitizers
default_ndjson_unsanitizer <- function(string) {
  for (k in names(sanitizer_map)) {
    string <- gsub(pattern = sanitizer_map[[k]], replacement = k, string, fixed = TRUE)
  }

  string[string == "__NA__"] <- NA_character_

  string
}


#' Write ndJSON-formatted log file
#'
#' @param log_df Data frame of log data. Rows are converted to `ndjson` entries,
#'   with the columns as the fields.
#' @param logfile Log file to write to. Defaults to currently-configured log
#'   file.
#' @param echo Echo the `ndjson` entry to the R console? Defaults to `TRUE`.
#' @param overwrite Overwrite previous log file data? Defaults to `FALSE`, and
#'   so will append new log entries to the log file.
#' @param sanitizer [Sanitizer function][sanitizers] to run over elements in log data.
#'   Defaults to [default_ndjson_sanitizer()].
#'
#' @keywords internal
write_ndjson <- function(log_df, logfile = get_logfile(), echo = TRUE, overwrite = FALSE,
                         sanitizer = default_ndjson_sanitizer) {

  for (field in colnames(log_df)) {
    log_df[, field] <- sanitizer(log_df[, field])
  }

  # logdata will be built into a character vector where each element is a valid
  # JSON object, constructed from each row of the log data frame.
  logdata <- character(nrow(log_df))

  field_names <- paste0("\"", colnames(log_df), "\"")

  for (row in seq_len(nrow(log_df))) {

    row_data <- as.character(log_df[row,])
    na_entries <- is.na(row_data)
    row_data <- row_data[!na_entries]
    row_names <- field_names[!na_entries]

    row_data <- paste0("\"", row_data, "\"")
    row_data <- paste(row_names, row_data, sep = ": ", collapse = ", ")
    logdata[row] <- paste0("{", row_data, "}")
  }

  # Cat out if echo is on, and write to log file
  if (echo) cat(logdata, sep = "\n")
  write(logdata, file = logfile, append = !overwrite)
}

#' Read ndJSON-formatted log file
#'
#' @param logfile Log file to read from, and convert to a `data.frame`.
#' @param unsanitizer Unsanitizer function passed in from [read_logs()].
#'
#' @keywords internal
#'
#' @return A `data.frame`
read_ndjson <- function(logfile, unsanitizer = default_ndjson_unsanitizer) {

  # Read in lines of log data
  logdata <- readLines(logfile)

  # List first; easier to add to dynamically
  log_df <- data.frame()

  # Split out the log data into individual pieces, which will include JSON keys AND values
  logdata <- substring(logdata, first = 3L, last = nchar(logdata) - 2L)
  logdata <- strsplit(logdata, '", "', fixed = TRUE)
  log_kvs <- lapply(logdata, FUN = function(x) strsplit(x, '": "', fixed = FALSE))
  for (kvs in seq_along(log_kvs)) {
    missing_key <- which(lengths(log_kvs[[kvs]]) == 1L)
    for (mk in missing_key) {
      log_kvs[[kvs]][[mk]] <- c(log_kvs[[kvs]][[mk]], "")
    }
  }

  key_value_split <- function(x) {
    x <- unlist(x, use.names = FALSE)
    keys <- x[c(TRUE, FALSE)]
    values <- x[c(FALSE, TRUE)]
    list(keys = keys, values = values)
  }

  log_kvs <- lapply(log_kvs, key_value_split)
  rowcount <- length(log_kvs)

  all_keys <- unique(unlist(lapply(log_kvs, FUN = function(x) x[["keys"]])))

  log_df <- rep(list(rep(NA_character_, rowcount)), length(all_keys))
  names(log_df) <- all_keys
  for (lognum in seq_len(rowcount)) {
    row <- log_kvs[[lognum]]
    keys <- row[["keys"]]
    values <- row[["values"]]
    for (i in seq_along(keys)) {
      log_df[[keys[i]]][lognum] <- values[i]
    }
  }

  # Unsanitize the log data
  log_df <- as.data.frame(lapply(log_df, FUN = unsanitizer))

  log_df
}
