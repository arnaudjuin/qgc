import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0

// Camera calculator "Grid" section for mission item editors
Column {
    anchors.left:   parent.left
    anchors.right:  parent.right
    spacing:        _margin

    property var    cameraCalc
    property bool   vehicleFlightIsFrontal:         true
    property string distanceToSurfaceLabel
    property int    distanceToSurfaceAltitudeMode:  QGroundControl.AltitudeModeNone
    property string frontalDistanceLabel
    property string sideDistanceLabel

    property real   _margin:            ScreenTools.defaultFontPixelWidth / 2
    property string _cameraName:        cameraCalc.cameraName.value
    property real   _fieldWidth:        ScreenTools.defaultFontPixelWidth * 10.5
    property var    _cameraList:        [ ]
    property var    _vehicle:           QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property var    _vehicleCameraList: _vehicle ? _vehicle.staticCameraList : []
    property bool   _cameraComboFilled: false

    readonly property int _gridTypeManual:          0
    readonly property int _gridTypeCustomCamera:    1
    readonly property int _gridTypeCamera:          2

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    Column {
        anchors.left:   parent.left
        anchors.right:  parent.right
        spacing:        _margin
        visible:        !cameraCalc.isManualCamera

        RowLayout {
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        _margin
            Item { Layout.fillWidth: true }
            QGCLabel {
                Layout.preferredWidth:  _root._fieldWidth
                text:                   qsTr("Front Lap")
            }
            QGCLabel {
                Layout.preferredWidth:  _root._fieldWidth
                text:                   qsTr("Side Lap")
            }
        }

        RowLayout {
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        _margin
            QGCLabel { text: qsTr("Overlap"); Layout.fillWidth: true }
            FactTextField {
                Layout.preferredWidth:  _root._fieldWidth
                fact:                   cameraCalc.frontalOverlap
            }
            FactTextField {
                Layout.preferredWidth:  _root._fieldWidth
                fact:                   cameraCalc.sideOverlap
            }
        }

        QGCLabel {
            wrapMode:               Text.WordWrap
            text:                   qsTr("Select one:")
            Layout.preferredWidth:  parent.width
            Layout.columnSpan:      2
        }

        GridLayout {
            anchors.left:   parent.left
            anchors.right:  parent.right
            columnSpacing:  _margin
            rowSpacing:     _margin
            columns:        2

            QGCRadioButton {
                id:                     fixedDistanceRadio
                text:                   distanceToSurfaceLabel
                checked:                !!cameraCalc.valueSetIsDistance.value
                onClicked:              cameraCalc.valueSetIsDistance.value = 1
            }




            QGCRadioButton {
                id:                     fixedImageDensityRadio
                text:                   qsTr("Ground Res")
                checked:                !cameraCalc.valueSetIsDistance.value
                onClicked:              cameraCalc.valueSetIsDistance.value = 0
            }

            FactTextField {
                fact:                   cameraCalc.imageDensity
                enabled:                fixedImageDensityRadio.checked
                Layout.fillWidth:       true
            }
        }
    } // Column - Camera spec based ui

    // No camera spec ui
    GridLayout {
        anchors.left:   parent.left
        anchors.right:  parent.right
        columnSpacing:  _margin
        rowSpacing:     _margin
        columns:        2
        visible:        cameraCalc.isManualCamera

        Rectangle {
            id:                 basicSurveyRectangle
            anchors.left:       parent.left
            anchors.right:      parent.right
            color:"transparent"
            //TODOSUIND
            height:             500

            Column {
                id:                 basicSurveyColumn
                anchors.margins:    _margins
                anchors.left:       parent.left
                anchors.right:      parent.right
                anchors.top:        parent.top
                spacing:            _margins


                Row {
                    width:      parent.width
                    spacing:            ScreenTools.defaultFontPixelWidth * 4

                    QGCLabel {
                        text:       qsTr("Travel Height")
                        font.family: ScreenTools.demiboldFontFamily
                    }
                }
                Row {
                    width:      parent.width
                    spacing:            ScreenTools.defaultFontPixelWidth * 1
                    anchors.topMargin:  ScreenTools.defaultFontPixelWidth * 2
                    QGCButton {
                        height:                 parent.height
                        width:                  height
                        text:                   "-"
                        anchors.verticalCenter: parent.verticalCenter
                        //onClicked: fact.value = Math.max(Math.min(fact.value - _minIncrement, fact.max), fact.min)
                    }
                    Slider {

                        id:                 travelHeight
                        minimumValue:       0.08
                        maximumValue:       4
                        stepSize:           1
                        tickmarksEnabled:   true

                        //                                onValueChanged: {
                        //                                    if (_loadComplete) {
                        //                                        _rateRollP.value = value
                        //                                        _rateRollI.value = value
                        //                                        _ratePitchP.value = value
                        //                                        _ratePitchI.value = value
                        //                                    }
                    }

                    QGCButton {
                        height:                 parent.height
                        width:                  height
                        text:                   "+"
                        anchors.verticalCenter: parent.verticalCenter

                        //onClicked: fact.value = Math.max(Math.min(fact.value - _minIncrement, fact.max), fact.min)
                    }
                    FactTextField {
                        anchors.verticalCenter: parent.verticalCenter
                        fact:                   sliderRoot.fact
                        showUnits:              true
                        showHelp:               false
                        text:                   "2"
                        width:                  30
                    }
                }
                Row {
                    width:      parent.width
                    spacing:            ScreenTools.defaultFontPixelWidth * 4

                    QGCLabel {
                        text:       qsTr("Spray Height")
                        font.family: ScreenTools.demiboldFontFamily
                    }
                }
                Row {
                    width:      parent.width
                    spacing:            ScreenTools.defaultFontPixelWidth * 1
                    anchors.topMargin:  ScreenTools.defaultFontPixelWidth * 2
                    QGCButton {
                        height:                 parent.height
                        width:                  height
                        text:                   "-"
                        anchors.verticalCenter: parent.verticalCenter
                        //onClicked: fact.value = Math.max(Math.min(fact.value - _minIncrement, fact.max), fact.min)
                    }
                    Slider {

                        id:                 sprayHeight
                        minimumValue:       0.08
                        maximumValue:       4
                        stepSize:           1
                        tickmarksEnabled:   true

                        //                                onValueChanged: {
                        //                                    if (_loadComplete) {
                        //                                        _rateRollP.value = value
                        //                                        _rateRollI.value = value
                        //                                        _ratePitchP.value = value
                        //                                        _ratePitchI.value = value
                        //                                    }
                    }

                    QGCButton {
                        height:                 parent.height
                        width:                  height
                        text:                   "+"
                        anchors.verticalCenter: parent.verticalCenter

                        //onClicked: fact.value = Math.max(Math.min(fact.value - _minIncrement, fact.max), fact.min)
                    }
                    FactTextField {
                        anchors.verticalCenter: parent.verticalCenter
                        fact:                   sliderRoot.fact
                        showUnits:              true
                        showHelp:               false
                        text:                   "2"
                        width:                  30
                    }
                }
                Row {
                    width:      parent.width
                    spacing:            ScreenTools.defaultFontPixelWidth * 4

                    QGCLabel {
                        text:       qsTr("Spray Volume")
                        font.family: ScreenTools.demiboldFontFamily
                    }
                }
                Row {
                    width:      parent.width
                    spacing:            ScreenTools.defaultFontPixelWidth * 1
                    anchors.topMargin:  ScreenTools.defaultFontPixelWidth * 2
                    QGCButton {
                        height:                 parent.height
                        width:                  height
                        text:                   "-"
                        anchors.verticalCenter: parent.verticalCenter
                        //onClicked: fact.value = Math.max(Math.min(fact.value - _minIncrement, fact.max), fact.min)
                    }
                    Slider {

                        id:                 sprayVolume
                        minimumValue:       0.08
                        maximumValue:       4
                        stepSize:           1
                        tickmarksEnabled:   true

                        //                                onValueChanged: {
                        //                                    if (_loadComplete) {
                        //                                        _rateRollP.value = value
                        //                                        _rateRollI.value = value
                        //                                        _ratePitchP.value = value
                        //                                        _ratePitchI.value = value
                        //                                    }
                    }

                    QGCButton {
                        height:                 parent.height
                        width:                  height
                        text:                   "+"
                        anchors.verticalCenter: parent.verticalCenter

                        //onClicked: fact.value = Math.max(Math.min(fact.value - _minIncrement, fact.max), fact.min)
                    }
                    FactTextField {
                        anchors.verticalCenter: parent.verticalCenter
                        fact:                   sliderRoot.fact
                        showUnits:              true
                        showHelp:               false
                        text:                   "2"
                        width:                  30
                    }
                }
                Row {
                    width:      parent.width
                    spacing:            ScreenTools.defaultFontPixelWidth * 4

                    QGCLabel {
                        text:       qsTr("Spacing")
                        font.family: ScreenTools.demiboldFontFamily
                    }
                }
                Row {
                    width:      parent.width
                    spacing:            ScreenTools.defaultFontPixelWidth * 1
                    anchors.topMargin:  ScreenTools.defaultFontPixelWidth * 2
                    QGCButton {
                        height:                 parent.height
                        width:                  height
                        text:                   "-"
                        anchors.verticalCenter: parent.verticalCenter
                        //onClicked: fact.value = Math.max(Math.min(fact.value - _minIncrement, fact.max), fact.min)
                    }
                    Slider {

                        id:                 spacing
                        minimumValue:       0.08
                        maximumValue:       4
                        stepSize:           1
                        tickmarksEnabled:   true

                        //                                onValueChanged: {
                        //                                    if (_loadComplete) {
                        //                                        _rateRollP.value = value
                        //                                        _rateRollI.value = value
                        //                                        _ratePitchP.value = value
                        //                                        _ratePitchI.value = value
                        //                                    }
                    }

                    QGCButton {
                        height:                 parent.height
                        width:                  height
                        text:                   "+"
                        anchors.verticalCenter: parent.verticalCenter

                        //onClicked: fact.value = Math.max(Math.min(fact.value - _minIncrement, fact.max), fact.min)
                    }
                    FactTextField {
                        anchors.verticalCenter: parent.verticalCenter
                        fact:                   sliderRoot.fact
                        showUnits:              true
                        showHelp:               false
                        text:                   "2"
                        width:                  30
                    }
                }
                Row {
                    width:      parent.width
                    spacing:            ScreenTools.defaultFontPixelWidth * 4

                    QGCLabel {
                        text:       qsTr("Spray Speed")
                        font.family: ScreenTools.demiboldFontFamily
                    }
                }
                Row {
                    width:      parent.width
                    spacing:            ScreenTools.defaultFontPixelWidth * 1
                    anchors.topMargin:  ScreenTools.defaultFontPixelWidth * 2
                    QGCButton {
                        height:                 parent.height
                        width:                  height
                        text:                   "-"
                        anchors.verticalCenter: parent.verticalCenter
                        //onClicked: fact.value = Math.max(Math.min(fact.value - _minIncrement, fact.max), fact.min)
                    }
                    Slider {

                        id:                 spraySpeed
                        minimumValue:       0.08
                        maximumValue:       4
                        stepSize:           1
                        tickmarksEnabled:   true

                        //                                onValueChanged: {
                        //                                    if (_loadComplete) {
                        //                                        _rateRollP.value = value
                        //                                        _rateRollI.value = value
                        //                                        _ratePitchP.value = value
                        //                                        _ratePitchI.value = value
                        //                                    }
                    }

                    QGCButton {
                        height:                 parent.height
                        width:                  height
                        text:                   "+"
                        anchors.verticalCenter: parent.verticalCenter

                        //onClicked: fact.value = Math.max(Math.min(fact.value - _minIncrement, fact.max), fact.min)
                    }
                    FactTextField {
                        anchors.verticalCenter: parent.verticalCenter
                        fact:                   sliderRoot.fact
                        showUnits:              true
                        showHelp:               false
                        text:                   "2"
                        width:                  30
                    }
                }


            }
        }

    } // GridLayout
} // Column

