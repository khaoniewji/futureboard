// src/gui/desktop/menubar.cpp

#include "menubar.hpp"
#include "audiomanager.hpp"
#include <QVBoxLayout>
#include <QApplication>
#include <QMessageBox>

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

void MenuBar::setupMenu() {
    QVector<Menu> menus = createMenuItems(); // Create the menu items

    for (const Menu &menu : menus) {
        QMenu *qMenu = menuBar->addMenu(menu.name);
        for (const MenuItem &item : menu.items) {
            QAction *action = qMenu->addAction(item.name);
            if (!item.shortcut.isEmpty()) {
                action->setShortcut(QKeySequence(item.shortcut));
            }
            // Set object names for special actions
            if (item.name == "Mixer") {
                action->setObjectName("actionMixer");
            } else if (item.name == "Audio Manager") {
                action->setObjectName("actionAudioManager");
                connect(action, &QAction::triggered, this, [this]() {
                    try {
                        // Get the main window
                        QWidget* mainWindow = QApplication::activeWindow();
                        
                        // Create AudioManager as a modeless dialog
                        AudioManager* audioManager = new AudioManager(nullptr);
                        audioManager->setAttribute(Qt::WA_DeleteOnClose);
                        audioManager->setWindowFlags(Qt::Dialog | Qt::WindowStaysOnTopHint);
                        audioManager->setWindowModality(Qt::NonModal);
                        
                        // Center the dialog relative to the main window
                        if (mainWindow) {
                            QPoint center = mainWindow->geometry().center();
                            audioManager->move(center.x() - audioManager->width()/2,
                                            center.y() - audioManager->height()/2);
                        }
                        
                        audioManager->show();
                    } catch (const std::exception& e) {
                        qWarning() << "Failed to create AudioManager:" << e.what();
                        QMessageBox::warning(this, tr("Warning"), "Failed to open Audio Manager: " + QString(e.what()));
                    }
                });
            }
        }
    }
}