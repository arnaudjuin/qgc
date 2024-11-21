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

    FactTextField {
        id: factVazaoOffline
        fact: QGroundControl.settingsManager.appSettings.offlineEditingHoverSpeed
        visible: false
        Layout.fillWidth: true
    }

    Component {
        id: coverageVisual
        Row {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom

            // Timer to update the getActualCoverage every second
            Timer {
                id: coverageUpdateTimer
                interval: 1000 // 1 second interval
                repeat: true
                running: true
                onTriggered: {
                    coverageLabel.text = getActualCoverage();
                }
            }

            function getActualCoverage() {
                console.log("QGroundControl.corePlugin.adjustedFootprintSide " + QGroundControl.corePlugin.adjustedFootprintSide )
                console.log("_actalue: " + _activeVehicle.flightDistance.value);
                console.log("fact: " + factVazaoOffline.fact.value);
                let vazao = 0;
                if (factVazaoOffline.fact.value === 1700) vazao = 30;
                if (factVazaoOffline.fact.value === 1500) vazao = 20;
                if (factVazaoOffline.fact.value === 1300) vazao = 10;
                // Replace the hardcoded width (6) with the actual width if needed
                return (((_activeVehicle.flightDistance.value) / 10000) * vazao) > 0.01 
                ? ((_activeVehicle.flightDistance.value) * vazao) 
                : 0;            
            }

            /*QGCLabel {
                id: surveyAreaLabel
                color: "black"
                Layout.alignment: Qt.AlignHCenter
                font.pointSize: _showBoth ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize
                text: getActualCoverage()
            }*/
            RowLayout {
                id:                     batteryInfoColumn
                anchors.top:            parent.top
                anchors.bottom:         parent.bottom
                spacing:                35

                QGCColoredImage {
                    anchors.top:        parent.top
                    anchors.bottom:     parent.bottom
                    width:              height
                    sourceSize.width:   width
                    source:             "/qmlimages/AreaPulverizada.png"
                    fillMode:           Image.PreserveAspectFit
                     color: "black" 
                }



                QGCLabel {
                    id: coverageLabel
                    color: "black"
                    Layout.alignment: Qt.AlignHCenter
                    font.pointSize: _showBoth ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize
                    text: getActualCoverage()
                }
            }
        }
    }
}
