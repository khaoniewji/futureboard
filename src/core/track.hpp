#pragma once
#include <QString>
#include <QObject>

class Track : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(QString color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(float volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(float pan READ pan WRITE setPan NOTIFY panChanged)
    Q_PROPERTY(bool mute READ mute WRITE setMute NOTIFY muteChanged)
    Q_PROPERTY(bool solo READ solo WRITE setSolo NOTIFY soloChanged)
    Q_PROPERTY(float leftLevel READ leftLevel NOTIFY leftLevelChanged)
    Q_PROPERTY(float rightLevel READ rightLevel NOTIFY rightLevelChanged)

public:
    explicit Track(QObject* parent = nullptr);

    QString name() const { return m_name; }
    QString type() const { return m_type; }
    QString color() const { return m_color; }
    float volume() const { return m_volume; }
    float pan() const { return m_pan; }
    bool mute() const { return m_mute; }
    bool solo() const { return m_solo; }
    float leftLevel() const { return m_leftLevel; }
    float rightLevel() const { return m_rightLevel; }

    void setName(const QString& name);
    void setType(const QString& type);
    void setColor(const QString& color);
    void setVolume(float volume);
    void setPan(float pan);
    void setMute(bool mute);
    void setSolo(bool solo);
    void updateLevels(float left, float right);

signals:
    void nameChanged();
    void typeChanged();
    void colorChanged();
    void volumeChanged();
    void panChanged();
    void muteChanged();
    void soloChanged();
    void leftLevelChanged();
    void rightLevelChanged();

private:
    QString m_name;
    QString m_type;
    QString m_color{"#297ACC"};
    float m_volume{0.7f};
    float m_pan{0.0f};
    bool m_mute{false};
    bool m_solo{false};
    float m_leftLevel{0.0f};
    float m_rightLevel{0.0f};
};
