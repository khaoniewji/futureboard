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
#include "gui/desktop/mainwindow.hpp"
#include "core/audioengine/windowsdevices.hpp"

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

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    // Set application metadata
    QCoreApplication::setApplicationName("Futureboard Studio");
    QCoreApplication::setOrganizationName("Khaoniewji Development");
    QCoreApplication::setApplicationVersion("2024.11.03");

    // Load custom font
    int fontId = QFontDatabase::addApplicationFont(":/fonts/InterDisplay-Medium.otf");
    QFont splashFont;
    if (fontId != -1) {
        QString fontFamily = QFontDatabase::applicationFontFamilies(fontId).at(0);
        splashFont = QFont(fontFamily, 10); // Adjust size as needed
    } else {
        qWarning("Failed to load Inter Display Medium font");
        splashFont = QFont("Arial", 10); // Fallback font
    }

    // Set app theme
    setTheme(app, isDarkMode());

    // Initialize splash screen with custom font
    ColoredSplashScreen splash(QPixmap(":/images/splash.png"), splashFont);
    splash.setWindowFlags(Qt::WindowStaysOnTopHint | Qt::SplashScreen);
    centerSplashScreen(splash);
    splash.show();

    // Message formatting
    int messageAlign = Qt::AlignBottom | Qt::AlignHCenter;
    auto showMessage = [&splash, messageAlign](const QString& message) {
        splash.showMessage(message, messageAlign, Qt::white);
        QApplication::processEvents();
    };

    // Start initialization sequence
    showMessage("Starting Futureboard Studio...");
    QThread::msleep(100);

    // Initialize audio system
    WindowsDevices audioDevices;
    DeviceScanThread scanThread(&audioDevices);

    // Connect scan thread signals
    QObject::connect(&scanThread, &DeviceScanThread::deviceFound,
        &splash, [&showMessage](const QString& deviceName) {
            showMessage("Detecting Audio Device: " + deviceName);
        }, Qt::QueuedConnection);

    QObject::connect(&scanThread, &DeviceScanThread::scanComplete,
        &splash, [&showMessage]() {
            showMessage("Audio System Initialized");
        }, Qt::QueuedConnection);

    QObject::connect(&scanThread, &DeviceScanThread::scanError,
        &splash, [&showMessage](const QString& error) {
            showMessage("Error: " + error);
            QMessageBox::warning(nullptr, "Initialization Error",
                                 "Failed to initialize audio system: " + error);
        }, Qt::QueuedConnection);

    // Start audio device scanning
    showMessage("Initializing Audio System...");
    scanThread.start();

    // Create and prepare main window
    MainWindow mainWindow;

    // Wait for scan completion
    scanThread.wait();

    // // Update audio devices in main window
    // mainWindow.setAudioDevices(audioDevices.getDeviceList());

    // Final initialization
    showMessage("Launching Futureboard Studio...");
    QThread::msleep(500);

    // Launch application
    mainWindow.show();
    splash.finish(&mainWindow);

    return app.exec();
}

#include "main.moc"
