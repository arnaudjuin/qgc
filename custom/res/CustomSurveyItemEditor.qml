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

    property real _margin: ScreenTools.defaultFontPixelWidth / 2
    property var _missionItem: missionItem
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property real _heading: _activeVehicle ? _activeVehicle.heading.rawValue : 0
    property int selectedButton: -1 // Propriedade para armazenar o botão selecionado

    property int faixaLargura: 0
    property real velocidade: 0

    Component {
        id: _transectValuesComponent

        GridLayout {
            Layout.fillWidth: true
            Layout.margins: Qt.leftMargin | Qt.rightMargin
            columnSpacing: _margin
            rowSpacing: _margin
            columns: 2

            QGCLabel { text: qsTr("Alinhamento") }
            FactTextField {
                fact: missionItem.gridAngle
                Layout.fillWidth: true
                onUpdated: angleSlider.value = missionItem.gridAngle.value
            }

            QGCSlider {
                id: angleSlider
                from: 0
                to: 359
                stepSize: 1
                tickmarksEnabled: false
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                Layout.margins: Qt.leftMargin | Qt.rightMargin
                onValueChanged: missionItem.gridAngle.value = value
                Component.onCompleted: value = missionItem.gridAngle.value
                live: true
            }

            QGCLabel { text: qsTr("Distância para curva") }
            FactTextField {
                fact: missionItem.turnAroundDistance
                Layout.fillWidth: true
                onUpdated: turnAroundSlider.value = missionItem.turnAroundDistance.value
            }

            QGCSlider {
                id: turnAroundSlider
                from: 0
                to: 19
                stepSize: 0.5
                tickmarksEnabled: false
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                Layout.margins: Qt.leftMargin | Qt.rightMargin
                onValueChanged: missionItem.turnAroundDistance.value = value
                Component.onCompleted: value = missionItem.turnAroundDistance.value
                live: true
            }

            QGCLabel {
                text:       qsTr("Largura de faixa")
                visible:    !forPresets
            }

            FactTextField {
                fact:                   _missionItem.cameraCalc.adjustedFootprintSide
                Layout.fillWidth:       true
                onUpdated:              {
                    gridSlider.value = _missionItem.cameraCalc.adjustedFootprintSide.value
                    QGroundControl.corePlugin.showAdjustedFootprint = _missionItem.cameraCalc.adjustedFootprintSide.value
                    console.log("set value")
                }
            }

            QGCSlider {
                id:                     gridSlider
                from:           6
                to:           12
                stepSize:               2
                tickmarksEnabled:       false
                Layout.fillWidth:       true
                Layout.columnSpan:      2
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                onValueChanged:         {_missionItem.cameraCalc.adjustedFootprintSide.value = value;                    QGroundControl.corePlugin.showAdjustedFootprint = _missionItem.cameraCalc.adjustedFootprintSide.value}
                Component.onCompleted:  value = _missionItem.cameraCalc.adjustedFootprintSide.value
                live: true
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



            

            QGCOptionsComboBox {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                visible: false

                model: [
                    {
                        text: qsTr("Hover and capture image"),
                        fact: missionItem.hoverAndCapture,
                        enabled: missionItem.cameraCalc.distanceMode === QGroundControl.AltitudeModeRelative || missionItem.cameraCalc.distanceMode === QGroundControl.AltitudeModeAbsolute,
                        visible: missionItem.hoverAndCaptureAllowed
                    },
                    {
                        text: qsTr("Refly at 90 deg offset"),
                        fact: missionItem.refly90Degrees,
                        enabled: missionItem.cameraCalc.distanceMode !== QGroundControl.AltitudeModeCalcAboveTerrain,
                        visible: true
                    },
                    {
                        text: qsTr("Images in turnarounds"),
                        fact: missionItem.cameraTriggerInTurnAround,
                        enabled: missionItem.hoverAndCaptureAllowed ? !missionItem.hoverAndCapture.rawValue : true,
                        visible: true
                    },
                    {
                        text: qsTr("Fly alternate transects"),
                        fact: missionItem.flyAlternateTransects,
                        enabled: true,
                        visible: _vehicle ? (_vehicle.fixedWing || _vehicle.vtol) : false
                    }
                ]
            }
        }
    }

    KMLOrSHPFileDialog {
        id: kmlOrSHPLoadDialog
        title: qsTr("Select Polygon File")

        onAcceptedForLoad: (file) => {
            missionItem.surveyAreaPolygon.loadKMLOrSHPFile(file)
            missionItem.resetState = false
            close()
        }
    }
}