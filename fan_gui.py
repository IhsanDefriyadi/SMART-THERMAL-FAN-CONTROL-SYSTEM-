# main.py
import sys
import json
import requests
from PyQt5.QtCore import QObject, pyqtSlot, pyqtSignal, QUrl, QTimer, pyqtProperty
from PyQt5.QtGui import QGuiApplication
from PyQt5.QtQml import QQmlApplicationEngine
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FanController(QObject):
    # Define signals for QML
    temperatureChanged = pyqtSignal(float)
    humidityChanged = pyqtSignal(float)
    modeChanged = pyqtSignal(bool)
    angleChanged = pyqtSignal(int)
    relayStateChanged = pyqtSignal(bool)
    connectionStatusChanged = pyqtSignal(bool)
    statusMessageChanged = pyqtSignal(str)
    rpmChanged = pyqtSignal(int)  # Add RPM signal

    def __init__(self):
        super().__init__()
        # Sesuaikan dengan IP ESP32 yang baru
        self.esp32_url = "http://192.168.100.161" # Ganti dengan IP ESP32 Anda
        self.connection_retry_count = 0
        self.max_retries = 3  # Mengurangi retry attempts
        
        # Initialize properties
        self._temperature = 0.0
        self._humidity = 0.0
        self._automatic_mode = True
        self._current_angle = 90
        self._relay_state = False
        self._is_connected = False
        self._status_message = "Starting..."
        self._current_rpm = 526  # Initial RPM value

        # Setup update timer with shorter interval
        self.update_timer = QTimer()
        self.update_timer.timeout.connect(self.update_status)
        self.update_timer.start(1000)  # Update every 1 second

    # Properties for QML
    @pyqtProperty(float, notify=temperatureChanged)
    def temperature(self):
        return self._temperature

    @pyqtProperty(float, notify=humidityChanged)
    def humidity(self):
        return self._humidity

    @pyqtProperty(bool, notify=modeChanged)
    def automatic_mode(self):
        return self._automatic_mode

    @pyqtProperty(int, notify=angleChanged)
    def current_angle(self):
        return self._current_angle

    @pyqtProperty(bool, notify=relayStateChanged)
    def relay_state(self):
        return self._relay_state

    @pyqtProperty(bool, notify=connectionStatusChanged)
    def is_connected(self):
        return self._is_connected

    @pyqtProperty(str, notify=statusMessageChanged)
    def status_message(self):
        return self._status_message

    @pyqtProperty(int, notify=rpmChanged)
    def current_rpm(self):
        return self._current_rpm

    def set_status_message(self, message):
        self._status_message = message
        self.statusMessageChanged.emit(message)
        logger.info(message)

    def calculate_rpm(self, angle):
        # Calculate RPM based on servo angle (526 RPM at 0°, 1052 RPM at 180°)
        return int(526 + (angle * (1052 - 526) / 180))

    @pyqtSlot(bool)
    def setMode(self, automatic):
        if not self._is_connected:
            self.set_status_message("Not connected to ESP32")
            return
            
        try:
            response = requests.post(
                f"{self.esp32_url}/mode",
                json={"auto": automatic},
                timeout=3.0
            )
            if response.status_code == 200:
                self._automatic_mode = automatic
                self.modeChanged.emit(automatic)
                self.set_status_message(f"Mode changed to: {'automatic' if automatic else 'manual'}")
            else:
                self.set_status_message(f"Failed to change mode. Status: {response.status_code}")
        except requests.exceptions.RequestException as e:
            self.handle_connection_error("Error setting mode", e)

    @pyqtSlot(int)
    def setAngle(self, angle):
        if not self._is_connected:
            self.set_status_message("Not connected to ESP32")
            return
            
        if not self._automatic_mode and 0 <= angle <= 180:
            try:
                response = requests.post(
                    f"{self.esp32_url}/angle",
                    json={"angle": angle},
                    timeout=3.0
                )
                if response.status_code == 200:
                    self._current_angle = angle
                    self.angleChanged.emit(angle)
                    # Update RPM when angle changes
                    new_rpm = self.calculate_rpm(angle)
                    self._current_rpm = new_rpm
                    self.rpmChanged.emit(new_rpm)
                    self.set_status_message(f"Angle set to: {angle}° (RPM: {new_rpm})")
                else:
                    self.set_status_message(f"Failed to set angle. Status: {response.status_code}")
            except requests.exceptions.RequestException as e:
                self.handle_connection_error("Error setting angle", e)

    @pyqtSlot(bool)
    def setRelay(self, state):
        if not self._is_connected:
            self.set_status_message("Not connected to ESP32")
            return
            
        if not self._automatic_mode:
            try:
                response = requests.post(
                    f"{self.esp32_url}/relay",
                    json={"state": state},
                    timeout=3.0
                )
                if response.status_code == 200:
                    self._relay_state = state
                    self.relayStateChanged.emit(state)
                    self.set_status_message(f"Fan {'turned on' if state else 'turned off'}")
                else:
                    self.set_status_message(f"Failed to set relay. Status: {response.status_code}")
            except requests.exceptions.RequestException as e:
                self.handle_connection_error("Error setting relay", e)

    def handle_connection_error(self, context, error):
        self.connection_retry_count += 1
        if self.connection_retry_count >= self.max_retries:
            self._is_connected = False
            self.connectionStatusChanged.emit(False)
            error_msg = f"{context}: {str(error)}"
            self.set_status_message(error_msg)
            logger.error(error_msg)
            
            # Reset retry count after max attempts
            if self.connection_retry_count > self.max_retries:
                self.connection_retry_count = 0
                self.set_status_message("Waiting to retry connection...")
        else:
            self.set_status_message(f"Retry attempt {self.connection_retry_count}/{self.max_retries}...")

    def update_status(self):
        try:
            response = requests.get(
                self.esp32_url,
                timeout=1.0  # Reduced timeout
            )
            if response.status_code == 200:
                data = response.json()
                self.connection_retry_count = 0
                
                # Batch all updates to reduce UI updates
                updates_needed = False
                
                # Temperature update
                if 0 <= float(data["temperature"]) <= 100 and self._temperature != float(data["temperature"]):
                    self._temperature = float(data["temperature"])
                    updates_needed = True
                
                # Humidity update
                if 0 <= float(data["humidity"]) <= 100 and self._humidity != float(data["humidity"]):
                    self._humidity = float(data["humidity"])
                    updates_needed = True
                
                # Mode update
                new_mode = data["mode"] == "auto"
                if new_mode != self._automatic_mode:
                    self._automatic_mode = new_mode
                    updates_needed = True
                
                # Angle and RPM update
                new_angle = int(data["angle"])
                if 0 <= new_angle <= 180 and self._current_angle != new_angle:
                    self._current_angle = new_angle
                    self._current_rpm = self.calculate_rpm(new_angle)
                    updates_needed = True
                
                # Relay update
                if self._relay_state != data["relay"]:
                    self._relay_state = data["relay"]
                    updates_needed = True
                
                # Emit all signals at once if needed
                if updates_needed:
                    self.temperatureChanged.emit(self._temperature)
                    self.humidityChanged.emit(self._humidity)
                    self.modeChanged.emit(self._automatic_mode)
                    self.angleChanged.emit(self._current_angle)
                    self.rpmChanged.emit(self._current_rpm)
                    self.relayStateChanged.emit(self._relay_state)
                
                # Update connection status only if needed
                if not self._is_connected:
                    self._is_connected = True
                    self.connectionStatusChanged.emit(True)
                    self.set_status_message("Connected to ESP32")
                
        except requests.exceptions.RequestException as e:
            self.handle_connection_error("Connection error", e)

if __name__ == '__main__':
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    # Create and register controller
    controller = FanController()
    engine.rootContext().setContextProperty("controller", controller)
    
    # Load QML
    engine.load(QUrl.fromLocalFile("main.qml"))
    
    if not engine.rootObjects():
        sys.exit(-1)
    
    sys.exit(app.exec_())