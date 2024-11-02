// src/gui/desktop/menubar.cpp

#include "menubar.hpp"
#include <QVBoxLayout>

MenuBar::MenuBar(QWidget *parent)
    : QWidget(parent),
      menuBar(new QMenuBar(this)) {

    // Set up the menu
    setupMenu();

    // Create a vertical layout to hold the menu bar
    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setContentsMargins(0, 0, 0, 0); // Set margins to 0
    layout->setSpacing(0); // Set spacing to 0
    layout->addWidget(menuBar); // Add the menu bar to the layout
    setLayout(layout); // Set the layout to the MenuBar widget
}

MenuBar::~MenuBar() {
    // Destructor
}

void MenuBar::setupMenu() {
    QVector<Menu> menus = createMenuItems(); // Create the menu items

    for (const Menu &menu : menus) {
        QMenu *qMenu = menuBar->addMenu(menu.name);
        for (const MenuItem &item : menu.items) {
            QAction *action = qMenu->addAction(item.name);
            if (!item.shortcut.isEmpty()) {
                action->setShortcut(QKeySequence(item.shortcut));
            }
        }
    }
}
