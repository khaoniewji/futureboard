#include "mixerview.hpp"
#include <QQmlContext>
#include <QQmlEngine>
#include <QVBoxLayout>
#include <QWidget>
#include "core/audioengine/audioengine.hpp"

MixerView::MixerView(QWindow *parent)
    : QQuickWindow(parent)
    , view(new QQuickView)
{
    setTitle("Mixer View");
    setMinimumWidth(1280);
    setMinimumHeight(720);
    
    view->setSource(QUrl(QStringLiteral("qrc:/qml/desktop/Mixer/main.qml")));
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    
    // Set up window container
    QWidget *container = QWidget::createWindowContainer(view, nullptr);
    container->setMinimumSize(1280, 720);
    container->setFocusPolicy(Qt::TabFocus);
    
    setupMixerWindow();
}

void MixerView::setupMixerWindow()
{
    view = new QQuickView();
    
    // Add QML import path
    view->engine()->addImportPath("qml");
    
    // Remove the setContextProperty call since we're using singleton registration
    
    // Additional setup code here
}

void MixerView::activateWindow() {
    show();  // Make sure window is visible
    raise(); // Bring window to front
    requestActivate(); // Request window activation from window manager
}

MixerView::~MixerView()
{
    delete view;
}
