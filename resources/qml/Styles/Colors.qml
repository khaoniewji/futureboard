pragma Singleton
import QtQuick

QtObject {
    // Primary Colors
    readonly property color background: "#1B1B1B"        // Main background
    readonly property color surface: "#252525"           // Raised surfaces
    readonly property color accent: "#3F7FD4"           // Blue accent like Serum
    readonly property color control: "#2D2D2D"          // Control backgrounds

    // Text Colors
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#808080"
    readonly property color textDisabled: "#404040"

    // Border Colors
    readonly property color borderLight: "#333333"
    readonly property color borderDark: "#121212"

    // Accent States
    readonly property color accentHover: "#4B8FE4"
    readonly property color accentPressed: "#346AB2"

    // Meter Colors
    readonly property color meterBackground: "#202020"
    readonly property color meterGreen: "#39B54A"
    readonly property color meterYellow: "#FFAA00"
    readonly property color meterRed: "#FF3333"
}
