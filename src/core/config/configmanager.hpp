// configmanager.hpp
#pragma once

#include <QObject>
#include <QString>
#include <QJsonObject>
#include <QHash>
#include <QStringList>

class ConfigManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString lastInputDevice READ getLastInputDevice NOTIFY configChanged)
    Q_PROPERTY(QString lastOutputDevice READ getLastOutputDevice NOTIFY configChanged)
    Q_PROPERTY(int lastBufferSize READ getLastBufferSize NOTIFY configChanged)
    Q_PROPERTY(int lastAudioAPI READ getLastAudioAPI NOTIFY configChanged)

public:
    static ConfigManager& instance();

    bool load();
    bool save();
    QString getConfigPath() const;

    QJsonObject getConfig() const { return m_config; }
    void setConfig(const QJsonObject& config);

    // Audio config methods
    QString getLastAudioDevice() const;
    void setLastAudioDevice(const QString& device);
    int getLastBufferSize() const;
    Q_INVOKABLE void setLastBufferSize(int size);
    int getLastAudioAPI() const;
    Q_INVOKABLE void setLastAudioAPI(int api);
    QString getLastInputDevice() const;
    QString getLastOutputDevice() const;
    Q_INVOKABLE void setLastInputDevice(const QString& device);
    Q_INVOKABLE void setLastOutputDevice(const QString& device);

    // Device scanning methods
    void saveInitialDeviceScan(const QStringList& asioDevices,
                              const QStringList& wasapiDevices,
                              const QStringList& mmeDevices);
    QStringList getScannedDevices(const QString& apiType) const;

signals:
    void configChanged();

private:
    void createDefaultConfig();
    ConfigManager();
    ~ConfigManager();

    QJsonObject m_config;
    QString m_configPath;
    static ConfigManager* s_instance;
    static constexpr int DEFAULT_BUFFER_SIZE = 256;

    static const QString DEVICE_SCAN_SECTION;
    QHash<QString, QStringList> m_scannedDevices;
};
