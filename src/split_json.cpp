#include <vector>
#include <string>
#include <R.h>
#include <Rinternals.h>
#include "loggit.h"

//' Convert a JSON string
//'
//' Split a JSON strings into keys and values.
//'
//' @param strSEXP A JSON string.
//'
//' @return A list of two character vectors: `keys` and `values`.
//'
//' @keywords internal
extern "C" SEXP split_json(SEXP strSEXP) {
    const char* str = CHAR(STRING_ELT(strSEXP, 0));
    std::vector<std::string> keys;
    std::vector<std::string> values;
    std::vector<bool> keysNA;
    std::vector<bool> valuesNA;
    std::string token;
    bool inQuotes = false;
    int backslashCount = 0;
    bool isKey = true;

    int start = 0;
    int end = strlen(str) - 1;

    // Ignore leading and trailing whitespaces
    while (str[start] == ' ') start++;
    while (str[end] == ' ') end--;

    // Check for '{' and '}' and adjust the boundaries
    if (str[start] == '{') start++;
    if (str[end] == '}') end--;

    for (int i = start; i <= end; ++i) {
        char ch = str[i];
        if (ch == ' ' && !inQuotes) continue; // Skip spaces outside quotes

        if (ch == '\\') {
            backslashCount++;
            token += ch;
        } else if (ch == '"' && (backslashCount % 2 == 0)) {
            inQuotes = !inQuotes;
            token += ch;
            backslashCount = 0;
        } else if ((ch == ',' || ch == ':') && !inQuotes) {
            bool isNA = token == "null";
            if (token.front() == '"' && token.back() == '"' && token.size() > 1) {
                token = token.substr(1, token.size() - 2); // Remove quotes
            }
            if (isKey) {
                keys.push_back(token);
                keysNA.push_back(isNA);
                isKey = false; // Next token will be a value
            } else {
                values.push_back(token);
                valuesNA.push_back(isNA);
                isKey = true; // Next token will be a key
            }
            token.clear();
            backslashCount = 0;
        } else {
            token += ch;
            backslashCount = 0;
        }
    }

    // Check the last token
    if (!token.empty() && token != "null") {
        if (token.front() == '"' && token.back() == '"' && token.size() > 1) {
            token = token.substr(1, token.size() - 2); // Remove quotes
        }
        values.push_back(token);
        valuesNA.push_back(token == "null");
    } else {
        values.push_back("");
        valuesNA.push_back(true);
    }

    SEXP ans = PROTECT(Rf_allocVector(VECSXP, 2)); // List with two elements
    SEXP keysR = PROTECT(Rf_allocVector(STRSXP, keys.size()));
    SEXP valuesR = PROTECT(Rf_allocVector(STRSXP, values.size()));

    for (size_t j = 0; j < keys.size(); ++j) {
        SET_STRING_ELT(keysR, j, keysNA[j] ? NA_STRING : Rf_mkChar(keys[j].c_str()));
    }
    for (size_t j = 0; j < values.size(); ++j) {
        SET_STRING_ELT(valuesR, j, valuesNA[j] ? NA_STRING : Rf_mkChar(values[j].c_str()));
    }

    SET_VECTOR_ELT(ans, 0, keysR);
    SET_VECTOR_ELT(ans, 1, valuesR);

    SEXP names = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(names, 0, Rf_mkChar("keys"));
    SET_STRING_ELT(names, 1, Rf_mkChar("values"));
    Rf_setAttrib(ans, R_NamesSymbol, names);

    UNPROTECT(4);
    return ans;
}


//' Convert a ndJSON object
//'
//' Split a vector of JSON strings into a list of R objects.
//'
//' @param strVecSEXP A vector of JSON strings.
//'
//' @return A list with the same length as `x`, each containing two character vectors: `keys` and `values`.
//'
//' @keywords internal
extern "C" SEXP split_ndjson(SEXP strVecSEXP) {
    if (!Rf_isString(strVecSEXP)) {
        Rf_error("Input must be a character vector.");
    }

    int n = Rf_length(strVecSEXP);
    SEXP result = PROTECT(Rf_allocVector(VECSXP, n));

    for (int i = 0; i < n; i++) {
        SEXP strSEXP = PROTECT(Rf_mkString(CHAR(STRING_ELT(strVecSEXP, i))));
        SET_VECTOR_ELT(result, i, split_json(strSEXP));
        UNPROTECT(1); // Remove protection for strSEXP after using it
    }

    UNPROTECT(1); // Remove protection for result 
    return result;
}

