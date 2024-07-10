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
            anchors.margins: 5  // Ajuste as margens para subir tudo um pouco
            spacing: 5  // Ajuste o espaçamento entre os componentes

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
                    } else {
                        toggleButton.text = "Active"
                        buttonBackground.color = "#ff4800"
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
                            text: "-"
                            anchors.fill: parent
                            onClicked: {
                                slider1.value = Math.max(slider1.value - 1, slider1.from);
                            }
                        }
                    }
                    QGCSlider {
                        id: slider1
                        width: 120
                        height: 30
                        from: 0
                        to: 100
                        stepSize: 1
                        enabled: false
                    }
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#ff4800"
                        radius: 5
                        QGCButton {
                            text: "+"
                            anchors.fill: parent
                            onClicked: {
                                slider1.value = Math.min(slider1.value + 1, slider1.to);
                            }
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
                            text: "-"
                            anchors.fill: parent
                            onClicked: {
                                slider2.value = Math.max(slider2.value - 1, slider2.from);
                            }
                        }
                    }
                    QGCSlider {
                        id: slider2
                        width: 120
                        height: 30
                        from: 0
                        to: 100
                        stepSize: 1
                        enabled: false
                    }
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#ff4800"
                        radius: 5
                        QGCButton {
                            text: "+"
                            anchors.fill: parent
                            onClicked: {
                                slider2.value = Math.min(slider2.value + 1, slider2.to);
                            }
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
                            text: "-"
                            anchors.fill: parent
                            onClicked: {
                                slider3.value = Math.max(slider3.value - 1, slider3.from);
                            }
                        }
                    }
                    QGCSlider {
                        id: slider3
                        width: 120
                        height: 30
                        from: 0
                        to: 100
                        stepSize: 1
                        enabled: false
                    }
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#ff4800"
                        radius: 5
                        QGCButton {
                            text: "+"
                            anchors.fill: parent
                            onClicked: {
                                slider3.value = Math.min(slider3.value + 1, slider3.to);
                            }
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
                            text: "-"
                            anchors.fill: parent
                            onClicked: {
                                slider4.value = Math.max(slider4.value - 1, slider4.from);
                            }
                        }
                    }
                    QGCSlider {
                        id: slider4
                        width: 120
                        height: 30
                        from: 0
                        to: 100
                        stepSize: 1
                        enabled: false
                    }
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#ff4800"
                        radius: 5
                        QGCButton {
                            text: "+"
                            anchors.fill: parent
                            onClicked: {
                                slider4.value = Math.min(slider4.value + 1, slider4.to);
                            }
                        }
                    }
                }
            }
        }
    }
}
