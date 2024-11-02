// src/gui/desktop/mainwindow.cpp

#include "mainwindow.hpp"
#include "menubar.hpp" // Include the MenuBar header
#include <QQuickView>
#include <QVBoxLayout>
#include <QWidget>

MainWindow::MainWindow(QWidget *parent)
    : QWidget(parent),
      view(new QQuickView()) {

    // Set the size of the main window
    setMinimumSize(1280, 720);

    // Set up the MenuBar
    MenuBar *menuBar = new MenuBar(this); // Instantiate MenuBar
    menuBar->setFixedHeight(22); // Set a fixed height for the menu bar

    // Set up the QQuickView to load the QML file
    view->setSource(QUrl(QStringLiteral("qrc:/qml/desktop/Main.qml")));
    view->setResizeMode(QQuickView::SizeRootObjectToView);

    // Wrap the QQuickView in a QWidget container
    QWidget *container = QWidget::createWindowContainer(view, this);
    // container->setMinimumSize(1280, 720);
    // container->setMaximumSize(1280, 720);
    container->setFocusPolicy(Qt::TabFocus);

    // Set up layout to include MenuBar and QQuickView container
    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setSpacing(0);
    layout->addWidget(menuBar); // Add MenuBar to the layout
    layout->addWidget(container); // Add QQuickView container to the layout

    setLayout(layout);
}

MainWindow::~MainWindow() {
    // Destructor
}
