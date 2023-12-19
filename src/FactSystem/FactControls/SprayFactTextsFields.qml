/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
import QtQuick          2.3
import QtQuick.Dialogs  1.2
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

Row {
    width:      parent.width
    spacing:            ScreenTools.defaultFontPixelWidth * 4

    QGCLabel {
        text:       qsTr("Travel Height")
        font.family: ScreenTools.demiboldFontFamily
    }
}
Row {
    width:      parent.width
    spacing:            ScreenTools.defaultFontPixelWidth * 1
    anchors.topMargin:  ScreenTools.defaultFontPixelWidth * 2
    QGCButton {
        height:                 parent.height
        width:                  height
        text:                   "-"
        anchors.verticalCenter: parent.verticalCenter
        //onClicked: fact.value = Math.max(Math.min(fact.value - _minIncrement, fact.max), fact.min)
    }
    Slider {

        id:                 travelHeight
        minimumValue:       0.08
        maximumValue:       4
        stepSize:           1
        tickmarksEnabled:   true

        //                                onValueChanged: {
        //                                    if (_loadComplete) {
        //                                        _rateRollP.value = value
        //                                        _rateRollI.value = value
        //                                        _ratePitchP.value = value
        //                                        _ratePitchI.value = value
        //                                    }
    }

    QGCButton {
        height:                 parent.height
        width:                  height
        text:                   "+"
        anchors.verticalCenter: parent.verticalCenter

        //onClicked: fact.value = Math.max(Math.min(fact.value - _minIncrement, fact.max), fact.min)
    }
    FactTextField {
        anchors.verticalCenter: parent.verticalCenter
        fact:                   sliderRoot.fact
        showUnits:              true
        showHelp:               false
        text:                   "2"
        width:                  30
    }
}
