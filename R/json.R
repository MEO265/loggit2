sanitizer_map <- list(
  "\\" = "\\\\",
  '"' = '\\\"',
  "\r" = "\\r",
  "\n" = "\\n"
)


#' Sanitization for ndJSON.
#'
#' *Sanitizer* and *unsanitizer* are needed because the `ndjson` format requires that each line be a valid JSON object,
#' thus special characters must be escaped. The functions worke in such a way that the concatenation
#' `unsanitizer(sanitizer())` corresponds to the identity function.
#'
#' @param string A character vector.
#'
#' @return A character vector.
#'
#' @details
#' The default sanatizer and unsanatizer are based on the following mapping:
#'
#'  | Character | Replacement |
#'  |:--------- | :-----------|
#'  | `\`       | `\\`        |
#'  | `"`       | `\"`        |
#'  | `\r`      | `\\r`       |
#'  | `\n`      | `\\n`       |
#'
#' @name sanitizers
#'
#' @examples
#' \dontrun{
#'   default_ndjson_sanitizer('This is \n an "example"')
#'   default_ndjson_unsanitizer('This is \\n an \\"example\\"')
#' }
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
#' @param log_df A `data.frame`. Entries are converted to `ndjson`, with the columns as the fields.
#' @param logfile Path of log file to write to.
#' @param echo Should the log entry (json) be echoed to `stdout` as well?
#' @param overwrite Overwrite previous log file?
#'
#' @return Invisible `NULL`.
#'
#' @keywords internal
write_ndjson <- function(log_df, logfile = get_logfile(), echo = get_echo(), overwrite = FALSE) {

  # logdata will be built into a character vector where each element is a valid
  # JSON object, constructed from each row of the log data frame.
  logdata <- character(nrow(log_df))

  colnames(log_df) <- default_ndjson_sanitizer(colnames(log_df))

  log_df <- as.data.frame(
    lapply(log_df, function(x) default_ndjson_sanitizer(as.character(x))),
    check.names = FALSE, fix.empty.names = FALSE, stringsAsFactors = FALSE
  )

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
#' @param logfile Path to log file to read from.
#' @param unsanitize Should escaped special characters be unescaped?
#' @param last_first Should the last log entry be the first row of the data frame?
#'
#' @return A `data.frame`, with the columns as the fields in the log file.
#'
#' @keywords internal
read_ndjson <- function(logfile, unsanitize = TRUE, last_first = FALSE) {

  # Read in lines of log data
  logdata <- readLines(logfile)

  log_kvs <- split_ndjson(logdata)

  rowcount <- length(log_kvs)

  all_keys <- unique(unlist(lapply(log_kvs, FUN = function(x) x[["keys"]])))

  log_df <- rep(list(rep(NA_character_, rowcount)), length(all_keys))
  names(log_df) <- all_keys
  for (lognum in seq_len(rowcount)) {
    lognum_df <- ifelse(last_first, yes = rowcount - lognum + 1L, no = lognum)
    row <- log_kvs[[lognum_df]]
    keys <- row[["keys"]]
    values <- row[["values"]]
    for (i in seq_along(keys)) {
      log_df[[keys[i]]][lognum] <- values[i]
    }
  }

  if (unsanitize) {
    names(log_df) <- default_ndjson_unsanitizer(names(log_df))
    log_df <- lapply(log_df, default_ndjson_unsanitizer)
  }

  log_df <- as.data.frame(log_df, stringsAsFactors = FALSE, check.names = FALSE, fix.empty.names = FALSE)

  log_df
}
