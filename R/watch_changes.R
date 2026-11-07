# Describe the result of an assignment, independently of how it was made.
describe_watch_changes <- function(name, old, new) {
  report <- new.env(parent = emptyenv())
  report$changes <- character()
  report$more <- FALSE

  record <- function(kind, path, before, after) {
    if (length(report$changes) == 5L) {
      report$more <- TRUE
      return(invisible(NULL))
    }
    label <- if (nzchar(path)) paste(kind, "at", path) else kind
    report$changes <- c(report$changes, paste(label, before, "->", after))
  }

  compare <- function(old, new, path, depth) {
    old_type <- typeof(old)
    new_type <- typeof(new)
    same_type <- identical(old_type, new_type)
    if (!same_type) record("type", path, old_type, new_type)

    old_class <- class(old)
    new_class <- class(new)
    # When class labels match the type labels, the type entry already shows them.
    class_change <- !identical(old_class, new_class) &&
      !(identical(old_class, old_type) && identical(new_class, new_type))
    if (class_change) record("class", path, toString(old_class), toString(new_class))

    old_attributes <- attributes(old)
    new_attributes <- attributes(new)
    keys <- union(names(old_attributes), names(new_attributes))
    if (class_change) keys <- setdiff(keys, "class")
    for (key in keys) {
      before <- old_attributes[[key]]
      after <- new_attributes[[key]]
      if (!identical(before, after)) {
        record(paste("attribute", encodeString(key, quote = '"')), path,
               watch_value_preview(before), watch_value_preview(after))
        if (report$more) return(invisible(NULL))
      }
    }

    # Compare vector payloads without dispatching class-specific subset methods.
    sequence <- same_type && !isS4(old) && !isS4(new) && (is.atomic(old) || old_type == "list")
    if (sequence) {
      if (!is.null(old_attributes)) attributes(old) <- NULL
      if (!is.null(new_attributes)) attributes(new) <- NULL
      if (identical(old, new)) return(invisible(NULL))

      size <- length(old)
      is_list <- old_type == "list"
      if (depth < 4L && (size > 1L || is_list) && size == length(new)) {
        dims <- old_attributes[["dim"]]
        if (!identical(dims, new_attributes[["dim"]])) dims <- NULL
        labels <- old_attributes[["names"]]
        if (!is_list || !identical(labels, new_attributes[["names"]])) labels <- NULL

        # Skip equal blocks in compiled code before looking at individual elements.
        for (start in seq.int(1L, size, by = 1024L)) {
          indices <- seq.int(start, min(start + 1023.0, size))
          if (identical(old[indices], new[indices])) next
          for (i in indices) {
            if (identical(old[[i]], new[[i]])) next
            component <- watch_component_path(i, dims, labels, is_list)
            compare(old[[i]], new[[i]], paste0(path, component), depth + 1L)
            if (report$more) return(invisible(NULL))
          }
        }
        return(invisible(NULL))
      }
    }

    record("value", path, watch_value_preview(old), watch_value_preview(new))
  }

  compare(old, new, "", 0L)
  if (report$more) report$changes <- c(report$changes, "more changes")
  paste0(name, ": ", paste(report$changes, collapse = "; "))
}

watch_component_path <- function(index, dims, labels, is_list) {
  if (!is.null(dims)) {
    position <- toString(arrayInd(index, dims))
  } else {
    position <- as.character(index)
    label <- labels[[index]]
    if (!is.null(label) && !is.na(label) && nzchar(label) && sum(labels == label, na.rm = TRUE) == 1L) {
      position <- encodeString(label, quote = '"')
    }
  }
  if (is_list) paste0("[[", position, "]]") else paste0("[", position, "]")
}

watch_value_preview <- function(value) {
  if (is.environment(value)) return(format.default(value))
  lines <- deparse(value, width.cutoff = 60L, nlines = 2L)
  text <- lines[[1L]]
  if (length(lines) > 1L || nchar(text) > 100L) paste0(substr(text, 1L, 100L), "...") else text
}
