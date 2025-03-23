#pragma once
#include <QString>

namespace Styles {
    const QString BUTTON_STYLE = R"(
        QPushButton {
            background-color: #2d2d2d;
            border: 1px solid #3d3d3d;
            border-radius: 4px;
            color: #ffffff;
            padding: 5px 15px;
            min-width: 80px;
        }
        QPushButton:hover {
            background-color: #3d3d3d;
        }
        QPushButton:pressed {
            background-color: #404040;
        }
        QPushButton:disabled {
            background-color: #252525;
            color: #666666;
        }
    )";

    const QString COMBOBOX_STYLE = R"(
        QComboBox {
            background-color: #2d2d2d;
            border: 1px solid #3d3d3d;
            border-radius: 4px;
            color: #ffffff;
            padding: 5px;
            min-width: 120px;
        }
        QComboBox:hover {
            border: 1px solid #4d4d4d;
        }
        QComboBox::drop-down {
            border: none;
            width: 20px;
        }
        QComboBox::down-arrow {
            image: url(:/images/down-arrow.png);
            width: 12px;
            height: 12px;
        }
        QComboBox QAbstractItemView {
            background-color: #2d2d2d;
            border: 1px solid #3d3d3d;
            color: #ffffff;
            selection-background-color: #404040;
        }
    )";

    const QString LABEL_STYLE = R"(
        QLabel {
            color: #ffffff;
            font-size: 12px;
        }
    )";

    const QString SECTION_STYLE = R"(
        QWidget {
            background-color: #1e1e1e;
            border: 1px solid #3d3d3d;
            border-radius: 6px;
            padding: 10px;
        }
    )";
}
