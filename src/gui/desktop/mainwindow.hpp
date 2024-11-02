// src/gui/desktop/mainwindow.hpp

#ifndef MAINWINDOW_HPP
#define MAINWINDOW_HPP

#include <QWidget>
#include <QQuickView>

class MainWindow : public QWidget {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private:
    QQuickView *view; // QQuickView for displaying QML content
    void setupLayout(); // Method to set up the layout
};

#endif // MAINWINDOW_HPP
