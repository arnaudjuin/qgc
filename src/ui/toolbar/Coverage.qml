/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl.Controllers
import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls
import MAVLink

//-------------------------------------------------------------------------
//-- Battery Indicator
Item {
    property var    _planMasterController:  globals.planMasterControllerFlyView
    property var    _missionController:     _planMasterController.missionController
    id:             control
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    width:          50

    property bool       showIndicator:      true
    property bool       waitForParameters:  false   // UI won't show until parameters are ready
    property Component  expandedPageComponent

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property Fact   _indicatorDisplay:  QGroundControl.settingsManager.batteryIndicatorSettings.display
    property bool   _showPercentage:    _indicatorDisplay.rawValue === 0
    property bool   _showVoltage:       _indicatorDisplay.rawValue === 1
    property bool   _showBoth:          _indicatorDisplay.rawValue === 2

    Row {
        id:             batteryIndicatorRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        Loader {
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            sourceComponent:    coverageVisual
        }
    }

    Component {
        id: coverageVisual
        Row {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom

            // Timer to trigger getTotalSurveyArea every second
            Timer {
                id: surveyAreaTimer
                interval: 1000  // 1 second interval
                repeat: true
                running: true
                onTriggered: {
                    surveyAreaLabel.text = "Survey Area: " + getTotalSurveyArea();
                }
            }

            function getCoverage() {
                return _planMasterController.missionController.missionDistance * 2 + "L"; // Adjusted function without factVazaoOffline
            }

            // Function to calculate the area of a polygon using the Shoelace formula
            function calculateArea(vertices) {
                let area = 0.0;
                for (let i = 0; i < vertices.length; i++) {
                    let j = (i + 1) % vertices.length;
                    area += vertices[i].latitude * vertices[j].longitude;
                    area -= vertices[j].latitude * vertices[i].longitude;
                }
                return Math.abs(area / 2.0);
            }

            QGCLabel {
                id: surveyAreaLabel
                color: "white"
                Layout.alignment: Qt.AlignHCenter
                font.pointSize: _showBoth ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize
                text: "Survey Area: " + getTotalSurveyArea()
            }

            QGCColoredImage {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                width:              height
                sourceSize.width:   width
                source:             "/qmlimages/TrackingIcon.svg"
                fillMode:           Image.PreserveAspectFit
            }

            ColumnLayout {
                id:                     batteryInfoColumn
                anchors.top:            parent.top
                anchors.bottom:         parent.bottom
                spacing:                0

                QGCLabel {
                    color: "white"
                    Layout.alignment: Qt.AlignHCenter
                    font.pointSize: _showBoth ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize
                    text: "Coverage: " + getCoverage()
                }
            }
        }
    }
}
