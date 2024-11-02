#ifndef MENUITEM_HPP
#define MENUITEM_HPP

#include <QString>
#include <QVector>

struct MenuItem {
    QString name;       // Name of the menu item
    QString shortcut;   // Shortcut key (optional)
};

struct Menu {
    QString name;               // Name of the menu
    QVector<MenuItem> items;    // List of items in the menu
};

QVector<Menu> createMenuItems();

#endif // MENUITEM_HPP
