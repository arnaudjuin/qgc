/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQml.Models
import QGroundControl
import QGroundControl.Controls

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Controllers
import GlobalSignals 1.0
import QGroundControl.FlightDisplay

Rectangle {
    id:     _root
    width:  parent.width
    height: ScreenTools.toolbarHeight
    color:  "#ff4800"

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property bool   _armed:             _activeVehicle ? _activeVehicle.armed : false
    property color  _mainStatusBGColor: "#ff4800"
    
    // Propriedade para medir o progresso da missão
    property real missionProgress: _activeVehicle ? _activeVehicle.missionManager.progress : 0
    // Propriedade para verificar se o veículo está em uma missão ativa
    property bool missionActive: _activeVehicle ? _activeVehicle.missionManager.isMissionActive : false

    function dropMessageIndicatorTool() {
        toolIndicators.dropMessageIndicatorTool();
    }

    QGCPalette { id: qgcPal }

    /// Bottom single pixel divider
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        visible: false
        height:         1
        color:          "black"
    }

    Rectangle {
        anchors.fill: viewButtonRow
        
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0;                                     color: _mainStatusBGColor }
            GradientStop { position: currentButton.x + currentButton.width; color: _mainStatusBGColor }
            GradientStop { position: 1;                                     color: _root.color }
        }
    }

    RowLayout {
        id:                     viewButtonRow
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        spacing:                ScreenTools.defaultFontPixelWidth / 2

        QGCToolBarButton {
            id: currentButton
            Layout.preferredHeight: viewButtonRow.height
            logo: true
            onClicked: mainWindow.showToolSelectDialog()
        
            Image {
                source: "qrc:/custom/img/menu.svg"
                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
                width: parent.width * 0.6
                height: parent.height * 0.6
            }
        }

        Item {
            Layout.preferredHeight: viewButtonRow.height
            width: parent.width

            Image {
                source: "/custom/img/logohural.png"
                fillMode: Image.PreserveAspectFit
                width: 82
                height: 82
                anchors.verticalCenter: parent.verticalCenter
                visible: !_activeVehicle
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: 90
            }
        }

        // Círculo de progresso do carregamento
        Canvas {
            id: progressCircle
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenterOffset: -50
            visible: _activeVehicle && !_activeVehicle.initialConnectComplete 

            onPaint: {
                if (_activeVehicle && !_activeVehicle.initialConnectComplete) {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    // Círculo de fundo (cinza)
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, width / 2 - 5, 0, 2 * Math.PI, false);
                    ctx.lineWidth = 5;
                    ctx.strokeStyle = "#e0e0e0";
                    ctx.stroke();

                    // Círculo de progresso de carregamento (verde)
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, width / 2 - 5, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * _activeVehicle.loadProgress, false);
                    ctx.lineWidth = 5;
                    ctx.strokeStyle = "#4CAF50";
                    ctx.stroke();
                }
            }

            Timer {
                interval: 16 
                running: true
                repeat: true
                onTriggered: {
                    if (_activeVehicle && _activeVehicle.initialConnectComplete) {
                        progressCircle.visible = false; 
                    } else {
                        progressCircle.requestPaint();
                    }
                }
            }

           
            QGCLabel {
                anchors.centerIn: parent
                text: Math.round(_activeVehicle.loadProgress * 100) + "%"
                color: "#4CAF50"
                font.bold: true
                visible: _activeVehicle && !_activeVehicle.initialConnectComplete 
            }
        }

        // Círculo de progresso da missão
        // Círculo de progresso da missão
        Canvas {
            id: missionProgressCircle
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenterOffset: -50
            visible: true // Sempre visível para testes

            property real missionProgress: 0.0 // Progresso inicial (0.0 a 1.0)
            property int totalWaypoints: _missionController.missionItemCount
            property int currentWaypoint: _missionController.currentMissionIndex

            // Atualiza o progresso da missão com base nos waypoints
            Connections {
                target: _missionController
                onCurrentMissionIndexChanged: {
                    if (totalWaypoints > 0) {
                        missionProgress = currentWaypoint / totalWaypoints;
                        console.log("Progresso da missão: " + Math.round(missionProgress * 100) + "%");
                        missionProgressCircle.requestPaint();
                    }
                }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                // Fundo cinza
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, width / 2 - 5, 0, 2 * Math.PI, false);
                ctx.lineWidth = 8;
                ctx.strokeStyle = "#e0e0e0";
                ctx.stroke();

                // Progresso azul
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, width / 2 - 5, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * missionProgress, false);
                ctx.lineWidth = 8;
                ctx.strokeStyle = "#2196F3";
                ctx.stroke();
            }

            // Texto para exibir o percentual
            QGCLabel {
                anchors.centerIn: parent
                text: Math.round(missionProgress * 100) + "%"
                color: "#2196F3"
                font.bold: true
            }
        }



        

        QGCButton {
            id:                 disconnectButton
            text:               qsTr("Disconnect")
            onClicked:          _activeVehicle.closeVehicle()
            visible:            _activeVehicle && _communicationLost
        }
    }

    MainStatusIndicator {
        anchors.right:parent.right
        visible: false
    }

    QGCFlickable {
        id: toolsFlickable
        width: toolIndicators.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        contentWidth: toolIndicators.width
        flickableDirection: Flickable.HorizontalFlick

        FlyViewToolBarIndicators {
            id: toolIndicators

            QGCButton {
                id: armDisarmButton
                text: _armed ? qsTr("Desarmar") : qsTr("Armar")
                visible:            _activeVehicle
                onClicked: {
                    if (!_armed) {
                        GlobalSignals.buttonArm()
                    }
                    else {
                        GlobalSignals.buttonDisarm()
                    }
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Branding Logo
    Image {
        anchors.right:          parent.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.margins:        ScreenTools.defaultFontPixelHeight * 0.66
        visible: false
        fillMode:               Image.PreserveAspectFit
        source:                 _outdoorPalette ? _brandImageOutdoor : _brandImageIndoor
        mipmap:                 true

        property bool   _outdoorPalette:        qgcPal.globalTheme === QGCPalette.Light
        property bool   _corePluginBranding:    QGroundControl.corePlugin.brandImageIndoor.length != 0
        property string _userBrandImageIndoor:  QGroundControl.settingsManager.brandImageSettings.userBrandImageIndoor.value
        property string _userBrandImageOutdoor: QGroundControl.settingsManager.brandImageSettings.userBrandImageOutdoor.value
        property bool   _userBrandingIndoor:    _userBrandImageIndoor.length != 0
        property bool   _userBrandingOutdoor:   _userBrandImageOutdoor.length != 0
        property string _brandImageIndoor:      brandImageIndoor()
        property string _brandImageOutdoor:     brandImageOutdoor()

        function brandImageIndoor() {
            if (_userBrandingIndoor) {
                return _userBrandImageIndoor
            } else {
                if (_userBrandingOutdoor) {
                    return _userBrandImageOutdoor
                } else {
                    if (_corePluginBranding) {
                        return QGroundControl.corePlugin.brandImageIndoor
                    } else {
                        return _activeVehicle ? _activeVehicle.brandImageIndoor : ""
                    }
                }
            }
        }

        function brandImageOutdoor() {
            if (_userBrandingOutdoor) {
                return _userBrandImageOutdoor
            } else {
                if (_userBrandingIndoor) {
                    return _userBrandingIndoor
                } else {
                    if (_corePluginBranding) {
                        return QGroundControl.corePlugin.brandImageOutdoor
                    } else {
                        return _activeVehicle ? _activeVehicle.brandImageOutdoor : ""
                    }
                }
            }
        }
    }
}
