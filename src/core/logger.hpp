#pragma once

#include <QObject>
#include <QString>

class Logger : public QObject {
    Q_OBJECT

public:
    enum Level {
        Debug,
        Info,
        Warning,
        Error,
        Critical
    };

    static Logger& instance();
    static void setDebugMode(bool enabled);
    static bool isDebugMode() { return s_debugMode; }
    
    void log(const QString& message, Level level, const char* file, int line);

private:
    Logger() = default;
    static bool s_debugMode;
};

#define LOG(msg, level) Logger::instance().log(msg, level, __FILE__, __LINE__)
#define LOG_DEBUG(msg) LOG(msg, Logger::Debug)
#define LOG_INFO(msg) LOG(msg, Logger::Info)
#define LOG_WARNING(msg) LOG(msg, Logger::Warning)
#define LOG_ERROR(msg) LOG(msg, Logger::Error)
#define LOG_CRITICAL(msg) LOG(msg, Logger::Critical)
