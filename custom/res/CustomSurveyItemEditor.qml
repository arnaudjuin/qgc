import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.FlightMap

TransectStyleComplexItemEditor {
    transectAreaDefinitionComplete: missionItem.surveyAreaPolygon.isValid
    transectAreaDefinitionHelp:     qsTr("Use the Polygon Tools to create the polygon which outlines your survey area.")
    transectValuesHeaderName:       qsTr("Transects")
    transectValuesComponent:        _transectValuesComponent
    presetsTransectValuesComponent: _transectValuesComponent

    // The following properties must be available up the hierarchy chain
    //  property real   availableWidth    ///< Width for control
    //  property var    missionItem       ///< Mission Item for editor

    property real   _margin:                ScreenTools.defaultFontPixelWidth / 2
    property var    _missionItem:           missionItem
    property var _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property real   _heading:               _activeVehicle   ? _activeVehicle.heading.rawValue : 0

    Component {
        id: _transectValuesComponent
    
        GridLayout {
            
            Layout.fillWidth:   true
            columnSpacing:      _margin
            rowSpacing:         _margin
            columns:            2

            QGCLabel { text: qsTr("Alinhamento") }
            FactTextField {
                fact:                   missionItem.gridAngle
                Layout.fillWidth:       true
                onUpdated:              angleSlider.value = missionItem.gridAngle.value
            }

            QGCSlider {
                id:                     angleSlider
                from:           0
                to:           359
                stepSize:               1
                tickmarksEnabled:       false
                Layout.fillWidth:       true
                Layout.columnSpan:      2
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                onValueChanged:         missionItem.gridAngle.value = value
                Component.onCompleted:  value = missionItem.gridAngle.value
                live: true
            }

            QGCLabel {
                id: headingLabel
                function _normalize(degrees) {
                    var a = degrees % 360
                    if (a < 0) a += 360
                    return a
                }
                
                property int _startAngle: modelData + 180 + _heading // Use modelData no cálculo do ângulo
                property int _angle: _normalize(_startAngle)
            }

            Text {
                id: headingDisplay
                text: "Graus: " + headingLabel._angle + "°"
                color: "black"
                font.pointSize: ScreenTools.defaultFontPointSize
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                Layout.columnSpan: 2
                anchors.top: angleSlider.bottom
                anchors.topMargin: 0
            }

            QGCLabel {
                text:       qsTr("Turnaround dist")
                visible:    !forPresets
            }
            FactTextField {
                fact:                   missionItem.turnAroundDistance
                Layout.fillWidth:       true
                onUpdated:              turnAroundSlider.value = missionItem.turnAroundDistance.value
            }

            QGCSlider {
                id:                     turnAroundSlider
                from:           0
                to:           19
                stepSize:               0.5
                tickmarksEnabled:       false
                Layout.fillWidth:       true
                Layout.columnSpan:      2
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                onValueChanged:         missionItem.turnAroundDistance.value = value
                Component.onCompleted:  value = missionItem.turnAroundDistance.value
                live: true
            }

            QGCLabel {
                text:       qsTr("Largura de faixa")
                visible:    !forPresets
            }

            FactTextField {
                fact:                   _missionItem.cameraCalc.adjustedFootprintSide
                Layout.fillWidth:       true
                onUpdated:              gridSlider.value = _missionItem.cameraCalc.adjustedFootprintSide.value
            }

            QGCSlider {
                id:                     gridSlider
                from:           5
                to:           12
                stepSize:               0.5
                tickmarksEnabled:       false
                Layout.fillWidth:       true
                Layout.columnSpan:      2
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                onValueChanged:         _missionItem.cameraCalc.adjustedFootprintSide.value = value
                Component.onCompleted:  value = _missionItem.cameraCalc.adjustedFootprintSide.value
                live: true
            }


            QGCOptionsComboBox {
                Layout.columnSpan:  2
                Layout.fillWidth:   true
                visible:            false

                model: [
                    {
                        text:       qsTr("Hover and capture image"),
                        fact:       missionItem.hoverAndCapture,
                        enabled:    missionItem.cameraCalc.distanceMode === QGroundControl.AltitudeModeRelative || missionItem.cameraCalc.distanceMode === QGroundControl.AltitudeModeAbsolute,
                        visible:    missionItem.hoverAndCaptureAllowed
                    },
                    {
                        text:       qsTr("Refly at 90 deg offset"),
                        fact:       missionItem.refly90Degrees,
                        enabled:    missionItem.cameraCalc.distanceMode !== QGroundControl.AltitudeModeCalcAboveTerrain,
                        visible:    true
                    },
                    {
                        text:       qsTr("Images in turnarounds"),
                        fact:       missionItem.cameraTriggerInTurnAround,
                        enabled:    missionItem.hoverAndCaptureAllowed ? !missionItem.hoverAndCapture.rawValue : true,
                        visible:    true
                    },
                    {
                        text:       qsTr("Fly alternate transects"),
                        fact:       missionItem.flyAlternateTransects,
                        enabled:    true,
                        visible:    _vehicle ? (_vehicle.fixedWing || _vehicle.vtol) : false
                    }
                ]
            }
        }
    }

    KMLOrSHPFileDialog {
        id:             kmlOrSHPLoadDialog
        title:          qsTr("Select Polygon File")

        onAcceptedForLoad: (file) => {
            missionItem.surveyAreaPolygon.loadKMLOrSHPFile(file)
            missionItem.resetState = false
            //editorMap.mapFitFunctions.fitMapViewportTomissionItems()
            close()
        }
    }
}
