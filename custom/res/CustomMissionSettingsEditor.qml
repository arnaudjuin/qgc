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

// Editor for Mission Settings
Rectangle {
    id:                 valuesRect
    width:              availableWidth
    height:             valuesColumn.height + (_margin * 2)
    color:              qgcPal.windowShadeDark
    visible:            missionItem.isCurrentItem
    radius:             _radius

    property var    _activeVehicle:                 QGroundControl.multiVehicleManager.activeVehicle
    property var    _masterControler:               masterController
    property var    _missionController:             _masterControler.missionController
    property var    _controllerVehicle:             _masterControler.controllerVehicle
    property bool   _vehicleHasHomePosition:        _controllerVehicle.homePosition.isValid
    property bool   _showCruiseSpeed:               !_controllerVehicle.multiRotor
    property bool   _showHoverSpeed:                _controllerVehicle.multiRotor || _controllerVehicle.vtol
    property bool   _multipleFirmware:              !QGroundControl.singleFirmwareSupport
    property bool   _multipleVehicleTypes:          !QGroundControl.singleVehicleSupport
    property real   _fieldWidth:                    ScreenTools.defaultFontPixelWidth * 16
    property bool   _mobile:                        ScreenTools.isMobile
    property var    _savePath:                      QGroundControl.settingsManager.appSettings.missionSavePath
    property var    _fileExtension:                 QGroundControl.settingsManager.appSettings.missionFileExtension
    property var    _appSettings:                   QGroundControl.settingsManager.appSettings
    property bool   _waypointsOnlyMode:             QGroundControl.corePlugin.options.missionWaypointsOnly
    property bool   _showCameraSection:             false
    property bool   _simpleMissionStart:            QGroundControl.corePlugin.options.showSimpleMissionStart
    property bool   _showFlightSpeed:               !_controllerVehicle.vtol && !_simpleMissionStart && !_controllerVehicle.apmFirmware
    property bool   _allowFWVehicleTypeSelection:   _noMissionItemsAdded && !globals.activeVehicle

    readonly property string _firmwareLabel:    qsTr("Firmware")
    readonly property string _vehicleLabel:     qsTr("Vehicle")
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth / 2

    QGCPalette { id: qgcPal }
    QGCFileDialogController { id: fileController }
    Component { id: altModeDialogComponent; AltModeDialog { } }

    Connections {
        target: _controllerVehicle
        function onSupportsTerrainFrameChanged() {
            if (!_controllerVehicle.supportsTerrainFrame && _missionController.globalAltitudeMode === QGroundControl.AltitudeModeTerrainFrame) {
                _missionController.globalAltitudeMode = QGroundControl.AltitudeModeCalcAboveTerrain
            }
        }
    }

    ColumnLayout {
        id:                 valuesColumn
        anchors.margins:    _margin
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        spacing:            _margin

        Column {
            Layout.fillWidth:   true
            spacing:            _margin
            visible:            !_simpleMissionStart

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

            GridLayout {
                anchors.left:   parent.left
                anchors.right:  parent.right
                columnSpacing:  ScreenTools.defaultFontPixelWidth
                rowSpacing:     columnSpacing
                columns:        2
                visible:        vehicleInfoSectionHeader.visible && vehicleInfoSectionHeader.checked

                RowLayout {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 13.5 : ScreenTools.defaultFontPixelWidth * 20
                    QGCLabel {
                        text: qsTr("Speed")
                        font.family: ScreenTools.demiboldFontFamily
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true
                    }
                }

                //Row for speed settings
                RowLayout {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 1 : ScreenTools.defaultFontPixelWidth * 3
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 2

                    QGCSlider {
                        id: flightSpeedSlider
                        property bool _loadComplete: false
                        from: 0
                        to: 7
                        stepSize: 0.5
                        Layout.fillWidth: true
                        value: factFlightSpeed.fact.value

                        onValueChanged: {
                            factFlightSpeed.fact.value = value;
                        }
                    }

                    Rectangle {
                        width: 40
                        height: 20
                        color: "#f0f0f0"  // Light grey background
                        border.color: "#d0d0d0"
                        border.width: 1
                        radius: 5
                        Layout.alignment: Qt.AlignRight

                        TextInput {
                            id: labelSpeed
                            text: factFlightSpeed.text
                            anchors.centerIn: parent
                            color: "#333333"
                            font.pixelSize: 12
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter

                            // Update the factFlightSpeed text when the user edits the TextInput
                            onEditingFinished: {
                                factFlightSpeed.text = labelSpeed.text;
                                flightSpeedSlider.value = parseFloat(labelSpeed.text);
                            }
                        }
                    }

                    FactTextField {
                        id: factFlightSpeed
                        fact: _missionController.visualItems.get(0).speedSection.flightSpeed
                        visible: false
                        enabled: flightSpeedCheckBox.checked
                        onTextChanged: {
                            labelSpeed.text = factFlightSpeed.text;
                            flightSpeedSlider.value = factFlightSpeed.fact.value;
                        }
                    }
                }

                //Vazão
                RowLayout {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 13.5 : ScreenTools.defaultFontPixelWidth * 20
                    QGCLabel {
                        text: qsTr("Vazão")
                        font.family: ScreenTools.demiboldFontFamily
                        Layout.alignment: Qt.AlignLeft
                        
                    }
                }

                //Row for speed settings
                RowLayout {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 1 : ScreenTools.defaultFontPixelWidth * 3
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 2

                    QGCSlider {
                        id: vazaoSlider
                        property bool _loadComplete: false
                        from: 1
                        to: 3
                        stepSize: 1
                        Layout.fillWidth: true
                        value: factVazao.fact.value

                        onValueChanged: {
                            var pwmValue = vazaoSlider.value === 1 ? 1600 : (vazaoSlider.value === 2 ? 1400 : 1200);
                            //console.log("Slider mudou. Enviando PWM " + pwmValue + ".");
                            _activeVehicle.sendCommand(
                                1,      // component
                                183,    // command
                                true,   // confirmation
                                8,      // param1
                                pwmValue // param2
                            );
                        }
                    }

                    Rectangle {
                        width: 40
                        height: 20
                        color: "#f0f0f0"  // Light grey background
                        border.color: "#d0d0d0"
                        border.width: 1
                        radius: 5
                        Layout.alignment: Qt.AlignRight

                        TextInput {
                            id: labelVazao
                            text: factVazao.text
                            anchors.centerIn: parent
                            color: "#333333"
                            font.pixelSize: 12
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter

                            // Update the factVazao text when the user edits the TextInput
                            onEditingFinished: {
                                factVazao.text = labelVazao.text;
                                vazaoSlider.value = parseFloat(labelVazao.text);
                            }
                        }
                    }

                    FactTextField {
                        id: factVazao
                        fact: _missionController.visualItems.get(0).speedSection.flightSpeed //@arnaudjuin fix here! We want to save the flow (Vazão) as a MissionParameter
                        visible: false
                        enabled: flightSpeedCheckBox.checked
                        onTextChanged: {
                            labelVazao.text = factVazao.text;
                            vazaoSlider.value = factVazao.fact.value;
                        }
                    }
                }
                
                   
               
            } // GridLayout


        } // Column
    } // Column
} // Rectangle