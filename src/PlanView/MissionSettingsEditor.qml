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
import QGroundControl.FactSystem 1.0
import QGroundControl.FactControls 1.0

// Editor for Mission Settings
Rectangle {
    id: valuesRect
    FactPanelController {
        id: controller
    }
    width: availableWidth + 50
    height: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 27 : ScreenTools.defaultFontPixelHeight * 42
    color: qgcPal.windowShadeDark
    radius: _radius
    property var _savedVertices: []

    property var _masterControler: masterController
    property var _missionController: _masterControler.missionController
    property var _controllerVehicle: _masterControler.controllerVehicle
    property bool _vehicleHasHomePosition: _controllerVehicle.homePosition.isValid
    property bool _showCruiseSpeed: !_controllerVehicle.multiRotor
    property bool _showHoverSpeed: _controllerVehicle.multiRotor || _controllerVehicle.vtol
    property bool _multipleFirmware: !QGroundControl.singleFirmwareSupport
    property bool _multipleVehicleTypes: !QGroundControl.singleVehicleSupport
    property real _fieldWidth: ScreenTools.defaultFontPixelWidth * 16
    property bool _mobile: ScreenTools.isMobile
    property var _savePath: QGroundControl.settingsManager.appSettings.missionSavePath
    property var _fileExtension: QGroundControl.settingsManager.appSettings.missionFileExtension
    property var _appSettings: QGroundControl.settingsManager.appSettings
    property bool _waypointsOnlyMode: QGroundControl.corePlugin.options.missionWaypointsOnly
    property bool _showCameraSection: (_waypointsOnlyMode || QGroundControl.corePlugin.showAdvancedUI) && !_controllerVehicle.apmFirmware
    property bool _simpleMissionStart: QGroundControl.corePlugin.options.showSimpleMissionStart
    property bool _showFlightSpeed: !_controllerVehicle.vtol && !_simpleMissionStart && !_controllerVehicle.apmFirmware
    property bool _allowFWVehicleTypeSelection: _noMissionItemsAdded && !globals.activeVehicle
    property bool _confirmationStart: false
    property bool loadChoice: false
    property bool _textFieldSave: false
    property bool _editTracing: false
    property bool isTraced: false
    readonly property string _firmwareLabel: qsTr("Firmware")
    readonly property string _vehicleLabel: qsTr("Vehicle")
    readonly property real _margin: ScreenTools.defaultFontPixelWidth / 2
    property var polygonItem: null
    QGCPalette {
        id: qgcPal
    }
    QGCFileDialogController {
        id: fileController
    }
    Component {
        id: altModeDialogComponent
        AltModeDialog {
        }
    }

    Connections {
        target: _controllerVehicle
        function onSupportsTerrainFrameChanged() {
            if (!_controllerVehicle.supportsTerrainFrame && _missionController.globalAltitudeMode === QGroundControl.AltitudeModeTerrainFrame) {
                _missionController.globalAltitudeMode = QGroundControl.AltitudeModeCalcAboveTerrain;
            }
        }
    }
    ColumnLayout {
        id: valuesHeader
        implicitHeight: 500   // or sum up individual implicit heights of children if more precise control is needed

        visible: !_confirmationStart && !_textFieldSave && !loadChoice
        anchors.margins: _margin
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: _margin
        Row {
            QGCToolBarButton {
                id: currentButton
                icon.source: "/res/QGCLogoFull"
                logo: true
                onClicked: mainWindow.showToolSelectDialog()
            }
        }
        Row {
            width: parent.width
            spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 0.5 : ScreenTools.defaultFontPixelWidth * 2
            QGCButton {
                scale: ScreenTools.isMobile ? 0.8 : 0.8
                text: "Undo Last"
                Layout.fillWidth: true
                onClicked: {
                    var lastIndex = _missionController.visualItems.count - 1;
                    if (lastIndex > 0) {
                        if (_missionController.visualItems.get(lastIndex).surveyAreaPolygon)
                            isTraced = false;
                    }
                    _missionController.removeVisualItem(lastIndex);
                }
            }

            QGCButton {
                scale: ScreenTools.isMobile ? 0.8 : 0.8
                text: "Start"
                primary: true
                Layout.fillWidth: true
                onClicked: {
                    if (polygonItem) {
                        polygonItem.surveyAreaPolygon.traceMode = false;
                        _editTracing = false;
                    }
                    _planMasterController.saveToSelectedFile();
                    _confirmationStart = true;
                }

                function insertBoundariesToFile() {
                    var nextIndex = _missionController.currentPlanViewVIIndex + 1;
                    // Loop through each boundary in the QVariantList
                    for (var i = 0; i < polygonItem.boundaries.length; i++) {
                        // Insert each boundary at the subsequent index
                        _missionController.insertSimpleMissionItemBoundary(polygonItem.boundaries[i], nextIndex + i, false /* makeCurrentItem */);
                    }
                }
                PropertyAnimation on opacity {
                    easing.type: Easing.OutQuart
                    from: 0.5
                    to: 1
                    loops: Animation.Infinite
                    running: true
                    alwaysRunToEnd: true
                    duration: 2000
                }
            }
        }
        Row {
            width: parent.width
            Layout.topMargin: _margin * 1// Add this line to set the top margin for the first Row
            spacing: 0.1   // Set a small spacing value to reduce horizontal gaps
            KMLOrSHPFileDialog {
                id: kmlOrSHPLoadDialog
                title: qsTr("Select Polygon File")

                onAcceptedForLoad: file => {
                    var currentIndex = _missionController.visualItems.count;
                    polygonItem = _missionController.visualItems.get(currentIndex - 1);
                    if (!isTraced)
                        insertComplexItemAfterCurrent(_missionController.complexMissionItemNames[0]);
                    polygonItem = _missionController.visualItems.get(currentIndex);
                    polygonItem.surveyAreaPolygon.loadKMLOrSHPFile(file);
                    mapFitFunctions.fitMapViewportToMissionItems();
                    close();
                }
            }
            QGCButton {
                scale: ScreenTools.isMobile ? 0.8 : 0.8
                text: "Clear"
                Layout.fillWidth: true
                onClicked: {
                    mainWindow.showMessageDialog(qsTr("Clear"), qsTr("Are you sure you want to remove all mission items and clear the mission from the vehicle?"), Dialog.Yes | Dialog.Cancel, function () {
                            polygonItem = null;
                            _editTracing = false;   
                            // Remove all visualItems one by one
                            for (var i = _missionController.visualItems.count - 1; i >= 0; i--) {
                                _missionController.removeVisualItem(i);
                            }
                            isTraced = false;
                            _missionController.setCurrentPlanViewSeqNum(0, true);
                        });
                }
            }
            QGCButton {
                id: loadButton
                scale: ScreenTools.isMobile ? 0.8 : 0.8
                text: "Load"
                Layout.fillWidth: true

                onClicked: {
                    loadChoice = true;
                }
            }

            QGCButton {
                text: qsTr("Save")
                scale: ScreenTools.isMobile ? 0.8 : 0.8
                Layout.fillWidth: true
                enabled: !_planMasterController.syncInProgress
                onClicked: {
                    dropPanelSave.hide();
                    if (_planMasterController.currentPlanFile !== "") {
                        _planMasterController.saveToCurrent();
                    } else {
                        _planMasterController.saveToSelectedFile();
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: ScreenTools.defaultFontPixelWidth * 1.5

            QGCButton {
                  id: buttonDraw
                Layout.fillWidth: true
                width: ScreenTools.isMobile ? 55 : 100
                height: width

                text: "Trace"

                onClicked: {
                    dropPanelLoad.hide();
                    dropPanelSave.hide();
                    _editTracing = !_editTracing;
                    _addWaypointOnClick = false;
                    _addWaypointOnClickSpray = false;
                    {
                        for (var i = 0; i < _missionController.visualItems.count; i++) {
                            if (_missionController.visualItems.get(i).surveyAreaPolygon && !_missionController.visualItems.get(i).surveyAreaPolygon.traceMode) {
                                _missionController.removeVisualItem(i);
                                polygonItem = null;
                            }
                        }
                        if (!isTraced) {
                            var currentIndex = _missionController.visualItems.count;
                            polygonItem = _missionController.visualItems.get(currentIndex - 1);
                            if (!isTraced)
                                insertComplexItemAfterCurrent(_missionController.complexMissionItemNames[0]);
                            polygonItem = _missionController.visualItems.get(currentIndex);
                            spacing.value = 2;
                            if (factSpacing && factSpacing.fact)
                                factSpacing.fact.value = 2;
                            QGroundControl.settingsManager.appSettings.offlineEditingSpacing.value = 2;
                            if (polygonItem)polygonItem.cameraCalc.adjustedFootprintSide.value = 2;
                            if (polygonItem.surveyAreaPolygon.traceMode) {
                                if (polygonItem.surveyAreaPolygon.count < 3) {
                                    _restorePreviousVertices(polygonItem);
                                }
                                isTraced = true;
                                polygonItem.surveyAreaPolygon.traceMode = false;
                            }
                            if (!polygonItem.surveyAreaPolygon.traceMode && _editTracing) {
                                polygonItem.surveyAreaPolygon.traceMode = true;
                                _saveCurrentVertices(polygonItem);
                                polygonItem.surveyAreaPolygon.clear();
                                isTraced = true;
                            }
                        } else {
                            if (polygonItem && polygonItem.surveyAreaPolygon && polygonItem.surveyAreaPolygon.traceMode)
                                polygonItem.surveyAreaPolygon.traceMode = false;
                        }
                    }
                    function _saveCurrentVertices(polygonItem) {
                        _savedVertices = [];
                        for (var i = 0; i < polygonItem.surveyAreaPolygon.count; i++) {
                            _savedVertices.push(polygonItem.surveyAreaPolygon.vertexCoordinate(i));
                        }
                    }
                    function _restorePreviousVertices() {
                        polygonItem.surveyAreaPolygon.beginReset();
                        polygonItem.surveyAreaPolygon.clear();
                        for (var i = 0; i < _savedVertices.length; i++) {
                            polygonItem.surveyAreaPolygon.appendVertex(_savedVertices[i]);
                        }
                        polygonItem.surveyAreaPolygon.endReset();
                    }
                }
            }



        }
    }
    Rectangle {
        id: sep
        anchors.top: valuesHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        Layout.fillWidth: true
        height: 1
        color: qgcPal.text
    }

    Rectangle {
        id: valuesRect2
        anchors.topMargin: 5  // Reduced top margin, adjust the value as needed

        anchors.top: sep.bottom
        width: parent.width
        height: parent.height - valuesHeader.height - sep.height
        color: qgcPal.windowShadeDark
        ScrollView {
            Layout.fillWidth: true
            contentWidth: width // Set the content width to the width of the ScrollView to prevent horizontal scrolling
            anchors.fill: parent
            ColumnLayout {
                id: valuesColumn
                implicitHeight: 2000// or sum up individual implicit heights of children if more precise control is needed

                visible: !_confirmationStart && !_textFieldSave && !loadChoice
                anchors.margins: _margin
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: sep.bottom
                spacing: _margin
                Row {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 2 : ScreenTools.defaultFontPixelWidth * 5

                    QGCHoverButton {
                        id: buttonResume
                        Layout.fillWidth: true
                        width: ScreenTools.isMobile ? 50 : 60
                        height: width
                        radius: ScreenTools.defaultFontPixelWidth / 2
                        autoExclusive: true

                        imageSource: "/InstrumentValueIcons/play-outline.svg"
                        text: "Resume"
                        checked: factResume.fact.value

                        onClicked: {
                            factResume.fact.value = !factResume.fact.value;
                        }
                    }
                    FactCheckBox {
                        id: factResume
                        visible: false
                        fact: controller.getParameterFact(-1, "SU_MSN_RESUME")
                        Layout.fillWidth: true
                        scale: ScreenTools.isMobile ? 0.7 : 0.8
                    }
                    QGCHoverButton {
                        id: buttonAutoSpray
                        Layout.fillWidth: true
                        width: ScreenTools.isMobile ? 50 : 60
                        height: width
                        radius: ScreenTools.defaultFontPixelWidth / 2
                        autoExclusive: true

                        imageSource: "/InstrumentValueIcons/spray.svg"
                        text: "Auto"
                        checked: factAutoSpray.fact.value

                        onClicked: {
                            factAutoSpray.fact.value = !factAutoSpray.fact.value;
                        }
                    }
                    FactCheckBox {
                        id: factAutoSpray
                        visible: false
                        fact: controller.getParameterFact(-1, "SU_AUTO_SPRY_EN")
                        Layout.fillWidth: true
                        scale: ScreenTools.isMobile ? 0.7 : 0.8
                    }
                }

                Row {

                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 9 : ScreenTools.defaultFontPixelWidth * 15
                    QGCLabel {
                        text: qsTr("Travel Height")
                        anchors.topMargin: 1 // Adjust this value to move the text lower
                        font.family: ScreenTools.demiboldFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    FactTextField {
                        fact: QGroundControl.settingsManager.appSettings.offlineEditingAltitude
                        showUnits: true
                        showHelp: false
                        width: ScreenTools.isMobile ? 60 : 100
                    }
                }
                Row {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 1 : ScreenTools.defaultFontPixelWidth * 3
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 2
                    QGCButton {
                        scale: ScreenTools.isMobile ? 0.9 : 1
                        height: parent.height
                        width: height
                        text: "-"
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: QGroundControl.settingsManager.appSettings.offlineEditingAltitude.value = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingAltitude.value - 0.5, QGroundControl.settingsManager.appSettings.offlineEditingAltitude.max), QGroundControl.settingsManager.appSettings.offlineEditingAltitude.min)
                    }
                    Slider {
                        id: travelHeight
                        property bool _loadComplete: false
                        from: QGroundControl.settingsManager.appSettings.offlineEditingAltitude.min
                        to: QGroundControl.settingsManager.appSettings.offlineEditingAltitude.max
                        stepSize: 0.5
                        width: ScreenTools.isMobile ? 100 : 200
                        value: factTravelHeight.fact.value
                        onValueChanged: {
                            QGroundControl.settingsManager.appSettings.offlineEditingAltitude.value = travelHeight.value;
                        }
                    }

                    FactTextFieldSlider {
                        id: factTravelHeight
                        visible: false
                        fact: controller.getParameterFact(-1, "SU_TRAVEL_ALT")
                    }

                    QGCButton {
                        scale: ScreenTools.isMobile ? 0.9 : 1
                        height: parent.height
                        width: height
                        text: "+"
                        anchors.verticalCenter: parent.verticalCenter

                        onClicked: QGroundControl.settingsManager.appSettings.offlineEditingAltitude.value = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingAltitude.value + 0.5, QGroundControl.settingsManager.appSettings.offlineEditingAltitude.max), QGroundControl.settingsManager.appSettings.offlineEditingAltitude.min)
                    }
                }

                Row {
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 9 : ScreenTools.defaultFontPixelWidth * 15
                    width: parent.width

                    QGCLabel {
                        text: qsTr("Spray Height")
                        font.family: ScreenTools.demiboldFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.topMargin: 1 // Adjust this value to move the text lower
                    }

                    FactTextField {
                        fact: QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight
                        showUnits: true
                        showHelp: false
                        width: ScreenTools.isMobile ? 60 : 100
                    }
                }
                Row {
                    width: parent.width * 1.5
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 1 : ScreenTools.defaultFontPixelWidth * 3
                    QGCButton {
                        scale: ScreenTools.isMobile ? 0.9 : 1
                        height: parent.height
                        width: height
                        text: "-"
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.value = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.value - 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.max), QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.min)
                    }
                    Slider {
                        id: sprayHeight
                        property bool _loadComplete: false
                        from: QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.min
                        to: QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.max
                        stepSize: 0.5
                        width: ScreenTools.isMobile ? 100 : 200
                        value: factSprayHeight.fact.value

                        onValueChanged: {
                            QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.value = sprayHeight.value;
                        }
                    }
                    FactTextFieldSlider {
                        id: factSprayHeight
                        visible: false
                        fact: controller.getParameterFact(-1, "SU_SPRAY_ALT")
                    }

                    QGCButton {
                        scale: ScreenTools.isMobile ? 0.9 : 1
                        height: parent.height
                        width: height
                        text: "+"
                        anchors.verticalCenter: parent.verticalCenter

                        onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.value = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.value + 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.max), QGroundControl.settingsManager.appSettings.offlineEditingSprayerHeight.min)
                    }
                }

                Row {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 9 : ScreenTools.defaultFontPixelWidth * 15

                    QGCLabel {
                        text: qsTr("Spray Volume")
                        font.family: ScreenTools.demiboldFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.topMargin: 1 // Adjust this value to move the text lower
                    }
                    FactTextField {
                        fact: QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume
                        showUnits: true
                        showHelp: false
                        width: ScreenTools.isMobile ? 60 : 100
                    }
                }
                Row {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 1 : ScreenTools.defaultFontPixelWidth * 3
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 2
                    QGCButton {
                        scale: ScreenTools.isMobile ? 0.9 : 1
                        height: parent.height
                        width: height
                        text: "-"
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.value = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.value - 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.max), QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.min)
                    }
                    Slider {
                        id: sprayVolume
                        property bool _loadComplete: false
                        from: QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.min
                        to: QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.max
                        stepSize: 0.5
                        width: ScreenTools.isMobile ? 100 : 200
                        value: factSprayVolume.fact.value

                        onValueChanged: {
                            QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.value = sprayVolume.value;
                        }
                    }
                    FactTextFieldSlider {
                        id: factSprayVolume
                        visible: false
                        fact: controller.getParameterFact(-1, "SU_SPRY_VOL")
                    }

                    QGCButton {
                        scale: ScreenTools.isMobile ? 0.9 : 1
                        height: parent.height
                        width: height
                        text: "+"
                        anchors.verticalCenter: parent.verticalCenter

                        onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.value = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.value + 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.max), QGroundControl.settingsManager.appSettings.offlineEditingSprayerVolume.min)
                    }
                }
                Row {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 9 : ScreenTools.defaultFontPixelWidth * 15
                    QGCLabel {
                        text: qsTr("Spray Speed")
                        anchors.topMargin: 1 // Adjust this value to move the text lower
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: ScreenTools.demiboldFontFamily
                    }
                    FactTextFieldSlider {
                        id: factSpraySpeed
                        visible: false
                        fact: controller.getParameterFact(-1, "SU_SPRY_FLT_SPD")
                    }
                    FactTextField {
                        fact: QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow
                        showUnits: true
                        showHelp: false
                        width: ScreenTools.isMobile ? 60 : 100
                    }
                }
                Row {
                    width: parent.width * 1.5
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 1 : ScreenTools.defaultFontPixelWidth * 3
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 2
                    QGCButton {
                        scale: ScreenTools.isMobile ? 0.9 : 1
                        height: parent.height
                        width: height
                        text: "-"
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.value = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.value - 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.max), QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.min)
                    }
                    Slider {
                        id: spraySpeed
                        property bool _loadComplete: false
                        from: QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.min
                        to: QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.max
                        stepSize: 0.5
                        //TO DO SUIND
                        //tickmarksEnabled:   true
                        width: ScreenTools.isMobile ? 100 : 200
                        value: factSpraySpeed.fact.value
                        onValueChanged: {
                            QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.value = spraySpeed.value;
                        }
                    }

                    QGCButton {
                        scale: ScreenTools.isMobile ? 0.9 : 1
                        height: parent.height
                        width: height
                        text: "+"
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.value = Math.max(Math.min(QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.value + 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.max), QGroundControl.settingsManager.appSettings.offlineEditingSprayerFlow.min)
                    }
                }
                Row {

                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 12 : ScreenTools.defaultFontPixelWidth * 18

                    QGCLabel {
                        text: qsTr("Spacing")
                        font.family: ScreenTools.demiboldFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.topMargin: 1 // Adjust this value to move the text lower
                    }
                    FactTextFieldSlider {
                        id: factSpacing
                        visible: false
                        fact: controller.getParameterFact(-1, "SU_SPRY_WIDTH")
                    }
                    FactTextField {
                        fact: QGroundControl.settingsManager.appSettings.offlineEditingSpacing
                        showUnits: true
                        showHelp: false
                        width: ScreenTools.isMobile ? 60 : 100
                    }
                }
                Row {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 1 : ScreenTools.defaultFontPixelWidth * 3
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 2
                    QGCButton {
                        scale: ScreenTools.isMobile ? 0.9 : 1
                        height: parent.height
                        width: height
                        text: "-"
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            factSpacing.fact.value = Math.max(Math.min(factSpacing.fact.value - 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSpacing.max), QGroundControl.settingsManager.appSettings.offlineEditingSpacing.min);
                            QGroundControl.settingsManager.appSettings.offlineEditingSpacing.value = factSpacing.fact.value;
                            polygonItem.cameraCalc.adjustedFootprintSide.value = factSpacing.fact.value;
                            spacing.value = factSpacing.fact.value;
                        }
                    }
                    Slider {
                        id: spacing
                        property bool _loadComplete: false
                        from: QGroundControl.settingsManager.appSettings.offlineEditingSpacing.min
                        to: QGroundControl.settingsManager.appSettings.offlineEditingSpacing.max
                        stepSize: 0.5
                        width: ScreenTools.isMobile ? 100 : 200
                        value: polygonItem ? QGroundControl.settingsManager.appSettings.offlineEditingSpacing.value : factSpacing.fact.value

                        Component.onCompleted: {
                            // Ensure the slider value is initialized only once on component completion
                            polygonItem.cameraCalc.adjustedFootprintSide.value = 2;
                            QGroundControl.settingsManager.appSettings.offlineEditingSpacing.value = 2.0;
                            factSpacing.fact.value = spacing.value = 2;
                            _loadComplete = true;
                        }

                        onValueChanged: {
                            // Update the value of the FactSlider when the Slider value changes
                            factSpacing.fact.value = spacing.value;
                            QGroundControl.settingsManager.appSettings.offlineEditingSpacing.value = spacing.value;
                            if (polygonItem)
                                polygonItem.cameraCalc.adjustedFootprintSide.value = spacing.value;
                        }
                    }

                    QGCButton {
                        scale: ScreenTools.isMobile ? 0.9 : 1
                        height: parent.height
                        width: height
                        text: "+"
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            factSpacing.fact.value = Math.max(Math.min(factSpacing.fact.value + 0.5, QGroundControl.settingsManager.appSettings.offlineEditingSpacing.max), QGroundControl.settingsManager.appSettings.offlineEditingSpacing.min);
                            QGroundControl.settingsManager.appSettings.offlineEditingSpacing.value = factSpacing.fact.value;
                            polygonItem.cameraCalc.adjustedFootprintSide.value = factSpacing.fact.value;
                            spacing.value = factSpacing.fact.value;
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 13.5 : ScreenTools.defaultFontPixelWidth * 20
                    QGCLabel {
                        text: qsTr("Angle")
                        font.family: ScreenTools.demiboldFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.topMargin: 1 // Adjust this value to move the text lower
                    }
                    FactTextField {
                        fact: QGroundControl.settingsManager.appSettings.batteryPercentRemainingAnnounce
                        showUnits: true
                        showHelp: false
                        width: ScreenTools.isMobile ? 60 : 100
                    }
                }
                Row {
                    width: parent.width * 1.5
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 1 : ScreenTools.defaultFontPixelWidth * 3
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 2
                    QGCButton {
                        scale: ScreenTools.isMobile ? 0.9 : 1
                        height: parent.height
                        width: height
                        text: "-"
                        anchors.verticalCenter: parent.verticalCenter

                        onClicked: {
                            polygonItem.gridAngle.value = Math.max(Math.min(QGroundControl.settingsManager.appSettings.batteryPercentRemainingAnnounce.value - 1, 180), 0);
                            QGroundControl.settingsManager.appSettings.batteryPercentRemainingAnnounce.value = polygonItem.gridAngle.value;
                            angle.value = QGroundControl.settingsManager.appSettings.batteryPercentRemainingAnnounce.value;
                        }
                    }
                    Slider {
                        id: angle
                        property bool _loadComplete: false
                        from: 0
                        to: 180
                        stepSize: 1
                        width: ScreenTools.isMobile ? 100 : 200

                        Component.onCompleted: {
                            QGroundControl.settingsManager.appSettings.batteryPercentRemainingAnnounce.value = 0;
                        }

                        onValueChanged: {
                            polygonItem.gridAngle.value = value;
                            QGroundControl.settingsManager.appSettings.batteryPercentRemainingAnnounce.value = value;
                        }
                    }

                    QGCButton {
                        scale: ScreenTools.isMobile ? 0.9 : 1
                        height: parent.height
                        width: height
                        text: "+"
                        anchors.verticalCenter: parent.verticalCenter

                        onClicked: {
                            polygonItem.gridAngle.value = Math.max(Math.min(polygonItem.gridAngle.value + 1, 180), 0);
                            QGroundControl.settingsManager.appSettings.batteryPercentRemainingAnnounce.value = polygonItem.gridAngle.value;
                            angle.value = QGroundControl.settingsManager.appSettings.batteryPercentRemainingAnnounce.value;
                        }
                    }
                }
                QGCButton {
                    text: qsTr("Rotate entry point")
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: polygonItem.rotateEntryPoint()
                }

                Row {
                    height: 50
                }
            }
        }
    }
    Column {
        id: confirmationColumn
        visible: _confirmationStart
        anchors.margins: _margin
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: _margin
        SectionHeader {
            id: sepConfirmation
            anchors.left: parent.left
            anchors.right: parent.right
            text: "Recap Header"
        }
        QGCLabel {
            text: qsTr("Are you sure you want to start the mission?")
            font.family: ScreenTools.demiboldFontFamily
        }
        Row {
            QGCButton {
                text: "No"
                Layout.fillWidth: true
                onClicked: {
                    _confirmationStart = false;
                }
            }

            QGCButton {
                text: "Yes"
                Layout.fillWidth: true
                onClicked: {
                    _confirmationStart = false;
                    _planMasterController.upload();
                    mainWindow.popView();
                }
            }
        }
        SectionHeader {
            id: statsHeader
            anchors.left: parent.left
            anchors.right: parent.right
            text: qsTr("Statistics")
        }

        Row {
            QGCLabel {
                text: qsTr("Trigger Distance")
            }
            // QGCLabel { text: polygonItem.cameraCalc.adjustedFootprintSide.valueString + " " + QGroundControl.appSettingsDistanceUnitsString }
        }
    }
    Column {
        id: loadChoiceColumn
        visible: loadChoice
        anchors.margins: _margin
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top + 500
        spacing: _margin
        QGCLabel {
            text: qsTr("Which kind of file are you loading?")
            font.family: ScreenTools.demiboldFontFamily
        }
        Row {
            QGCButton {
                text: "KML"
                Layout.fillWidth: true
                onClicked: {
                    loadChoice = false;
                    kmlOrSHPLoadDialog.openForLoad();
                }
            }

            QGCButton {
                text: "Mission"
                Layout.fillWidth: true
                onClicked: {
                    loadChoice = false;
                    _planMasterController.loadFromSelectedFile();
                }
            }
        }
        Row {
            QGCButton {
                text: "Back"
                Layout.fillWidth: true
                onClicked: {
                    loadChoice = false;
                }
            }
        }
    }
}
// Rectangle