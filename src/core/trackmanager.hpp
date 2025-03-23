#pragma once

#include <QObject>
#include <QAbstractListModel>
#include <memory>
#include "track.hpp"

class TrackListModel : public QAbstractListModel {
    Q_OBJECT

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        TypeRole,
        ColorRole,
        VolumeRole,
        PanRole,
        MuteRole,
        SoloRole,
        LeftLevelRole,
        RightLevelRole
    };

    explicit TrackListModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

public slots:
    void addTrack(const QString &name, const QString &type, const QString &color);
    void removeTrack(int index);
    void updateTrack(int index, Track* track);
    Track* getTrack(int index);

private:
    QList<Track*> m_tracks;
};

class TrackManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(TrackListModel* trackModel READ trackModel CONSTANT)
    Q_PROPERTY(TrackListModel* mixerModel READ mixerModel CONSTANT)

public:
    static TrackManager& instance();
    TrackListModel* trackModel() const { return m_trackModel.get(); }
    TrackListModel* mixerModel() const { return m_mixerModel.get(); }

public slots:
    void syncTrackToMixer(int index);
    void syncMixerToTrack(int index);
    void addTrack(const QVariantMap& trackData);  // Add this method

private:
    TrackManager();
    std::unique_ptr<TrackListModel> m_trackModel;
    std::unique_ptr<TrackListModel> m_mixerModel;
};
