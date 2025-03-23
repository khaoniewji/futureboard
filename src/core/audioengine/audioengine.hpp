// audioengine.hpp
#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <portaudio.h>
#include <pa_asio.h>
#include <mmdeviceapi.h>
#include <audioclient.h>
#include <functiondiscoverykeys_devpkey.h>
#include "../config/configmanager.hpp"  // Add this line

class AudioEngine : public QObject {
    Q_OBJECT

public:
    static AudioEngine& instance();

    enum class AudioAPI {
        MME,
        WASAPI,
        ASIO
    };

    // Properties
    Q_PROPERTY(QStringList audioApis READ getAudioApis NOTIFY apisChanged)
    Q_PROPERTY(QStringList devices READ getInputDevices NOTIFY devicesChanged)
    Q_PROPERTY(QStringList outputDevices READ getOutputDevices NOTIFY outputDevicesChanged)
    Q_PROPERTY(int currentApi READ getCurrentApi WRITE setCurrentApi NOTIFY currentApiChanged)
    Q_PROPERTY(int bufferSize READ getBufferSize WRITE setBufferSize NOTIFY bufferSizeChanged)
    Q_PROPERTY(bool isAsioDevice READ isAsioDevice NOTIFY currentDeviceChanged)
    Q_PROPERTY(QStringList asioChannels READ getAsioChannels NOTIFY asioChannelsChanged)
    Q_PROPERTY(QString deviceInfo READ getDeviceInfo NOTIFY deviceInfoChanged)
    Q_PROPERTY(QString sampleRate READ getSampleRate NOTIFY sampleRateChanged)
    Q_PROPERTY(QString bufferInfo READ getBufferInfo NOTIFY bufferInfoChanged)
    Q_PROPERTY(QString statusText READ getStatusText NOTIFY statusTextChanged)
    Q_PROPERTY(QString currentOutput READ getCurrentOutput WRITE setCurrentOutput NOTIFY currentOutputChanged)
    Q_PROPERTY(QString currentInput READ getCurrentInput WRITE setCurrentInput NOTIFY currentInputChanged)
    Q_PROPERTY(QStringList devices READ getDevices NOTIFY devicesChanged)
    Q_PROPERTY(QStringList asioDevices READ getAsioDevices NOTIFY asioDevicesChanged)

    // Getters
    QStringList getAudioApis() const { return m_audioApis; }
    QStringList getInputDevices() const { return m_inputDevices; }
    QStringList getAsioChannels() const { return m_asioChannels; }
    int getCurrentApi() const { return static_cast<int>(m_currentApi); }
    int getBufferSize() const { return m_bufferSize; }
    bool isAsioDevice() const { return m_isAsioDevice; }
    QString getDeviceInfo() const { return m_deviceInfo; }
    QString getSampleRate() const { return m_sampleRate; }
    QString getBufferInfo() const { return m_bufferInfo; }
    QString getStatusText() const;
    QStringList getOutputDevices() const { return m_outputDevices; }
    QString getCurrentOutput() const { return m_currentOutput; }
    QString getCurrentInput() const { return m_currentInput; }
    void setCurrentOutput(const QString& device);
    void setCurrentInput(const QString& device);
    QStringList getDevices() const { 
        // Return proper device list based on API type
        if (m_currentApi == AudioAPI::ASIO) {
            // Get ASIO devices from scanned devices
            return ConfigManager::instance().getScannedDevices("asio");
        }
        return m_inputDevices;
    }
    QStringList getAsioDevices() const {
        return ConfigManager::instance().getScannedDevices("asio");
    }

    // Q_INVOKABLE methods
    Q_INVOKABLE void setCurrentApi(int index);
    Q_INVOKABLE void setBufferSize(int size);
    Q_INVOKABLE void setInputDevice(int index);
    Q_INVOKABLE void showAsioPanel();
    Q_INVOKABLE void save_preset(const QString& path);
    Q_INVOKABLE void load_preset(const QString& path);

    bool initializePortAudio();  // Move from private to public
    bool hasScannedDevices() const;

signals:
    void levelsChanged(float left, float right);
    void devicesChanged();
    void currentApiChanged();
    void bufferSizeChanged();
    void currentDeviceChanged();
    void asioChannelsChanged();
    void apisChanged();
    void deviceInfoChanged();
    void sampleRateChanged();
    void bufferInfoChanged();
    void statusTextChanged();
    void outputDevicesChanged();
    void currentOutputChanged();
    void currentInputChanged();
    void inputDeviceChanged(const QString& device);
    void outputDeviceChanged(const QString& device);
    void engineStatusChanged();
    void asioDevicesChanged();
    void deviceChanged();
    void errorOccurred(const QString& error);

public slots:

private:
    AudioEngine();
    ~AudioEngine();

    // Initialization and cleanup
    void initializeAudio();
    void cleanupAudio();
    void updateAvailableApis();
    void updateDeviceList();
    void updateAsioChannels(int deviceIndex);

    // PortAudio methods
    void cleanupPortAudio();
    void startPortAudioStream(int deviceIndex);
    void stopPortAudioStream();

    // WASAPI methods
    bool initializeWASAPI();
    void cleanupWASAPI();
    bool startWASAPICapture();
    void stopWASAPICapture();

    // ASIO methods
    bool initializeASIO();
    void cleanupASIO();
    bool startASIOCapture();
    void stopASIOCapture();

    // Callback
    static int streamCallback(
        const void* input,
        void* output,
        unsigned long frameCount,
        const PaStreamCallbackTimeInfo* timeInfo,
        PaStreamCallbackFlags statusFlags,
        void* userData
    );

    // Member variables
    AudioAPI m_currentApi;
    bool m_usePortAudio = true;  // Always true now
    int m_bufferSize = 256;  // Add this line
    bool m_isCapturing;
    bool m_isAsioDevice;
    int m_currentDeviceIndex;
    
    QStringList m_audioApis;
    QStringList m_inputDevices;
    QStringList m_asioChannels;
    QStringList m_outputDevices;
    QString m_currentOutput;
    QString m_currentInput;

    // PortAudio
    PaStream* m_paStream;

    // WASAPI
    IMMDeviceEnumerator* m_deviceEnumerator;
    IMMDevice* m_currentDevice;
    IAudioClient* m_audioClient;
    IAudioCaptureClient* m_captureClient;
    WAVEFORMATEX* m_mixFormat;

    static AudioEngine* s_instance;

    QString m_deviceInfo;
    QString m_sampleRate;
    QString m_bufferInfo;
    void updateDeviceInfo();
    void updateStatusText();
    void updateOutputDevices();
    void enumerateWASAPIDevices(EDataFlow dataFlow, QStringList& deviceList);
    bool loadScannedDevices();
    void initDevicesFromConfig();
    void emitEngineStatus();
};