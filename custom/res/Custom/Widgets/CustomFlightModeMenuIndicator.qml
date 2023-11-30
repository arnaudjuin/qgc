/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick 2.11
import QtQuick.Layouts 1.11

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.MultiVehicleManager 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Palette 1.0

RowLayout {
    id: _root
    spacing: 0

    property real fontPointSize: ScreenTools.largeFontPointSize
    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property string accessType: QGroundControl.corePlugin.accessType

    property var flightModesMenuItems: []
    property var flightModesMenuItemsBasic: ["Stabilized", "Alt Hold", "Position", "Guided","Land","Return","RTL"]
    property var flightModesMenuItemsExpert: ["Manual", "Hold", "Return", "Precision Land", "Stabilized", "Acro", "Position", "Mission"]
    property var flightModesMenuItemsFactory: ["Manual", "Stabilized", "Acro", "Rattitude", "Altitude", "Offboard", "Position", "Hold", "Mission", "Return", "Follow Me", "Precision Land"]

    function updateFlightModesMenu(newAccessType) {
        if (newAccessType == "Basic") {
            flightModesMenuItems = flightModesMenuItemsBasic
        } else if (newAccessType == "Expert") {
            flightModesMenuItems = flightModesMenuItemsExpert
        } else if (newAccessType == "Factory") {
            flightModesMenuItems = flightModesMenuItemsFactory
        }

        if (flightModesMenuItems.indexOf(activeVehicle.flightMode) == -1) {
            activeVehicle.flightMode = flightModesMenuItems[0]
        }
    }

    Connections {
        target:                 QGroundControl.multiVehicleManager
        function onActiveVehicleChanged(activeVehicle) { _root.updateFlightModesMenu(accessType) }
    }

    Component {
        id: flightModeMenu

        Rectangle {
            width: flickable.width + (ScreenTools.defaultFontPixelWidth * 2)
            height: flickable.height + (ScreenTools.defaultFontPixelWidth * 2)
            radius: ScreenTools.defaultFontPixelHeight * 0.5
            color: qgcPal.window
            border.color: qgcPal.text

            QGCFlickable {
                id: flickable
                anchors.margins: ScreenTools.defaultFontPixelWidth
                anchors.top: parent.top
                anchors.left: parent.left
                width: mainLayout.width
                height: _fullWindowHeight <= mainLayout.height ? _fullWindowHeight : mainLayout.height
                flickableDirection: Flickable.VerticalFlick
                contentHeight: mainLayout.height
                contentWidth: mainLayout.width

                property real _fullWindowHeight: mainWindow.contentItem.height - (indicatorPopup.padding * 2) - (ScreenTools.defaultFontPixelWidth * 2)

                ColumnLayout {
                    id: mainLayout
                    spacing: ScreenTools.defaultFontPixelWidth / 2

                    Repeater {
                        model: flightModesMenuItems

                        QGCButton {
                            text: modelData
                            Layout.fillWidth: true
                            onClicked: {
                                activeVehicle.flightMode = text
                                mainWindow.hideIndicatorPopup()
                            }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        QGCLabel {
            text: activeVehicle ? activeVehicle.flightMode : qsTr("N/A", "No data to display")
            font.pointSize: fontPointSize
            Layout.alignment: Qt.AlignCenter

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    updateFlightModesMenu(QGroundControl.corePlugin.accessType)
                    mainWindow.showIndicatorPopup(_root, flightModeMenu)
                }
            }
        }
    }
}
