import sys
import os
import json
from PySide6.QtCore import QObject, Property, Signal, Slot
from PySide6.QtWidgets import QApplication
from audio_manager_widget import AudioManagerWidget

class ConfigManagerMock(QObject):
    configChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self._config = {}
        self.load_config()

    def load_config(self):
        with open("audio_config.json", "r") as f:
            self._config = json.load(f)

    @Property(int)
    def lastBufferSize(self):
        return self._config["audio"]["bufferSize"]

    @Property(int)
    def lastAudioAPI(self):
        return self._config["audio"]["api"]

    @Property(str)
    def lastInputDevice(self):
        return self._config["audio"]["lastInputDevice"]

    @Property(str)
    def lastOutputDevice(self):
        return self._config["audio"]["lastOutputDevice"]

    @Slot(int)
    def setLastBufferSize(self, size):
        self._config["audio"]["bufferSize"] = size
        self.configChanged.emit()

    @Slot(int)
    def setLastAudioAPI(self, api):
        self._config["audio"]["api"] = api
        self.configChanged.emit()

    @Slot(str)
    def setLastInputDevice(self, device):
        self._config["audio"]["lastInputDevice"] = device
        self.configChanged.emit()

    @Slot(str)
    def setLastOutputDevice(self, device):
        self._config["audio"]["lastOutputDevice"] = device
        self.configChanged.emit()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    
    config_manager = ConfigManagerMock()
    widget = AudioManagerWidget(config_manager)
    widget.show()
    
    sys.exit(app.exec())
