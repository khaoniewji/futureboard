#include "track.hpp"

Track::Track(QObject* parent) 
    : QObject(parent) {}

void Track::setName(const QString& name) {
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

void Track::setColor(const QString& color) {
    if (m_color != color) {
        m_color = color;
        emit colorChanged();
    }
}

void Track::setVolume(float volume) {
    if (!qFuzzyCompare(m_volume, volume)) {
        m_volume = volume;
        emit volumeChanged();
    }
}

void Track::setPan(float pan) {
    if (!qFuzzyCompare(m_pan, pan)) {
        m_pan = pan;
        emit panChanged();
    }
}

void Track::setMute(bool mute) {
    if (m_mute != mute) {
        m_mute = mute;
        emit muteChanged();
    }
}

void Track::setSolo(bool solo) {
    if (m_solo != solo) {
        m_solo = solo;
        emit soloChanged();
    }
}

void Track::setType(const QString& type) {
    if (m_type != type) {
        m_type = type;
        emit typeChanged();
    }
}

void Track::updateLevels(float left, float right) {
    bool changed = false;
    if (!qFuzzyCompare(m_leftLevel, left)) {
        m_leftLevel = left;
        changed = true;
    }
    if (!qFuzzyCompare(m_rightLevel, right)) {
        m_rightLevel = right;
        changed = true;
    }
    if (changed) {
        emit leftLevelChanged();
        emit rightLevelChanged();
    }
}
