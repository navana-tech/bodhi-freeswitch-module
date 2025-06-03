// utils.hpp
#pragma once

#include <string>

namespace utils {
    const char* http_status_text(int code);
    std::string getCurrentTimestamp();
}
