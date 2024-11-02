// src/gui/desktop/menubar.hpp

#ifndef MENUBAR_HPP
#define MENUBAR_HPP

#include <QWidget>
#include <QMenuBar>
#include <QAction>
#include "menuitem.hpp" // Include the MenuItem header

class MenuBar : public QWidget {
    Q_OBJECT

public:
    explicit MenuBar(QWidget *parent = nullptr);
    ~MenuBar();

private:
    QMenuBar *menuBar; // The actual QMenuBar
    void setupMenu(); // Method to set up the menu
};

#endif // MENUBAR_HPP
