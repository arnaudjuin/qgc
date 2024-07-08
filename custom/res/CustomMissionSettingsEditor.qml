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
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle

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

        QGCLabel {
            text:           qsTr("All Altitudes")
            font.pointSize: ScreenTools.smallFontPointSize
        }
        MouseArea {
            Layout.preferredWidth:  childrenRect.width
            Layout.preferredHeight: childrenRect.height
            enabled:                _noMissionItemsAdded

            onClicked: {
                var removeModes = []
                var updateFunction = function(altMode){ _missionController.globalAltitudeMode = altMode }
                if (!_controllerVehicle.supportsTerrainFrame) {
                    removeModes.push(QGroundControl.AltitudeModeTerrainFrame)
                }
                altModeDialogComponent.createObject(mainWindow, { rgRemoveModes: removeModes, updateAltModeFn: updateFunction }).open()
            }

            RowLayout {
                spacing: ScreenTools.defaultFontPixelWidth
                enabled: _noMissionItemsAdded

                QGCLabel {
                    id:     altModeLabel
                    text:   QGroundControl.altitudeModeShortDescription(_missionController.globalAltitudeMode)
                }
                QGCColoredImage {
                    height:     ScreenTools.defaultFontPixelHeight / 2
                    width:      height
                    source:     "/res/DropArrow.svg"
                    color:      altModeLabel.color
                }
            }
        }

        QGCLabel {
            text:           qsTr("Initial Waypoint Alt")
            font.pointSize: ScreenTools.smallFontPointSize
        }
        FactTextField {
            fact:               QGroundControl.settingsManager.appSettings.defaultMissionItemAltitude
            Layout.fillWidth:   true
        }


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

            SectionHeader {
                id:             vehicleInfoSectionHeader
                anchors.left:   parent.left
                anchors.right:  parent.right
                text:           qsTr("Vehicle Info")
                visible:        !_waypointsOnlyMode
                checked:        false
            }


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
                    width: _rightPanelWidth - 30
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
            RowLayout {

                /*QGCLabel {
                        id: pumpValue2
                        visible: true
                        color: "white"
                        text: "test"
                    }
                    QGCLabel {
                        id: pumpValue
                        visible: true
                        color: "white"
                        text: _activeVehicle ? QGroundControl.corePlugin.sprayPumpState : ""
                    }*/

                spacing: parent.width * 0.03
                QGCSwitch {
                    id: switchBomb
                    onCheckedChanged: {
                        if (switchBomb.checked) {
                            var pwmValue = bomba.value === 1 ? 1600 : (bomba.value === 2 ? 1500 : 1200);
                            //console.log("Switch ligado. Enviando PWM " + pwmValue + ".");
                            _activeVehicle.sendCommand(
                                        1,      // component
                                        183,    // command
                                        true,   // confirmation
                                        8,      // param1
                                        pwmValue // param2
                                        );
                        } else {
                            //console.log("Switch desligado. Enviando para Bomba PWM 1051.");
                            _activeVehicle.sendCommand(
                                        1,      // component
                                        183,    // command
                                        true,   // confirmation
                                        8,      // param1
                                        1051    // param2
                                        );
                        }
                    }


                }
                Item {
                    width: 40  // Defina a largura igual ao switch
                    height: 19.8 // Defina a altura igual ao switch

                    QGCButton {
                        id: autoBomb
                        anchors.fill: parent // Faz o botão preencher o Item
                        text: "Auto"
                        font.pixelSize: Math.max(10, parent.width * 0.020) // Ajusta o tamanho da fonte
                        property bool isActive: true
                        background: Rectangle { // Define um fundo retangular
                            color: autoBomb.isActive ? "#ff4800" : "green" // Cor do fundo
                            radius: 10 // Bordas arredondadas
                            anchors.fill: parent // Preenche todo o espaço do botão
                        }
                        onClicked: {
                            autoBomb.isActive = !autoBomb.isActive
                            switchBomb.checked = false
                        }
                    }
                }
                Label {
                    text: "Bombas"
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: headerArea.width * 0.06
                }
            }
            //Vazão Slider
            RowLayout{
                spacing: parent.width * 0.03

                Label{
                    text: "Vazão"
                    color: "white"
                    Layout.leftMargin: 12
                    font.pixelSize: headerArea.width * 0.06
                }

            }

            RowLayout {
                spacing: parent.width * 0.03

                QGCSlider {
                    id:                     bomba
                    from:                   1
                    to:                     3
                    stepSize:               1
                    snapMode: QGCSlider.SnapAlways

                    Layout.fillWidth: false  // Não preenche toda a largura
                    Layout.preferredWidth: 90
                    Layout.columnSpan:      2
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                    Layout.leftMargin: 12
                    live: true
                    onValueChanged: {
                        if (switchBomb.checked) {
                            var pwmValue = bomba.value === 1 ? 1600 : (bomba.value === 2 ? 1400 : 1200);
                            //console.log("Slider mudou. Enviando PWM " + pwmValue + ".");
                            console.log("PWN Value: ", pwmValue);
                            factBomba.fact.value = pwmValue;
                            QGroundControl.settingsManager.appSettings.offlineEditingHoverSpeed.value = pwmValue;
                            console.log(QGroundControl.settingsManager.appSettings.offlineEditingHoverSpeed.value);
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
                FactTextField {
                    id : factBomba
                    fact:                   QGroundControl.settingsManager.appSettings.offlineEditingHoverSpeed
                    visible:                true
                    Layout.preferredWidth:  _fieldWidth
                }
                Rectangle {
                    id: ret1
                    width: 40
                    height: 14
                    color: "#f0f0f0"  // Light grey background
                    border.color: "#d0d0d0"
                    border.width: 1
                    radius: 5

                    Label {
                        text: bomba.value === 1 ? "Alta" : bomba.value === 2 ? "Média" : "Baixa"
                        anchors.centerIn: parent
                        color: "#333333"
                        font.pixelSize: ret1.width * 0.20
                    }
                }
            }


        } // Column
    } // Column
} // Rectangle
