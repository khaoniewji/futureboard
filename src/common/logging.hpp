#pragma once
#include <QString>

#define LOG_WARNING(msg) Logger::warning(__FILE__, __LINE__, msg)

class Logger {
public:
    static void warning(const char* file, int line, const QString& message);
};
