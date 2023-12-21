import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Vehicle           1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0
import QGroundControl.SettingsManager   1.0
import QGroundControl.Controllers       1.0

// Editor for Mission Settings
Rectangle {
    id:                 valuesRect
    width:              availableWidth
    height:             valuesColumn.height + (_margin * 2)
    color:              qgcPal.windowShadeDark
    radius:             _radius
    visible:            missionItem.isCurrentItem

    property var    _masterControler:               masterController
    property var    _missionController:             _masterControler.missionController
    property var    _missionVehicle:                _masterControler.controllerVehicle
    property bool   _vehicleHasHomePosition:        _missionVehicle.homePosition.isValid
    property bool   _offlineEditing:                _missionVehicle.isOfflineEditingVehicle
    property bool   _enableOfflineVehicleCombos:    _offlineEditing && _noMissionItemsAdded
    property bool   _showCruiseSpeed:               !_missionVehicle.multiRotor
    property bool   _showHoverSpeed:                _missionVehicle.multiRotor || _missionVehicle.vtol
    property bool   _multipleFirmware:              QGroundControl.supportedFirmwareCount > 2
    property bool   _multipleVehicleTypes:          QGroundControl.supportedVehicleCount > 1
    property real   _fieldWidth:                    ScreenTools.defaultFontPixelWidth * 16
    property bool   _mobile:                        ScreenTools.isMobile
    property var    _savePath:                      QGroundControl.settingsManager.appSettings.missionSavePath
    property var    _fileExtension:                 QGroundControl.settingsManager.appSettings.missionFileExtension
    property var    _appSettings:                   QGroundControl.settingsManager.appSettings
    property bool   _waypointsOnlyMode:             QGroundControl.corePlugin.options.missionWaypointsOnly
    property bool   _showCameraSection:             (_waypointsOnlyMode || QGroundControl.corePlugin.showAdvancedUI) && !_missionVehicle.apmFirmware
    property bool   _simpleMissionStart:            QGroundControl.corePlugin.options.showSimpleMissionStart
    property bool   _showFlightSpeed:               !_missionVehicle.vtol && !_simpleMissionStart && !_missionVehicle.apmFirmware

    readonly property string _firmwareLabel:    qsTr("Firmware")
    readonly property string _vehicleLabel:     qsTr("Vehicle")
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth / 2

    QGCPalette { id: qgcPal }
    QGCFileDialogController { id: fileController }

    Column {
        id:                 valuesColumn
        anchors.margins:    _margin
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        spacing:            _margin


                QGCButton {
                    text:               "New"
                    Layout.fillWidth:   true

                    onClicked: {
                        insertComplexItemAfterCurrent( _missionController.complexMissionItemNames[0])
                        dropPanel.hide()
                    }
                }

        Row {
            width:      parent.width

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
                onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.value  = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.value - 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.max), QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.min)
            }
            Slider {
                property bool   _loadComplete:  false

                id:                 spraySpeed
                minimumValue:       QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.min
                maximumValue:       QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.max
                stepSize:           0.5
                tickmarksEnabled:   true
                width:150
                value:QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.value
            }

            QGCButton {
                height:                 parent.height
                width:                  height
                text:                   "+"
                anchors.verticalCenter: parent.verticalCenter

                onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.value  = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.value + 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.max), QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.min)
            }
            FactTextField {
                fact:                   QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow
                showUnits:              true
                showHelp:               false
                width:                  80
            }

        }
        Column {

            SectionHeader {
                id:             statsHeader
                anchors.left:   parent.left
                anchors.right:  parent.right
                text:           qsTr("Statistics")
            }

            Grid {
                columns:        2
                columnSpacing:  ScreenTools.defaultFontPixelWidth
                visible:        statsHeader.checked

                QGCLabel { text: qsTr("Layers") }
                QGCLabel { text: missionItem.layers.valueString }

                QGCLabel { text: qsTr("Layer Height") }
                QGCLabel { text: missionItem.cameraCalc.adjustedFootprintFrontal.valueString + " " + QGroundControl.appSettingsDistanceUnitsString }

                QGCLabel { text: qsTr("Top Layer Alt") }
                QGCLabel { text: QGroundControl.metersToAppSettingsDistanceUnits(missionItem.topFlightAlt).toFixed(1) + " " + QGroundControl.appSettingsDistanceUnitsString }

                QGCLabel { text: qsTr("Bottom Layer Alt") }
                QGCLabel { text: QGroundControl.metersToAppSettingsDistanceUnits(missionItem.bottomFlightAlt).toFixed(1) + " " + QGroundControl.appSettingsDistanceUnitsString }

                QGCLabel { text: qsTr("Photo Count") }
                QGCLabel { text: missionItem.cameraShots }

                QGCLabel { text: qsTr("Photo Interval") }
                QGCLabel { text: missionItem.timeBetweenShots.toFixed(1) + " " + qsTr("secs") }

                QGCLabel { text: qsTr("Trigger Distance") }
                QGCLabel { text: missionItem.cameraCalc.adjustedFootprintSide.valueString + " " + QGroundControl.appSettingsDistanceUnitsString }
            }



        }



        Column {
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        _margin
            visible:        false

            CameraSection {
                id:         cameraSection
                checked:    !_waypointsOnlyMode && missionItem.cameraSection.settingsSpecified
                visible:    _showCameraSection
            }

            QGCLabel {
                anchors.left:           parent.left
                anchors.right:          parent.right
                text:                   qsTr("Above camera commands will take affect immediately upon mission start.")
                wrapMode:               Text.WordWrap
                horizontalAlignment:    Text.AlignHCenter
                font.pointSize:         ScreenTools.smallFontPointSize
                visible:                _showCameraSection && cameraSection.checked
            }

            SectionHeader {
                id:             vehicleInfoSectionHeader
                anchors.left:   parent.left
                anchors.right:  parent.right
                text:           qsTr("Vehicle Info")
                visible:        false
                checked:        false
            }

            GridLayout {
                anchors.left:   parent.left
                anchors.right:  parent.right
                columnSpacing:  ScreenTools.defaultFontPixelWidth
                rowSpacing:     columnSpacing
                columns:        2
                visible:        vehicleInfoSectionHeader.visible && vehicleInfoSectionHeader.checked

                //                QGCLabel {
                //                    text:               _firmwareLabel
                //                    Layout.fillWidth:   true
                //                    visible:            _multipleFirmware
                //                }
                //                FactComboBox {
                //                    fact:                   QGroundControl.settingsManager.appSettings.offlineEditingFirmwareType
                //                    indexModel:             false
                //                    Layout.preferredWidth:  _fieldWidth
                //                    visible:                _multipleFirmware
                //                    enabled:                _enableOfflineVehicleCombos
                //                }
                //
                //                QGCLabel {
                //                    text:               _vehicleLabel
                //                    Layout.fillWidth:   true
                //                    visible:            _multipleVehicleTypes
                //                }
                //                FactComboBox {
                //                    fact:                   QGroundControl.settingsManager.appSettings.offlineEditingVehicleType
                //                    indexModel:             false
                //                    Layout.preferredWidth:  _fieldWidth
                //                    visible:                _multipleVehicleTypes
                //                    enabled:                _enableOfflineVehicleCombos
                //                }

                QGCLabel {
                    text:               qsTr("Cruise speed")
                    visible:            _showCruiseSpeed
                    Layout.fillWidth:   true
                }
                FactTextField {
                    fact:                   QGroundControl.settingsManager.appSettings.offlineEditingCruiseSpeed
                    visible:                _showCruiseSpeed
                    Layout.preferredWidth:  _fieldWidth
                }

                QGCLabel {
                    text:               qsTr("Hover speed")
                    visible:            _showHoverSpeed
                    Layout.fillWidth:   true
                }
                FactTextField {
                    fact:                   QGroundControl.settingsManager.appSettings.offlineEditingHoverSpeed
                    visible:                _showHoverSpeed
                    Layout.preferredWidth:  _fieldWidth
                }
                QGCLabel
                {
                    text:               qsTr("Spray Ammount")
                    visible:            true
                    Layout.fillWidth:   true
                }
                FactTextField {
                    fact:                   QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow
                    visible:                true
                    Layout.preferredWidth:  _fieldWidth
                }
            } // GridLayout


            //            SectionHeader {
            //                id:             plannedHomePositionSection
            //                anchors.left:   parent.left
            //                anchors.right:  parent.right
            //                text:           qsTr("Launch Position")
            //                visible:        !_vehicleHasHomePosition
            //                checked:        false
            //            }
            //
            //            Column {
            //                anchors.left:   parent.left
            //                anchors.right:  parent.right
            //                spacing:        _margin
            //                visible:        plannedHomePositionSection.checked && !_vehicleHasHomePosition
            //
            //                GridLayout {
            //                    anchors.left:   parent.left
            //                    anchors.right:  parent.right
            //                    columnSpacing:  ScreenTools.defaultFontPixelWidth
            //                    rowSpacing:     columnSpacing
            //                    columns:        2
            //
            //                    QGCLabel {
            //                        text: qsTr("Altitude")
            //                    }
            //                    FactTextField {
            //                        fact:               missionItem.plannedHomePositionAltitude
            //                        Layout.fillWidth:   true
            //                    }
            //                }
            //
            //                QGCLabel {
            //                    width:                  parent.width
            //                    wrapMode:               Text.WordWrap
            //                    font.pointSize:         ScreenTools.smallFontPointSize
            //                    text:                   qsTr("Actual position set by vehicle at flight time.")
            //                    horizontalAlignment:    Text.AlignHCenter
            //                }
            //
            //                QGCButton {
            //                    text:                       qsTr("Set To Map Center")
            //                    onClicked:                  missionItem.coordinate = map.center
            //                    anchors.horizontalCenter:   parent.horizontalCenter
            //                }
            //            }
        } // Column
    } // Column
} // Rectangle