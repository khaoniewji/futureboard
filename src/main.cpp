// src/main.cpp

#include <QApplication>
#include <QPalette>
#include <QStyleFactory>
#include <QSettings>
#include <QStyle>
#include <QSplashScreen>
#include <QPixmap>
#include <QTimer>
#include <QThread>
#include <QMessageBox>
#include <QScreen>
#include <QColor>
#include <QPainter>
#include <QFontDatabase>
#include <QtQuickControls2/QQuickStyle>
#include "gui/desktop/mainwindow.hpp"
#include "core/audioengine/windowsdevices.hpp"
#include "core/logger.hpp"
#include "core/system/performancemeter.hpp"
#include "core/trackmanager.hpp"
#include <QQmlEngine>

class DeviceScanThread : public QThread {
    Q_OBJECT
public:
    explicit DeviceScanThread(WindowsDevices* devices) : m_devices(devices) {}

signals:
    void deviceFound(const QString& deviceName);
    void scanComplete();
    void scanError(const QString& error);

protected:
    void run() override {
        try {
            m_devices->initialDevices();
            emit scanComplete();
        } catch (const std::exception& e) {
            emit scanError(QString::fromStdString(e.what()));
        }
    }

private:
    WindowsDevices* m_devices;
};

class ColoredSplashScreen : public QSplashScreen {
public:
    explicit ColoredSplashScreen(const QPixmap& pixmap, const QFont& font)
        : QSplashScreen(pixmap), m_font(font) {}

protected:
    void drawContents(QPainter* painter) override {
        painter->setPen(Qt::white);
        painter->setFont(m_font);
        QSplashScreen::drawContents(painter);
    }

private:
    QFont m_font;
};

bool isDarkMode() {
    QSettings settings("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
                       QSettings::NativeFormat);
    return settings.value("AppsUseLightTheme", 1).toInt() == 0;
}

void setTheme(QApplication& app, bool dark) {
    app.setStyle(QStyleFactory::create("Fusion"));

    QPalette palette;
    if (dark) {
        palette.setColor(QPalette::Window, QColor(53, 53, 53));
        palette.setColor(QPalette::WindowText, Qt::white);
        palette.setColor(QPalette::Base, QColor(25, 25, 25));
        palette.setColor(QPalette::AlternateBase, QColor(53, 53, 53));
        palette.setColor(QPalette::ToolTipBase, Qt::white);
        palette.setColor(QPalette::ToolTipText, Qt::white);
        palette.setColor(QPalette::Text, Qt::white);
        palette.setColor(QPalette::Button, QColor(53, 53, 53));
        palette.setColor(QPalette::ButtonText, Qt::white);
        palette.setColor(QPalette::BrightText, Qt::red);
        palette.setColor(QPalette::Link, QColor(42, 130, 218));
        palette.setColor(QPalette::Highlight, QColor(42, 130, 218));
        palette.setColor(QPalette::HighlightedText, Qt::black);
        palette.setColor(QPalette::Disabled, QPalette::Text, Qt::darkGray);
        palette.setColor(QPalette::Disabled, QPalette::ButtonText, Qt::darkGray);
    } else {
        palette = app.style()->standardPalette();
    }
    app.setPalette(palette);
}

void centerSplashScreen(QSplashScreen& splash) {
    if (QScreen* screen = QGuiApplication::primaryScreen()) {
        QRect screenGeometry = screen->geometry();
        splash.setGeometry(QStyle::alignedRect(
            Qt::LeftToRight,
            Qt::AlignCenter,
            splash.size(),
            screenGeometry
        ));
    }
}

bool initializeAudioSystem(const std::function<void(const QString&)>& statusCallback) {
    try {
        statusCallback("Initializing Audio System...");
        if (!AudioEngine::instance().initializePortAudio()) {
            throw std::runtime_error("Failed to initialize PortAudio");
        }
        return true;
    } catch (const std::exception& e) {
        QMessageBox::critical(nullptr, "Error",
                            QString("Failed to initialize audio system: %1").arg(e.what()));
        return false;
    }
}

bool scanAudioDevices(const std::function<void(const QString&)>& statusCallback) {
    try {
        QStringList asioDevices, wasapiDevices, mmeDevices;

        // Scan MME devices
        statusCallback("Scanning MME devices...");
        PaHostApiIndex mmeApiIndex = Pa_HostApiTypeIdToHostApiIndex(paMME);
        if (mmeApiIndex != paHostApiNotFound) {
            const PaHostApiInfo* mmeInfo = Pa_GetHostApiInfo(mmeApiIndex);
            for (int i = 0; i < mmeInfo->deviceCount; i++) {
                int deviceIndex = Pa_HostApiDeviceIndexToDeviceIndex(mmeApiIndex, i);
                const PaDeviceInfo* deviceInfo = Pa_GetDeviceInfo(deviceIndex);
                if (deviceInfo) {
                    mmeDevices.append(deviceInfo->name);
                    statusCallback(QString("MME: %1").arg(deviceInfo->name));
                }
            }
        }

        // Scan WASAPI devices
        statusCallback("Scanning WASAPI devices...");
        PaHostApiIndex wasapiApiIndex = Pa_HostApiTypeIdToHostApiIndex(paWASAPI);
        if (wasapiApiIndex != paHostApiNotFound) {
            const PaHostApiInfo* wasapiInfo = Pa_GetHostApiInfo(wasapiApiIndex);
            for (int i = 0; i < wasapiInfo->deviceCount; i++) {
                int deviceIndex = Pa_HostApiDeviceIndexToDeviceIndex(wasapiApiIndex, i);
                const PaDeviceInfo* deviceInfo = Pa_GetDeviceInfo(deviceIndex);
                if (deviceInfo) {
                    wasapiDevices.append(deviceInfo->name);
                    statusCallback(QString("WASAPI: %1").arg(deviceInfo->name));
                }
            }
        }

        // Scan ASIO devices
        statusCallback("Scanning ASIO devices...");
        PaHostApiIndex asioApiIndex = Pa_HostApiTypeIdToHostApiIndex(paASIO);
        if (asioApiIndex != paHostApiNotFound) {
            const PaHostApiInfo* asioInfo = Pa_GetHostApiInfo(asioApiIndex);
            for (int i = 0; i < asioInfo->deviceCount; i++) {
                int deviceIndex = Pa_HostApiDeviceIndexToDeviceIndex(asioApiIndex, i);
                const PaDeviceInfo* deviceInfo = Pa_GetDeviceInfo(deviceIndex);
                if (deviceInfo) {
                    asioDevices.append(deviceInfo->name);
                    statusCallback(QString("ASIO: %1").arg(deviceInfo->name));
                }
            }
        }

        // Save scanned devices to config
        ConfigManager::instance().saveInitialDeviceScan(asioDevices, wasapiDevices, mmeDevices);
        statusCallback("Device scan complete...");
        return true;

    } catch (const std::exception& e) {
        QMessageBox::critical(nullptr, "Error",
                            QString("Failed to scan audio devices: %1").arg(e.what()));
        return false;
    }
}

int main(int argc, char *argv[]) {
    try {
        // Set application attributes
        QCoreApplication::setAttribute(Qt::AA_UseDesktopOpenGL);
        QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
        QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
        QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);

        QApplication app(argc, argv);
        QQuickStyle::setStyle("Basic");

        // Set application metadata
        QCoreApplication::setApplicationName("Futureboard Studio");
        QCoreApplication::setOrganizationName("Khaoniewji Development");
        QCoreApplication::setApplicationVersion("2024.11.03");

        // Handle command line arguments
        QStringList args = app.arguments();
        if (args.contains("--debug")) {
            Logger::setDebugMode(true);
            LOG_INFO("Debug mode enabled");
        }

        // Initialize QML engine
        QQmlEngine engine;
        engine.addImportPath("qrc:/qml/desktop");

        // Register QML types
        qmlRegisterSingletonType<ConfigManager>("com.futureboard.core", 1, 0, 
            "ConfigManager", [](QQmlEngine *engine, QJSEngine *) -> QObject* {
                engine->setObjectOwnership(&ConfigManager::instance(), QQmlEngine::CppOwnership);
                return &ConfigManager::instance();
            });

        qmlRegisterSingletonType<AudioEngine>("com.futureboard.audio", 1, 0, 
            "AudioEngine", [](QQmlEngine *engine, QJSEngine *) -> QObject* {
                engine->setObjectOwnership(&AudioEngine::instance(), QQmlEngine::CppOwnership);
                return &AudioEngine::instance();
            });

        qmlRegisterSingletonType<TrackManager>("com.futureboard.core", 1, 0, 
            "TrackManager", [](QQmlEngine *engine, QJSEngine *) -> QObject* {
                engine->setObjectOwnership(&TrackManager::instance(), QQmlEngine::CppOwnership);
                return &TrackManager::instance();
            });

        qmlRegisterSingletonType<PerformanceMeter>("com.futureboard.system", 1, 0, 
            "PerformanceMeter", [](QQmlEngine *engine, QJSEngine *) -> QObject* {
                engine->setObjectOwnership(&PerformanceMeter::instance(), QQmlEngine::CppOwnership);
                return &PerformanceMeter::instance();
            });

        // Load custom font
        int fontId = QFontDatabase::addApplicationFont(":/fonts/InterDisplay-Medium.otf");
        QFont splashFont;
        if (fontId != -1) {
            QString fontFamily = QFontDatabase::applicationFontFamilies(fontId).at(0);
            splashFont = QFont(fontFamily, 10);
        } else {
            qWarning() << "Failed to load Inter Display Medium font";
            splashFont = QFont("Arial", 10);
        }

        // Set application theme
        setTheme(app, isDarkMode());

        // Initialize splash screen
        ColoredSplashScreen splash(QPixmap(":/images/splash.png"), splashFont);
        splash.setWindowFlags(Qt::WindowStaysOnTopHint | Qt::SplashScreen);
        centerSplashScreen(splash);
        splash.show();

        // Message display function
        auto showMessage = [&splash](const QString& message) {
            splash.showMessage(message, Qt::AlignBottom | Qt::AlignHCenter, Qt::white);
            QApplication::processEvents();
            QThread::msleep(100);
        };

        // Initialize audio system
        if (!initializeAudioSystem(showMessage)) {
            return 1;
        }

        // Scan audio devices
        if (!scanAudioDevices(showMessage)) {
            return 1;
        }

        // Create and show main window
        showMessage("Launching Futureboard Studio...");
        MainWindow mainWindow;
        mainWindow.show();
        splash.finish(&mainWindow);

        // Start application event loop
        return app.exec();

    } catch (const std::exception& e) {
        QMessageBox::critical(nullptr, "Fatal Error",
                            QString("Application failed to start: %1").arg(e.what()));
        return 1;
    } catch (...) {
        QMessageBox::critical(nullptr, "Fatal Error",
                            "Application failed to start due to an unknown error");
        return 1;
    }
}

#include "main.moc"
