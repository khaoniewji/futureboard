#include "menubar.hpp"
#include "menuitem.hpp"

QVector<Menu> createMenuItems() {
    QVector<Menu> menuItems;

    // Populate "File" menu
    Menu fileMenu;
    fileMenu.name = "File";
    fileMenu.items = {
        {"New Project", "Ctrl+N"},
        {"New Project Template", "Ctrl+Shift+N"},
        {"Open Project", "Ctrl+O"},
        {"Save Project", "Ctrl+S"},
        {"Save As", "Ctrl+Shift+S"},
        {"Save New Version", "Ctrl+Alt+S"},
        {"Import Data", "Ctrl+M"},
        {"Export Data", "Ctrl+Shift+M"},
        {"Export Audio", "Ctrl+R"},
        {"Preferences", "Ctrl+."},
        {"Exit", "Alt+F4 / Ctrl+Q"}
    };
    menuItems.append(fileMenu);

    // Populate "Edit" menu
    Menu editMenu;
    editMenu.name = "Edit";
    editMenu.items = {
        {"Cut", "Ctrl+X"},
        {"Copy", "Ctrl+C"},
        {"Paste", "Ctrl+V"},
        {"Duplicate Clip", "Ctrl+D"},
        {"Duplicate Track", "Ctrl+Shift+D"},
        {"Remove Track", "Shift+Del"},
        {"Add Track", "T"},
        {"Rename", "F2"},
        {"Split", "B"},
        {"Ripple Trim Previous", "Q"},
        {"Ripple Trim Next", "W"}
    };
    menuItems.append(editMenu);

    // Populate "Project" menu
    Menu projectMenu;
    projectMenu.name = "Project";
    projectMenu.items = {
        {"Project Setting"},
        {"Automation View"},
        {"Auto Color"},
        {"Remove Unused Track"},
        {"Marker"},
        {"XML Data Editor"},
        {"Copy data to Project folder"}
    };
    menuItems.append(projectMenu);

    // Populate "Audio" menu
    Menu audioMenu;
    audioMenu.name = "Audio";
    audioMenu.items = {
        {"Processor"},
        {"Fades"},
        {"Latency Calculator"},
        {"Force Zero Latency"},
        {"Freeze Tracks"},
        {"Selected Clip to Sampler"},
        {"Audio Editor Preferences"}
    };
    menuItems.append(audioMenu);

    // Populate "Window" menu
    Menu windowMenu;
    windowMenu.name = "Window";
    windowMenu.items = {
        {"Mixer", "F3"},
        {"Timeline", "F5"},
        {"Editor", "F4"},
        {"Audio Manager"},
        {"Plugin Manager"}
    };
    menuItems.append(windowMenu);

    // Populate "Tools" menu
    Menu toolsMenu;
    toolsMenu.name = "Tools";
    toolsMenu.items = {
        {"Command Palette", "Ctrl+Shift+P"},
        {"Enable Keyboard Cursor Editing", "Alt+C"},
        {"Stem Extractor"},
        {"Discord RPC"}
    };
    menuItems.append(toolsMenu);

    // Populate "Help" menu
    Menu helpMenu;
    helpMenu.name = "Help";
    helpMenu.items = {
        {"Help/Documentation", "F1"},
        {"About"},
        {"GitHub Repository"}
    };
    menuItems.append(helpMenu);

    return menuItems;
}
