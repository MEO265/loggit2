#include <vector>
#include <string>
#include <R.h>
#include <Rinternals.h>


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

        if (ch == '\\' && !inQuotes) {
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
        SET_STRING_ELT(keysR, j, keysNA[j] ? NA_STRING : mkChar(keys[j].c_str()));
    }
    for (size_t j = 0; j < values.size(); ++j) {
        SET_STRING_ELT(valuesR, j, valuesNA[j] ? NA_STRING : mkChar(values[j].c_str()));
    }

    SET_VECTOR_ELT(ans, 0, keysR);
    SET_VECTOR_ELT(ans, 1, valuesR);

    UNPROTECT(3);
    return ans;
}
