// main.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import QtGraphicalEffects 1.15

ApplicationWindow {
    visible: true
    width: 900
    height: 600
    title: "Smart Thermal Fan Control System"
    
    Material.theme: Material.Dark
    Material.accent: Material.Blue

    // Custom fonts
    FontLoader { id: poppins; source: "https://fonts.gstatic.com/s/poppins/v20/pxiEyp8kv8JHgFVrFJA.ttf" }
    FontLoader { id: montserrat; source: "https://fonts.gstatic.com/s/montserrat/v25/JTUHjIg1_i6t8kCHKm4532VJOt5-QNFgpCs16Hw5aX8.ttf" }
    FontLoader { id: orbitron; source: "https://fonts.gstatic.com/s/orbitron/v29/yMJMMIlzdpvBhQQL_SC3X9yhF25-T1nyGy6xpmIyXjU1pg.ttf" }

    // Background Image with blur effect
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "file:WALL.jpg"
        fillMode: Image.PreserveAspectCrop
        
        layer.enabled: true
        layer.effect: FastBlur {
            radius: 32
        }
        opacity: 0.3
    }

    // Gradient overlay
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1a1a1a" }
            GradientStop { position: 1.0; color: "#2d2d2d" }
        }
        opacity: 0.85
    }

    // Title at the top
    Text {
        id: titleText
        text: "SMART THERMAL FAN CONTROL"
        font.family: orbitron.name
        font.pixelSize: 28
        font.bold: true
        color: "#ffffff"
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 10
        
        layer.enabled: true
        layer.effect: Glow {
            radius: 8
            samples: 17
            color: "#80ffffff"
        }
    }

    // Team names
    Text {
        id: teamText
        text: "Abdul | Agil | Ihsan | Latifah | Nabil | Yoga"
        font.family: montserrat.name
        font.pixelSize: 14
        font.bold: true
        color: "#ffffff"
        anchors.top: titleText.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 5
        
        layer.enabled: true
        layer.effect: Glow {
            radius: 4
            samples: 9
            color: "#40ffffff"
        }
    }

    // Connection status bar with glass effect
    Rectangle {
        id: statusBar
        width: parent.width
        height: 50
        anchors.top: teamText.bottom
        anchors.topMargin: 10
        color: "transparent"
        
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: controller.is_connected ? "#4CAF50" : "#F44336" }
                GradientStop { position: 1.0; color: controller.is_connected ? "#45a049" : "#d32f2f" }
            }
            opacity: 0.9
        }
        
        // Glass reflection effect
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 0.5; color: "transparent" }
            }
            opacity: 0.1
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            
            Row {
                spacing: 10
                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: "white"
                    opacity: controller.is_connected ? 1.0 : 0.5
                    
                    SequentialAnimation on opacity {
                        running: controller.is_connected
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 1000 }
                        NumberAnimation { to: 1.0; duration: 1000 }
                    }
                }
                
                Text {
                    text: controller.is_connected ? "CONNECTED" : "DISCONNECTED"
                    color: "white"
                    font.pixelSize: 16
                    font.family: montserrat.name
                    font.bold: true
                    font.letterSpacing: 1.2
                }
            }
            
            Text {
                text: controller.status_message
                color: "white"
                font.pixelSize: 14
                font.family: poppins.name
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        anchors.topMargin: statusBar.height + titleText.height + 40
        spacing: 20

        // Temperature and Humidity Panel with glass effect
        Rectangle {
            Layout.fillWidth: true
            height: 200
            color: "#2d2d2d"
            radius: 15
            opacity: 0.85
            
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 4
                radius: 12.0
                samples: 16
                color: "#80000000"
            }
            
            // Glass reflection
            Rectangle {
                anchors.fill: parent
                radius: 15
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#ffffff" }
                    GradientStop { position: 0.1; color: "transparent" }
                }
                opacity: 0.1
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                // Temperature Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#363636"
                    radius: 12
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Text {
                            text: "🌡️"
                            font.pixelSize: 32
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: "Temperature"
                            font.pixelSize: 18
                            font.family: poppins.name
                            color: "white"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: controller.temperature.toFixed(1) + "°C"
                            font.pixelSize: 36
                            font.bold: true
                            font.family: poppins.name
                            color: controller.temperature > 28.0 ? "#ff5252" : "#4fc3f7"
                            Layout.alignment: Qt.AlignHCenter
                            
                            layer.enabled: true
                            layer.effect: Glow {
                                radius: 4
                                samples: 9
                                color: controller.temperature > 28.0 ? "#40ff5252" : "#404fc3f7"
                            }
                        }
                    }
                }

                // Humidity Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#363636"
                    radius: 12
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Text {
                            text: "💧"
                            font.pixelSize: 32
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: "Humidity"
                            font.pixelSize: 18
                            font.family: poppins.name
                            color: "white"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: controller.humidity.toFixed(1) + "%"
                            font.pixelSize: 36
                            font.bold: true
                            font.family: poppins.name
                            color: "#4fc3f7"
                            Layout.alignment: Qt.AlignHCenter
                            
                            layer.enabled: true
                            layer.effect: Glow {
                                radius: 4
                                samples: 9
                                color: "#404fc3f7"
                            }
                        }
                    }
                }

                // RPM Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#363636"
                    radius: 12
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Text {
                            text: "⚡"
                            font.pixelSize: 32
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: "Fan Speed"
                            font.pixelSize: 18
                            font.family: poppins.name
                            color: "white"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: controller.current_rpm
                            font.pixelSize: 36
                            font.bold: true
                            font.family: poppins.name
                            color: "#ffd54f"
                            Layout.alignment: Qt.AlignHCenter
                            
                            layer.enabled: true
                            layer.effect: Glow {
                                radius: 4
                                samples: 9
                                color: "#40ffd54f"
                            }
                        }
                        
                        Text {
                            text: "RPM"
                            font.pixelSize: 14
                            font.family: poppins.name
                            color: "#ffd54f"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Fan Status Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#363636"
                    radius: 12
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Text {
                            text: controller.relay_state ? "🌪️" : "⭕"
                            font.pixelSize: 32
                            Layout.alignment: Qt.AlignHCenter
                            
                            RotationAnimation on rotation {
                                running: controller.relay_state
                                from: 0
                                to: 360
                                duration: controller.current_rpm > 0 ? (2000 * 1052 / controller.current_rpm) : 2000
                                loops: Animation.Infinite
                            }
                        }
                        
                        Text {
                            text: "Fan Status"
                            font.pixelSize: 18
                            font.family: poppins.name
                            color: "white"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        
                        Text {
                            text: controller.relay_state ? "ON" : "OFF"
                            font.pixelSize: 36
                            font.bold: true
                            font.family: poppins.name
                            color: controller.relay_state ? "#66bb6a" : "#9e9e9e"
                            Layout.alignment: Qt.AlignHCenter
                            
                            layer.enabled: true
                            layer.effect: Glow {
                                radius: 4
                                samples: 9
                                color: controller.relay_state ? "#4066bb6a" : "#409e9e9e"
                            }
                        }
                    }
                }
            }
        }

        // Control Panel with glass effect
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#2d2d2d"
            radius: 15
            opacity: 0.85
            
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 4
                radius: 12.0
                samples: 16
                color: "#80000000"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                // Mode Switch
                Rectangle {
                    Layout.fillWidth: true
                    height: 70
                    color: "#363636"
                    radius: 12
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15

                        Image {
                            source: controller.automatic_mode ?
                                   "https://img.icons8.com/color/96/000000/automatic.png" :
                                   "https://img.icons8.com/color/96/000000/manual.png"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                        }

                        Text {
                            text: "Control Mode"
                            font.pixelSize: 18
                            font.family: roboto.name
                            color: "white"
                        }

                        Item { Layout.fillWidth: true }

                        Switch {
                            checked: controller.automatic_mode
                            onCheckedChanged: controller.setMode(checked)
                        }

                        Text {
                            text: controller.automatic_mode ? "Automatic" : "Manual"
                            font.pixelSize: 18
                            font.family: roboto.name
                            color: controller.automatic_mode ? "#66bb6a" : "#42a5f5"
                            font.bold: true
                        }
                    }
                }

                // Manual Controls
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#363636"
                    radius: 12
                    opacity: !controller.automatic_mode ? 1.0 : 0.5
                    enabled: !controller.automatic_mode

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 30

                        // Servo Control
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            RowLayout {
                                Layout.fillWidth: true
                                
                                Image {
                                    source: "https://img.icons8.com/color/96/000000/servo-motor.png"
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                }
                                
                                Text {
                                    text: "Fan Direction: " + servoSlider.value + "°"
                                    font.pixelSize: 18
                                    font.family: roboto.name
                                    color: "white"
                                }
                            }

                            Slider {
                                id: servoSlider
                                Layout.fillWidth: true
                                from: 0
                                to: 180
                                stepSize: 1
                                value: controller.current_angle
                                onMoved: controller.setAngle(value)
                                
                                background: Rectangle {
                                    x: servoSlider.leftPadding
                                    y: servoSlider.topPadding + servoSlider.availableHeight / 2 - height / 2
                                    width: servoSlider.availableWidth
                                    height: 4
                                    radius: 2
                                    color: "#424242"

                                    Rectangle {
                                        width: servoSlider.visualPosition * parent.width
                                        height: parent.height
                                        color: "#42a5f5"
                                        radius: 2
                                    }
                                }

                                handle: Rectangle {
                                    x: servoSlider.leftPadding + servoSlider.visualPosition * (servoSlider.availableWidth - width)
                                    y: servoSlider.topPadding + servoSlider.availableHeight / 2 - height / 2
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: servoSlider.pressed ? "#1976d2" : "#2196f3"
                                }
                            }
                        }

                        // Fan Power Control
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 20

                            Image {
                                source: "https://img.icons8.com/color/96/000000/power.png"
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                            }

                            Text {
                                text: "Fan Power"
                                font.pixelSize: 18
                                font.family: roboto.name
                                color: "white"
                            }

                            Switch {
                                checked: controller.relay_state
                                onCheckedChanged: controller.setRelay(checked)
                            }
                        }
                    }
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }
            }
        }
    }
    
    // Corner decorations with glow effect
    Rectangle {
        width: 100
        height: 100
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "transparent"
        opacity: 0.7
        
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.strokeStyle = "#42a5f5";
                ctx.lineWidth = 3;
                ctx.shadowBlur = 10;
                ctx.shadowColor = "#42a5f5";
                ctx.beginPath();
                ctx.moveTo(width, height-20);
                ctx.lineTo(width, height);
                ctx.lineTo(width-20, height);
                ctx.stroke();
            }
        }
    }
    
    Rectangle {
        width: 100
        height: 100
        anchors.left: parent.left
        anchors.top: parent.top
        color: "transparent"
        opacity: 0.7
        
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.strokeStyle = "#42a5f5";
                ctx.lineWidth = 3;
                ctx.shadowBlur = 10;
                ctx.shadowColor = "#42a5f5";
                ctx.beginPath();
                ctx.moveTo(0, 20);
                ctx.lineTo(0, 0);
                ctx.lineTo(20, 0);
                ctx.stroke();
            }
        }
    }
}