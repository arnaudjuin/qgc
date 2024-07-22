/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.SettingsManager
import QGroundControl.Controllers
import QGroundControl.FactSystem 1.0
import QGroundControl.FactControls 1.0

Rectangle {
    id: calibrationView
    width: 400
    height: 300
    color: qgcPal.window

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    function enableButtons(enabled) {
        minusButton1.enabled = enabled;
        plusButton1.enabled = enabled;
        minusButton2.enabled = enabled;
        plusButton2.enabled = enabled;
        minusButton3.enabled = enabled;
        plusButton3.enabled = enabled;
        minusButton4.enabled = enabled;
        plusButton4.enabled = enabled;
    }

    function sendPWMCommand(channel, value) {
        var pwmValue = 1500 + (value * 10);
        var paramId = "";

        // Define o paramId com base no canal
        if (channel === 3) {
            paramId = "SERVO3_TRIM";
        } else if (channel === 4) {
            paramId = "SERVO4_TRIM";
        } else if (channel === 5) {
            paramId = "SERVO5_TRIM";
        } else if (channel === 6) {
            paramId = "SERVO6_TRIM";
        }

        // Log to console for debugging
        console.log("Sending command to channel:", channel, "with paramId:", paramId, "and pwmValue:", pwmValue);

        if (_activeVehicle && _activeVehicle.parameterManager) {
            _activeVehicle.parameterManager.sendParamSetToVehicle(1, paramId, FactMetaData.valueTypeFloat, pwmValue);
        }
    }

    Rectangle {
        id: calibrationRec
        width: 275
        height: 305
        border.color: "#d3d3d3"
        anchors.centerIn: parent
        radius: 10
        color: "white"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 5

            Label {
                text: "Wheel alignment panel"
                font.pointSize: 12
                font.bold: true
                color: qgcPal.text
                Layout.alignment: Qt.AlignHCenter
            }

            QGCButton {
                id: toggleButton
                Layout.alignment: Qt.AlignHCenter
                width: 100
                height: 30
                text: "Active"
                background: Rectangle {
                    id: buttonBackground
                    color: "#ff4800"
                    radius: 5
                }
                onClicked: {
                    if (toggleButton.text === "Active") {
                        toggleButton.text = "Disable"
                        buttonBackground.color = "#ff0000"
                        enableButtons(true)
                    } else {
                        toggleButton.text = "Active"
                        buttonBackground.color = "#ff4800"
                        enableButtons(false)
                    }
                }
            }

            // Slider 1
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignHCenter
                Label {
                    text: "Left front"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }
                RowLayout {
                    spacing: 5
                    Layout.alignment: Qt.AlignHCenter
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#ff4800"
                        radius: 5
                        QGCButton {
                            id: minusButton1
                            text: "-"
                            anchors.fill: parent
                            enabled: false
                            onPressed: {
                                holdTimerMinus1.start();
                            }
                            onReleased: {
                                holdTimerMinus1.stop();
                            }
                            onClicked: {
                                slider1.value = Math.max(slider1.value - 1, slider1.from);
                                sendPWMCommand(3, slider1.value);
                            }
                        }
                    }
                    QGCSlider {
                        id: slider1
                        width: 120
                        height: 30
                        from: -40
                        to: 40
                        stepSize: 1
                        enabled: false
                        value: 0
                    }
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#ff4800"
                        radius: 5
                        QGCButton {
                            id: plusButton1
                            text: "+"
                            anchors.fill: parent
                            enabled: false
                            onPressed: {
                                holdTimerPlus1.start();
                            }
                            onReleased: {
                                holdTimerPlus1.stop();
                            }
                            onClicked: {
                                slider1.value = Math.min(slider1.value + 1, slider1.to);
                                sendPWMCommand(3, slider1.value);
                            }
                        }
                    }
                    Timer {
                        id: holdTimerMinus1
                        interval: 100
                        repeat: true
                        onTriggered: {
                            slider1.value = Math.max(slider1.value - 1, slider1.from);
                            sendPWMCommand(3, slider1.value);
                        }
                    }
                    Timer {
                        id: holdTimerPlus1
                        interval: 100
                        repeat: true
                        onTriggered: {
                            slider1.value = Math.min(slider1.value + 1, slider1.to);
                            sendPWMCommand(3, slider1.value);
                        }
                    }
                }
            }

            // Slider 2
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignHCenter
                Label {
                    text: "Left rear"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }
                RowLayout {
                    spacing: 5
                    Layout.alignment: Qt.AlignHCenter
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#ff4800"
                        radius: 5
                        QGCButton {
                            id: minusButton2
                            text: "-"
                            anchors.fill: parent
                            enabled: false
                            onPressed: {
                                holdTimerMinus2.start();
                            }
                            onReleased: {
                                holdTimerMinus2.stop();
                            }
                            onClicked: {
                                slider2.value = Math.max(slider2.value - 1, slider2.from);
                                sendPWMCommand(4, slider2.value);
                            }
                        }
                    }
                    QGCSlider {
                        id: slider2
                        width: 120
                        height: 30
                        from: -40
                        to: 40
                        stepSize: 1
                        enabled: false
                        value: 0
                    }
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#ff4800"
                        radius: 5
                        QGCButton {
                            id: plusButton2
                            text: "+"
                            anchors.fill: parent
                            enabled: false
                            onPressed: {
                                holdTimerPlus2.start();
                            }
                            onReleased: {
                                holdTimerPlus2.stop();
                            }
                            onClicked: {
                                slider2.value = Math.min(slider2.value + 1, slider2.to);
                                sendPWMCommand(4, slider2.value);
                            }
                        }
                    }
                    Timer {
                        id: holdTimerMinus2
                        interval: 100
                        repeat: true
                        onTriggered: {
                            slider2.value = Math.max(slider2.value - 1, slider2.from);
                            sendPWMCommand(4, slider2.value);
                        }
                    }
                    Timer {
                        id: holdTimerPlus2
                        interval: 100
                        repeat: true
                        onTriggered: {
                            slider2.value = Math.min(slider2.value + 1, slider2.to);
                            sendPWMCommand(4, slider2.value);
                        }
                    }
                }
            }

            // Slider 3
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignHCenter
                Label {
                    text: "Right front"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }
                RowLayout {
                    spacing: 5
                    Layout.alignment: Qt.AlignHCenter
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#ff4800"
                        radius: 5
                        QGCButton {
                            id: minusButton3
                            text: "-"
                            anchors.fill: parent
                            enabled: false
                            onPressed: {
                                holdTimerMinus3.start();
                            }
                            onReleased: {
                                holdTimerMinus3.stop();
                            }
                            onClicked: {
                                slider3.value = Math.max(slider3.value - 1, slider3.from);
                                sendPWMCommand(5, slider3.value);
                            }
                        }
                    }
                    QGCSlider {
                        id: slider3
                        width: 120
                        height: 30
                        from: -40
                        to: 40
                        stepSize: 1
                        enabled: false
                        value: 0
                    }
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#ff4800"
                        radius: 5
                        QGCButton {
                            id: plusButton3
                            text: "+"
                            anchors.fill: parent
                            enabled: false
                            onPressed: {
                                holdTimerPlus3.start();
                            }
                            onReleased: {
                                holdTimerPlus3.stop();
                            }
                            onClicked: {
                                slider3.value = Math.min(slider3.value + 1, slider3.to);
                                sendPWMCommand(5, slider3.value);
                            }
                        }
                    }
                    Timer {
                        id: holdTimerMinus3
                        interval: 100
                        repeat: true
                        onTriggered: {
                            slider3.value = Math.max(slider3.value - 1, slider3.from);
                            sendPWMCommand(5, slider3.value);
                        }
                    }
                    Timer {
                        id: holdTimerPlus3
                        interval: 100
                        repeat: true
                        onTriggered: {
                            slider3.value = Math.min(slider3.value + 1, slider3.to);
                            sendPWMCommand(5, slider3.value);
                        }
                    }
                }
            }

            // Slider 4
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignHCenter
                Label {
                    text: "Right rear"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }
                RowLayout {
                    spacing: 5
                    Layout.alignment: Qt.AlignHCenter
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#ff4800"
                        radius: 5
                        QGCButton {
                            id: minusButton4
                            text: "-"
                            anchors.fill: parent
                            enabled: false
                            onPressed: {
                                holdTimerMinus4.start();
                            }
                            onReleased: {
                                holdTimerMinus4.stop();
                            }
                            onClicked: {
                                slider4.value = Math.max(slider4.value - 1, slider4.from);
                                sendPWMCommand(6, slider4.value);
                            }
                        }
                    }
                    QGCSlider {
                        id: slider4
                        width: 120
                        height: 30
                        from: -40
                        to: 40
                        stepSize: 1
                        enabled: false
                        value: 0
                    }
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#ff4800"
                        radius: 5
                        QGCButton {
                            id: plusButton4
                            text: "+"
                            anchors.fill: parent
                            enabled: false
                            onPressed: {
                                holdTimerPlus4.start();
                            }
                            onReleased: {
                                holdTimerPlus4.stop();
                            }
                            onClicked: {
                                slider4.value = Math.min(slider4.value + 1, slider4.to);
                                sendPWMCommand(6, slider4.value);
                            }
                        }
                    }
                    Timer {
                        id: holdTimerMinus4
                        interval: 100
                        repeat: true
                        onTriggered: {
                            slider4.value = Math.max(slider4.value - 1, slider4.from);
                            sendPWMCommand(6, slider4.value);
                        }
                    }
                    Timer {
                        id: holdTimerPlus4
                        interval: 100
                        repeat: true
                        onTriggered: {
                            slider4.value = Math.min(slider4.value + 1, slider4.to);
                            sendPWMCommand(6, slider4.value);
                        }
                    }
                }
            }
        }
    }
}



