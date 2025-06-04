#include "utils.hpp"
#include "jsmn.h"
#include <cstring>
#include <ctime>

namespace utils {

const char* http_status_text(int code) {
    switch (code) {
        case 400: return "Bad Request";
        case 401: return "Authentication Failed";
        case 402: return "Insufficient Credits";
        case 403: return "Inactive Customer";
        case 500: return "Internal Server Error";
        default:  return "Something went wrong - Unexpected response from the server.";
    }
}

std::string getCurrentTimestamp() {
    std::time_t t = std::time(nullptr);
    char buf[64];
    std::strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", std::gmtime(&t)); // RFC3339 / ISO8601
    return std::string(buf);
}

bool hasJsonKey(const char* json, const char* keyName) {
    jsmn_parser parser;
    jsmntok_t tokens[512];  // adjust size if needed
    int r, i;

    jsmn_init(&parser);
    r = jsmn_parse(&parser, json, std::strlen(json), tokens, sizeof(tokens)/sizeof(tokens[0]));
    if (r < 0) {
        // parse error
        return false;
    }
    if (r < 1 || tokens[0].type != JSMN_OBJECT) {
        // root not object
        return false;
    }

    int keyLen = std::strlen(keyName);

    // Iterate over key-value pairs in root object
    for (i = 1; i < r; i++) {
        jsmntok_t key = tokens[i];
        if (key.type == JSMN_STRING) {
            int len = key.end - key.start;
            if (len == keyLen && std::strncmp(json + key.start, keyName, keyLen) == 0) {
                return true;
            }
            i++; // skip the value token
        }
    }
    return false;
}

} // namespace utils
