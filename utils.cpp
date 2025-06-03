// utils.cpp
#include "utils.hpp"
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

} // namespace utils
