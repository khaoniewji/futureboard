#include "logger.hpp"
#include <QDebug>
#include <QDateTime>
#include <QFile>
#include <QDir>

bool Logger::s_debugMode = false;

Logger& Logger::instance() {
    static Logger instance;
    return instance;
}

void Logger::setDebugMode(bool enabled) {
    s_debugMode = enabled;
}

void Logger::log(const QString& message, Level level, const char* file, int line) {
    QString levelStr;
    switch (level) {
        case Debug: levelStr = "DEBUG"; break;
        case Info: levelStr = "INFO"; break;
        case Warning: levelStr = "WARNING"; break;
        case Error: levelStr = "ERROR"; break;
        case Critical: levelStr = "CRITICAL"; break;
    }

    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz");
    QString logMessage = QString("[%1] %2: %3 (%4:%5)")
        .arg(timestamp)
        .arg(levelStr)
        .arg(message)
        .arg(file)
        .arg(line);

    // Output to console
    if (s_debugMode || level >= Warning) {
        qDebug().noquote() << logMessage;
    }

    // TODO: Add file logging if needed
}
