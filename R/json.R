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
    string <- gsub(pattern = k, replacement =  sanitizer_map[[k]], string, fixed = TRUE)
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
#'
#' @keywords internal
write_ndjson <- function(log_df, logfile = get_logfile(), echo = TRUE, overwrite = FALSE) {

  # logdata will be built into a character vector where each element is a valid
  # JSON object, constructed from each row of the log data frame.
  logdata <- character(nrow(log_df))

  # The looping construct makes it easier to read & debug than an `lapply()` or
  # similar.
  for (row in seq_len(nrow(log_df))) {
    # Open the JSON
    logdata[row] <- "{"
    for (col in colnames(log_df)) {
      # Only log non-NA entries to JSON, in case there's more than one to flush
      # at once
      if (is.na(log_df[row, col])) next
      # Throw warning if embedded newlines are detected
      if (grepl("\\n|\\r", log_df[row, col])) {
        base::warning(
          "Logs in ndjson format should not have embedded newlines!\n",
          "found here: ", log_df[row, col]
        )
      }
      logdata[row] <- paste0(logdata[row], sprintf('\"%s\": \"%s\", ', col, log_df[row, col]))

    }
    # Drop the trailing comma and space from the last entry, and close the JSON
    logdata[row] <- substring(logdata[row], 1L, nchar(logdata[row]) - 2L)
    logdata[row] <- paste0(logdata[row], "}")
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
  log_df <- list()

  # Split out the log data into individual pieces, which will include JSON keys AND values
  logdata <- substring(logdata, first = 3L, last = nchar(logdata) - 2L)
  logdata <- strsplit(logdata, '", "', fixed = TRUE)
  log_kvs <- lapply(logdata, FUN = function(x) unlist(strsplit(x, '": "', fixed = FALSE), use.names = FALSE))

  rowcount <- length(log_kvs)
  for (lognum in seq_len(rowcount)) {
    rowdata <- log_kvs[[lognum]]
    # Filter out emtpy values from strsplit()
    rowdata <- rowdata[!(rowdata %in% c("", " "))]

    for (logfieldnum in seq_along(rowdata)) {
      # If odd, it's the key; if even, it's the value, where the preceding element
      # is the corresponding key.
      if (logfieldnum %% 2L == 0L) {
        colname <- rowdata[logfieldnum - 1L]
        # If the field doesn't exist, create it (filled with NAs) with the right length
        if (!(colname %in% names(log_df))) {
          log_df[[colname]] <- rep(NA_character_, length = rowcount)
        }
        # Unsanitize text, and store to df
        rowdata[logfieldnum] <- unsanitizer(rowdata[logfieldnum])
        log_df[[colname]][lognum] <- rowdata[logfieldnum]
      }
    }
  }

  log_df <- as.data.frame(log_df, stringsAsFactors = FALSE)
  log_df
}
