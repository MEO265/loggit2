#' Konvertiert ein einzelnes atomisches Objekt in seine JSON-Repräsentation.
#'
#' Konvertiert ein atomisches Objekt der Länge 1 oder NULL in einen JSON-Wert.
#' Numerische Werte werden als Zahlen, logische Werte als true/false ausgegeben,
#' NA und NULL werden als null dargestellt. Integer-Werte werden mit einem nachgestellten "L" ausgegeben.
#'
#' @param x Ein atomisches Objekt der Länge 1 oder NULL.
#' @return Ein Zeichenvektor, der den JSON-Wert repräsentiert.
baseAtomic2json <- function(x) {
  if (is.null(x))
    return("null")
  
  if (is.na(x))
    return("null")
  
  if (is.logical(x))
    return(if (x) "true" else "false")
  
  if (is.integer(x))
    return(paste0(as.character(x), "L"))
  
  if (is.numeric(x))
    return(as.character(x))
  
  if (is.character(x))
    return(paste0("\"", x, "\""))
  
  paste0("\"", toString(x), "\"")
}

#' Konvertiert einen atomaren Vektor oder eine Matrix in ein JSON-Array.
#'
#' Konvertiert einen atomaren Vektor oder eine Matrix (oder ein höherdimensionales Array)
#' in ein JSON-Array. Bei Matrizen/Arrays wird jede Scheibe entlang der ersten Dimension
#' rekursiv verarbeitet.
#'
#' @param x Ein atomarer Vektor, eine Matrix oder ein höherdimensionales Array.
#' @return Ein Zeichenvektor, der das JSON-Array repräsentiert.
vector2json <- function(x) {
  if (!is.null(dim(x)) && length(dim(x)) > 1) {
    outer_dim <- dim(x)[1]
    inner <- vapply(seq_len(outer_dim), function(i) {
      idx <- c(list(i), replicate(length(dim(x)) - 1, TRUE, simplify = FALSE))
      sub <- do.call("[", c(list(x), idx, list(drop = TRUE)))
      vector2json(sub)
    }, FUN.VALUE = character(1))
    paste0("[", paste(inner, collapse = ","), "]")
  } else {
    json_elements <- vapply(seq_along(x), function(i) {
      baseAtomic2json(x[i])
    }, FUN.VALUE = character(1))
    paste0("[", paste(json_elements, collapse = ","), "]")
  }
}

#' Konvertiert die Elemente einer Liste in ihre jeweilige JSON-Repräsentation.
#'
#' Wendet auf jedes Element der Liste die passende Funktion an:
#' Ist das Element ein Environment, wird es in eine Liste umgewandelt und mit list2json verarbeitet.
#' Ist es eine Liste, wird list2json verwendet, bei Vektoren/Matrizen vector2json und bei atomaren
#' Objekten baseAtomic2json. Falls keine der Bedingungen zutrifft, wird ein Fallback mittels toString und Anführungszeichen verwendet.
#'
#' @param x Eine Liste mit verschiedenen Elementtypen.
#' @return Ein Zeichenvektor, in dem jedes Element in seine JSON-Repräsentation konvertiert wurde.
convertListElements <- function(x) {
  vapply(x, function(elem) {
    if (is.environment(elem)) {
      list2json(as.list(elem))
    } else if (is.list(elem)) {
      list2json(elem)
    } else if (is.matrix(elem) || (is.atomic(elem) && length(elem) > 1)) {
      vector2json(elem)
    } else if (is.atomic(elem) && length(elem) == 1) {
      baseAtomic2json(elem)
    } else {
      paste0("\"", toString(elem), "\"")
    }
  }, FUN.VALUE = character(1))
}

#' Konvertiert rekursiv eine Liste in ein JSON-Objekt.
#'
#' Konvertiert eine Liste in ein JSON-Objekt. Falls ein Element ein Environment ist,
#' wird es in eine Liste umgewandelt. Dabei werden alle Elemente mittels convertListElements
#' verarbeitet. Handelt es sich um einen Vektor oder eine Matrix (bzw. um einen atomaren Vektor mit
#' mehreren Elementen), wird vector2json verwendet.
#'
#' @param x Eine Liste, die verschachtelte Listen, Vektoren, Matrizen oder Environments enthalten kann.
#' @return Ein Zeichenvektor, der das JSON-Objekt repräsentiert.
list2json <- function(x) {
  nms <- names(x)
  values <- convertListElements(x)
  keys <- vapply(seq_along(x), function(i) {
    if (!is.null(nms) && nms[i] != "")
      paste0("\"", nms[i], "\"")
    else
      paste0("\"", i, "\"")
  }, FUN.VALUE = character(1))
  pairs <- paste0(keys, ":", values)
  paste0("{", paste(pairs, collapse = ","), "}")
}