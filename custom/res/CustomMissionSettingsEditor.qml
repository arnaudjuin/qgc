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

    GridLayout {
        id:                 valuesColumn
        anchors.margins:    _margin
        Layout.fillWidth:   true
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        columnSpacing:      _margin + 80
        rowSpacing:         _margin 
        columns:            2

        CameraSection {
            id:         cameraSection
            checked:    !_waypointsOnlyMode && missionItem.cameraSection.settingsSpecified
            visible:    false
            Layout.columnSpan: 2
        }

        QGCLabel {
            anchors.left:           parent.left
            anchors.right:          parent.right
            text:                   qsTr("Above camera commands will take affect immediately upon mission start.")
            wrapMode:               Text.WordWrap
            horizontalAlignment:    Text.AlignHCenter
            font.pointSize:         ScreenTools.smallFontPointSize
            visible:                _showCameraSection && cameraSection.checked
            Layout.columnSpan: 2
        }

        QGCLabel {
            text: qsTr("Velocidade")
        }
        FactTextField {
            id: factFlightSpeed
            fact: QGroundControl.settingsManager.appSettings.offlineEditingCruiseSpeed
            visible: true
            enabled: true
            Layout.fillWidth: true
            onTextChanged: {
                flightSpeedSlider.value = factFlightSpeed.fact.value;
            }
        }
        QGCSlider {
            id: flightSpeedSlider
            from: 3.6
            to: 18
            stepSize: 3.6
            tickmarksEnabled: false
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
            value: factFlightSpeed.fact.value
            onValueChanged: {
                factFlightSpeed.fact.value = value;
            }
        }

        QGCLabel {
            text: qsTr("Vazão")
        }
        FactTextField {
            id : factVazaoOffline
            property string displayValue: {
                switch (factVazaoOffline.fact.value) {
                    case 1300: return "10L";
                    case 1500: return "20L";
                    case 1700: return "30L";
                    default: return factVazaoOffline.fact.value.toString();
                }
            }
            fact: QGroundControl.settingsManager.appSettings.offlineEditingHoverSpeed
            visible: true
            text: displayValue
            Layout.fillWidth: true
            onTextChanged: {
                vazaoSlider.value = factVazaoOffline.fact.value;
            }
        }
        QGCSlider {
            id: vazaoSlider
            from: 1
            to: 3
            stepSize: 1
            snapMode: QGCSlider.SnapAlways
            live: true
            Layout.columnSpan: 2
            Layout.fillWidth: true
            value: factVazaoOffline.fact.value
            onValueChanged: {
                var pwmValue = vazaoSlider.value === 1 ? 1300 : (vazaoSlider.value === 2 ? 1500 : 1700);
                factVazaoOffline.fact.value = pwmValue;
                QGroundControl.settingsManager.appSettings.offlineEditingHoverSpeed.value = pwmValue;
            }
        }

        QGCLabel {
            text: qsTr("Tamanho da gota")
        }
        FactTextField {
            id : factBicoOffline
            property string displayValue2: {
                switch (factBicoOffline.fact.value) {
                    case 1300: return "Grossa";
                    case 1500: return "Média";
                    case 1700: return "Fina";
                    default: return factBicoOffline.fact.value.toString();
                }
            }
            fact: QGroundControl.settingsManager.appSettings.offlineEditingAscentSpeed
            visible: true
            text: displayValue2
            Layout.fillWidth: true
            onTextChanged: {
                nozzleSlider.value = factBicoOffline.fact.value;
            }
        }
        QGCSlider {
            id: nozzleSlider
            from: 1
            to: 3
            stepSize: 1
            snapMode: QGCSlider.SnapAlways
            live: true
            Layout.columnSpan: 2
            Layout.fillWidth: true
            value: factBicoOffline.fact.value
            onValueChanged: {
                var pwmValue = nozzleSlider.value === 1 ? 1300 : (nozzleSlider.value === 2 ? 1500 : 1700);
                factBicoOffline.fact.value = pwmValue;
                QGroundControl.settingsManager.appSettings.offlineEditingAscentSpeed.value = pwmValue;
            }
        }
    }
} // Rectangle