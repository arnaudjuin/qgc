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

import Custom.Widgets

Item {
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
    //-- Pop Up

    Rectangle {
        id: expandablePanel
        width: parent.width * 0.24 // 20% da largura do elemento pai
        height: isMinimized ? 40 : contentArea.implicitHeight + headerArea.height  // Altura fixa quando minimizado e quando expandido
        color: "black"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 10
        radius: 10
        clip: true
        property bool isMinimized: true 

        // Área do cabeçalho
        Rectangle {
            id: headerArea
            width: parent.width
            height: 40
            color: "black"
            radius: 10
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    expandablePanel.isMinimized = !expandablePanel.isMinimized
                    expandablePanel.height = expandablePanel.isMinimized ? headerArea.height : 300
                }
            }
            RowLayout {
                anchors.fill: parent
                spacing: parent.width * 0.02

                // Botão para minimizar/maximizar
                Button {
                    id: toggleButton
                    onClicked: {
                        expandablePanel.isMinimized = !expandablePanel.isMinimized
                        expandablePanel.height = expandablePanel.isMinimized ? headerArea.height : 300
                    }
                    Layout.leftMargin: parent.width * 0.02
                    Layout.preferredWidth: parent.width * 0.08

                    background: Rectangle {
                        radius: 15
                        color: "transparent"
                    }

                    Label {
                        text: expandablePanel.isMinimized ? "+" : "-"
                        font.pixelSize: headerArea.width * 0.08
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Título do Painel
                Label {
                    text: "Painel de Instrumentos"
                    color: "#ff4800"
                    Layout.fillWidth: true
                    Layout.rightMargin: parent.width * 0.02
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: headerArea.width * 0.08
                }
            }
        }

        // Conteúdo do painel
        Rectangle {
            visible: !expandablePanel.isMinimized
            anchors.top: headerArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: "black"
            radius: 10

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 0.5
                anchors.rightMargin: 0.5
                anchors.topMargin: 5
                anchors.bottomMargin: 5
                spacing: -2
                Component.onCompleted: {
                    expandablePanel.height = isMinimized ? headerArea.height : contentArea.implicitHeight + headerArea.height;
                }

                RowLayout {
                    spacing: parent.width * 0.03
                    QGCSwitch {
                        id: switchBrake
                    }

                    Item {
                        width: 40  
                        height: 19.8 
                        

                        QGCButton {
                            id: autoBrake
                            property bool isActive: true
                            anchors.fill: parent 
                            text: "Auto"
                            font.pixelSize: Math.max(10, parent.width * 0.020)
                            background: Rectangle { // Define um fundo retangular
                                color: autoBrake.isActive ? "#ff4800" : "green" // Cor do fundo
                                radius: 10 // Bordas arredondadas
                                anchors.fill: parent // Preenche todo o espaço do botão
                            }
                            onClicked: {
                                autoBrake.isActive = !autoBrake.isActive
                            }
                        }
                    }

                    Label {
                        text: "Freio"
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: headerArea.width * 0.06
                    }
                }

                RowLayout {
                    spacing: parent.width * 0.03
                    QGCSwitch {
                        id: switchLight
                    }

                    Item {
                        width: 40  
                        height: 19.8 
                        

                        QGCButton {
                            id: autoLight
                            property bool isActive: true
                            anchors.fill: parent 
                            text: "Auto"
                            font.pixelSize: Math.max(10, parent.width * 0.020)
                            background: Rectangle { // Define um fundo retangular
                                color: autoLight.isActive ? "#ff4800" : "green" // Cor do fundo
                                radius: 10 // Bordas arredondadas
                                anchors.fill: parent // Preenche todo o espaço do botão
                            }
                            onClicked: {
                                autoLight.isActive = !autoLight.isActive
                            }
                        }
                    }

                    Label {
                        text: "Luzes"
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: headerArea.width * 0.06
                    }
                }

                RowLayout {
                    spacing: parent.width * 0.03
                    QGCSwitch {
                        id: switchBomb
                    
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

                RowLayout {
                    spacing: parent.width * 0.03
                    QGCSwitch {
                        id: switchNozzle
                    }
                    Item {
                        width: 40  
                        height: 19.8 
                        

                        QGCButton {
                            id: autoNozzle
                            property bool isActive: true
                            anchors.fill: parent 
                            text: "Auto"
                            font.pixelSize: Math.max(10, parent.width * 0.020)
                            background: Rectangle { // Define um fundo retangular
                                color: autoNozzle.isActive ? "#ff4800" : "green" // Cor do fundo
                                radius: 10 // Bordas arredondadas
                                anchors.fill: parent // Preenche todo o espaço do botão
                            }
                            onClicked: {
                                autoNozzle.isActive = !autoNozzle.isActive
                            }
                        }
                    }
                    Label {
                        text: "Bicos"
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
                    id:                     bombas
                    from:                   2
                    to:                     20
                    stepSize:               2
                    snapMode: QGCSlider.SnapAlways 
                    
                    Layout.fillWidth: false  // Não preenche toda a largura
                    Layout.preferredWidth: 110
                    Layout.columnSpan:      2
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                    Layout.leftMargin: 12
                    live: true
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
                            text: bombas.value.toFixed(1)
                            anchors.centerIn: parent
                            color: "#333333"
                            font.pixelSize: ret1.width * 0.20
                        }
                    }
                }
                //Tamanho gota
                RowLayout{
                    spacing: parent.width * 0.03

                    Label{
                    text: "Tamanho da gota"
                    color: "white"
                    Layout.leftMargin: 12
                    font.pixelSize: headerArea.width * 0.06
                    }

                }

                RowLayout {
                    spacing: parent.width * 0.03

                    QGCSlider {
                        id:                     bicos
                        from:           1
                        to:           3
                        stepSize:               1 

                        snapMode: QGCSlider.SnapAlways 
                        Layout.fillWidth: false  // Não preenche toda a largura
                        Layout.preferredWidth: 110
                        Layout.columnSpan:      2
                        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                        Layout.leftMargin: 12
                        live: true
                    }

                    Rectangle {
                        
                        width: 40
                        height: 14
                        color: "#f0f0f0"  // Light grey background
                        border.color: "#d0d0d0"
                        border.width: 1
                        radius: 5

                        Label {
                            text: bicos.value === 1 ? "Fina" :
                            bicos.value === 2 ? "Média" : "Grossa"
                            anchors.centerIn: parent
                            color: "#333333"
                            font.pixelSize: ret1.width * 0.20
                        }
                    }
                }

                RowLayout{
                    spacing: parent.width * 0.03

                    Label{
                    text: "Velocidade"
                    color: "white"
                    Layout.leftMargin: 12
                    font.pixelSize: headerArea.width * 0.06
                    }

                }
                //Slider velocidade
                RowLayout {
                    spacing: parent.width * 0.03

                    QGCSlider {
                    id:                     velocidade
                    from:                   3
                    to:                     18
                    stepSize:               3
                    snapMode: QGCSlider.SnapAlways 
                    
                    Layout.fillWidth: false  // Não preenche toda a largura
                    Layout.preferredWidth: 110
                    Layout.columnSpan:      2
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
                    Layout.leftMargin: 12
                    live: true
                    }

                    Rectangle {
                        width: 40
                        height: 14
                        color: "#f0f0f0"  // Light grey background
                        border.color: "#d0d0d0"
                        border.width: 1
                        radius: 5

                        Label {
                            text: velocidade.value.toFixed(1)
                            anchors.centerIn: parent
                            color: "#333333"
                            font.pixelSize: ret1.width * 0.20       
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
