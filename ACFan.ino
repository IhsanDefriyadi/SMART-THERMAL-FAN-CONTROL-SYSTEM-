#include <WiFi.h>
#include <ESP32Servo.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// WiFi credentials
const char* ssid = "ALAYDRUS";
const char* password = "87654321";

// Pin definitions - Mengubah ke sisi lain ESP32
const int SERVO_PIN = 32;    // Mengubah dari 19 ke 32
const int DHT_PIN = 33;      // Mengubah dari 5 ke 33
const int RELAY_PIN = 25;    // Mengubah dari 18 ke 25
#define DHTTYPE DHT22

// I2C pins - Mengubah ke sisi lain ESP32
const int I2C_SDA = 26;      // Mengubah dari 21 ke 26
const int I2C_SCL = 27;      // Mengubah dari 22 ke 27

// Global variables
Servo myservo;
DHT dht(DHT_PIN, DHTTYPE);
WebServer server(80);
LiquidCrystal_I2C lcd(0x27, 16, 2);
bool automaticMode = true;
int manualAngle = 90;
bool relayState = false;
float tempThreshold = 28.0;

void setup() {
    Serial.begin(115200);
    delay(1000);
    
    Serial.println("\n\nStarting System...");
    
    // Initialize I2C with new pins
    Wire.begin(I2C_SDA, I2C_SCL);
    
    // Detailed I2C scan
    Serial.println("\n=== I2C Scanner Start ===");
    byte error, address;
    int nDevices = 0;
    byte lcd_addr = 0x27;
    
    for(address = 1; address < 127; address++) {
        Wire.beginTransmission(address);
        error = Wire.endTransmission();
        
        if (error == 0) {
            Serial.print("I2C device found at address 0x");
            if (address < 16) Serial.print("0");
            Serial.print(address, HEX);
            
            if (address == 0x27 || address == 0x3F) {
                lcd_addr = address;
                Serial.print(" - Likely LCD");
            }
            Serial.println();
            nDevices++;
        }
    }
    
    if (nDevices == 0) {
        Serial.println("No I2C devices found - Check connections!");
    }
    Serial.println("=== I2C Scanner End ===\n");
    
    // Initialize LCD
    Serial.println("Initializing LCD...");
    lcd = LiquidCrystal_I2C(lcd_addr, 16, 2);
    
    bool lcd_ready = false;
    for(int attempt = 1; attempt <= 3; attempt++) {
        Serial.print("LCD Init Attempt " + String(attempt) + "... ");
        
        lcd.init();
        lcd.begin(16, 2);
        delay(100);
        
        Wire.beginTransmission(lcd_addr);
        error = Wire.endTransmission();
        
        if(error == 0) {
            lcd_ready = true;
            Serial.println("SUCCESS!");
            lcd.backlight();
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("System Start");
            lcd.setCursor(0, 1);
            lcd.print("Initializing...");
            break;
        } else {
            Serial.println("FAILED!");
            delay(1000);
        }
    }
    
    // Initialize servo
    ESP32PWM::allocateTimer(0);
    myservo.setPeriodHertz(50);
    
    if(myservo.attach(SERVO_PIN)) {
        Serial.println("Servo initialized on pin " + String(SERVO_PIN));
        myservo.write(90);
    } else {
        Serial.println("Servo initialization failed!");
    }
    
    // Initialize DHT
    dht.begin();
    Serial.println("DHT initialized on pin " + String(DHT_PIN));
    
    // Initialize relay
    pinMode(RELAY_PIN, OUTPUT);
    digitalWrite(RELAY_PIN, LOW);
    Serial.println("Relay initialized on pin " + String(RELAY_PIN));
    
    // Connect to WiFi
    WiFi.begin(ssid, password);
    Serial.println("\nConnecting to WiFi");
    Serial.print("SSID: ");
    Serial.println(ssid);
    
    int wifiAttempt = 0;
    while (WiFi.status() != WL_CONNECTED && wifiAttempt < 20) {
        delay(500);
        Serial.print(".");
        wifiAttempt++;
    }
    
    if(WiFi.status() == WL_CONNECTED) {
        Serial.println("\n=============================");
        Serial.println("WiFi Connected Successfully!");
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP());
        Serial.print("MAC Address: ");
        Serial.println(WiFi.macAddress());
        Serial.println("=============================\n");
        
        // Don't show IP on LCD anymore
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("WiFi Connected");
        lcd.setCursor(0, 1);
        lcd.print("System Ready");
    } else {
        Serial.println("\n=============================");
        Serial.println("WiFi Connection FAILED!");
        Serial.println("Please check your WiFi settings");
        Serial.println("=============================\n");
    }
    
    // Setup server
    server.on("/", HTTP_GET, handleRoot);
    server.on("/mode", HTTP_POST, handleMode);
    server.on("/angle", HTTP_POST, handleAngle);
    server.on("/relay", HTTP_POST, handleRelay);
    server.begin();
    
    Serial.println("HTTP server started");
    Serial.println("System initialization complete!");
}

void loop() {
    server.handleClient();
    
    static unsigned long lastUpdate = 0;
    unsigned long currentMillis = millis();
    
    // Update sensor readings every 1 second
    if (currentMillis - lastUpdate >= 1000) {
        lastUpdate = currentMillis;
        
        float temperature = dht.readTemperature();
        float humidity = dht.readHumidity();
        
        if (isnan(temperature) || isnan(humidity)) {
            Serial.println("Failed to read from DHT sensor!");
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Sensor Error!");
            return;
        }
        
        // Debug output
        Serial.printf("T:%.1f°C H:%.1f%% A:%d° RPM:%d\n", 
                     temperature, humidity, manualAngle,
                     map(manualAngle, 0, 180, 526, 1052));
        
        updateLCD(temperature, humidity);
        
        if (automaticMode) {
            controlServoAuto(temperature);
            controlRelayAuto(temperature);
        }
    }
}

void updateLCD(float temperature, float humidity) {
    static unsigned long lastLCDUpdate = 0;
    unsigned long currentMillis = millis();
    
    // Update LCD every 500ms to prevent flickering
    if (currentMillis - lastLCDUpdate >= 500) {
        lastLCDUpdate = currentMillis;
        
        // Retry LCD if not responding
        Wire.beginTransmission(0x27);
        if(Wire.endTransmission() != 0) {
            lcd.init();
            lcd.backlight();
        }
        
        // Calculate RPM based on servo angle
        int rpm = map(manualAngle, 0, 180, 526, 1052);
        
        // Update LCD
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("T:");
        lcd.print(temperature, 1);
        lcd.print("C H:");
        lcd.print(humidity, 1);
        lcd.print("%");
        
        lcd.setCursor(0, 1);
        lcd.print(rpm);
        lcd.print("RPM ");
        lcd.print(relayState ? "ON" : "OFF");
    }
}

void handleRoot() {
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    
    String response = "{\"mode\": \"" + String(automaticMode ? "auto" : "manual") + "\", ";
    response += "\"angle\": " + String(manualAngle) + ", ";
    response += "\"relay\": " + String(relayState ? "true" : "false") + ", ";
    response += "\"temperature\": " + String(temperature) + ", ";
    response += "\"humidity\": " + String(humidity) + "}";
    
    server.send(200, "application/json", response);
}

void handleMode() {
    if (server.hasArg("plain")) {
      StaticJsonDocument<200> doc;
      DeserializationError error = deserializeJson(doc, server.arg("plain"));
      
      if (!error) {
        automaticMode = doc["auto"].as<bool>();
        server.send(200, "application/json", "{\"status\": \"success\"}");
        return;
      }
    }
    server.send(400, "application/json", "{\"status\": \"error\"}");
}

void handleAngle() {
    if (server.hasArg("plain")) {
      StaticJsonDocument<200> doc;
      DeserializationError error = deserializeJson(doc, server.arg("plain"));
      
      if (!error) {
        manualAngle = doc["angle"].as<int>();
        if (!automaticMode) {
          myservo.write(manualAngle);
        }
        server.send(200, "application/json", "{\"status\": \"success\"}");
        return;
      }
    }
    server.send(400, "application/json", "{\"status\": \"error\"}");
}

void handleRelay() {
    if (server.hasArg("plain")) {
      StaticJsonDocument<200> doc;
      DeserializationError error = deserializeJson(doc, server.arg("plain"));
      
      if (!error) {
        if (!automaticMode) {
          relayState = doc["state"].as<bool>();
          digitalWrite(RELAY_PIN, relayState ? HIGH : LOW);
        }
        server.send(200, "application/json", "{\"status\": \"success\"}");
        return;
      }
    }
    server.send(400, "application/json", "{\"status\": \"error\"}");
}

void controlServoAuto(float temperature) {
    int angle;
    
    // Detailed temperature-based servo control
    if (temperature < 25) {
        angle = 0;
    }
    else if (temperature >= 35) {
        angle = 180;
    }
    else {
        // More granular control between 25°C and 35°C
        switch (int(temperature)) {
            case 25: angle = 20; break;
            case 26: angle = 40; break;
            case 27: angle = 50; break;
            case 28: angle = 60; break;
            case 29: angle = 70; break;
            case 30: angle = 90; break;
            case 31: angle = 110; break;
            case 32: angle = 130; break;
            case 33: angle = 150; break;
            case 34: angle = 170; break;
            default:
                // For fractional temperatures, interpolate
                float fraction = temperature - int(temperature);
                int baseTemp = int(temperature);
                int lowerAngle, upperAngle;
                
                // Get angles for interpolation
                if (baseTemp < 25) {
                    lowerAngle = 0;
                    upperAngle = 20;
                } else if (baseTemp >= 34) {
                    lowerAngle = 170;
                    upperAngle = 180;
                } else {
                    // Use switch values for interpolation
                    switch (baseTemp) {
                        case 25: lowerAngle = 20; upperAngle = 40; break;
                        case 26: lowerAngle = 40; upperAngle = 50; break;
                        case 27: lowerAngle = 50; upperAngle = 60; break;
                        case 28: lowerAngle = 60; upperAngle = 70; break;
                        case 29: lowerAngle = 70; upperAngle = 90; break;
                        case 30: lowerAngle = 90; upperAngle = 110; break;
                        case 31: lowerAngle = 110; upperAngle = 130; break;
                        case 32: lowerAngle = 130; upperAngle = 150; break;
                        case 33: lowerAngle = 150; upperAngle = 170; break;
                        default: lowerAngle = 0; upperAngle = 180;
                    }
                }
                angle = lowerAngle + (fraction * (upperAngle - lowerAngle));
        }
    }
    
    Serial.printf("Temp: %.1f°C, Servo: %d°, RPM: %d\n", 
                 temperature, angle, 
                 map(angle, 0, 180, 526, 1052));
    
    myservo.write(angle);
    manualAngle = angle;
}

void controlRelayAuto(float temperature) {
    // Turn on fan exactly at 28°C
    if (temperature >= tempThreshold && !relayState) {
        relayState = true;
        digitalWrite(RELAY_PIN, HIGH);
        Serial.println("Fan ON - Temperature: " + String(temperature) + "°C");
    }
    // Turn off fan at 27°C (1 degree hysteresis)
    else if (temperature < (tempThreshold - 1.0) && relayState) {
        relayState = false;
        digitalWrite(RELAY_PIN, LOW);
        Serial.println("Fan OFF - Temperature: " + String(temperature) + "°C");
    }
}
