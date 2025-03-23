from PySide6.QtWidgets import (QWidget, QVBoxLayout, QHBoxLayout, QComboBox, 
                              QPushButton, QLabel, QFrame, QSizePolicy)
from PySide6.QtCore import Qt
from PySide6.QtGui import QFont, QColor, QPalette
import json

class StyleConstants:
    MAIN_COLOR = "#CC3636"
    BG_COLOR = "#191D21"
    SECTION_COLOR = "#272C32"
    CONTROL_BG_COLOR = "#353B41"
    BORDER_COLOR = "#0A0B08"
    TEXT_COLOR = "#FFFFFF"

class ModernComboBox(QComboBox):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setFixedHeight(30)
        self.setStyleSheet(f"""
            QComboBox {{
                background-color: {StyleConstants.CONTROL_BG_COLOR};
                border: 1px solid {StyleConstants.BORDER_COLOR};
                border-radius: 2px;
                color: white;
                padding-left: 8px;
                font-family: Inter;
            }}
            QComboBox::drop-down {{
                border: none;
            }}
            QComboBox::down-arrow {{
                image: url(down_arrow.png);
                width: 12px;
                height: 12px;
            }}
            QComboBox QAbstractItemView {{
                background-color: {StyleConstants.BG_COLOR};
                border: 1px solid {StyleConstants.BORDER_COLOR};
                selection-background-color: {StyleConstants.MAIN_COLOR};
            }}
        """)

class ModernButton(QPushButton):
    def __init__(self, text, parent=None):
        super().__init__(text, parent)
        self.setFixedHeight(30)
        self.setStyleSheet(f"""
            QPushButton {{
                background-color: {StyleConstants.CONTROL_BG_COLOR};
                border: 1px solid {StyleConstants.BORDER_COLOR};
                border-radius: 2px;
                color: white;
                font-family: Inter;
            }}
            QPushButton:hover {{
                background-color: #404549;
            }}
            QPushButton:pressed {{
                background-color: {StyleConstants.MAIN_COLOR};
            }}
        """)

class SectionFrame(QFrame):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setStyleSheet(f"""
            QFrame {{
                background-color: {StyleConstants.SECTION_COLOR};
                border: 1px solid {StyleConstants.BORDER_COLOR};
            }}
        """)

class AudioManagerWidget(QWidget):
    def __init__(self, config_manager, parent=None):
        super().__init__(parent)
        self.config_manager = config_manager
        self.current_devices = []
        self.current_output_devices = []
        self.is_asio_device = False
        self.setup_ui()
        self.load_devices_for_api(self.config_manager.lastAudioAPI)
        
    def load_devices_for_api(self, api_index):
        with open("audio_config.json", "r") as f:
            config = json.load(f)
            api_map = {0: "mme", 1: "asio", 2: "wasapi"}
            api_key = api_map.get(api_index, "mme")
            
            self.current_devices = config["deviceScan"][api_key]
            self.is_asio_device = (api_index == 1)
            
            if self.is_asio_device:
                self.current_output_devices = self.current_devices
            else:
                self.current_output_devices = [d for d in self.current_devices 
                                             if "Output" in d or "Speakers" in d]
            
            # Update UI
            self.update_device_ui()
    
    def update_device_ui(self):
        self.asio_section.setVisible(self.is_asio_device)
        self.mme_section.setVisible(not self.is_asio_device)
        
        if self.is_asio_device:
            self.asio_device_selector.clear()
            self.asio_device_selector.addItems(self.current_devices)
            last_device = self.config_manager.lastInputDevice
            if last_device in self.current_devices:
                self.asio_device_selector.setCurrentText(last_device)
        else:
            self.input_selector.clear()
            self.input_selector.addItems(self.current_devices)
            self.output_selector.clear()
            self.output_selector.addItems(self.current_output_devices)
            
            # Restore last selected devices
            last_input = self.config_manager.lastInputDevice
            last_output = self.config_manager.lastOutputDevice
            if last_input in self.current_devices:
                self.input_selector.setCurrentText(last_input)
            if last_output in self.current_output_devices:
                self.output_selector.setCurrentText(last_output)

    def setup_ui(self):
        self.setWindowTitle("Audio Settings")
        self.setFixedSize(500, 600)


        main_layout = QVBoxLayout(self)
        main_layout.setSpacing(1)
        main_layout.setContentsMargins(0, 0, 0, 0)

        # Header
        header = QFrame()
        header.setFixedHeight(32)
        header.setStyleSheet(f"background-color: {StyleConstants.MAIN_COLOR};")
        header_layout = QHBoxLayout(header)
        header_label = QLabel("AUDIO SETTINGS")
        header_label.setStyleSheet("color: white; font-weight: bold; font-family: Inter;")
        header_layout.addWidget(header_label, alignment=Qt.AlignCenter)
        main_layout.addWidget(header)

        # Audio Engine Section
        engine_section = SectionFrame()
        engine_layout = QVBoxLayout(engine_section)
        engine_layout.setContentsMargins(12, 12, 12, 12)
        engine_layout.setSpacing(8)

        engine_header = QLabel("AUDIO ENGINE")
        engine_header.setStyleSheet("color: white; font-weight: bold; font-family: Inter; border: none;")
        engine_layout.addWidget(engine_header)

        # Driver selection
        driver_layout = QHBoxLayout()
        driver_label = QLabel("Driver")
        driver_label.setFixedWidth(80)
        driver_label.setStyleSheet("color: white; font-family: Inter; border: none;")
        self.api_selector = ModernComboBox()
        self.api_selector.addItems(["MME", "ASIO", "WASAPI"])
        driver_layout.addWidget(driver_label)
        driver_layout.addWidget(self.api_selector)
        engine_layout.addLayout(driver_layout)

        # Buffer size
        buffer_layout = QHBoxLayout()
        buffer_label = QLabel("Buffer Size")
        buffer_label.setFixedWidth(80)
        buffer_label.setStyleSheet("color: white; font-family: Inter;  border: none;")
        self.buffer_selector = ModernComboBox()
        self.buffer_selector.addItems(["64", "128", "256", "512", "1024", "2048"])
        buffer_layout.addWidget(buffer_label)
        buffer_layout.addWidget(self.buffer_selector)
        engine_layout.addLayout(buffer_layout)

        main_layout.addWidget(engine_section)

        # Device Selection Section
        device_section = SectionFrame()
        device_layout = QVBoxLayout(device_section)
        device_layout.setContentsMargins(12, 12, 12, 12)
        device_layout.setSpacing(8)

        device_header = QLabel("AUDIO DEVICES")
        device_header.setStyleSheet("color: white; font-weight: bold; font-family: Inter;  border: none;")
        device_layout.addWidget(device_header)

        # ASIO Section
        self.asio_section = QWidget()
        asio_layout = QVBoxLayout(self.asio_section)
        asio_layout.setContentsMargins(0, 0, 0, 0)
        asio_layout.setSpacing(8)

        interface_layout = QHBoxLayout()
        interface_label = QLabel("Interface")
        interface_label.setFixedWidth(80)
        interface_label.setStyleSheet("color: white; font-family: Inter;  border: none;")
        self.asio_device_selector = ModernComboBox()
        interface_layout.addWidget(interface_label)
        interface_layout.addWidget(self.asio_device_selector)
        asio_layout.addLayout(interface_layout)

        self.device_info_label = QLabel()
        self.device_info_label.setStyleSheet("color: white; font-family: Inter;  border: none;")
        asio_layout.addWidget(self.device_info_label)

        asio_panel_button = ModernButton("ASIO Control Panel")
        asio_layout.addWidget(asio_panel_button)
        device_layout.addWidget(self.asio_section)

        # MME/WASAPI Section
        self.mme_section = QWidget()
        mme_layout = QVBoxLayout(self.mme_section)
        mme_layout.setContentsMargins(0, 0, 0, 0)
        mme_layout.setSpacing(8)

        # Input device
        input_layout = QHBoxLayout()
        input_label = QLabel("Input")
        input_label.setFixedWidth(80)
        input_label.setStyleSheet("color: white; font-family: Inter;  border: none;")
        self.input_selector = ModernComboBox()
        input_layout.addWidget(input_label)
        input_layout.addWidget(self.input_selector)
        mme_layout.addLayout(input_layout)

        # Output device
        output_layout = QHBoxLayout()
        output_label = QLabel("Output")
        output_label.setFixedWidth(80)
        output_label.setStyleSheet("color: white; font-family: Inter;  border: none;")
        self.output_selector = ModernComboBox()
        output_layout.addWidget(output_label)
        output_layout.addWidget(self.output_selector)
        mme_layout.addLayout(output_layout)

        device_layout.addWidget(self.mme_section)
        main_layout.addWidget(device_section)

        # Connect additional signals
        self.asio_device_selector.currentTextChanged.connect(
            lambda t: self.config_manager.setLastInputDevice(t))
        self.input_selector.currentTextChanged.connect(
            lambda t: self.config_manager.setLastInputDevice(t))
        self.output_selector.currentTextChanged.connect(
            lambda t: self.config_manager.setLastOutputDevice(t))
        asio_panel_button.clicked.connect(lambda: print("ASIO Control Panel requested"))

        # Update device lists
        self.api_selector.currentIndexChanged.connect(self.load_devices_for_api)

        # Status bar
        status_bar = QFrame()
        status_bar.setFixedHeight(28)
        status_bar.setStyleSheet(f"""
            background-color: {StyleConstants.SECTION_COLOR};
            border: 1px solid {StyleConstants.BORDER_COLOR};
        """)
        status_layout = QHBoxLayout(status_bar)
        status_layout.setContentsMargins(8, 0, 8, 0)
        
        status_label = QLabel("Current Audio Device: ")
        status_label.setStyleSheet("color: white; font-family: Inter; border: none;")
        status_layout.addWidget(status_label)
        
        main_layout.addStretch()
        main_layout.addWidget(status_bar)

        # Connect signals
        self.api_selector.currentIndexChanged.connect(self.on_api_changed)
        self.buffer_selector.currentIndexChanged.connect(self.on_buffer_changed)

    def on_api_changed(self, index):
        self.config_manager.setLastAudioAPI(index)
        self.load_devices_for_api(index)

    def on_buffer_changed(self, index):
        size = int(self.buffer_selector.currentText())
        self.config_manager.setLastBufferSize(size)
