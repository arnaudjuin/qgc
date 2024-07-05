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
    width: 600
    height: 400
    color: qgcPal.window

    Rectangle {
        width: 310
        height: 325
        border.color: "#d3d3d3"
        anchors.centerIn: parent
        radius: 10

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 5  // Ajuste o espaçamento entre as linhas

            Label {
                text: "Wheel alignment panel"
                font.pointSize: 8
                font.bold: true
                color: qgcPal.text
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                spacing: 2
                Layout.alignment: Qt.AlignHCenter
                ColumnLayout {
                    spacing: 0  // Espaçamento entre a label e o slider
                    Label {
                        text: "Left front"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    RowLayout {
                        spacing: 2
                        QGCButton {
                            width: 30
                            height: 30
                            text: "-"
                            onClicked: {
                                slider1.value = Math.max(slider1.value - 1, slider1.from);
                            }
                        }
                        QGCSlider {
                            id: slider1
                            width: 150
                            from: 0
                            to: 100
                            stepSize: 1
                            enabled: false
                        }
                        QGCButton {
                            width: 30
                            height: 30
                            text: "+"
                            onClicked: {
                                slider1.value = Math.min(slider1.value + 1, slider1.to);
                            }
                        }
                    }
                }
            }

            RowLayout {
                spacing: 2
                Layout.alignment: Qt.AlignHCenter
                ColumnLayout {
                    spacing: 0  // Espaçamento entre a label e o slider
                    Label {
                        text: "Left rear"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    RowLayout {
                        spacing: 2
                        QGCButton {
                            width: 30
                            height: 30
                            text: "-"
                            onClicked: {
                                slider2.value = Math.max(slider2.value - 1, slider2.from);
                            }
                        }
                        QGCSlider {
                            id: slider2
                            width: 150
                            from: 0
                            to: 100
                            stepSize: 1
                            enabled: false
                        }
                        QGCButton {
                            width: 30
                            height: 30
                            text: "+"
                            onClicked: {
                                slider2.value = Math.min(slider2.value + 1, slider2.to);
                            }
                        }
                    }
                }
            }

            RowLayout {
                spacing: 2
                Layout.alignment: Qt.AlignHCenter
                ColumnLayout {
                    spacing: 0  // Espaçamento entre a label e o slider
                    Label {
                        text: "Right front"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    RowLayout {
                        spacing: 2
                        QGCButton {
                            width: 30
                            height: 30
                            text: "-"
                            onClicked: {
                                slider3.value = Math.max(slider3.value - 1, slider3.from);
                            }
                        }
                        QGCSlider {
                            id: slider3
                            width: 150
                            from: 0
                            to: 100
                            stepSize: 1
                            enabled: false
                        }
                        QGCButton {
                            width: 30
                            height: 30
                            text: "+"
                            onClicked: {
                                slider3.value = Math.min(slider3.value + 1, slider3.to);
                            }
                        }
                    }
                }
            }

            RowLayout {
                spacing: 2
                Layout.alignment: Qt.AlignHCenter
                ColumnLayout {
                    spacing: 0  // Espaçamento entre a label e o slider
                    Label {
                        text: "Right rear"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    RowLayout {
                        spacing: 2
                        QGCButton {
                            width: 30
                            height: 30
                            text: "-"
                            onClicked: {
                                slider4.value = Math.max(slider4.value - 20, slider4.from);
                            }
                        }
                        QGCSlider {
                            id: slider4
                            width: 150
                            from: 0
                            to: 100
                            stepSize: 20
                            enabled: false
                        }
                        QGCButton {
                            width: 30
                            height: 30
                            text: "+"
                            onClicked: {
                                slider4.value = Math.min(slider4.value + 20, slider4.to);
                            }
                        }
                    }
                }
            }
        }
    }
}
