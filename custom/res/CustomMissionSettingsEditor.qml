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
    property var    _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle

    // Define properties
    property var myGeoFenceController
    property var _flightMap
    id: valuesRect

    // Controller for managing facts
    FactPanelController {
        id: controller
    }

    // Set height based on whether the screen is mobile
   // height: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 45 : ScreenTools.defaultFontPixelHeight * 50

    // Background color and corner radius
    color: qgcPal.windowShadeDark
    radius: _radius

    // Array to save vertices
    property var _savedVertices: []

    // Mission and controller-related properties
    property var _masterControler
    property var _missionController: _masterControler.missionController
    property var _controllerVehicle: _masterControler.controllerVehicle
    property bool _vehicleHasHomePosition: _controllerVehicle.homePosition.isValid
    property bool _showCruiseSpeed: !_controllerVehicle.multiRotor
    property bool _showHoverSpeed: _controllerVehicle.multiRotor || _controllerVehicle.vtol
    property bool _multipleFirmware: !QGroundControl.singleFirmwareSupport
    property bool _multipleVehicleTypes: !QGroundControl.singleVehicleSupport

    // Layout-related properties
    property real _fieldWidth: ScreenTools.defaultFontPixelWidth * 16
    property bool _mobile: ScreenTools.isMobile

    // File save path and extension
    property var _savePath: QGroundControl.settingsManager.appSettings.missionSavePath
    property var _fileExtension: QGroundControl.settingsManager.appSettings.missionFileExtension

    // App settings
    property var _appSettings: QGroundControl.settingsManager.appSettings
    property bool _waypointsOnlyMode: QGroundControl.corePlugin.options.missionWaypointsOnly
    property bool _showCameraSection: (_waypointsOnlyMode || QGroundControl.corePlugin.showAdvancedUI) && !_controllerVehicle.apmFirmware
    property bool _simpleMissionStart: QGroundControl.corePlugin.options.showSimpleMissionStart
    property bool _showFlightSpeed: !_controllerVehicle.vtol && !_simpleMissionStart && !_controllerVehicle.apmFirmware

    // Various boolean flags
    property bool _allowFWVehicleTypeSelection: false
    property bool _confirmationStart: false
    property bool loadChoice: false
    property bool _textFieldSave: false
    property bool _editTracing: false
    property bool isTraced: false

    // Labels and margins
    readonly property string _firmwareLabel: qsTr("Firmware")
    readonly property string _vehicleLabel: qsTr("Vehicle")
    readonly property real _margin: ScreenTools.defaultFontPixelWidth / 2
    readonly property real  _rightPanelWidth:           ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 34 :  ScreenTools.defaultFontPixelWidth * 50

    // Polygon item
    property var polygonItem: null

    // QGCPalette for UI colors
    QGCPalette {
        id: qgcPal
    }

    // File dialog controller
    QGCFileDialogController {
        id: fileController
    }

    // Altitude mode dialog component
    Component {
        id: altModeDialogComponent
        AltModeDialog {
        }
    }

    // Connections for vehicle property changes
    Connections {
        target: _controllerVehicle
        function onSupportsTerrainFrameChanged() {
            if (!_controllerVehicle.supportsTerrainFrame && _missionController.globalAltitudeMode === QGroundControl.AltitudeModeTerrainFrame) {
                _missionController.globalAltitudeMode = QGroundControl.AltitudeModeCalcAboveTerrain;
            }
        }
    }

    // Layout for the main UI elements
    ColumnLayout {
        id: valuesHeader

        // Visibility based on flags
        visible: !_confirmationStart && !_textFieldSave && !loadChoice
        anchors.margins: _margin
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: _margin

        // Row for the toolbar and tab bar
        Row {
            Layout.leftMargin: _margin -5
            Layout.topMargin: _margin -5
            /*QGCToolBarButton {
                id: currentButton
                icon.source: "/qmlimages/Home.svg"
                logo: true
                onClicked: mainWindow.showToolSelectDialog()
            }*/
            QGCTabBar {
                id: bar
                width: _rightPanelWidth - 32
                background: null
                Component.onCompleted: {
                    currentIndex = 0
                }
                QGCTabButton {
                    text: qsTr("Mission")
                    height: 35
                }
                QGCTabButton {
                    text: qsTr("Fence")
                    height: 35
                }
            }
        }
        // Row for trace and add waypoint buttons
        Row {
            visible: bar.currentIndex == 0
            spacing: ScreenTools.defaultFontPixelWidth * 1.5
            //Layout.leftMargin: _margin + 12

            // Trace button
            QGCButton {

                width: _rightPanelWidth - 36
                height: ScreenTools.isMobile ? 28 : 28
                id: buttonDraw
                text: "Trace"
                checked: _editTracing
                               background: Rectangle {
                    color: _editTracing ? "#595757" : "#ffffff" // When clicked turns light grey
                    radius: 14  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                onClicked: {
                    // Toggle the _editTracing property
                    _editTracing = !_editTracing;
                    // Disable adding waypoints on click
                    _addWaypointOnClick = false;

                    {
            
                        // Check if tracing has not been started yet
                        if (!isTraced) {
                            // Get the index of the last visual item
                            var currentIndex = _missionController.visualItems.count;
                            // Retrieve the last visual item as polygonItem
                            polygonItem = _missionController.visualItems.get(currentIndex - 1);

                            // Insert a complex mission item if it hasn't been traced yet
                            insertComplexItemAfterCurrent(_missionController.complexMissionItemNames[0]);

                            // Get the current visual item as polygonItem
                            polygonItem = _missionController.visualItems.get(currentIndex);

                            // If the polygonItem exists, set its camera footprint side value
                            if (polygonItem) 
                                polygonItem.cameraCalc.adjustedFootprintSide.value = 2;

                            // Check if the polygon's traceMode is enabled
                            if (polygonItem.surveyAreaPolygon.traceMode) {
                                // If the polygon has fewer than 3 vertices, restore previous vertices
                                if (polygonItem.surveyAreaPolygon.count < 3) {
                                    _restorePreviousVertices(polygonItem);
                                }
                                // Mark tracing as started
                                isTraced = true;
                                // Disable traceMode
                                polygonItem.surveyAreaPolygon.traceMode = false;
                            }

                            // Enable traceMode if tracing is being edited
                            if (!polygonItem.surveyAreaPolygon.traceMode && _editTracing) {
                                polygonItem.surveyAreaPolygon.traceMode = true;
                                // Save the current vertices
                                _saveCurrentVertices(polygonItem);
                                // Clear the current polygon vertices
                                polygonItem.surveyAreaPolygon.clear();
                                // Mark tracing as started
                                isTraced = true;
                            }
                        } else {
                            // If tracing was already started, disable traceMode
                            if (polygonItem && polygonItem.surveyAreaPolygon && polygonItem.surveyAreaPolygon.traceMode)
                                polygonItem.surveyAreaPolygon.traceMode = false;
                        }
                    }
                }
            }   
        }
        // Add waypoint button
        Row {
            visible: bar.currentIndex == 0
            width: parent.width
            //spacing: ScreenTools.defaultFontPixelWidth * 1.5
            //Layout.leftMargin: _margin + 12
            
            QGCButton {
                background: Rectangle {
                    color: _addWaypointOnClick ? "#595757" : "#ffffff" // When clicked turns light grey
                    radius: 14  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                id: buttonTravel
                width: _rightPanelWidth - 36
                height: ScreenTools.isMobile ? 28 : 28
                text: "Add waypoint"
                checked: _addWaypointOnClick
                onClicked: {
                    if (polygonItem) {
                        polygonItem.surveyAreaPolygon.traceMode = false;
                        _editTracing = false;
                    }
                    _addWaypointOnClick = !_addWaypointOnClick;
                    buttonTravel.color = _addWaypointOnClick ? "#d3d3d3" : "#ffffff"; // Change background color
                }
            }
        }
                Row {
            visible: bar.currentIndex == 0
            width: parent.width
            //spacing: ScreenTools.defaultFontPixelWidth * 1.5
            //Layout.leftMargin: _margin + 12
            
            QGCButton {
                id: buttonsetwp
                width: _rightPanelWidth - 36
                height: ScreenTools.isMobile ? 28 : 28
                text: "Set last waypoint as vehicle position"
                onClicked: {
                var currentIndex = _missionController.visualItems.count;
                // Retrieve the last visual item as waypointItem
                var  waypointItem= _missionController.visualItems.get(currentIndex - 1);
                waypointItem.coordinate = _activeVehicle.coordinate

                }
            }
        }



        // Row for mission buttons
        Row {
            visible: bar.currentIndex == 0
            width: parent.width
            //Layout.leftMargin: _margin + 12
            spacing: ScreenTools.defaultFontPixelWidth * 1.5

            // Undo button
            QGCButton {
                background: Rectangle {
                    color: "#ffffff"  
                    radius: 14  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                width: ScreenTools.isMobile ?  80 : 28
                height: ScreenTools.isMobile ? 28 : 28
                text: "Undo"
                onClicked: {
                    var lastIndex = _missionController.visualItems.count - 1;
                    if (lastIndex > 0) {
                        if (_missionController.visualItems.get(lastIndex).surveyAreaPolygon)
                            isTraced = false;
                    }
                    _missionController.removeVisualItem(lastIndex);
                }
            }
            
            // Clear button
            QGCButton {
                background: Rectangle {
                    color: "#ffffff"  
                    radius: 14  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                width: ScreenTools.isMobile ? 80 : 28
                height: ScreenTools.isMobile ? 28 : 28
                text: "Clear"
                Layout.fillWidth: true
                onClicked: {
                    
                    mainWindow.showMessageDialog(qsTr("Clear"), qsTr("Are you sure you want to remove all mission items and clear the mission from the vehicle?"), Dialog.Yes | Dialog.Cancel, function () {
                        polygonItem = null;
                        _editTracing = false;
                        for (var i = _missionController.visualItems.count - 1; i >= 0; i--) {
                            _missionController.removeVisualItem(i);
                        }
                        _planMasterController.removeAllFromVehicle();
                        isTraced = false;
                        _missionController.setCurrentPlanViewSeqNum(0, true);
                    });
                }
            }
        }

        // Row for additional mission buttons
        Row {
            visible: bar.currentIndex == 0
            width: parent.width
            //Layout.topMargin: _margin * 1
            spacing: ScreenTools.defaultFontPixelWidth * 1.5
            //Layout.leftMargin: _margin + 12

            // File dialog for loading KML or SHP files
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

            

            // Load button
            QGCButton {
                background: Rectangle {
                    color: "#ffffff"  
                    radius: 14  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                width: ScreenTools.isMobile ? 80 : 28
                height: ScreenTools.isMobile ? 28 : 28
                id: loadButton
                text: "Load"
                Layout.fillWidth: true
                onClicked: {
                    loadChoice = true;
                }
            }

            // Save button
            QGCButton {
                background: Rectangle {
                    color: "#ffffff"  
                    radius: 14  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                text: qsTr("Save")
                width: ScreenTools.isMobile ? 80 : 28
                height: ScreenTools.isMobile ? 28 : 28
                Layout.fillWidth: true
                enabled: !_planMasterController.syncInProgress
                onClicked: {
                                        if (polygonItem) {
                        polygonItem.surveyAreaPolygon.traceMode = false;
                        _editTracing = false;
                    }
                    if (_planMasterController.currentPlanFile !== "") {
                        _planMasterController.saveToCurrent();
                    } else {
                        _planMasterController.saveToSelectedFile();
                    }
                }
            }
        }
        //Row for start button
        Row {
            visible: bar.currentIndex == 0
            width: parent.width
            Layout.topMargin: _margin * 1
            spacing: ScreenTools.defaultFontPixelWidth * 1.5
            //Layout.leftMargin: _margin + 12

            // Start button
            QGCButton {
                background: Rectangle {
                    color: "#99ff8a"  
                    radius: 14  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                width: _rightPanelWidth - 36
                height: ScreenTools.isMobile ? 28 : 28
                text: "Start"
                //primary: true
                onClicked: {
                    if (polygonItem) {
                        polygonItem.surveyAreaPolygon.traceMode = false;
                        _editTracing = false;
                    }
                    _planMasterController.saveToSelectedFile();
                    _confirmationStart = true;
                }

                // Function to insert boundaries to file
                function insertBoundariesToFile() {
                    var nextIndex = _missionController.currentPlanViewVIIndex + 1;
                    for (var i = 0; i < polygonItem.boundaries.length; i++) {
                        _missionController.insertSimpleMissionItemBoundary(polygonItem.boundaries[i], nextIndex + i, false);
                    }
                }

                // Animation for button opacity
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
        
        
    }

    // Separator line
    Rectangle {
        visible: bar.currentIndex == 0
        id: sep
        anchors.top: valuesHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        Layout.fillWidth: true
        height: 1
        color: qgcPal.text
    }

    // ScrollView for mission settings
    Rectangle {
        visible: bar.currentIndex == 0
        id: valuesRect2
        anchors.topMargin: 5
        width: ScreenTools.isMobile ? 300 : 400
        anchors.top: sep.bottom
        height: parent.height - valuesHeader.height - sep.height
        color: "transparent"

        ScrollView {
            anchors.fill: parent
            contentWidth: width

            ColumnLayout {
                id: valuesColumn
                implicitHeight: 50000
                anchors.top: sep.bottom

                visible: !_confirmationStart && !_textFieldSave && !loadChoice
                spacing: _margin
                // Row for angle setting
                RowLayout {
                    width: parent.width
                    spacing: ScreenTools.defaultFontPixelWidth * 2

                    QGCLabel {
                        text: qsTr("Angle")
                        font.family: ScreenTools.demiboldFontFamily
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true
                    }

                    FactTextField {
                        id: factAngle
                        visible: false
                        fact: QGroundControl.settingsManager.appSettings.batteryPercentRemainingAnnounce
                        showUnits: true
                        showHelp: false
                        width: ScreenTools.isMobile ? 60 : 60  // Ajuste a largura
                        height: ScreenTools.isMobile ? 30 : 30  // Ajuste a altura
                        Layout.alignment: Qt.AlignRight
                        onTextChanged: {
                            labelAngle.text = factAngle.text;
                            angleSlider.value = factAngle.fact.value;
                        }
                    }
                }

                // Row for angle adjustment
                RowLayout {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 1 : ScreenTools.defaultFontPixelWidth * 3
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 2

                    QGCSlider {
                        id: angleSlider
                        property bool _loadComplete: false
                        from: 0
                        to: 180
                        stepSize: 1
                        width: parent.width - 30  // Ajuste a largura do slider

                        Component.onCompleted: {
                            QGroundControl.settingsManager.appSettings.batteryPercentRemainingAnnounce.value = 0;
                        }

                        onValueChanged: {
                            polygonItem.gridAngle.value = value;
                            QGroundControl.settingsManager.appSettings.batteryPercentRemainingAnnounce.value = value;
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
                            id: labelAngle
                            text: factSpacing.text
                            anchors.centerIn: parent
                            color: "#333333"
                            font.pixelSize: 12
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter

                            // Update the factFlightSpeed text when the user edits the TextInput
                            onEditingFinished: {
                                factAngle.text = labelAngle.text;
                                angleSlider.value = parseFloat(labelAngle.text);
                            }
                        }
                    }
                }

                // Row for spacing setting
                RowLayout {
                    width: parent.width
                    spacing: ScreenTools.defaultFontPixelWidth * 2

                    QGCLabel {
                        text: qsTr("Spacing")
                        font.family: ScreenTools.demiboldFontFamily
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true
                    }

                    FactTextField {
                        id: factSpacing
                        visible: false
                        fact: polygonItem.cameraCalc.adjustedFootprintSide
                        showUnits: true
                        showHelp: false
                        width: ScreenTools.isMobile ? 60 : 60  // Ajuste a largura
                        height: ScreenTools.isMobile ? 30 : 30  // Ajuste a altura
                        Layout.alignment: Qt.AlignRight
                        onTextChanged: {
                            labelSpacing.text = factSpacing.text;
                            spacingSlider.value = factSpacing.fact.value;
                        }
                    }
                }

                // Row for spacing adjustment
                RowLayout {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 1 : ScreenTools.defaultFontPixelWidth * 3
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 2

                    QGCSlider {
                        id: spacingSlider
                        property bool _loadComplete: false
                        from: 5
                        to: 12
                        stepSize: 0.5
                        width: _rightPanelWidth - 30  // Ajuste a largura do slider

                        onValueChanged: {
                            polygonItem.cameraCalc.adjustedFootprintSide.value = value;
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
                            id: labelSpacing
                            text: factSpacing.text
                            anchors.centerIn: parent
                            color: "#333333"
                            font.pixelSize: 12
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter

                            // Update the factFlightSpeed text when the user edits the TextInput
                            onEditingFinished: {
                                factSpacing.text = labelSpacing.text;
                                spacingSlider.value = parseFloat(labelSpacing.text);
                            }
                        }
                    }
                }

                // Row for turnaround setting
                RowLayout {
                    width: parent.width
                    spacing: ScreenTools.defaultFontPixelWidth * 2

                    QGCLabel {
                        text: qsTr("Turnaround Dist")
                        font.family: ScreenTools.demiboldFontFamily
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillWidth: true
                    }
                }

                // Row for turnaround adjustment
                RowLayout {
                    width: parent.width
                    spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 1 : ScreenTools.defaultFontPixelWidth * 3
                    anchors.topMargin: ScreenTools.defaultFontPixelWidth * 2

                    QGCSlider {
                        id: turnAroundSlider
                        property bool _loadComplete: false
                        from: 0
                        to: 19
                        stepSize: 0.5
                        width: parent.width - 30  // Ajuste a largura do slider

                        onValueChanged: {
                            polygonItem.turnAroundDistance.value = value;
                        }
                    }

                    FactTextField {
                        id: factTurnaround
                        visible: false
                        fact: polygonItem.turnAroundDistance
                        Layout.alignment: Qt.AlignRight
                        onTextChanged: {
                            labelTurnaround.text = factTurnaround.text;
                            turnAroundSlider.value = factTurnaround.fact.value;
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
                            id: labelTurnaround
                            text: factTurnaround.text
                            anchors.centerIn: parent
                            color: "#333333"
                            font.pixelSize: 12
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter

                            // Update the factFlightSpeed text when the user edits the TextInput
                            onEditingFinished: {
                                factTurnaround.text = labelTurnaround.text;
                                turnAroundSlider.value = parseFloat(labelTurnaround.text);
                            }
                        }
                    }
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

                // Button to rotate entry point
                Row {
                    visible: bar.currentIndex == 0
                    width: parent.width
                    Layout.topMargin: _margin * 4
                    Layout.leftMargin: _margin * 1
                    spacing: ScreenTools.defaultFontPixelWidth * 1.5
                    QGCButton {
                        background: Rectangle {
                        color: "#ff4800"
                        radius: 14
                        border.color: "white"
                        anchors.fill: parent
                        }
                        width: _rightPanelWidth - 36
                        height: ScreenTools.isMobile ? 28 : 28
                        text: qsTr("Rotate entry point")
                        //anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: polygonItem.rotateEntryPoint()
                    }
                }

                Row {
                    height: 500
                }
            }
        }
    }


    // Column for mission start confirmation
    Column {
        id: confirmationColumn
        visible: _confirmationStart && bar.currentIndex == 0
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
                                        if (polygonItem) {
                        polygonItem.surveyAreaPolygon.traceMode = false;
                        _editTracing = false;
                    }
                    _confirmationStart = false;
                    _planMasterController.upload();
                    mainWindow.showFlyView()
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
                        visible:polygonItem
                        text: qsTr("Survey Area:")
                    }
                    QGCLabel {
                        visible: polygonItem
                        QGCLabel { visible : polygonItem; text: QGroundControl.unitsConversion.squareMetersToAppSettingsAreaUnits(polygonItem.coveredArea/10000).toFixed(2) + " " +  "hA"}
                    }        }
    }

    // Column for file load choice
    Column {
        id: loadChoiceColumn
        visible: loadChoice && bar.currentIndex == 0
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

    // Rectangle for GeoFence editor
    Rectangle {
        visible: bar.currentIndex == 1
        id: geo
        anchors.topMargin: 5
        anchors.top: sep.bottom
        height: 500
        width: ScreenTools.isMobile ? 300 : 400
        color: qgcPal.windowShadeDark
        GeoFenceEditor {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            visible: bar.currentIndex == 1
            myGeoFenceController: _planMasterController.geoFenceController
            flightMap: _flightMap
        }
    }
}
