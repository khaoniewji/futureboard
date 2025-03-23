// configmanager.cpp
#include "configmanager.hpp"
#include "core/audioengine/audioengine.hpp"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QSettings>

ConfigManager* ConfigManager::s_instance = nullptr;
const QString ConfigManager::DEVICE_SCAN_SECTION = "deviceScan";

ConfigManager& ConfigManager::instance() {
    if (!s_instance) {
        s_instance = new ConfigManager();
    }
    return *s_instance;
}

ConfigManager::ConfigManager() {
    QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(appDataPath);
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    m_configPath = dir.filePath("config.json");
    load();
}

ConfigManager::~ConfigManager() {
    save();
}

bool ConfigManager::load() {
    QFile file(m_configPath);
    if (!file.open(QIODevice::ReadOnly)) {
        // Generate default config if file doesn't exist
        createDefaultConfig();
        return true;
    }

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    m_config = doc.object();
    emit configChanged();
    return true;
}

void ConfigManager::createDefaultConfig() {
    QJsonObject defaultConfig;
    QJsonObject audioConfig;

    // Default audio settings
    audioConfig["lastDevice"] = "";
    audioConfig["lastInputDevice"] = "";
    audioConfig["lastOutputDevice"] = "";
    audioConfig["bufferSize"] = DEFAULT_BUFFER_SIZE;
    audioConfig["api"] = 0;  // Default to MME (index 0)

    defaultConfig["audio"] = audioConfig;

    m_config = defaultConfig;
    save();
}

bool ConfigManager::save() {
    QFile file(m_configPath);
    if (!file.open(QIODevice::WriteOnly)) {
        return false;
    }

    QJsonDocument doc(m_config);
    file.write(doc.toJson());
    return true;
}

QString ConfigManager::getConfigPath() const {
    return m_configPath;
}

void ConfigManager::setConfig(const QJsonObject& config) {
    m_config = config;
    emit configChanged();
    save();
}

QString ConfigManager::getLastAudioDevice() const {
    return m_config["audio"].toObject()["lastDevice"].toString();
}

void ConfigManager::setLastAudioDevice(const QString& device) {
    QJsonObject audio = m_config["audio"].toObject();
    audio["lastDevice"] = device;
    m_config["audio"] = audio;
    save();
}

int ConfigManager::getLastBufferSize() const {
    return m_config["audio"].toObject()["bufferSize"].toInt(DEFAULT_BUFFER_SIZE);
}

void ConfigManager::setLastBufferSize(int size) {
    QJsonObject audio = m_config["audio"].toObject();
    audio["bufferSize"] = size;
    m_config["audio"] = audio;
    save();
}

int ConfigManager::getLastAudioAPI() const {
    return m_config["audio"].toObject()["api"].toInt(0);
}

void ConfigManager::setLastAudioAPI(int api) {
    QJsonObject audio = m_config["audio"].toObject();
    audio["api"] = api;
    m_config["audio"] = audio;
    save();
}

void ConfigManager::setLastInputDevice(const QString& device) {
    QJsonObject audio = m_config["audio"].toObject();
    audio["lastInputDevice"] = device;
    m_config["audio"] = audio;
    save();
}

void ConfigManager::setLastOutputDevice(const QString& device) {
    QJsonObject audio = m_config["audio"].toObject();
    audio["lastOutputDevice"] = device;
    m_config["audio"] = audio;
    save();
}

QString ConfigManager::getLastInputDevice() const {
    return m_config["audio"].toObject()["lastInputDevice"].toString();
}

QString ConfigManager::getLastOutputDevice() const {
    return m_config["audio"].toObject()["lastOutputDevice"].toString();
}

void ConfigManager::saveInitialDeviceScan(const QStringList& asioDevices,
                                        const QStringList& wasapiDevices,
                                        const QStringList& mmeDevices) {
    m_scannedDevices["asio"] = asioDevices;
    m_scannedDevices["wasapi"] = wasapiDevices;
    m_scannedDevices["mme"] = mmeDevices;

    QJsonObject scanConfig;
    scanConfig["asio"] = QJsonArray::fromStringList(asioDevices);
    scanConfig["wasapi"] = QJsonArray::fromStringList(wasapiDevices);
    scanConfig["mme"] = QJsonArray::fromStringList(mmeDevices);
    m_config[DEVICE_SCAN_SECTION] = scanConfig;
    save();
}

QStringList ConfigManager::getScannedDevices(const QString& apiType) const {
    QString key = apiType.toLower();

    // First try memory cache
    if (m_scannedDevices.contains(key)) {
        return m_scannedDevices[key];
    }

    // Fallback to JSON config
    QJsonObject scanConfig = m_config[DEVICE_SCAN_SECTION].toObject();
    QJsonArray array = scanConfig[key].toArray();

    QStringList result;
    for (const QJsonValue& value : array) {
        result.append(value.toString());
    }
    return result;
}
