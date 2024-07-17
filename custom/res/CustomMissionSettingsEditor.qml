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

            ColumnLayout {

                Layout.fillWidth: true
                spacing: _margin
                visible: vehicleInfoSectionHeader.visible && vehicleInfoSectionHeader.checked
            
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 60
                    QGCLabel {
                        text: qsTr("Speed")
                    }
                    FactTextField {
                        id: factFlightSpeed
                        fact: _missionController.visualItems.get(0).speedSection.flightSpeed
                        visible: true
                        enabled: true
                        Layout.alignment: Qt.AlignRight
                        onTextChanged: {
                            flightSpeedSlider.value = factFlightSpeed.fact.value;
                        }
                    }
                }
                QGCSlider {
                    id: flightSpeedSlider
                    property bool _loadComplete: false
                    from: 0
                    to: 15
                    stepSize: 0.5
                    tickmarksEnabled: false
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                    value: factFlightSpeed.fact.value
                    onValueChanged: {
                        factFlightSpeed.fact.value = value;
                    }
                }
            } // GridLayout

            ColumnLayout {
                
                Layout.fillWidth: true
                spacing: _margin
                visible: vehicleInfoSectionHeader.visible && vehicleInfoSectionHeader.checked

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 60
                    QGCLabel {
                        text: qsTr("Vazão")
                    }
                    FactTextField {
                        id : factVazaoOffline
                        property string displayValue: {
                            switch (factVazaoOffline.fact.value) {
                                case 1200: return "Baixa";
                                case 1400: return "Média";
                                case 1600: return "Alta";
                                default: return factVazaoOffline.fact.value.toString();
                            }
                        }
                        fact:                   QGroundControl.settingsManager.appSettings.offlineFlowRoverSetting
                        visible:                true
                        text: displayValue
                        Layout.alignment: Qt.AlignRight
                        onTextChanged: {
                            vazaoSlider.value = factVazaoOffline.fact.value;
                        }
                    }
                }
                QGCSlider {
                    id: vazaoSlider
                    property bool _loadComplete: false
                    from: 1
                    to: 3
                    stepSize: 1
                    Layout.fillWidth: true
                    value: factVazaoOffline.fact.value

                    onValueChanged: {
                        var pwmValue = vazaoSlider.value === 1 ? 1600 : (vazaoSlider.value === 2 ? 1400 : 1200);
                        //console.log("Slider mudou. Enviando PWM " + pwmValue + ".");
                        factVazaoOffline.fact.value = pwmValue;
                    QGroundControl.settingsManager.appSettings.offlineFlowRoverSetting.value = pwmValue;
                        _activeVehicle.sendCommand(
                            1,      // component
                            183,    // command
                            true,   // confirmation
                            8,      // param1
                            pwmValue // param2
                        );
                    }
                }
            }
        } // Column
    } // Column
} // Rectangle