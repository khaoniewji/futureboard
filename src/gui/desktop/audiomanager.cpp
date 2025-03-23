#include "audiomanager.hpp"
#include "styles.hpp"
#include "core/logger.hpp"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFrame>
#include <QMessageBox>
#include <QCloseEvent>
#include <QShowEvent>
#include <QApplication>
#include <QScreen>
#include <QStyle>

const QStringList AudioManager::BUFFER_SIZES = {"64", "128", "256", "512", "1024", "2048"};

AudioManager::AudioManager(QWidget *parent)
    : QDialog(nullptr)  // Always set parent to nullptr for proper window handling
    , m_isInitialized(false)
    , m_isUpdating(false)
    , m_hasUnsavedChanges(false)
    , m_audioEngine(AudioEngine::instance())
    , m_configManager(ConfigManager::instance())
{
    try {
        setWindowFlags(Qt::Dialog | Qt::WindowStaysOnTopHint);
        setWindowModality(Qt::NonModal);
        setWindowTitle("Audio Settings");
        setFixedSize(500, 600);

        // Initialize style sheets
        initializeStyles();

        // Setup UI
        setupUi();
        
        // Setup signal connections
        setupConnections();

        // Load initial settings
        loadSettings();

        // Initialize device lists and info
        updateDeviceLists();
        updateDeviceInfo();
        
        m_isInitialized = true;
        
        LOG_DEBUG("AudioManager initialized successfully");

    } catch (const std::exception& e) {
        LOG_ERROR("AudioManager initialization failed: " + QString(e.what()));
        QMessageBox::critical(this, "Initialization Error",
                            "Failed to initialize Audio Manager: " + QString(e.what()));
        close();
    }
}

AudioManager::~AudioManager()
{
    if (m_hasUnsavedChanges && m_isInitialized) {
        LOG_WARNING("AudioManager destroyed with unsaved changes");
    }
}

void AudioManager::initializeStyles()
{
    m_buttonStyle = Styles::BUTTON_STYLE;
    m_comboBoxStyle = Styles::COMBOBOX_STYLE;
    m_labelStyle = Styles::LABEL_STYLE;
    m_sectionStyle = Styles::SECTION_STYLE;

    // Apply styles to widgets
    m_apiSelector->setStyleSheet(m_comboBoxStyle);
    m_bufferSelector->setStyleSheet(m_comboBoxStyle);
    m_inputSelector->setStyleSheet(m_comboBoxStyle);
    m_outputSelector->setStyleSheet(m_comboBoxStyle);
    
    m_deviceInfoLabel->setStyleSheet(m_labelStyle);
    m_statusLabel->setStyleSheet(m_labelStyle);
    
    m_applyButton->setStyleSheet(m_buttonStyle);
    m_revertButton->setStyleSheet(m_buttonStyle);
    m_defaultButton->setStyleSheet(m_buttonStyle);
    m_asioPanelButton->setStyleSheet(m_buttonStyle);
    
    m_asioSection->setStyleSheet(m_sectionStyle);
    m_standardSection->setStyleSheet(m_sectionStyle);
}

void AudioManager::setupUi()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setSpacing(10);
    mainLayout->setContentsMargins(10, 10, 10, 10);

    // Header
    QFrame *header = new QFrame(this);
    header->setStyleSheet(m_sectionStyle);
    QHBoxLayout *headerLayout = new QHBoxLayout(header);
    QLabel *headerLabel = new QLabel("AUDIO SETTINGS", header);
    headerLabel->setStyleSheet(m_labelStyle + "font-weight: bold;");
    headerLayout->addWidget(headerLabel, 0, Qt::AlignCenter);
    mainLayout->addWidget(header);

    // Audio Engine Section
    QFrame *engineSection = new QFrame(this);
    engineSection->setStyleSheet(m_sectionStyle);
    QVBoxLayout *engineLayout = new QVBoxLayout(engineSection);

    // API Selection
    QHBoxLayout *apiLayout = new QHBoxLayout();
    QLabel *apiLabel = new QLabel("Audio API:", engineSection);
    apiLabel->setStyleSheet(m_labelStyle);
    m_apiSelector = new QComboBox(engineSection);
    m_apiSelector->setStyleSheet(m_comboBoxStyle);
    apiLayout->addWidget(apiLabel);
    apiLayout->addWidget(m_apiSelector, 1);
    engineLayout->addLayout(apiLayout);

    // Buffer Size
    QHBoxLayout *bufferLayout = new QHBoxLayout();
    QLabel *bufferLabel = new QLabel("Buffer Size:", engineSection);
    bufferLabel->setStyleSheet(m_labelStyle);
    m_bufferSelector = new QComboBox(engineSection);
    m_bufferSelector->setStyleSheet(m_comboBoxStyle);
    m_bufferSelector->addItems(BUFFER_SIZES);
    bufferLayout->addWidget(bufferLabel);
    bufferLayout->addWidget(m_bufferSelector, 1);
    engineLayout->addLayout(bufferLayout);

    mainLayout->addWidget(engineSection);

    // Device Stack
    m_deviceStack = new QStackedWidget(this);
    createAsioSection();
    createStandardSection();
    mainLayout->addWidget(m_deviceStack);

    // Status Bar
    QFrame *statusBar = new QFrame(this);
    statusBar->setStyleSheet(m_sectionStyle);
    QHBoxLayout *statusLayout = new QHBoxLayout(statusBar);
    m_statusLabel = new QLabel(statusBar);
    m_statusLabel->setStyleSheet(m_labelStyle);
    statusLayout->addWidget(m_statusLabel);
    mainLayout->addWidget(statusBar);

    // Bottom Bar
    createBottomBar();
    
    // Install event filter
    installEventFilter(this);
}

void AudioManager::createAsioSection()
{
    m_asioSection = new QWidget(m_deviceStack);
    QVBoxLayout *asioLayout = new QVBoxLayout(m_asioSection);

    QLabel *asioLabel = new QLabel("ASIO INTERFACE", m_asioSection);
    asioLabel->setStyleSheet(m_labelStyle + "font-weight: bold;");
    asioLayout->addWidget(asioLabel);

    m_inputSelector = new QComboBox(m_asioSection);
    m_inputSelector->setStyleSheet(m_comboBoxStyle);
    asioLayout->addWidget(m_inputSelector);

    m_deviceInfoLabel = new QLabel(m_asioSection);
    m_deviceInfoLabel->setStyleSheet(m_labelStyle);
    m_deviceInfoLabel->setWordWrap(true);
    asioLayout->addWidget(m_deviceInfoLabel);

    m_asioPanelButton = new QPushButton("ASIO Control Panel", m_asioSection);
    m_asioPanelButton->setStyleSheet(m_buttonStyle);
    asioLayout->addWidget(m_asioPanelButton);

    asioLayout->addStretch();
    m_deviceStack->addWidget(m_asioSection);
}

void AudioManager::createStandardSection()
{
    m_standardSection = new QWidget(m_deviceStack);
    QVBoxLayout *standardLayout = new QVBoxLayout(m_standardSection);

    // Input Device
    QLabel *inputLabel = new QLabel("INPUT DEVICE", m_standardSection);
    inputLabel->setStyleSheet(m_labelStyle + "font-weight: bold;");
    standardLayout->addWidget(inputLabel);

    m_outputSelector = new QComboBox(m_standardSection);
    m_outputSelector->setStyleSheet(m_comboBoxStyle);
    standardLayout->addWidget(m_outputSelector);

    // Output Device
    QLabel *outputLabel = new QLabel("OUTPUT DEVICE", m_standardSection);
    outputLabel->setStyleSheet(m_labelStyle + "font-weight: bold;");
    standardLayout->addWidget(outputLabel);

    QComboBox *outputSelector = new QComboBox(m_standardSection);
    outputSelector->setStyleSheet(m_comboBoxStyle);
    standardLayout->addWidget(outputSelector);

    standardLayout->addStretch();
    m_deviceStack->addWidget(m_standardSection);
}

void AudioManager::createBottomBar()
{
    QHBoxLayout *bottomLayout = new QHBoxLayout();
    
    m_defaultButton = new QPushButton("Defaults", this);
    m_revertButton = new QPushButton("Revert", this);
    m_applyButton = new QPushButton("Apply", this);

    m_defaultButton->setStyleSheet(m_buttonStyle);
    m_revertButton->setStyleSheet(m_buttonStyle);
    m_applyButton->setStyleSheet(m_buttonStyle);

    bottomLayout->addWidget(m_defaultButton);
    bottomLayout->addStretch();
    bottomLayout->addWidget(m_revertButton);
    bottomLayout->addWidget(m_applyButton);

    qobject_cast<QVBoxLayout*>(layout())->addLayout(bottomLayout);
}

void AudioManager::setupConnections()
{
    // ComboBox connections
    connect(m_apiSelector, QOverload<int>::of(&QComboBox::currentIndexChanged),
            this, &AudioManager::onApiChanged);
    connect(m_bufferSelector, QOverload<int>::of(&QComboBox::currentIndexChanged),
            this, &AudioManager::onBufferSizeChanged);
    connect(m_inputSelector, &QComboBox::currentTextChanged,
            this, &AudioManager::onInputDeviceChanged);
    connect(m_outputSelector, &QComboBox::currentTextChanged,
            this, &AudioManager::onOutputDeviceChanged);

    // Button connections
    connect(m_asioPanelButton, &QPushButton::clicked,
            this, &AudioManager::onAsioControlPanelClicked);
    connect(m_applyButton, &QPushButton::clicked,
            this, &AudioManager::onApplySettings);
    connect(m_revertButton, &QPushButton::clicked,
            this, &AudioManager::onRevertSettings);
    connect(m_defaultButton, &QPushButton::clicked,
            this, &AudioManager::onDefaultSettings);

    // AudioEngine connections
    connect(&m_audioEngine, &AudioEngine::deviceChanged,
            this, &AudioManager::onDevicesChanged);
    connect(&m_audioEngine, &AudioEngine::deviceInfoChanged,
            this, &AudioManager::onDeviceInfoChanged);
    connect(&m_audioEngine, &AudioEngine::engineStatusChanged,
            this, &AudioManager::onEngineStatusChanged);
}

void AudioManager::loadSettings()
{
    m_currentSettings.apiIndex = m_configManager.getLastAudioAPI();
    m_currentSettings.bufferSize = m_configManager.getLastBufferSize();
    m_currentSettings.inputDevice = m_configManager.getLastInputDevice();
    m_currentSettings.outputDevice = m_configManager.getLastOutputDevice();

    m_pendingSettings = m_currentSettings;
}

void AudioManager::saveSettings()
{
    if (m_hasUnsavedChanges) {
        m_configManager.setLastAudioAPI(m_pendingSettings.apiIndex);
        m_configManager.setLastBufferSize(m_pendingSettings.bufferSize);
        m_configManager.setLastInputDevice(m_pendingSettings.inputDevice);
        m_configManager.setLastOutputDevice(m_pendingSettings.outputDevice);

        m_currentSettings = m_pendingSettings;
        m_hasUnsavedChanges = false;
        updateUIState();
    }
}

void AudioManager::updateDeviceLists()
{
    if (m_isUpdating) return;
    m_isUpdating = true;

    try {
        // Update API list
        m_apiSelector->clear();
        m_apiSelector->addItems(m_audioEngine.getAudioApis());
        m_apiSelector->setCurrentIndex(m_audioEngine.getCurrentApi());

        // Update device lists
        m_inputSelector->clear();
        m_outputSelector->clear();
        m_inputSelector->addItems(m_audioEngine.getInputDevices());
        m_outputSelector->addItems(m_audioEngine.getOutputDevices());

        // Set current devices
        QString currentInput = m_audioEngine.getCurrentInput();
        QString currentOutput = m_audioEngine.getCurrentOutput();
        if (!currentInput.isEmpty()) {
            m_inputSelector->setCurrentText(currentInput);
        }
        if (!currentOutput.isEmpty()) {
            m_outputSelector->setCurrentText(currentOutput);
        }

        // Show appropriate device section
        bool isAsio = m_audioEngine.isAsioDevice();
        m_deviceStack->setCurrentWidget(isAsio ? m_asioSection : m_standardSection);

    } catch (const std::exception& e) {
        LOG_ERROR("Failed to update device lists: " + QString(e.what()));
        showError("Failed to update device lists: " + QString(e.what()));
    }

    m_isUpdating = false;
}

void AudioManager::updateDeviceInfo()
{
    m_deviceInfoLabel->setText(m_audioEngine.getDeviceInfo());
    m_statusLabel->setText(m_audioEngine.getStatusText());
}

void AudioManager::updateUIState()
{
    m_applyButton->setEnabled(m_hasUnsavedChanges);
    m_revertButton->setEnabled(m_hasUnsavedChanges);
}

void AudioManager::showError(const QString& message)
{
    QMessageBox::critical(this, "Audio Settings Error", message);
}

bool AudioManager::confirmChanges()
{
    if (m_hasUnsavedChanges) {
        QMessageBox::StandardButton reply = QMessageBox::question(this,
            "Unsaved Changes",
            "You have unsaved changes. Do you want to save them?",
            QMessageBox::Yes | QMessageBox::No | QMessageBox::Cancel);

        if (reply == QMessageBox::Yes) {
            onApplySettings();
            return true;
        } else if (reply == QMessageBox::No) {
            onRevertSettings();
            return true;
        }
        return false;
    }
    return true;
}

void AudioManager::closeEvent(QCloseEvent *event)
{
    if (confirmChanges()) {
        event->accept();
    } else {
        event->ignore();
    }
}

void AudioManager::showEvent(QShowEvent *event)
{
    QDialog::showEvent(event);
    updateDeviceLists();
    updateDeviceInfo();
}

bool AudioManager::eventFilter(QObject *watched, QEvent *event)
{
    if (event->type() == QEvent::KeyPress) {
        QKeyEvent *keyEvent = static_cast<QKeyEvent*>(event);
        if (keyEvent->key() == Qt::Key_Escape) {
            if (m_hasUnsavedChanges) {
                if (confirmChanges()) {
                    close();
                }
                return true;
            }
        }
    }
    return QDialog::eventFilter(watched, event);
}

// Slot implementations
void AudioManager::onApiChanged(int index)
{
    if (m_isUpdating) return;
    
    try {
        m_pendingSettings.apiIndex = index;
        m_hasUnsavedChanges = true;
        updateUIState();
        updateDeviceLists();
    } catch (const std::exception& e) {
        LOG_ERROR("Failed to change API: " + QString(e.what()));
        showError("Failed to change API: " + QString(e.what()));
    }
}

void AudioManager::onBufferSizeChanged(int index)
{
    if (m_isUpdating) return;

    try {
        m_pendingSettings.bufferSize = m_bufferSelector->currentText().toInt();
        m_hasUnsavedChanges = true;
        updateUIState();
    } catch (const std::exception& e) {
        LOG_ERROR("Failed to change buffer size: " + QString(e.what()));
        showError("Failed to change buffer size: " + QString(e.what()));
    }
}

void AudioManager::onAsioControlPanelClicked()
{
    try {
        m_audioEngine.showAsioPanel();
    } catch (const std::exception& e) {
        LOG_ERROR("Failed to show ASIO panel: " + QString(e.what()));
        showError("Failed to show ASIO panel: " + QString(e.what()));
    }
}

void AudioManager::onInputDeviceChanged(const QString& device)
{
    if (m_isUpdating) return;

    try {
        m_pendingSettings.inputDevice = device;
        m_hasUnsavedChanges = true;
        updateUIState();
    } catch (const std::exception& e) {
        LOG_ERROR("Failed to change input device: " + QString(e.what()));
        showError("Failed to change input device: " + QString(e.what()));
    }
}

void AudioManager::onOutputDeviceChanged(const QString& device)
{
    if (m_isUpdating) return;

    try {
        m_pendingSettings.outputDevice = device;
        m_hasUnsavedChanges = true;
        updateUIState();
    } catch (const std::exception& e) {
        LOG_ERROR("Failed to change output device: " + QString(e.what()));
        showError("Failed to change output device: " + QString(e.what()));
    }
}

void AudioManager::onEngineStatusChanged()
{
    updateDeviceInfo();
}

void AudioManager::onDeviceInfoChanged()
{
    updateDeviceInfo();
}

void AudioManager::onDevicesChanged()
{
    updateDeviceLists();
}

void AudioManager::onAsioStatusChanged()
{
    bool isAsio = m_audioEngine.isAsioDevice();
    m_deviceStack->setCurrentWidget(isAsio ? m_asioSection : m_standardSection);
    updateDeviceInfo();
}

void AudioManager::onApplySettings()
{
    try {
        m_audioEngine.setCurrentApi(m_pendingSettings.apiIndex);
        m_audioEngine.setBufferSize(m_pendingSettings.bufferSize);
        m_audioEngine.setCurrentInput(m_pendingSettings.inputDevice);
        m_audioEngine.setCurrentOutput(m_pendingSettings.outputDevice);
        
        saveSettings();
        updateDeviceInfo();
        
        LOG_DEBUG("Audio settings applied successfully");
    } catch (const std::exception& e) {
        LOG_ERROR("Failed to apply settings: " + QString(e.what()));
        showError("Failed to apply settings: " + QString(e.what()));
    }
}

void AudioManager::onRevertSettings()
{
    try {
        m_pendingSettings = m_currentSettings;
        m_hasUnsavedChanges = false;
        updateUIState();
        updateDeviceLists();
        updateDeviceInfo();
    } catch (const std::exception& e) {
        LOG_ERROR("Failed to revert settings: " + QString(e.what()));
        showError("Failed to revert settings: " + QString(e.what()));
    }
}

void AudioManager::onDefaultSettings()
{
    try {
        m_pendingSettings.apiIndex = 0;  // First available API
        m_pendingSettings.bufferSize = 512;  // Default buffer size
        m_pendingSettings.inputDevice.clear();
        m_pendingSettings.outputDevice.clear();
        
        m_hasUnsavedChanges = true;
        updateUIState();
        updateDeviceLists();
    } catch (const std::exception& e) {
        LOG_ERROR("Failed to reset to default settings: " + QString(e.what()));
        showError("Failed to reset to default settings: " + QString(e.what()));
    }
}