// src/gui/desktop/mainwindow.cpp

#include "mainwindow.hpp"
#include "menubar.hpp"
#include "core/trackmanager.hpp"
#include "core/logger.hpp"
#include "audiomanager.hpp"
#include <QQuickWidget>
#include <QVBoxLayout>
#include <QWidget>
#include <QQmlContext>
#include <QQmlEngine>
#include <QUuid>
#include <QScreen>
#include <QMessageBox>
#include <QCloseEvent>
#include <QSettings>
#include <QApplication>

MainWindow::MainWindow(QWidget *parent)
    : QWidget(parent)
    , m_view(new QQuickWidget())
    , m_mixerView(nullptr)
    , m_isInitialized(false)
    , m_isClosing(false)
{
    LOG_DEBUG("Initializing MainWindow");

    try {
        // Install event filter
        qApp->installEventFilter(this);

        // Initialize audio first
        initializeAudio();

        // Setup UI
        setupUi();

        // Setup QML
        setupQml();

        // Restore window state
        restoreWindowState();

        // Connect signals
        connect(&AudioEngine::instance(), &AudioEngine::deviceChanged,
                this, &MainWindow::onAudioDeviceChanged);
        connect(&AudioEngine::instance(), &AudioEngine::errorOccurred,
                this, &MainWindow::onAudioEngineError);

        m_isInitialized = true;
        LOG_DEBUG("MainWindow initialization complete");

    } catch (const std::exception& e) {
        LOG_ERROR("MainWindow initialization failed: " + QString(e.what()));
        showErrorMessage("Initialization Error", 
                        "Failed to initialize main window: " + QString(e.what()));
    }
}

MainWindow::~MainWindow()
{
    m_isClosing = true;

    // Save window state
    if (m_isInitialized) {
        saveWindowState();
    }

    // Cleanup windows
    cleanupWindows();

    // Remove event filter
    qApp->removeEventFilter(this);
}

void MainWindow::setupUi()
{
    // Set the size of the main window
    setMinimumSize(1280, 720);

    // Set up the MenuBar
    MenuBar *menuBar = new MenuBar(this);
    menuBar->setFixedHeight(22);

    // Set up the QQuickWidget to load the QML file
    m_view->setSource(QUrl(QStringLiteral("qrc:/qml/desktop/Main.qml")));
    m_view->setResizeMode(QQuickWidget::SizeRootObjectToView);
    m_view->setFocusPolicy(Qt::TabFocus);

    // Set up layout to include MenuBar and QQuickWidget
    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(0);
    layout->addWidget(menuBar);
    layout->addWidget(m_view);

    setLayout(layout);

    // Connect mixer window action
    if (QAction* mixerAction = menuBar->findChild<QAction*>("actionMixer")) {
        connect(mixerAction, &QAction::triggered, this, &MainWindow::openMixerView);
    }
}

void MainWindow::setupQml()
{
    // Add QML import path
    m_view->engine()->addImportPath("qml");

    // Register ConfigManager with QML
    m_view->rootContext()->setContextProperty("ConfigManager", &ConfigManager::instance());
    m_view->rootContext()->setContextProperty("AudioEngine", &AudioEngine::instance());
    m_view->rootContext()->setContextProperty("TrackManager", &TrackManager::instance());
}

void MainWindow::initializeAudio()
{
    try {
        auto& audio = AudioEngine::instance();
        auto& config = ConfigManager::instance();

        // Initialize PortAudio before loading settings
        if (!audio.initializePortAudio()) {
            throw std::runtime_error("Failed to initialize PortAudio");
        }

        // Load and apply settings
        int savedApi = config.getLastAudioAPI();
        int savedBufferSize = config.getLastBufferSize();
        QString savedInput = config.getLastInputDevice();
        QString savedOutput = config.getLastOutputDevice();

        // Set API first
        audio.setCurrentApi(savedApi);
        audio.setBufferSize(savedBufferSize);

        // Set devices after API is configured
        if (!savedInput.isEmpty()) {
            audio.setCurrentInput(savedInput);
        }
        if (!savedOutput.isEmpty()) {
            audio.setCurrentOutput(savedOutput);
        }

    } catch (const std::exception& e) {
        LOG_ERROR("Audio initialization failed: " + QString(e.what()));
        throw;
    }
}

QQuickWidget* MainWindow::createWindow(const QString& qmlPath, const QString& title)
{
    QString windowId = QUuid::createUuid().toString();
    
    try {
        QQuickWidget* window = new QQuickWidget();
        window->setResizeMode(QQuickWidget::SizeRootObjectToView);
        
        // Set TrackManager for the new window
        window->rootContext()->setContextProperty("TrackManager", &TrackManager::instance());
        
        // Load QML content
        window->setSource(QUrl(qmlPath));
        
        setupWindow(window, title);
        
        // Store window reference
        m_windows[windowId] = window;
        
        // Connect destruction signal
        connect(window, &QQuickWidget::destroyed,
                this, &MainWindow::handleWindowClosed);
        
        LOG_DEBUG("Created new window: " + windowId);
        
        return window;

    } catch (const std::exception& e) {
        LOG_ERROR("Failed to create window: " + QString(e.what()));
        showErrorMessage("Window Creation Error",
                        "Failed to create window: " + QString(e.what()));
        return nullptr;
    }
}

void MainWindow::setupWindow(QQuickWidget* window, const QString& title)
{
    if (!title.isEmpty()) {
        window->setWindowTitle(title);
    }
    
    window->setWindowFlags(Qt::Window | Qt::WindowStaysOnTopHint);
    
    const QRect screenGeometry = QGuiApplication::primaryScreen()->geometry();
    const QSize& size = window->size();
    window->move(screenGeometry.center() - QPoint(size.width() / 2, size.height() / 2));
}

void MainWindow::closeWindow(const QString& windowId)
{
    if (m_windows.contains(windowId)) {
        QQuickWidget* window = m_windows[windowId];
        m_windows.remove(windowId);
        window->close();
        window->deleteLater();
        LOG_DEBUG("Closed window: " + windowId);
    }
}

void MainWindow::handleWindowClosed()
{
    if (QQuickWidget* window = qobject_cast<QQuickWidget*>(sender())) {
        QString windowId = m_windows.key(window);
        if (!windowId.isEmpty()) {
            m_windows.remove(windowId);
            LOG_DEBUG("Window destroyed: " + windowId);
        }
    }
}

void MainWindow::openMixerView()
{
    LOG_DEBUG("Opening MixerView");
    try {
        if (!m_mixerView) {
            m_mixerView = new MixerView();
            m_mixerView->show();
        } else {
            m_mixerView->raise();
            m_mixerView->activateWindow();
        }
    } catch (const std::exception& e) {
        LOG_ERROR("Failed to open MixerView: " + QString(e.what()));
        showErrorMessage("Mixer Error",
                        "Failed to open mixer view: " + QString(e.what()));
    }
}

void MainWindow::onAudioDeviceChanged()
{
    try {
        // Handle audio device changes
        LOG_DEBUG("Audio device changed");
        // Implement any necessary updates
    } catch (const std::exception& e) {
        LOG_ERROR("Error handling audio device change: " + QString(e.what()));
    }
}

void MainWindow::onAudioEngineError(const QString& error)
{
    LOG_ERROR("Audio engine error: " + error);
    showErrorMessage("Audio Error", error);
}

void MainWindow::saveWindowState()
{
    QSettings settings;
    settings.beginGroup("MainWindow");
    settings.setValue("geometry", saveGeometry());
    settings.endGroup();
}

void MainWindow::restoreWindowState()
{
    QSettings settings;
    settings.beginGroup("MainWindow");
    m_windowGeometry = settings.value("geometry").toByteArray();
    m_windowState = settings.value("windowState").toByteArray();
    settings.endGroup();

    if (!m_windowGeometry.isEmpty()) {
        restoreGeometry(m_windowGeometry);
    }
}

void MainWindow::cleanupWindows()
{
    // Close audio managers
    for (QPointer<AudioManager>& manager : m_audioManagers) {
        if (manager) {
            manager->close();
            delete manager;
        }
    }
    m_audioManagers.clear();

    // Close other windows
    qDeleteAll(m_windows);
    m_windows.clear();
    
    if (m_mixerView) {
        delete m_mixerView;
        m_mixerView = nullptr;
    }
}

void MainWindow::closeEvent(QCloseEvent* event)
{
    try {
        if (m_isInitialized && !m_isClosing) {
            saveWindowState();
            cleanupWindows();
        }
        event->accept();
    } catch (const std::exception& e) {
        LOG_ERROR("Error during window close: " + QString(e.what()));
        event->accept(); // Still close even if there's an error
    }
}

bool MainWindow::eventFilter(QObject* watched, QEvent* event)
{
    if (!m_isClosing) {
        try {
            // Add any global event handling here
            return QWidget::eventFilter(watched, event);
        } catch (const std::exception& e) {
            LOG_ERROR("Error in event filter: " + QString(e.what()));
            return false;
        }
    }
    return false;
}

void MainWindow::showErrorMessage(const QString& title, const QString& message)
{
    QMessageBox::critical(this, title, message);
}