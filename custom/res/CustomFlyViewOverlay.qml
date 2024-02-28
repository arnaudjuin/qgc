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
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.ScreenTools

import Custom.Widgets

import QGroundControl
import QGroundControl.Vehicle
import QGroundControl.FactControls
import QGroundControl.SettingsManager
import QGroundControl.Controllers
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
Item {
    FactPanelController { id: controller; }
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
        bottomEdgeRightInset:   parent.height 
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
    //-- Heading Indicator
    Rectangle {
        id:                         compassBar
        height:                     ScreenTools.defaultFontPixelHeight * 1.5
        width:                      ScreenTools.defaultFontPixelWidth  * 50
        color:                      "#DEDEDE"
        radius:                     2
        clip:                       true
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
        id:                         headingIndicator
        height:                     ScreenTools.defaultFontPixelHeight
        width:                      ScreenTools.defaultFontPixelWidth * 4
        color:                      qgcPal.windowShadeDark
        anchors.top:                parent.top
        anchors.topMargin:          _toolsMargin
        anchors.horizontalCenter:   parent.horizontalCenter
        QGCLabel {
            text:                   _heading
            color:                  qgcPal.text
            font.pointSize:         ScreenTools.smallFontPointSize
            anchors.centerIn:       parent
        }
    }
    Image {
        id:                         compassArrowIndicator
        height:                     _indicatorsHeight
        width:                      height
        source:                     "/custom/img/compass_pointer.svg"
        fillMode:                   Image.PreserveAspectFit
        sourceSize.height:          height
        anchors.top:                compassBar.bottom
        anchors.topMargin:          -height / 2
        anchors.horizontalCenter:   parent.horizontalCenter
    }

    Rectangle {
        id:                     compassBackground
        anchors.bottom:         parent.bottom
        anchors.right:          parent.right
        color:                  qgcPal.window
        width:                  200
      height: ScreenTools.defaultFontPixelHeight * 10

    ScrollView {
        anchors.fill: parent
        // Optionally, set the width and height explicitly if needed
        // width: ...
        // height: ...
        ColumnLayout {
            anchors.fill: parent
            id:                 valuesColumn
            anchors.margins:     ScreenTools.defaultFontPixelWidth / 2
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.top:        parent.top
            spacing:             ScreenTools.defaultFontPixelWidth / 2


            Row {
                width:      parent.width
                spacing:            ScreenTools.defaultFontPixelWidth * 17
                QGCLabel {
                    text:       qsTr("Travel Height")
                    font.family: ScreenTools.demiboldFontFamily
                }

            }
            Row {
                width:      parent.width
                spacing:            ScreenTools.defaultFontPixelWidth * 3
                anchors.topMargin:  ScreenTools.defaultFontPixelWidth * 2
                QGCButton {
                    height:                 parent.height
                    width:                  height
                    text:                   "-"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: QGroundControl.settingsManager.appSettings.offlineEditingAltitude.value  = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingAltitude.value - 0.5, QGroundControl.settingsManager.appSettings.offlineEditingAltitude.max), QGroundControl.settingsManager.appSettings.offlineEditingAltitude.min)
                }
                Slider {
                    property bool   _loadComplete:  false

                    id:                 travelHeight
                    from:       QGroundControl.settingsManager.appSettings.offlineEditingAltitude.min
                    to:       QGroundControl.settingsManager.appSettings.offlineEditingAltitude.max
                    stepSize:           0.5
                    width:100
                    value: QGroundControl.settingsManager.appSettings.offlineEditingAltitude.value
                    onValueChanged: {
                        // Update the value of the FactSlider when the Slider value changes
                        factTravelHeight.fact.value = travelHeight.value;
                        QGroundControl.settingsManager.appSettings.offlineEditingAltitude.value= travelHeight.value;
                    }
                    Canvas {
                        id: canvastravelHeight
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            var tickInterval = travelHeight.width / ((travelHeight.to - travelHeight.from) / travelHeight.stepSize);
                            ctx.beginPath();
                            for (var i = 0; i <= travelHeight.width; i += tickInterval) {
                                ctx.moveTo(i, travelHeight.height - 10);
                                ctx.lineTo(i, travelHeight.height);
                            }
                            ctx.stroke();
                        }
                    }

                }
                FactTextFieldSlider {
                    id:factTravelHeight
                    visible: false
                    fact: controller.getParameterFact(-1, "SU_TRAVEL_ALT")
                }


                QGCButton {
                    height:                 parent.height
                    width:                  height
                    text:                   "+"
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: QGroundControl.settingsManager.appSettings.offlineEditingAltitude.value  = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingAltitude.value + 0.5, QGroundControl.settingsManager.appSettings.offlineEditingAltitude.max), QGroundControl.settingsManager.appSettings.offlineEditingAltitude.min)
                }
                FactTextField {
                    fact:                   QGroundControl.settingsManager.appSettings.offlineEditingAltitude
                    showUnits:              true
                    showHelp:               false
                    width:                  100
                }
            }
            Row {
                spacing:            ScreenTools.defaultFontPixelWidth * 17
                width:      parent.width
                QGCLabel {
                    text:       qsTr("Spray Height")
                    font.family: ScreenTools.demiboldFontFamily
                }
            }
            Row {
                width:      parent.width * 1.5
                spacing:            ScreenTools.defaultFontPixelWidth * 3
                QGCButton {
                    height:                 parent.height
                    width:                  height
                    text:                   "-"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.value  = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.value - 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.max), QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.min)
                }
                Slider {
                    property bool   _loadComplete:  false

                    id:                 sprayHeight
                    from:       QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.min
                    to:       QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.max
                    stepSize:           0.5
                    width:100
                    value:QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.value
                    onValueChanged: {
                        // Update the value of the FactSlider when the Slider value changes
                        factSprayHeight.fact.value = sprayHeight.value;
                        QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.value = sprayHeight.value;
                    }
                    Canvas {
                        id: canvassprayHeight
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            var tickInterval = sprayHeight.width / ((sprayHeight.to - sprayHeight.from) / sprayHeight.stepSize);
                            ctx.beginPath();
                            for (var i = 0; i <= sprayHeight.width; i += tickInterval) {
                                ctx.moveTo(i, sprayHeight.height - 10);
                                ctx.lineTo(i, sprayHeight.height);
                            }
                            ctx.stroke();
                        }
                    }

                }
                FactTextFieldSlider {
                    id:factSprayHeight
                    visible: false
                    fact: controller.getParameterFact(-1, "SU_TRAVEL_ALT")
                }

                QGCButton {
                    height:                 parent.height
                    width:                  height
                    text:                   "+"
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.value  = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.value + 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.max), QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.min)
                }
                FactTextField {
                    fact:                   QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight
                    showUnits:              true
                    showHelp:               false
                    width:                  100
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
                spacing:            ScreenTools.defaultFontPixelWidth * 3
                anchors.topMargin:  ScreenTools.defaultFontPixelWidth * 2
                QGCButton {
                    height:                 parent.height
                    width:                  height
                    text:                   "-"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.value  = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.value - 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.max), QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.min)
                }
                Slider {
                    property bool   _loadComplete:  false

                    id:                 sprayVolume
                    from:       QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.min
                    to:       QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.max
                    stepSize:           0.5
                    width:100
                    value:QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.value
                    onValueChanged: {
                        // Update the value of the FactSlider when the Slider value changes
                        factSprayVolume.fact.value = sprayVolume.value;
                        QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.value = sprayVolume.value;
                    }
                    Canvas {
                        id: canvassprayVolume
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            var tickInterval = sprayVolume.width / ((sprayVolume.to - sprayVolume.from) / sprayVolume.stepSize);
                            ctx.beginPath();
                            for (var i = 0; i <= sprayVolume.width; i += tickInterval) {
                                ctx.moveTo(i, sprayVolume.height - 10);
                                ctx.lineTo(i, sprayVolume.height);
                            }
                            ctx.stroke();
                        }
                    }

                    Component.onCompleted: {
                        canvas.requestPaint();
                    }
                }
                FactTextFieldSlider {
                    id:factSprayVolume
                    visible: false
                    fact: controller.getParameterFact(-1, "SU_SPRY_VOL")
                }


                QGCButton {
                    height:                 parent.height
                    width:                  height
                    text:                   "+"
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.value  = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.value + 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.max), QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.min)
                }
                FactTextField {
                    fact:                   QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume
                    showUnits:              true
                    showHelp:               false
                    width:                  100
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
                spacing:            ScreenTools.defaultFontPixelWidth * 3
                anchors.topMargin:  ScreenTools.defaultFontPixelWidth * 2
                QGCButton {
                    height:                 parent.height
                    width:                  height
                    text:                   "-"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSpacing.value  = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSpacing.value - 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSpacing.max), QGroundControl.settingsManager.appSettings.offlineEditingSpacing.min)
                }
                Slider {
                    property bool   _loadComplete:  false

                    id:                 spacing
                    from:       QGroundControl.settingsManager.appSettings.offlineEditingSpacing.min
                    to:       QGroundControl.settingsManager.appSettings.offlineEditingSpacing.max
                    stepSize:           0.5
                    width:100
                    value:QGroundControl.settingsManager.appSettings.offlineEditingSpacing.value
                    onValueChanged: {
                        // Update the value of the FactSlider when the Slider value changes
                        factSpacing.fact.value = spacing.value;
                        QGroundControl.settingsManager.appSettings.offlineEditingSpacing.value  = spacing.value;
                    }
                    Canvas {
                        id: canvasspacing
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            var tickInterval = spacing.width / ((spacing.to - spacing.from) / spacing.stepSize);
                            ctx.beginPath();
                            for (var i = 0; i <= spacing.width; i += tickInterval) {
                                ctx.moveTo(i, spacing.height - 10);
                                ctx.lineTo(i, spacing.height);
                            }
                            ctx.stroke();
                        }
                    }

                }
                FactTextFieldSlider {
                    id:factSpacing
                    visible: false
                    fact: controller.getParameterFact(-1, "SU_SPRY_WIDTH")
                }


                QGCButton {
                    height:                 parent.height
                    width:                  height
                    text:                   "+"
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSpacing.value  = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSpacing.value + 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSpacing.max), QGroundControl.settingsManager.appSettings.offlineEditingSpacing.min)
                }
                FactTextField {
                    fact:                   QGroundControl.settingsManager.appSettings.offlineEditingSpacing
                    showUnits:              true
                    showHelp:               false
                    width:                  100
                }
            }
            Row {
                width:      parent.width
                spacing:            ScreenTools.defaultFontPixelWidth * 6
                QGCLabel {
                    text:       qsTr("Spray Speed")
                    font.family: ScreenTools.demiboldFontFamily
                }


            }
            Row {
                width:      parent.width * 1.5
                spacing:            ScreenTools.defaultFontPixelWidth * 3
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
                    from:       QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.min
                    to:       QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.max
                    stepSize:           0.5
                    width:100
                    value:QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.value

                    onValueChanged: {
                        // Update the value of the FactSlider when the Slider value changes
                        factSpraySpeed.fact.value = spraySpeed.value;
                        QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.value = spraySpeed.value;
                    }
                    Canvas {
                        id: canvasspraySpeed
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            var tickInterval = spraySpeed.width / ((spraySpeed.to - spraySpeed.from) / spraySpeed.stepSize);
                            ctx.beginPath();
                            for (var i = 0; i <= spraySpeed.width; i += tickInterval) {
                                ctx.moveTo(i, spraySpeed.height - 10);
                                ctx.lineTo(i, spraySpeed.height);
                            }
                            ctx.stroke();
                        }
                    }

                }
                FactTextFieldSlider {
                    id:factSpraySpeed
                    visible: false
                    fact: controller.getParameterFact(-1, "SU_SPRY_FLT_SPD")
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
                    width:                  100
                }

            }
            Rectangle {
                visible :false
                id:                     compassBezel
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin:     _toolsMargin
                anchors.left:           parent.left
                width:                  height
                height:                 parent.height - (northLabelBackground.height / 2) - (headingLabelBackground.height / 2)
                radius:                 height / 2
                border.color:           qgcPal.text
                border.width:           1
                color:                  Qt.rgba(0,0,0,0)
            }

            Rectangle {
                visible :false

                id:                         northLabelBackground
                anchors.top:                compassBezel.top
                anchors.topMargin:          -height / 2
                anchors.horizontalCenter:   compassBezel.horizontalCenter
                width:                      northLabel.contentWidth * 1.5
                height:                     northLabel.contentHeight * 1.5
                radius:                     ScreenTools.defaultFontPixelWidth  * 0.25
                color:                      qgcPal.windowShade

                QGCLabel {
                    id:                 northLabel
                    anchors.centerIn:   parent
                    text:               "N"
                    color:              qgcPal.text
                    font.pointSize:     ScreenTools.smallFontPointSize
                }
            }

            Image {
                visible :false

                id:                 headingNeedle
                anchors.centerIn:   compassBezel
                height:             compassBezel.height * 0.75
                width:              height
                source:             "/custom/img/compass_needle.svg"
                fillMode:           Image.PreserveAspectFit
                sourceSize.height:  height
                transform: [
                    Rotation {
                        origin.x:   headingNeedle.width  / 2
                        origin.y:   headingNeedle.height / 2
                        angle:      _heading
                    }]
            }

            Rectangle {
                visible :false

                id:                         headingLabelBackground
                anchors.top:                compassBezel.bottom
                anchors.topMargin:          -height / 2
                anchors.horizontalCenter:   compassBezel.horizontalCenter
                width:                      headingLabel.contentWidth * 1.5
                height:                     headingLabel.contentHeight * 1.5
                radius:                     ScreenTools.defaultFontPixelWidth  * 0.25
                color:                      qgcPal.windowShade

                QGCLabel {
                    id:                 headingLabel
                    anchors.centerIn:   parent
                    text:               _heading
                    color:              qgcPal.text
                    font.pointSize:     ScreenTools.smallFontPointSize
                }
            }
        }
    }


    }
} 
