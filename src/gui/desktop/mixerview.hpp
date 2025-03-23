#ifndef MIXERVIEW_HPP
#define MIXERVIEW_HPP

#include <QQuickWindow>
#include <QQuickView>
#include <QUrl>
#include "core/audioengine/audioengine.hpp"

class MixerView : public QQuickWindow {
    Q_OBJECT

public:
    explicit MixerView(QWindow *parent = nullptr);
    ~MixerView();
    void activateWindow();

private:
    QQuickView *view;
    void setupMixerWindow();
};

#endif // MIXERVIEW_HPP
