#include "trackmanager.hpp"

TrackListModel::TrackListModel(QObject *parent) 
    : QAbstractListModel(parent) {}

int TrackListModel::rowCount(const QModelIndex &parent) const {
    if (parent.isValid()) return 0;
    return m_tracks.size();
}

QVariant TrackListModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid()) return QVariant();
    
    const auto track = m_tracks[index.row()];
    switch (role) {
        case NameRole: return track->name();
        case TypeRole: return track->type();
        case ColorRole: return track->color();
        case VolumeRole: return track->volume();
        case PanRole: return track->pan();
        case MuteRole: return track->mute();
        case SoloRole: return track->solo();
        case LeftLevelRole: return track->leftLevel();
        case RightLevelRole: return track->rightLevel();
        default: return QVariant();
    }
}

QHash<int, QByteArray> TrackListModel::roleNames() const {
    return {
        {NameRole, "name"},
        {TypeRole, "type"},
        {ColorRole, "color"},
        {VolumeRole, "volume"},
        {PanRole, "pan"},
        {MuteRole, "mute"},
        {SoloRole, "solo"},
        {LeftLevelRole, "leftLevel"},
        {RightLevelRole, "rightLevel"}
    };
}

void TrackListModel::addTrack(const QString &name, const QString &type, const QString &color) {
    int index = m_tracks.size();
    beginInsertRows(QModelIndex(), index, index);
    auto track = new Track(this);
    track->setName(name);
    track->setType(type);
    track->setColor(color);
    m_tracks.append(track);
    endInsertRows();
}

void TrackListModel::updateTrack(int index, Track* track) {
    if (index < 0 || index >= m_tracks.size()) return;
    
    auto existing = m_tracks[index];
    existing->setName(track->name());
    existing->setColor(track->color());
    existing->setVolume(track->volume());
    existing->setPan(track->pan());
    existing->setMute(track->mute());
    existing->setSolo(track->solo());
    
    auto modelIndex = createIndex(index, 0);
    emit dataChanged(modelIndex, modelIndex);
}

Track* TrackListModel::getTrack(int index) {
    if (index < 0 || index >= m_tracks.size()) return nullptr;
    return m_tracks[index];
}

void TrackListModel::removeTrack(int index) {
    if (index < 0 || index >= m_tracks.size()) return;
    beginRemoveRows(QModelIndex(), index, index);
    m_tracks.removeAt(index);
    endRemoveRows();
}

TrackManager::TrackManager() 
    : m_trackModel(std::make_unique<TrackListModel>())
    , m_mixerModel(std::make_unique<TrackListModel>()) {}

TrackManager& TrackManager::instance() {
    static TrackManager instance;
    return instance;
}

void TrackManager::syncTrackToMixer(int index) {
    auto track = m_trackModel->getTrack(index);
    if (track) {
        m_mixerModel->updateTrack(index, track);
    }
}

void TrackManager::syncMixerToTrack(int index) {
    auto track = m_mixerModel->getTrack(index);
    if (track) {
        m_trackModel->updateTrack(index, track);
    }
}

void TrackManager::addTrack(const QVariantMap& trackData) {
    if (!m_trackModel) return;

    bool ok;
    int count = trackData["count"].toInt(&ok);
    if (!ok || count < 1) count = 1;
    if (count > 16) count = 16;

    qDebug() << "Adding" << count << "tracks of type" << trackData["type"].toString();

    QString baseType = trackData["type"].toString();
    QString baseColor = trackData["color"].toString();
    QString baseName = trackData["name"].toString();
    int currentCount = m_trackModel->rowCount();

    for (int i = 0; i < count; i++) {
        QString name = QString("%1 %2").arg(baseName).arg(currentCount + i + 1);
        m_trackModel->addTrack(name, baseType, baseColor);
    }

    qDebug() << "Added" << count << "tracks. New total:" << m_trackModel->rowCount();
}
