#include <R.h>
#include <Rinternals.h>
#include <vector>
#include <string>

extern "C" SEXP splitString(SEXP strSEXP) {
    const char* str = CHAR(STRING_ELT(strSEXP, 0));
    std::vector<std::string> result;
    std::string token;
    bool inQuotes = false;
    int backslashCount = 0;

    for (int i = 0; str[i] != '\0'; ++i) {
        char ch = str[i];
        if (ch == '\\' && !inQuotes) {
            backslashCount++;
            token += ch;
        } else if (ch == '"' && (backslashCount % 2 == 0)) {
            inQuotes = !inQuotes;
            token += ch;
            backslashCount = 0;
        } else if ((ch == ',' || ch == ':') && !inQuotes) {
            result.push_back(token);
            token.clear();
            backslashCount = 0;
        } else {
            token += ch;
            backslashCount = 0;
        }
    }

    if (!token.empty()) {
        result.push_back(token);
    }

    SEXP ans = PROTECT(allocVector(STRSXP, result.size()));
    for (size_t j = 0; j < result.size(); ++j) {
        SET_STRING_ELT(ans, j, mkChar(result[j].c_str()));
    }

    UNPROTECT(1);
    return ans;
}
