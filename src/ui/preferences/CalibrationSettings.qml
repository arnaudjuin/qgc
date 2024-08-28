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
    width: 500
    height: 500
    color: qgcPal.window

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    function enableButtons(slider, minusButton, plusButton, enabled) {
        minusButton.enabled = enabled;
        plusButton.enabled = enabled;
        slider.enabled = enabled;
    }

    function sendPWMCommand(channel, value) {
        var pwmValue = 1500 + (value * 10);
        var paramId = "";

        if (channel === 3) {
            paramId = "SERVO3_TRIM";
        } else if (channel === 4) {
            paramId = "SERVO4_TRIM";
            pwmValue = 1500 - (value * 10); // Invertido para o Left Rear
        } else if (channel === 5) {
            paramId = "SERVO5_TRIM";
        } else if (channel === 6) {
            paramId = "SERVO6_TRIM";
            pwmValue = 1500 - (value * 10); // Invertido para o Right Rear
        }

        console.log("Sending command to channel:", channel, "with paramId:", paramId, "and pwmValue:", pwmValue);

        if (_activeVehicle && _activeVehicle.parameterManager) {
            _activeVehicle.parameterManager.sendParamSetToVehicle(1, paramId, 3, pwmValue);
        }
    }

    function sendDefaultPWM(channel) {
        sendPWMCommand(channel, 0);
    }

    Rectangle {
        id: calibrationRec
        width: 600
        height: 350
        border.color: "#d3d3d3"
        anchors.centerIn: parent
        radius: 10
        color: "white"

        GridLayout {
            columns: 2
            anchors.centerIn: parent
            rowSpacing: 20
            columnSpacing: 50

            // Dianteira Esquerda
            ColumnLayout {
                spacing: 10
                Label {
                    text: "Dianteira esquerda"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }
                QGCButton {
                    id: enableButton1
                    Layout.alignment: Qt.AlignHCenter
                    width: 100
                    height: 30
                    text: "Ativar"
                    background: Rectangle {
                        id: buttonBackground1
                        color: "#ff4800"
                        radius: 5
                    }
                    onClicked: {
                        if (enableButton1.text === "Ativar") {
                            enableButton1.text = "Desativar"
                            buttonBackground1.color = "#ff0000"
                            enableButtons(slider1, minusButton1, plusButton1, true)
                            slider1.value = 0;  // Reseta o slider para o ponto inicial
                            sendDefaultPWM(3)
                        } else {
                            enableButton1.text = "Ativar"
                            buttonBackground1.color = "#ff4800"
                            enableButtons(slider1, minusButton1, plusButton1, false)
                        }
                    }
                }
                RowLayout {
                    spacing: 10
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
                        width: 150
                        height: 30
                        from: -50
                        to: 50
                        stepSize: 1
                        enabled: false
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

            // Dianteira Direita
            ColumnLayout {
                spacing: 10
                Label {
                    text: "Dianteira direita"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }
                QGCButton {
                    id: enableButton3
                    Layout.alignment: Qt.AlignHCenter
                    width: 100
                    height: 30
                    text: "Ativar"
                    background: Rectangle {
                        id: buttonBackground3
                        color: "#ff4800"
                        radius: 5
                    }
                    onClicked: {
                        if (enableButton3.text === "Ativar") {
                            enableButton3.text = "Desativar"
                            buttonBackground3.color = "#ff0000"
                            enableButtons(slider3, minusButton3, plusButton3, true)
                            slider3.value = 0;  // Reseta o slider para o ponto inicial
                            sendDefaultPWM(5)
                        } else {
                            enableButton3.text = "Ativar"
                            buttonBackground3.color = "#ff4800"
                            enableButtons(slider3, minusButton3, plusButton3, false)
                        }
                    }
                }
                RowLayout {
                    spacing: 10
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
                        width: 150
                        height: 30
                        from: -50
                        to: 50
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

            // Traseira Esquerda
            ColumnLayout {
                spacing: 10
                Label {
                    text: "Traseira esquerda"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }
                QGCButton {
                    id: enableButton2
                    Layout.alignment: Qt.AlignHCenter
                    width: 100
                    height: 30
                    text: "Ativar"
                    background: Rectangle {
                        id: buttonBackground2
                        color: "#ff4800"
                        radius: 5
                    }
                    onClicked: {
                        if (enableButton2.text === "Ativar") {
                            enableButton2.text = "Desativar"
                            buttonBackground2.color = "#ff0000"
                            enableButtons(slider2, minusButton2, plusButton2, true)
                            slider2.value = 0;  // Reseta o slider para o ponto inicial
                            sendDefaultPWM(4)
                        } else {
                            enableButton2.text = "Ativar"
                            buttonBackground2.color = "#ff4800"
                            enableButtons(slider2, minusButton2, plusButton2, false)
                        }
                    }
                }
                RowLayout {
                    spacing: 10
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
                        width: 150
                        height: 30
                        from: -50
                        to: 50
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

            // Traseira Direita
            ColumnLayout {
                spacing: 10
                Label {
                    text: "Traseira direita"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }
                QGCButton {
                    id: enableButton4
                    Layout.alignment: Qt.AlignHCenter
                    width: 100
                    height: 30
                    text: "Ativar"
                    background: Rectangle {
                        id: buttonBackground4
                        color: "#ff4800"
                        radius: 5
                    }
                    onClicked: {
                        if (enableButton4.text === "Ativar") {
                            enableButton4.text = "Desativar"
                            buttonBackground4.color = "#ff0000"
                            enableButtons(slider4, minusButton4, plusButton4, true)
                            slider4.value = 0;  // Reseta o slider para o ponto inicial
                            sendDefaultPWM(6)
                        } else {
                            enableButton4.text = "Ativar"
                            buttonBackground4.color = "#ff4800"
                            enableButtons(slider4, minusButton4, plusButton4, false)
                        }
                    }
                }
                RowLayout {
                    spacing: 10
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
                        width: 150
                        height: 30
                        from: -50
                        to: 50
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
