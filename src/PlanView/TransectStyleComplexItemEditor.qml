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

Rectangle {
    id:         _root
    height:     childrenRect.y + childrenRect.height + _margin
    width:      availableWidth
    color:      qgcPal.windowShadeDark
    radius:     _radius
    property real velocidade: 0
    property int selectedButton: -1 // Propriedade para armazenar o botão selecionado

    property bool   transectAreaDefinitionComplete: true
    property string transectAreaDefinitionHelp:     _internalError
    property string transectValuesHeaderName:       _internalError
    property var    transectValuesComponent:        undefined
    property var    presetsTransectValuesComponent: undefined

    readonly property string _internalError: "Internal Error"

    property var    _missionItem:               missionItem
    property real   _margin:                    ScreenTools.defaultFontPixelWidth / 2
    property real   _fieldWidth:                ScreenTools.defaultFontPixelWidth * 10.5
    property var    _vehicle:                   QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property real   _cameraMinTriggerInterval:  _missionItem.cameraCalc.minTriggerInterval.rawValue
    property string _doneAdjusting:             qsTr("Done")
    property bool   _presetsAvailable:          _missionItem.presetNames.length !== 0

    function polygonCaptureStarted() {
        _missionItem.clearPolygon()
    }

    function polygonCaptureFinished(coordinates) {
        for (var i=0; i<coordinates.length; i++) {
            _missionItem.addPolygonCoordinate(coordinates[i])
        }
    }

    function polygonAdjustVertex(vertexIndex, vertexCoordinate) {
        _missionItem.adjustPolygonCoordinate(vertexIndex, vertexCoordinate)
    }

    function polygonAdjustStarted() { }
    function polygonAdjustFinished() { }

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    ColumnLayout {
        id:                 editorColumn
        anchors.margins:    _margin
        anchors.top:        parent.top
        anchors.left:       parent.left
        anchors.right:      parent.right

        QGCLabel {
            id:                     transectAreaDefinitionCompleteLabel
            Layout.fillWidth:       true
            wrapMode:               Text.WordWrap
            horizontalAlignment:    Text.AlignHCenter
            text:                   transectAreaDefinitionHelp
            visible:                !transectAreaDefinitionComplete || _missionItem.wizardMode
        }

        ColumnLayout {
            Layout.fillWidth:   true
            spacing:            _margin
            visible:            transectAreaDefinitionComplete && !_missionItem.wizardMode

            TransectStyleComplexItemTabBar {
                id:                 tabBar
                Layout.fillWidth:   true
                visible: false
            }

            // Grid tab
            ColumnLayout {
                Layout.fillWidth:   true
                //spacing:            _margin
                visible:            tabBar.currentIndex === 0

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               qsTr("WARNING: Photo interval is below minimum interval (%1 secs) supported by camera.").arg(_cameraMinTriggerInterval.toFixed(1))
                    wrapMode:           Text.WordWrap
                    color:              qgcPal.warningText
                    visible:            _missionItem.cameraShots > 0 && _cameraMinTriggerInterval !== 0 && _cameraMinTriggerInterval > _missionItem.timeBetweenShots
                }

                /*CameraCalcGrid {
                    Layout.fillWidth:               true
                    cameraCalc:                     _missionItem.cameraCalc
                    vehicleFlightIsFrontal:         true
                    //distanceToSurfaceLabel:         qsTr("Altitude")
                    //frontalDistanceLabel:           qsTr("Trigger Dist")
                    //sideDistanceLabel:              qsTr("Largura de faixa") //adjustedFootprintSide
                }/*
                

                /*SectionHeader {
                    id:                 transectValuesHeader
                    Layout.fillWidth:   true
                    text:               transectValuesHeaderName
                }*/

                Loader {
                    Layout.fillWidth:   true
                    visible:            true
                    sourceComponent:    transectValuesComponent

                    property bool forPresets: false
                }

                QGCButton {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Rotacionar ponto de entrada")
                    onClicked:          _missionItem.rotateEntryPoint()
                    visible:            true
                }

                QGCLabel {
                    id:                 statsHeader
                    Layout.fillWidth:   true
                    text:               qsTr("Statistics")
                }

                TransectStyleComplexItemStats {
                    Layout.fillWidth:   true
                    //visible:            statsHeader.checked
                }

            QGCLabel { text: qsTr("Tamanho da gota") }
            FactTextField {
                id: factBicoOffline
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
                    nozzleSlider.value = factBicoOffline.fact.value
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
                //Layout.margins: Qt.leftMargin | Qt.rightMargin
                value: factBicoOffline.fact.value
                onValueChanged: {
                    var pwmValue = nozzleSlider.value === 1 ? 1300 : (nozzleSlider.value === 2 ? 1500 : 1700)
                    factBicoOffline.fact.value = pwmValue
                    QGroundControl.settingsManager.appSettings.offlineEditingAscentSpeed.value = pwmValue
                }
            }

            QGCLabel {
                text: qsTr("Vazão   L/Ha")
            }
            FactTextField {
                id : factVazaoOffline
                property string displayValue: {
                    switch (vazaoSlider.value) {
                        case 1: return "10L";
                        case 2: return "20L";
                        case 3: return "30L";
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
                    var pwmValue;
                    switch (gridSlider.value) {
                        case 6:
                            if (vazaoSlider.value === 1) pwmValue = 1200;
                            else if (vazaoSlider.value === 2) pwmValue = 1225;
                            else if (vazaoSlider.value === 3) pwmValue = 1250;
                            break;
                        case 8:
                            if (vazaoSlider.value === 1) pwmValue = 1200;
                            else if (vazaoSlider.value === 2) pwmValue = 1250;
                            else if (vazaoSlider.value === 3) pwmValue = 1300;
                            break;
                        case 10:
                            if (vazaoSlider.value === 1) pwmValue = 1200;
                            else if (vazaoSlider.value === 2) pwmValue = 1300;
                            else if (vazaoSlider.value === 3) pwmValue = 1350;
                            break;
                        case 12:
                            if (vazaoSlider.value === 1) pwmValue = 1225;
                            else if (vazaoSlider.value === 2) pwmValue = 1300;
                            else if (vazaoSlider.value === 3) pwmValue = 1400;
                            break;
                    }
                    QGroundControl.settingsManager.appSettings.offlineEditingHoverSpeed.value = pwmValue;
                    factVazaoOffline.fact.value = pwmValue;
                }
            }



                            QGCLabel { text: qsTr("Velocidade (Km/H)") }
            RowLayout {
                Layout.fillWidth: true

                QGCButton {
                    id: button36
                    text: "3.6"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: parent.selected ? "lightgrey" : "#ff4800" // Muda a cor de fundo
                        radius: 5
                    }
                    visible: (gridSlider.value === 6 && vazaoSlider.value === 3) ||
                            (gridSlider.value === 8 && (vazaoSlider.value === 2 || vazaoSlider.value === 3)) ||
                            (gridSlider.value === 10 && (vazaoSlider.value === 2 || vazaoSlider.value === 3)) ||
                            (gridSlider.value === 12 && (vazaoSlider.value === 2 || vazaoSlider.value === 3))
                    onClicked: {
                        selectedButton = 0;
                        var pwmValue = 1200;
                        QGroundControl.settingsManager.appSettings.offlineEditingCruiseSpeed.value = 3.6;
                        velocidade = 3.6;
                        factVazaoOffline.fact.value = pwmValue;
                    }
                    property bool selected: selectedButton === 0
                }

                QGCButton {
                    id: button72
                    text: "7.2"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: parent.selected ? "lightgrey" : "#ff4800"
                        radius: 5
                    }
                    visible: (gridSlider.value === 6 && (vazaoSlider.value === 2 || vazaoSlider.value === 3)) ||
                            (gridSlider.value === 8 && (vazaoSlider.value === 1 || vazaoSlider.value === 2 || vazaoSlider.value === 3)) ||
                            (gridSlider.value === 10 && (vazaoSlider.value === 1 || vazaoSlider.value === 2 || vazaoSlider.value === 3)) ||
                            (gridSlider.value === 12 && (vazaoSlider.value === 1 || vazaoSlider.value === 2 || vazaoSlider.value === 3))
                    onClicked: {
                        selectedButton = 1;
                        var pwmValue;
                        if (gridSlider.value === 6 && vazaoSlider.value === 2) {
                            pwmValue = 1225;
                        } else if (gridSlider.value === 6 && vazaoSlider.value === 3) {
                            pwmValue = 1250;
                        } else if (gridSlider.value === 8 && vazaoSlider.value === 1) {
                            pwmValue = 1200;
                        } else if (gridSlider.value === 8 && vazaoSlider.value === 2) {
                            pwmValue = 1250;
                        } else if (gridSlider.value === 8 && vazaoSlider.value === 3) {
                            pwmValue = 1300;
                        } else if (gridSlider.value === 10 && vazaoSlider.value === 1) {
                            pwmValue = 1200;
                        } else if (gridSlider.value === 10 && vazaoSlider.value === 2) {
                            pwmValue = 1300;
                        } else if (gridSlider.value === 10 && vazaoSlider.value === 3) {
                            pwmValue = 1350;
                        } else if (gridSlider.value === 12 && vazaoSlider.value === 1) {
                            pwmValue = 1225;
                        } else if (gridSlider.value === 12 && vazaoSlider.value === 2) {
                            pwmValue = 1300;
                        } else if (gridSlider.value === 12 && vazaoSlider.value === 3) {
                            pwmValue = 1400;
                        }
                        QGroundControl.settingsManager.appSettings.offlineEditingCruiseSpeed.value = 7.2;
                        velocidade = 7.2;
                        factVazaoOffline.fact.value = pwmValue;
                    }
                    property bool selected: selectedButton === 1
                }

                QGCButton {
                    id: button108
                    text: "10.8"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: parent.selected ? "lightgrey" : "#ff4800"
                        radius: 5
                    }
                    visible: (gridSlider.value === 6 && (vazaoSlider.value === 1 || vazaoSlider.value === 2 || vazaoSlider.value === 3)) ||
                            (gridSlider.value !== 6)
                    onClicked: {
                        selectedButton = 2;
                        var pwmValue;
                        if (gridSlider.value === 6 && vazaoSlider.value === 1) {
                            pwmValue = 1200;
                        } else if (gridSlider.value === 6 && vazaoSlider.value === 2) {
                            pwmValue = 1250;
                        } else if (gridSlider.value === 6 && vazaoSlider.value === 3) {
                            pwmValue = 1325;
                        } else if (gridSlider.value === 8 && vazaoSlider.value === 1) {
                            pwmValue = 1225;
                        } else if (gridSlider.value === 8 && vazaoSlider.value === 2) {
                            pwmValue = 1325;
                        } else if (gridSlider.value === 8 && vazaoSlider.value === 3) {
                            pwmValue = 1400;
                        } else if (gridSlider.value === 10 && vazaoSlider.value === 1) {
                            pwmValue = 1250;
                        } else if (gridSlider.value === 10 && vazaoSlider.value === 2) {
                            pwmValue = 1350;
                        } else if (gridSlider.value === 10 && vazaoSlider.value === 3) {
                            pwmValue = 1500;
                        } else if (gridSlider.value === 12 && vazaoSlider.value === 1) {
                            pwmValue = 1250;
                        } else if (gridSlider.value === 12 && vazaoSlider.value === 2) {
                            pwmValue = 1400;
                        } else if (gridSlider.value === 12 && vazaoSlider.value === 3) {
                            pwmValue = 1600;
                        }
                        QGroundControl.settingsManager.appSettings.offlineEditingCruiseSpeed.value = 10.8;
                        velocidade = 10.8;
                        factVazaoOffline.fact.value = pwmValue;
                    }
                    property bool selected: selectedButton === 2
                }
            }

            } // Grid Column

            // Camera Tab
            CameraCalcCamera {
                Layout.fillWidth:   true
                visible: false
                //visible:            tabBar.currentIndex === 1
                cameraCalc:         _missionItem.cameraCalc
            }

            // Terrain Tab
            TransectStyleComplexItemTerrainFollow {
                Layout.fillWidth:   true
                spacing:            _margin
                visible:            tabBar.currentIndex === 2
                missionItem:        _missionItem
            }

            // Presets Tab
            ColumnLayout {
                Layout.fillWidth:   true
                spacing:            _margin
                visible:            tabBar.currentIndex === 3

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               qsTr("Presets")
                    wrapMode:           Text.WordWrap
                }

                QGCComboBox {
                    id:                 presetCombo
                    Layout.fillWidth:   true
                    model:              _missionItem.presetNames
                }

                RowLayout {
                    Layout.fillWidth:   true

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Apply Preset")
                        enabled:            _missionItem.presetNames.length != 0
                        onClicked:          _missionItem.loadPreset(presetCombo.textAt(presetCombo.currentIndex))
                    }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Delete Preset")
                        enabled:            _missionItem.presetNames.length != 0
                        onClicked:          deletePresetDialog.createObject(mainWindow, { presetName: presetCombo.textAt(presetCombo.currentIndex) }).open()

                        Component {
                            id: deletePresetDialog

                            QGCSimpleMessageDialog {
                                title:      qsTr("Delete Preset")
                                text:       qsTr("Are you sure you want to delete '%1' preset?").arg(presetName)
                                buttons:    Dialog.Yes | Dialog.No

                                property string presetName

                                onAccepted: { _missionItem.deletePreset(presetName) }
                            }
                        }
                    }
                }

                Item { height: ScreenTools.defaultFontPixelHeight; width: 1 }

                QGCButton {
                    Layout.alignment:   Qt.AlignCenter
                    Layout.fillWidth:   true
                    text:               qsTr("Save Settings As New Preset")
                    onClicked:          savePresetDialog.createObject(mainWindow).open()
                }

                SectionHeader {
                    id:                 presectsTransectValuesHeader
                    Layout.fillWidth:   true
                    text:               transectValuesHeaderName
                    visible:            !!presetsTransectValuesComponent
                }

                Loader {
                    Layout.fillWidth:   true
                    visible:            presectsTransectValuesHeader.checked && !!presetsTransectValuesComponent
                    sourceComponent:    presetsTransectValuesComponent

                    property bool forPresets: true
                }

                SectionHeader {
                    id:                 presetsStatsHeader
                    Layout.fillWidth:   true
                    text:               qsTr("Statistics")
                }

                TransectStyleComplexItemStats {
                    Layout.fillWidth:   true
                    visible:            presetsStatsHeader.checked
                }
            } // Main editing column
        } // Top level  Column

        Component {
            id: savePresetDialog

            QGCPopupDialog {
                id:         popupDialog
                title:      qsTr("Save Preset")
                buttons:    Dialog.Save | Dialog.Cancel

                onAccepted: {
                    if (presetNameField.text != "") {
                        _missionItem.savePreset(presetNameField.text.trim())
                    } else {
                        preventClose = true
                    }
                }

                ColumnLayout {
                    width:      ScreenTools.defaultFontPixelWidth * 30
                    spacing:    ScreenTools.defaultFontPixelHeight

                    QGCLabel {
                        Layout.fillWidth:   true
                        text:               qsTr("Save the current settings as a named preset.")
                        wrapMode:           Text.WordWrap
                    }

                    QGCLabel {
                        text: qsTr("Preset Name")
                    }

                    QGCTextField {
                        id:                 presetNameField
                        Layout.fillWidth:   true
                        placeholderText:    qsTr("Enter preset name")

                        Component.onCompleted:  validateText(presetNameField.text)
                        onTextChanged:          validateText(text)

                        function validateText(text) {
                            if (text.trim() === "") {
                                nameError.text = qsTr("Preset name cannot be blank.")
                                popupDialog.acceptButtonEnabled = false
                            } else if (text.includes("/")) {
                                nameError.text = qsTr("Preset name cannot include the \"/\" character.")
                                popupDialog.acceptButtonEnabled = false
                            } else {
                                nameError.text = ""
                                popupDialog.acceptButtonEnabled = true
                            }
                        }
                    }

                    QGCLabel {
                        id:                 nameError
                        Layout.fillWidth:   true
                        wrapMode:           Text.WordWrap
                        color:              QGroundControl.globalPalette.warningText
                        visible:            text !== ""
                    }
                }
            }
        }
    }
}