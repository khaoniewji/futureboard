// src/gui/desktop/mainwindow.hpp

#ifndef MAINWINDOW_HPP
#define MAINWINDOW_HPP

#include <QWidget>
#include <QQuickWidget>
#include <QHash>
#include <QPointer>
#include "mixerview.hpp"
#include "audiomanager.hpp"
#include "core/audioengine/audioengine.hpp"
#include "core/config/configmanager.hpp"

class MainWindow : public QWidget {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

    QQuickWidget* createWindow(const QString& qmlPath, const QString& title = QString());
    void closeWindow(const QString& windowId);

protected:
    void closeEvent(QCloseEvent* event) override;
    bool eventFilter(QObject* watched, QEvent* event) override;

private slots:
    void openMixerView();
    void handleWindowClosed();
    void onAudioDeviceChanged();
    void onAudioEngineError(const QString& error);

private:
    void setupUi();
    void setupQml();
    void setupWindow(QQuickWidget* window, const QString& title);
    void initializeAudio();
    void saveWindowState();
    void restoreWindowState();
    void cleanupWindows();
    void showErrorMessage(const QString& title, const QString& message);
    
    QQuickWidget* m_view;
    MixerView* m_mixerView;
    QHash<QString, QQuickWidget*> m_windows;
    QList<QPointer<AudioManager>> m_audioManagers;
    
    // Window state
    QByteArray m_windowGeometry;
    QByteArray m_windowState;
    
    // Flags
    bool m_isInitialized;
    bool m_isClosing;
};

#endif // MAINWINDOW_HPP