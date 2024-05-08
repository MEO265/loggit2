sanitizer_map <- list(
  "\\" =  "\\\\",
  '"' = '\\\"',
  "\r" = "\\r",
  "\n" = "\\n")


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
#'  |:--------- | :-----------|
#'  | `"`       | `\"`        |
#'  | `\r`      | `\\r`       |
#'  | `\n`      | `\\n`       |
#'
#' This type of function is needed because because some characters in a JSON cannot appear unescaped and
#' since `loggit2` reimplements its own very simple string-based JSON parser.
#'
#' @param string A character vector
#'
#' @return A character vector
#'
#' @name sanitizers
#'
#' @keywords internal
NULL


#' @rdname sanitizers
default_ndjson_sanitizer <- function(string) {
  for (k in names(sanitizer_map)) {
    string <- gsub(pattern = k, replacement = sanitizer_map[[k]], string, fixed = TRUE)
  }

  string
}

#' @rdname sanitizers
default_ndjson_unsanitizer <- function(string) {
  for (k in rev(names(sanitizer_map))) {
    string <- gsub(pattern = sanitizer_map[[k]], replacement = k, string, fixed = TRUE)
  }

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
write_ndjson <- function(log_df, logfile = get_logfile(), echo = get_echo(), overwrite = FALSE) {

  # logdata will be built into a character vector where each element is a valid
  # JSON object, constructed from each row of the log data frame.
  logdata <- character(nrow(log_df))

  log_df <- as.data.frame(lapply(log_df, function (x) default_ndjson_sanitizer(as.character(x))))

  row_names <- paste0("\"", colnames(log_df), "\"")

  for (row in seq_len(nrow(log_df))) {

    row_data <- as.character(log_df[row,])

    na_entries <- is.na(row_data)
    row_data[!na_entries] <- paste0("\"", row_data[!na_entries], "\"")
    row_data[na_entries] <- "null"
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
#' @param unsanitize Should the log data be unsanitized?
#'
#' @keywords internal
#'
#' @return A `data.frame`
read_ndjson <- function(logfile, unsanitize = TRUE) {

  # Read in lines of log data
  logdata <- readLines(logfile)

  log_kvs <- split_ndjson(logdata)

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

  if(unsanitize) log_df <- lapply(log_df, default_ndjson_unsanitizer)

  log_df <- as.data.frame(log_df)

  log_df
}
