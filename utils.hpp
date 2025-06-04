#pragma once

#include <string>

namespace utils {

    const char* http_status_text(int code);
    std::string getCurrentTimestamp();

    // Returns true if the top-level JSON object contains the specified key
    bool hasJsonKey(const char* json, const char* keyName);

}