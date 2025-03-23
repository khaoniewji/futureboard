// audioengine.cpp
#include "audioengine.hpp"
#include "core/config/configmanager.hpp"
#include <QDebug>
#include <stdexcept>
// #include <asiosys.h>
// #include <asio.h>
// #include <asiodrivers.h>

AudioEngine* AudioEngine::s_instance = nullptr;

AudioEngine& AudioEngine::instance() {
    if (!s_instance) {
        s_instance = new AudioEngine();
    }
    return *s_instance;
}

AudioEngine::AudioEngine() 
    : QObject(nullptr)
    , m_currentApi(AudioAPI::MME)  // Changed from WASAPI to MME
    , m_bufferSize(256)
    , m_isCapturing(false)
    , m_isAsioDevice(false)
    , m_currentDeviceIndex(-1)
    , m_paStream(nullptr)
    , m_deviceEnumerator(nullptr)
    , m_currentDevice(nullptr)
    , m_audioClient(nullptr)
    , m_captureClient(nullptr)
    , m_mixFormat(nullptr)
{
    // Initialize COM for WASAPI
    HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    if (SUCCEEDED(hr)) {
        initializeAudio();
        updateAvailableApis();
    } else {
        qWarning() << "Failed to initialize COM";
    }
}

AudioEngine::~AudioEngine() {
    m_isCapturing = false;
    cleanupAudio();
    
    // Cleanup COM resources
    if (m_mixFormat) CoTaskMemFree(m_mixFormat);
    if (m_captureClient) m_captureClient->Release();
    if (m_audioClient) m_audioClient->Release();
    if (m_currentDevice) m_currentDevice->Release();
    if (m_deviceEnumerator) m_deviceEnumerator->Release();
    
    CoUninitialize();
}

void AudioEngine::initializeAudio() {
    if (m_usePortAudio) {
        initializePortAudio();
        
        // Set default host API to MME
        PaHostApiIndex mmeApiIndex = Pa_HostApiTypeIdToHostApiIndex(paMME);
        if (mmeApiIndex != paHostApiNotFound) {
            m_currentApi = AudioAPI::MME;
        }
    }
    updateAvailableApis();
}

void AudioEngine::cleanupAudio() {
    if (m_usePortAudio) {
        cleanupPortAudio();
    } else {
        switch (m_currentApi) {
            case AudioAPI::WASAPI:
                cleanupWASAPI();
                break;
            case AudioAPI::ASIO:
                cleanupASIO();
                break;
            default:
                break;
        }
    }
}

bool AudioEngine::initializePortAudio() {
    PaError err = Pa_Initialize();
    if (err != paNoError) {
        qWarning() << "PortAudio initialization failed:" << Pa_GetErrorText(err);
        return false;
    }
    return true;
}

void AudioEngine::cleanupPortAudio() {
    stopPortAudioStream();
    Pa_Terminate();
}

void AudioEngine::startPortAudioStream(int deviceIndex) {
    if (m_paStream) {
        Pa_CloseStream(m_paStream);
        m_paStream = nullptr;
    }

    const PaDeviceInfo* deviceInfo = Pa_GetDeviceInfo(deviceIndex);
    if (!deviceInfo) return;

    PaStreamParameters inputParams;
    inputParams.device = deviceIndex;
    inputParams.channelCount = 2;
    inputParams.sampleFormat = paFloat32;
    inputParams.suggestedLatency = deviceInfo->defaultLowInputLatency;
    inputParams.hostApiSpecificStreamInfo = nullptr;

    PaStreamParameters outputParams;
    outputParams.device = deviceIndex;
    outputParams.channelCount = 2;
    outputParams.sampleFormat = paFloat32;
    outputParams.suggestedLatency = deviceInfo->defaultLowOutputLatency;
    outputParams.hostApiSpecificStreamInfo = nullptr;

    PaError err = Pa_OpenStream(
        &m_paStream,
        deviceInfo->maxInputChannels > 0 ? &inputParams : nullptr,
        deviceInfo->maxOutputChannels > 0 ? &outputParams : nullptr,
        44100,
        m_bufferSize,
        paClipOff,
        streamCallback,
        this
    );

    if (err != paNoError) {
        qWarning() << "Error opening stream:" << Pa_GetErrorText(err);
        return;
    }

    err = Pa_StartStream(m_paStream);
    if (err != paNoError) {
        qWarning() << "Error starting stream:" << Pa_GetErrorText(err);
        Pa_CloseStream(m_paStream);
        m_paStream = nullptr;
        return;
    }

    m_isCapturing = true;
}

void AudioEngine::stopPortAudioStream() {
    if (m_paStream) {
        m_isCapturing = false;
        
        try {
            if (Pa_IsStreamActive(m_paStream) == 1) {
                Pa_StopStream(m_paStream);
            }
            Pa_CloseStream(m_paStream);
        } catch (...) {
            qWarning() << "Error stopping PortAudio stream";
        }
        
        m_paStream = nullptr;
    }
}

void AudioEngine::updateAvailableApis() {
    m_audioApis.clear();
    m_isAsioDevice = false;
    
    qDebug() << "Scanning available audio APIs...";
    
    // Always add MME first since it's our default
    PaHostApiIndex mmeApiIndex = Pa_HostApiTypeIdToHostApiIndex(paMME);
    if (mmeApiIndex != paHostApiNotFound) {
        const PaHostApiInfo* mmeInfo = Pa_GetHostApiInfo(mmeApiIndex);
        qDebug() << "MME devices found:" << mmeInfo->deviceCount;
        m_audioApis.append("MME");
    }
    
    // Add ASIO next if available
    PaHostApiIndex asioApiIndex = Pa_HostApiTypeIdToHostApiIndex(paASIO);
    if (asioApiIndex != paHostApiNotFound) {
        const PaHostApiInfo* asioInfo = Pa_GetHostApiInfo(asioApiIndex);
        qDebug() << "ASIO devices found:" << asioInfo->deviceCount;
        if (asioInfo->deviceCount > 0) {
            m_audioApis.append("ASIO");
        }
    }
    
    // Add WASAPI last
    PaHostApiIndex wasapiApiIndex = Pa_HostApiTypeIdToHostApiIndex(paWASAPI);
    if (wasapiApiIndex != paHostApiNotFound) {
        const PaHostApiInfo* wasapiInfo = Pa_GetHostApiInfo(wasapiApiIndex);
        qDebug() << "WASAPI devices found:" << wasapiInfo->deviceCount;
        m_audioApis.append("WASAPI");
    }
    
    updateDeviceList();
    emit apisChanged();
}

bool AudioEngine::hasScannedDevices() const {
    return !ConfigManager::instance().getScannedDevices("mme").isEmpty() ||
           !ConfigManager::instance().getScannedDevices("asio").isEmpty() ||
           !ConfigManager::instance().getScannedDevices("wasapi").isEmpty();
}

void AudioEngine::updateDeviceList() {
    m_inputDevices.clear();
    m_outputDevices.clear();

    if (hasScannedDevices()) {
        // Load from config if already scanned
        initDevicesFromConfig();
        return;
    }

    PaHostApiIndex apiIndex = -1;
    switch (m_currentApi) {
        case AudioAPI::MME:
            apiIndex = Pa_HostApiTypeIdToHostApiIndex(paMME);
            qDebug() << "Scanning MME devices...";
            break;
        case AudioAPI::ASIO:
            apiIndex = Pa_HostApiTypeIdToHostApiIndex(paASIO);
            qDebug() << "Scanning ASIO devices...";
            break;
        case AudioAPI::WASAPI:
            apiIndex = Pa_HostApiTypeIdToHostApiIndex(paWASAPI);
            qDebug() << "Scanning WASAPI devices...";
            break;
    }
    
    if (apiIndex != paHostApiNotFound) {
        const PaHostApiInfo* apiInfo = Pa_GetHostApiInfo(apiIndex);
        if (apiInfo) {
            for (int i = 0; i < apiInfo->deviceCount; i++) {
                int deviceIndex = Pa_HostApiDeviceIndexToDeviceIndex(apiIndex, i);
                const PaDeviceInfo* deviceInfo = Pa_GetDeviceInfo(deviceIndex);
                if (deviceInfo) {
                    QString name = QString::fromLatin1(deviceInfo->name); // Changed from fromUtf8 to fromLatin1
                    name = name.trimmed(); // Remove any trailing whitespace
                    
                    if (m_currentApi == AudioAPI::ASIO) {
                        // Debug output
                        qDebug() << "ASIO Device" << i + 1 << "full name:" << name;
                        
                        if (deviceInfo->maxInputChannels > 0 || deviceInfo->maxOutputChannels > 0) {
                            m_inputDevices.append(name);
                            m_outputDevices.append(name);
                            m_currentDeviceIndex = deviceIndex;
                            updateDeviceInfo();
                        }
                    } else {
                        // Debug output for other APIs
                        if (deviceInfo->maxInputChannels > 0) {
                            qDebug() << "Input Device" << i + 1 << "full name:" << name;
                            m_inputDevices.append(name);
                        }
                        if (deviceInfo->maxOutputChannels > 0) {
                            qDebug() << "Output Device" << i + 1 << "full name:" << name;
                            m_outputDevices.append(name);
                        }
                    }
                }
            }
        }
    }
    
    qDebug() << "Current API:" << (m_currentApi == AudioAPI::ASIO ? "ASIO" : 
                                  m_currentApi == AudioAPI::MME ? "MME" : "WASAPI");
    qDebug() << "Input devices:" << m_inputDevices;
    qDebug() << "Output devices:" << m_outputDevices;
    
    // Update device selections
    if (m_currentApi == AudioAPI::ASIO) {
        // For ASIO, use the same device for input and output
        if (!m_inputDevices.isEmpty()) {
            QString device = m_inputDevices.first();
            m_currentInput = device;
            m_currentOutput = device;
            m_isAsioDevice = true;
            
            // Update ASIO channels
            if (m_currentDeviceIndex >= 0) {
                updateAsioChannels(m_currentDeviceIndex);
            }
        }
    } else {
        m_isAsioDevice = false;
        // Set default devices for MME/WASAPI
        if (!m_inputDevices.isEmpty()) {
            m_currentInput = m_inputDevices.first();
        }
        if (!m_outputDevices.isEmpty()) {
            m_currentOutput = m_outputDevices.first();
        }
    }
    
    emit devicesChanged();
    emit outputDevicesChanged();
    emit currentInputChanged();
    emit currentOutputChanged();
    emit currentDeviceChanged();
}

void AudioEngine::initDevicesFromConfig() {
    QString apiName = m_currentApi == AudioAPI::MME ? "mme" :
                     m_currentApi == AudioAPI::ASIO ? "asio" : "wasapi";
    
    QStringList devices = ConfigManager::instance().getScannedDevices(apiName);
    
    if (m_currentApi == AudioAPI::ASIO) {
        m_inputDevices = devices;
        m_outputDevices = devices;
        m_isAsioDevice = true;
        
        if (!devices.isEmpty()) {
            m_currentInput = devices.first();
            m_currentOutput = devices.first();
            
            // Find device index for ASIO info
            PaHostApiIndex asioApiIndex = Pa_HostApiTypeIdToHostApiIndex(paASIO);
            if (asioApiIndex != paHostApiNotFound) {
                for (int i = 0; i < Pa_GetDeviceCount(); i++) {
                    const PaDeviceInfo* deviceInfo = Pa_GetDeviceInfo(i);
                    if (deviceInfo && deviceInfo->hostApi == asioApiIndex &&
                        QString::fromLatin1(deviceInfo->name) == devices.first()) {
                        m_currentDeviceIndex = i;
                        updateDeviceInfo();
                        break;
                    }
                }
            }
        }
    } else {
        // For MME/WASAPI, filter input/output devices
        for (const QString& device : devices) {
            // Check device capabilities using PortAudio
            for (int i = 0; i < Pa_GetDeviceCount(); i++) {
                const PaDeviceInfo* deviceInfo = Pa_GetDeviceInfo(i);
                if (deviceInfo && QString::fromLatin1(deviceInfo->name) == device) {
                    if (deviceInfo->maxInputChannels > 0) {
                        m_inputDevices.append(device);
                    }
                    if (deviceInfo->maxOutputChannels > 0) {
                        m_outputDevices.append(device);
                    }
                    break;
                }
            }
        }
    }

    emit devicesChanged();
    emit outputDevicesChanged();
    emit currentInputChanged();
    emit currentOutputChanged();
    emit currentDeviceChanged();
}

void AudioEngine::setCurrentApi(int index) {
    if (index < 0 || index >= m_audioApis.size()) return;
    
    AudioAPI newApi;
    if (m_audioApis[index] == "MME") {
        newApi = AudioAPI::MME;
    }
    else if (m_audioApis[index] == "ASIO") {
        newApi = AudioAPI::ASIO;
    }
    else if (m_audioApis[index] == "WASAPI") {
        newApi = AudioAPI::WASAPI;
    }
    else {
        return;
    }
    
    if (m_currentApi != newApi) {
        cleanupAudio();
        m_currentApi = newApi;
        m_isAsioDevice = (newApi == AudioAPI::ASIO);
        
        // Clear current selections
        m_currentInput.clear();
        m_currentOutput.clear();
        m_currentDeviceIndex = -1;
        
        // Reinitialize with new API
        initializeAudio();
        updateDeviceList();
        
        // Emit all necessary signals
        emit currentApiChanged();
        emit currentDeviceChanged();
        emit devicesChanged();
        emit currentInputChanged();
        emit currentOutputChanged();
        updateDeviceInfo();
    }
}

void AudioEngine::setBufferSize(int size) {
    if (m_bufferSize != size) {
        m_bufferSize = size;
        if (m_isCapturing) {
            cleanupAudio();
            initializeAudio();
        }
        emit bufferSizeChanged();
    }
}

void AudioEngine::setInputDevice(int index) {
    if (index >= 0 && index < m_inputDevices.size()) {
        // Stop current stream if any
        if (m_isCapturing) {
            cleanupAudio();
        }
        
        m_currentDeviceIndex = index;
        
        if (m_usePortAudio) {
            // Get actual PortAudio device index
            int paDeviceIndex = -1;
            int deviceCount = 0;
            
            // Find the corresponding PortAudio device index
            int numDevices = Pa_GetDeviceCount();
            for (int i = 0; i < numDevices; i++) {
                const PaDeviceInfo* deviceInfo = Pa_GetDeviceInfo(i);
                if (deviceInfo && deviceInfo->maxInputChannels > 0) {
                    const PaHostApiInfo* apiInfo = Pa_GetHostApiInfo(deviceInfo->hostApi);
                    if (apiInfo && static_cast<int>(m_currentApi) == apiInfo->type) {
                        if (deviceCount == index) {
                            paDeviceIndex = i;
                            break;
                        }
                        deviceCount++;
                    }
                }
            }
            
            if (paDeviceIndex >= 0) {
                try {
                    startPortAudioStream(paDeviceIndex);
                    if (m_isAsioDevice) {
                        updateAsioChannels(paDeviceIndex);
                        updateDeviceInfo();  // Add this line
                    }
                } catch (const std::exception& e) {
                    qWarning() << "Error starting audio stream:" << e.what();
                    m_isCapturing = false;
                    m_paStream = nullptr;
                }
            }
        } else {
            switch (m_currentApi) {
                case AudioAPI::WASAPI:
                    startWASAPICapture();
                    break;
                case AudioAPI::ASIO:
                    startASIOCapture();
                    break;
                default:
                    break;
            }
        }
        
        emit currentDeviceChanged();
    }
}

void AudioEngine::updateAsioChannels(int deviceIndex) {
    m_asioChannels.clear();
    
    if (m_isAsioDevice) {
        if (m_usePortAudio) {
            const PaDeviceInfo* deviceInfo = Pa_GetDeviceInfo(deviceIndex);
            if (deviceInfo) {
                for (int i = 0; i < deviceInfo->maxInputChannels; i++) {
                    m_asioChannels.append(QString("Input %1").arg(i + 1));
                }
            }
        }
    }
    
    emit asioChannelsChanged();
}

void AudioEngine::showAsioPanel() {
    if (m_isAsioDevice && m_currentDeviceIndex >= 0) {
        PaError err = PaAsio_ShowControlPanel(m_currentDeviceIndex, nullptr);
        if (err != paNoError) {
            qWarning() << "Failed to show ASIO control panel:" << Pa_GetErrorText(err);
        }
    }
}

int AudioEngine::streamCallback(
    const void* input,
    void* output,
    unsigned long frameCount,
    const PaStreamCallbackTimeInfo* timeInfo,
    PaStreamCallbackFlags statusFlags,
    void* userData
) {
    AudioEngine* engine = static_cast<AudioEngine*>(userData);
    const float* in = static_cast<const float*>(input);
    
    if (in && engine->m_isCapturing) {
        float leftSum = 0.0f, rightSum = 0.0f;
        for (unsigned long i = 0; i < frameCount; i++) {
            leftSum += std::abs(in[i * 2]);
            rightSum += std::abs(in[i * 2 + 1]);
        }
        
        emit engine->levelsChanged(leftSum / frameCount, rightSum / frameCount);
    }
    
    return paContinue;
}

void AudioEngine::save_preset(const QString& path) {
    qDebug() << "Saving preset to:" << path;
}

void AudioEngine::load_preset(const QString& path) {
    qDebug() << "Loading preset from:" << path;
}

// WASAPI methods
bool AudioEngine::initializeWASAPI() {
    HRESULT hr = CoCreateInstance(
        __uuidof(MMDeviceEnumerator),
        nullptr,
        CLSCTX_ALL,
        __uuidof(IMMDeviceEnumerator),
        (void**)&m_deviceEnumerator
    );
    return SUCCEEDED(hr);
}

void AudioEngine::cleanupWASAPI() {
    stopWASAPICapture();
}

bool AudioEngine::startWASAPICapture() {
    // TODO: Implement WASAPI capture
    return false;
}

void AudioEngine::stopWASAPICapture() {
    // TODO: Implement WASAPI cleanup
}

// ASIO Direct methods
bool AudioEngine::initializeASIO() {
    // Simply check if ASIO is available through PortAudio
    const PaHostApiInfo* asioApi = Pa_GetHostApiInfo(Pa_HostApiTypeIdToHostApiIndex(paASIO));
    return asioApi != nullptr;
}

void AudioEngine::cleanupASIO() {
    stopASIOCapture();
}

bool AudioEngine::startASIOCapture() {
    // TODO: Implement direct ASIO capture
    return false;
}

void AudioEngine::stopASIOCapture() {
    // TODO: Implement direct ASIO cleanup
}

QString AudioEngine::getStatusText() const {
    return QString("Current Project: Untitled.ftbp / A = 440hz / %1 / %2 %3")
        .arg(m_sampleRate)
        .arg(m_deviceInfo)
        .arg(m_bufferInfo);
}

void AudioEngine::updateStatusText() {
    emit statusTextChanged();
}

void AudioEngine::updateDeviceInfo() {
    if (m_isAsioDevice) {
        const PaDeviceInfo* deviceInfo = Pa_GetDeviceInfo(m_currentDeviceIndex);
        if (deviceInfo) {
            m_deviceInfo = QString("ASIO: %1").arg(deviceInfo->name);
            m_sampleRate = QString("%1 Hz").arg(deviceInfo->defaultSampleRate);
            m_bufferInfo = QString("%1 smp %2 ms")
                .arg(m_bufferSize)
                .arg((m_bufferSize / deviceInfo->defaultSampleRate * 1000.0), 0, 'f', 2);
            
            emit deviceInfoChanged();
            emit sampleRateChanged();
            emit bufferInfoChanged();
            updateStatusText();
            emit engineStatusChanged();
        }
    }
}

void AudioEngine::setCurrentOutput(const QString& device) {
    if (!m_isAsioDevice && m_currentOutput != device) {
        m_currentOutput = device;
        emit currentOutputChanged();
        emit outputDeviceChanged(device);
        
        // Save to config
        ConfigManager::instance().setLastOutputDevice(device);
        emitEngineStatus();
    }
}

void AudioEngine::setCurrentInput(const QString& device) {
    if (m_currentInput != device) {
        m_currentInput = device;
        emit currentInputChanged();
        emit inputDeviceChanged(device);
        
        // Find and set device index
        int index = m_inputDevices.indexOf(device);
        if (index >= 0) {
            setInputDevice(index);
        }
        
        // Save to config
        ConfigManager::instance().setLastInputDevice(device);
        emitEngineStatus();
    }
}

void AudioEngine::emitEngineStatus() {
    updateDeviceInfo();
    updateStatusText();
    emit engineStatusChanged();
}