#ifndef MENUBAR_HPP
#define MENUBAR_HPP

#include <QWidget>
#include <QMenuBar>
#include <QAction>
#include "menuitem.hpp"

class MenuBar : public QWidget {
    Q_OBJECT

public:
    explicit MenuBar(QWidget *parent = nullptr);

private:
    QMenuBar *menuBar;
    void setupMenu();
};

#endif // MENUBAR_HPP
