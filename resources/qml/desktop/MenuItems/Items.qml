// MenuItems/Items.qml
pragma Singleton
import QtQml 2.15

QtObject {
    readonly property var menuItems: [
        {
            menu: "File",
            items: [
                { name: "New Project", shortcut: "Ctrl+N" },
                { name: "New Project Template", shortcut: "Ctrl+Shift+N" },
                { name: "Open Project", shortcut: "Ctrl+O" },
                { name: "Save Project", shortcut: "Ctrl+S" },
                { name: "Save As", shortcut: "Ctrl+Shift+S" },
                { name: "Save New Version", shortcut: "Ctrl+Alt+S" },
                { name: "Import Data", shortcut: "Ctrl+M" },
                { name: "Export Data", shortcut: "Ctrl+Shift+M" },
                { name: "Export Audio", shortcut: "Ctrl+R" },
                { name: "Preferences", shortcut: "Ctrl+." },
                { name: "Exit", shortcut: "Alt+F4 / Ctrl+Q" }
            ]
        },
        {
            menu: "Edit",
            items: [
                { name: "Cut", shortcut: "Ctrl+X" },
                { name: "Copy", shortcut: "Ctrl+C" },
                { name: "Paste", shortcut: "Ctrl+V" },
                { name: "Duplicate Clip", shortcut: "Ctrl+D" },
                { name: "Duplicate Track", shortcut: "Ctrl+Shift+D" },
                { name: "Remove Track", shortcut: "Shift+Del" },
                { name: "Add Track", shortcut: "T" },
                { name: "Rename", shortcut: "F2" },
                { name: "Split", shortcut: "B" },
                { name: "Ripple Trim Previous", shortcut: "Q" },
                { name: "Ripple Trim Next", shortcut: "W" }
            ]
        },
        {
            menu: "Project",
            items: [
                { name: "Project Setting" },
                { name: "Automation View" },
                { name: "Auto Color" },
                { name: "Remove Unused Track" },
                { name: "Marker" },
                { name: "XML Data Editor" },
                { name: "Copy data to Project folder" }
            ]
        },
        {
            menu: "Audio",
            items: [
                { name: "Processor" },
                { name: "Fades" },
                { name: "Latency Calculator" },
                { name: "Force Zero Latency" },
                { name: "Freeze Tracks" },
                { name: "Selected Clip to Sampler" },
                { name: "Audio Editor Preferences" }
            ]
        },
        {
            menu: "Window",
            items: [
                { name: "Mixer", shortcut: "F3" },
                { name: "Timeline", shortcut: "F5" },
                { name: "Editor", shortcut: "F4" },
                { name: "Plugin Manager" }
            ]
        },
        {
            menu: "Tools",
            items: [
                { name: "Command Palette", shortcut: "Ctrl+Shift+P" },
                { name: "Enable Keyboard Cursor Editing", shortcut: "Alt+C" },
                { name: "Stem Extractor" },
                { name: "Discord RPC" }
            ]
        },
        {
            menu: "Help",
            items: [
                { name: "Help/Documentation", shortcut: "F1" },
                { name: "About" },
                { name: "GitHub Repository" }
            ]
        }
    ]
}
