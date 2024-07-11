/****************************************************************************
 *
 * (c) 2009-2019 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 * @file
 *   @author Gus Grubba <gus@auterion.com>
 */

import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import Custom.Widgets
import QGroundControl.Controllers

Item {
    property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.initialConnectComplete : true

    Loader {
        id: controllerLoader
        active: _initialDownloadComplete // This loader becomes active when _initialDownloadComplete is tråue
        sourceComponent: factPanelControllerComponent
    }

    Component {
        id: factPanelControllerComponent
        FactPanelController {
            // Initialize your FactPanelController here
        }
    }

    property var parentToolInsets                       // These insets tell you what screen real estate is available for positioning the controls in your overlay
    property var totalToolInsets:   _totalToolInsets    // The insets updated for the custom overlay additions
    property var mapControl

    readonly property string noGPS:         qsTr("NO GPS")
    readonly property real   indicatorValueWidth:   ScreenTools.defaultFontPixelWidth * 7

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property real   _indicatorDiameter:     ScreenTools.defaultFontPixelWidth * 18
    property real   _indicatorsHeight:      ScreenTools.defaultFontPixelHeight
    property var    _sepColor:              qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(0,0,0,0.5) : Qt.rgba(1,1,1,0.5)
    property color  _indicatorsColor:       qgcPal.text
    property bool   _isVehicleGps:          _activeVehicle ? _activeVehicle.gps.count.rawValue > 1 && _activeVehicle.gps.hdop.rawValue < 1.4 : false
    property string _altitude:              _activeVehicle ? (isNaN(_activeVehicle.altitudeRelative.value) ? "0.0" : _activeVehicle.altitudeRelative.value.toFixed(1)) + ' ' + _activeVehicle.altitudeRelative.units : "0.0"
    property string _distanceStr:           isNaN(_distance) ? "0" : _distance.toFixed(0) + ' ' + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
    property real   _heading:               _activeVehicle   ? _activeVehicle.heading.rawValue : 0
    property real   _distance:              _activeVehicle ? _activeVehicle.distanceToHome.rawValue : 0
    property string _messageTitle:          ""
    property string _messageText:           ""
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75

    function secondsToHHMMSS(timeS) {
        var sec_num = parseInt(timeS, 10);
        var hours   = Math.floor(sec_num / 3600);
        var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
        var seconds = sec_num - (hours * 3600) - (minutes * 60);
        if (hours   < 10) {hours   = "0"+hours;}
        if (minutes < 10) {minutes = "0"+minutes;}
        if (seconds < 10) {seconds = "0"+seconds;}
        return hours+':'+minutes+':'+seconds;
    }

    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       parentToolInsets.leftEdgeTopInset
        leftEdgeCenterInset:    exampleRectangle.leftEdgeCenterInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parent.width - compassBackground.x
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     compassArrowIndicator.y + compassArrowIndicator.height
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  parentToolInsets.bottomEdgeCenterInset
        bottomEdgeRightInset:   parent.height - attitudeIndicator.y
    }

    // This is an example of how you can use parent tool insets to position an element on the custom fly view layer
    // - we use parent topEdgeLeftInset to position the widget below the toolstrip
    // - we use parent bottomEdgeLeftInset to dodge the virtual joystick if enabled
    // - we use the parent leftEdgeTopInset to size our element to the same width as the ToolStripAction
    // - we export the width of this element as the leftEdgeCenterInset so that the map will recenter if the vehicle flys behind this element
    Rectangle {
        id: exampleRectangle
        visible: false // to see this example, set this to true. To view insets, enable the insets viewer FlyView.qml
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: parentToolInsets.topEdgeLeftInset + _toolsMargin
        anchors.bottomMargin: parentToolInsets.bottomEdgeLeftInset + _toolsMargin
        anchors.leftMargin: _toolsMargin
        width: parentToolInsets.leftEdgeTopInset - _toolsMargin
        color: 'red'

        property real leftEdgeCenterInset: visible ? x + width : 0
    }

    //-------------------------------------------------------------------------
        //Play - Pause - Stop
        Rectangle {
        width: parent.width * 0.06
        color: "transparent"
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        radius: 10
    
        ColumnLayout {
            id: columnLayout
            spacing: 8
            anchors.fill: parent
            anchors.margins: 5
    
            QGCButton {
                width: 30
                Layout.preferredHeight: 30
                onClicked: {
                    guidedActionsController.confirmAction(guidedActionsController.actionStartMission)
                }
                
                background: Rectangle {
                    color: "#ff4800"
                    radius: 100
                }
    
                Image {
                    width: parent.width * 0.3
                    height: parent.height * 0.3
                    source: "/custom/img/play.png"
                    fillMode: Image.PreserveAspectFit
                    anchors.centerIn: parent
                }

                PropertyAnimation on opacity {
                    easing.type: Easing.OutQuart
                    from: 0.7
                    to: 1
                    loops: Animation.Infinite
                    running: true
                    alwaysRunToEnd: true
                    duration: 1000
                }

            }
    
            QGCButton {
                width: 30
                Layout.preferredHeight: 30
                onClicked: {
                    guidedActionsController.confirmAction(guidedActionsController.actionMVPause)
                }
                background: Rectangle {
                    color: "#ff4800"
                    radius: 100
                }
    
                Image {
                    width: parent.width * 0.3
                    height: parent.height * 0.3
                    source: "/custom/img/pause.png"
                    fillMode: Image.PreserveAspectFit
                    anchors.centerIn: parent
                }
            }
    
            QGCButton {
                width: 30
                Layout.preferredHeight: 30
                onClicked: {
                    guidedActionsController.confirmAction(guidedActionsController.actionEmergencyStop)
                }
                background: Rectangle {
                    color: "#ff4800" // Vermelho em hexadecimal
                    radius: 100
                }

                Image {
                    width: parent.width * 0.3
                    height: parent.height * 0.3
                    source: "/custom/img/stop.png"
                    fillMode: Image.PreserveAspectFit
                    anchors.centerIn: parent
                }
            }
        }
    
        // Correção: Define a altura do Rectangle de forma dinâmica para abranger todo o conteúdo do ColumnLayout
        height: columnLayout.implicitHeight + 10
    }
    
    
    
    //-- Pop Up

   // Cabeçalho que abre e fecha o painel
    Rectangle {
        id: header
        width: 180
        height: 30
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 10
        color: "black"
        border.color: "black"
        radius:     ScreenTools.defaultFontPixelWidth / 2

        Row {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 15  // Espaço entre a imagem e o texto

             Text {
                font.pixelSize: 18
                width: 10
                text: panel.visible ? "-" : "+"
                anchors.verticalCenter: parent.verticalCenter
                color: "#ffffff"  // Cor do texto
            }

            Text {
                font.pixelSize: 12
                text: "Painel de Instrumentos"
                anchors.verticalCenter: parent.verticalCenter
                color: "#ff4800"
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: panel.visible = !panel.visible
        }
    }

    // Definição do Panel
    Rectangle {
        id: panel
        width: 180
        height: 220
        anchors.top: header.bottom
        anchors.left: header.left
        color: "#80000000" // Cinza meio transparente
        border.color: "#80000000"
        radius:     ScreenTools.defaultFontPixelWidth / 2
        visible: false

        ColumnLayout {
            anchors.fill: parent
            //anchors.leftMargin: 5
            anchors.rightMargin: 5
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            spacing: 1

            RowLayout {
                spacing: 2
                QGCSwitch {
                    id: switchBrake
                    width: 25
                    height: 18
                }

                Item {
                    width: 35
                    height: 18

                    QGCButton {
                        id: autoBrake
                        property bool isActive: true
                        anchors.fill: parent
                        text: "Auto"
                        font.pixelSize: 10
                        background: Rectangle {
                            color: autoBrake.isActive ? "#ff4800" : "green"
                            radius: 10
                            anchors.fill: parent
                        }
                        onClicked: {
                            autoBrake.isActive = !autoBrake.isActive
                            switchBrake.checked = false
                        }
                    }
                }

                Item {
                    width: 5 // Espaçamento entre o botão "Auto" e a label
                }

                Label {
                    text: "Freio"
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }
            }

            RowLayout {
                spacing: 2
                QGCSwitch {
                    id: switchLight
                    width: 25
                    height: 18
                }

                Item {
                    width: 35
                    height: 18

                    QGCButton {
                        id: autoLight
                        property bool isActive: true
                        anchors.fill: parent
                        text: "Auto"
                        font.pixelSize: 10
                        background: Rectangle {
                            color: autoLight.isActive ? "#ff4800" : "green"
                            radius: 10
                            anchors.fill: parent
                        }
                        onClicked: {
                            autoLight.isActive = !autoLight.isActive
                            switchLight.checked = false
                        }
                    }
                }

                Item {
                    width: 5 // Espaçamento entre o botão "Auto" e a label
                }

                Label {
                    text: "Luzes"
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }
            }

            RowLayout {
                spacing: 2
                QGCSwitch {
                    id: switchBomb
                    width: 25
                    height: 18
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
                    width: 35
                    height: 18

                    QGCButton {
                        id: autoBomb
                        anchors.fill: parent
                        text: "Auto"
                        font.pixelSize: 10
                        property bool isActive: true
                        background: Rectangle {
                            color: autoBomb.isActive ? "#ff4800" : "green"
                            radius: 10
                            anchors.fill: parent
                        }
                        onClicked: {
                            autoBomb.isActive = !autoBomb.isActive
                            switchBomb.checked = false
                        }
                    }
                }

                Item {
                    width: 5 // Espaçamento entre o botão "Auto" e a label
                }

                Label {
                    text: "Bombas"
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }
            }

            RowLayout {
                spacing: 2
                QGCSwitch {
                    id: switchNozzle
                    width: 25
                    height: 18
                    onCheckedChanged: {
                        if (switchNozzle.checked) {
                            var pwmValue = bicos.value === 1 ? 1800 : (bicos.value === 2 ? 1500 : 1200);
                            //console.log("Switch ligado. Enviando PWM " + pwmValue + ".");
                            _activeVehicle.sendCommand(
                                1,      // component
                                183,    // command
                                true,   // confirmation
                                9,      // param1
                                pwmValue // param2
                            );
                        } else {
                            //console.log("Switch desligado. Enviando PWM 1051.");
                            _activeVehicle.sendCommand(
                                1,      // component
                                183,    // command
                                true,   // confirmation
                                9,      // param1
                                1051    // param2
                            );
                        }
                    }
                }

                Item {
                    width: 35
                    height: 18

                    QGCButton {
                        id: autoNozzle
                        property bool isActive: true
                        anchors.fill: parent
                        text: "Auto"
                        font.pixelSize: 10
                        background: Rectangle {
                            color: autoNozzle.isActive ? "#ff4800" : "green"
                            radius: 10
                            anchors.fill: parent
                        }
                        onClicked: {
                            //console.log("Test.");
                            _activeVehicle.sendCommand(
                                1,
                                183,  
                                true,  
                                9,  
                                1100  
                            );
                            //console.log("Bicos foram desligados automaticamente.");
                        }
                    }
                }

                Item {
                    width: 5 // Espaçamento entre o botão "Auto" e a label
                }

                Label {
                    text: "Bicos"
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }
            }

            // Vazão Slider
            ColumnLayout {
                spacing: 5
                Layout.leftMargin: 15

                Label {
                    text: "Vazão"
                    color: "white"
                    font.pixelSize: 10
                }

                RowLayout {
                    spacing: 2
                    QGCSlider {
                        id: bomba
                        from: 1
                        to: 3
                        stepSize: 1
                        snapMode: QGCSlider.SnapAlways
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        live: true
                        onValueChanged: {
                            if (switchBomb.checked) {
                                var pwmValue = bomba.value === 1 ? 1200 : (bomba.value === 2 ? 1400 : 1600);
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
                    }

                    Rectangle {
                        width: 35
                        height: 18
                        color: "#f0f0f0"
                        border.color: "#d0d0d0"
                        border.width: 1
                        radius: 5

                        Label {
                            text: bomba.value === 1 ? "Baixa" : bomba.value === 2 ? "Média" : "Alta"
                            anchors.centerIn: parent
                            color: "#333333"
                            font.pixelSize: 10
                        }
                    }
                }

                Label {
                    text: "Tamanho da gota"
                    color: "white"
                    font.pixelSize: 10
                }

                RowLayout {
                    spacing: 2
                    QGCSlider {
                        id: bicos
                        from: 1
                        to: 3
                        stepSize: 1
                        snapMode: QGCSlider.SnapAlways
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        live: true
                        onValueChanged: {
                            if (switchNozzle.checked) {
                                var pwmValue = bicos.value === 1 ? 1200 : (bicos.value === 2 ? 1500 : 1800);
                                //console.log("Slider mudou. Enviando PWM " + pwmValue + ".");
                                _activeVehicle.sendCommand(
                                    1,      // component
                                    183,    // command
                                    true,   // confirmation
                                    9,      // param1
                                    pwmValue // param2
                                );
                            }
                        }
                    }

                    Rectangle {
                        width: 35
                        height: 18
                        color: "#f0f0f0"
                        border.color: "#d0d0d0"
                        border.width: 1
                        radius: 5

                        Label {
                            text: bicos.value === 1 ? "Grossa" : bicos.value === 2 ? "Média" : "Fina"
                            anchors.centerIn: parent
                            color: "#333333"
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
    
    

    //-------------------------------------------------------------------------
    //-- Heading Indicator
    Rectangle {
        id:                         compassBar
        height:                     ScreenTools.defaultFontPixelHeight * 1.5
        width:                      ScreenTools.defaultFontPixelWidth  * 50
        color:                      "#DEDEDE"
        radius:                     2
        clip:                       true
        visible: false
        anchors.top:                headingIndicator.bottom
        anchors.topMargin:          -headingIndicator.height / 2
        anchors.horizontalCenter:   parent.horizontalCenter
        Repeater {
            model: 720
            QGCLabel {
                function _normalize(degrees) {
                    var a = degrees % 360
                    if (a < 0) a += 360
                    return a
                }
                property int _startAngle: modelData + 180 + _heading
                property int _angle: _normalize(_startAngle)
                anchors.verticalCenter: parent.verticalCenter
                x:              visible ? ((modelData * (compassBar.width / 360)) - (width * 0.5)) : 0
                visible:        _angle % 45 == 0
                color:          "#75505565"
                font.pointSize: ScreenTools.smallFontPointSize
                text: {
                    switch(_angle) {
                    case 0:     return "N"
                    case 45:    return "NE"
                    case 90:    return "E"
                    case 135:   return "SE"
                    case 180:   return "S"
                    case 225:   return "SW"
                    case 270:   return "W"
                    case 315:   return "NW"
                    }
                    return ""
                }
            }
        }
    }
    Rectangle {

        id: compassBackground
        anchors.bottom: attitudeIndicator.bottom
        anchors.right: attitudeIndicator.left
        visible: false
        anchors.rightMargin: -attitudeIndicator.width / 2
        width: -anchors.rightMargin + compassBezel.width + (_toolsMargin * 2) * 0.75 // Reduzindo o tamanho
        height: attitudeIndicator.height * 0.6 // Reduzindo o tamanho
        radius: 2
        color: qgcPal.window

        Rectangle {
            id: compassBezel
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: _toolsMargin
            anchors.left: parent.left
            width: height // Mantém a proporção circular
            height: parent.height - (northLabelBackground.height / 2) - (headingLabelBackground.height / 2)
            radius: height / 2
            border.color: qgcPal.text
            border.width: 1
            color: Qt.rgba(0,0,0,0)
        }

        Rectangle {
            id: northLabelBackground
            anchors.top: compassBezel.top
            anchors.topMargin: -height / 2
            anchors.horizontalCenter: compassBezel.horizontalCenter
            width: northLabel.contentWidth * 1.5
            height: northLabel.contentHeight * 1.5
            radius: ScreenTools.defaultFontPixelWidth * 0.25
            color: qgcPal.windowShade

            QGCLabel {
                id: northLabel
                anchors.centerIn: parent
                text: "N"
                color: qgcPal.text
                font.pointSize: ScreenTools.smallFontPointSize
            }
        }

        Image {
            id: headingNeedle
            anchors.centerIn: compassBezel
            height: compassBezel.height * 0.75 // Ajustando a altura
            width: height // Mantém a proporção
            source: "/custom/img/compass_needle.svg"
            fillMode: Image.PreserveAspectFit
            sourceSize.height: height
            transform: [
                Rotation {
                    origin.x: headingNeedle.width / 2
                    origin.y: headingNeedle.height / 2
                    angle: _heading
                }]
        }

        Rectangle {
            id: headingLabelBackground
            anchors.top: compassBezel.bottom
            anchors.topMargin: -height / 2
            anchors.horizontalCenter: compassBezel.horizontalCenter
            width: headingLabel.contentWidth * 1.5
            height: headingLabel.contentHeight * 1.5
            radius: ScreenTools.defaultFontPixelWidth * 0.25
            color: qgcPal.windowShade

            QGCLabel {
                id: headingLabel
                anchors.centerIn: parent
                text: _heading
                color: qgcPal.text
                font.pointSize: ScreenTools.smallFontPointSize
            }
        }
    }

    Rectangle {
        id:                     attitudeIndicator
        anchors.bottomMargin:   10 // Define a margem do fundo
        height:                 ScreenTools.defaultFontPixelHeight * 6
        width:                  height
        radius:                 height * 0.5
        visible: false
        color:                  qgcPal.windowShade
        anchors.horizontalCenter: parent.horizontalCenter // Centraliza horizontalmente
        anchors.bottom:         parent.bottom // Ancora na parte inferior da tela

        CustomAttitudeWidget {
            size:               parent.height * 0.95
            vehicle:            _activeVehicle
            showHeading:        false
            anchors.centerIn:   parent
        }
    }
}
