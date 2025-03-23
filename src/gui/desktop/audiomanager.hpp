#ifndef AUDIOMANAGER_HPP
#define AUDIOMANAGER_HPP

#include <QDialog>
#include <QComboBox>
#include <QLabel>
#include <QPointer>
#include <QPushButton>
#include <QStackedWidget>
#include "core/audioengine/audioengine.hpp"
#include "core/config/configmanager.hpp"
#include <QString>

class AudioManager : public QDialog {
    Q_OBJECT

public:
    explicit AudioManager(QWidget *parent = nullptr);
    ~AudioManager() override;

protected:
    void closeEvent(QCloseEvent *event) override;
    void showEvent(QShowEvent *event) override;
    bool eventFilter(QObject *watched, QEvent *event) override;

private slots:
    void onApiChanged(int index);
    void onBufferSizeChanged(int index);
    void onAsioControlPanelClicked();
    void onInputDeviceChanged(const QString& device);
    void onOutputDeviceChanged(const QString& device);
    void onEngineStatusChanged();
    void onDeviceInfoChanged();
    void onDevicesChanged();
    void onAsioStatusChanged();
    void onApplySettings();
    void onRevertSettings();
    void onDefaultSettings();
    void updateDeviceInfo();

private:
    void setupUi();
    void setupConnections();
    void updateDeviceLists();
    void saveSettings();
    void loadSettings();
    void createAsioSection();
    void createStandardSection();
    void createBottomBar();
    void updateUIState();
    void showError(const QString& message);
    bool confirmChanges();

    // UI Components
    QComboBox *m_apiSelector;
    QComboBox *m_bufferSelector;
    QComboBox *m_inputSelector;
    QComboBox *m_outputSelector;
    QLabel *m_deviceInfoLabel;
    QLabel *m_statusLabel;
    QStackedWidget *m_deviceStack;
    QWidget *m_asioSection;
    QWidget *m_standardSection;
    QPushButton *m_applyButton;
    QPushButton *m_revertButton;
    QPushButton *m_defaultButton;
    QPushButton *m_asioPanelButton;

    // State tracking
    struct AudioSettings {
        int apiIndex;
        int bufferSize;
        QString inputDevice;
        QString outputDevice;
    };

    AudioSettings m_currentSettings;
    AudioSettings m_pendingSettings;
    bool m_isInitialized;
    bool m_isUpdating;
    bool m_hasUnsavedChanges;
    // References
    AudioEngine &m_audioEngine;
    ConfigManager &m_configManager;

    // Style sheets
    QString m_buttonStyle;
    QString m_comboBoxStyle;
    QString m_labelStyle;
    QString m_sectionStyle;
    
    void initializeStyles();

    static const QStringList BUFFER_SIZES;
};

#endif // AUDIOMANAGER_HPP