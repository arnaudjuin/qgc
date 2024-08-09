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
import GlobalSignals 1.0

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
   height: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 45 : ScreenTools.defaultFontPixelHeight * 50

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
    property bool _editCorridor: false
    property bool isTraced: false
    property bool isTracedCorridor: false

    // Labels and margins
    readonly property string _firmwareLabel: qsTr("Firmware")
    readonly property string _vehicleLabel: qsTr("Vehicle")
    readonly property real _margin: ScreenTools.defaultFontPixelWidth / 2
    //readonly property real  _rightPanelWidth:           ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 34 :  ScreenTools.defaultFontPixelWidth * 51

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
                width: _rightPanelWidth - (_margin + 2)
                background: null
                Component.onCompleted: {
                    currentIndex = 0
                }
                QGCTabButton {
                    height: 35
                    background: Rectangle {
                        id: backgroundRect1
                        color: bar.currentIndex === 0 ? "#ff4800" : (bar.currentIndex === 1 ? "black" : "black")
                        radius: 5
                        width: parent.width
                        height: parent.height
                    }
                    Image {
                        source: "/custom/img/MissionTab.svg" // Caminho para a imagem SVG
                        width: 30
                        height: 30
                        anchors.centerIn: parent
                    }
                }
                QGCTabButton {
                    height: 35
                    background: Rectangle {
                        id: backgroundRect2
                        color: bar.currentIndex === 1 ? "#ff4800" : (bar.currentIndex === 0 ? "black" : "black")
                        radius: 5
                        width: parent.width
                        height: parent.height
                    }
                    Image {
                        source: "/custom/img/FenceTab.svg" // Caminho para a imagem SVG
                        width: 30
                        height: 30
                        anchors.centerIn: parent
                    }
                }
                QGCTabButton{
                    height: 35
                    background: Rectangle {
                        id: backgroundRect3
                        color: bar.currentIndex === 2 ? "#ff4800" : (bar.currentIndex === 0 ? "black" : "black")
                        radius: 5
                        width: parent.width
                        height: parent.height
                    }
                    Image {
                        source: "/custom/img/LoadTab.svg" // Caminho para a imagem SVG
                        width: 30
                        height: 30
                        anchors.centerIn: parent
                    }
                }
            }
            // Connections to handle tab changes
            Connections {
                target: bar
                onCurrentIndexChanged: {
                    if (bar.currentIndex === 1) {
                        QGroundControl.corePlugin.showGeoFence = true;
                        QGroundControl.corePlugin.showLoadPlan = true;
                    }
                    else if (bar.currentIndex === 2){
                        QGroundControl.corePlugin.showGeoFence = true;
                        QGroundControl.corePlugin.showLoadPlan = true;
                    }
                    else {
                        QGroundControl.corePlugin.showGeoFence = false;
                        QGroundControl.corePlugin.showLoadPlan = false;
                    }
                }
            } 
        }
        // Row for trace and add waypoint buttons
        Row {
            Layout.topMargin: _margin - 2
            visible: bar.currentIndex == 0
            spacing: ScreenTools.defaultFontPixelWidth * 1.5
            //Layout.leftMargin: _margin + 12

            // Trace button
            QGCButton {

                width: _rightPanelWidth - (_margin + 3)
                height: ScreenTools.isMobile ? 28 : 28
                id: buttonDraw
                text: _editTracing ? "Finalizar" : "Novo polígono" 
                checked: _editTracing
                enabled: !_addWaypointOnClick
                    background: Rectangle {
                    color: _editTracing ? "#FF6666" : "#ffffff" // When clicked turns light grey
                    radius: 5  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                onClicked: {
                    // Toggle the _editTracing property
                    _editTracing = !_editTracing;
                    // Disable adding waypoints on click
                    _addWaypointOnClick = false;
                    //Show RoverVT button
                    // Emit signal to show or hide Rover VT button
                    if (_editTracing) {
                        GlobalSignals.showRoverVT();
                    } else {
                        GlobalSignals.hideRoverVT();
                    }

                    {
            
                        // Check if tracing has not been started yet
                        if (!isTraced) {
                            isTraced = true;

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
                                polygonItem.cameraCalc.adjustedFootprintSide.value = 6;

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
                            {
                                polygonItem.surveyAreaPolygon.traceMode = false;
                            }
                        isTraced=false;

                        }
                    }
                }
            }   
        }

        Row {
            Layout.topMargin: _margin - 2
            visible: bar.currentIndex == 0
            spacing: ScreenTools.defaultFontPixelWidth * 1.5
            //Layout.leftMargin: _margin + 12

            // Trace button
            QGCButton {

                width: _rightPanelWidth - (_margin + 3)
                height: ScreenTools.isMobile ? 28 : 28
                id: buttonCorridor
                text: _editCorridor ? "Finalizar" : "Corridor" 
                checked: _editCorridor
                enabled: !_addWaypointOnClick
                    background: Rectangle {
                    color: _editCorridor ? "#FF6666" : "#ffffff" // When clicked turns light grey
                    radius: 5  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                onClicked: {
                    // Toggle the _editTracing property
                    _editCorridor = !_editCorridor;
                    // Disable adding waypoints on click
                    _addWaypointOnClick = false;

                    {

                        // Check if tracing has not been started yet
                        if (!isTracedCorridor) {
                            isTracedCorridor = true;

                            // Get the index of the last visual item
                            var currentIndex = _missionController.visualItems.count;
                            // Retrieve the last visual item as polygonItem
                            polygonItem = _missionController.visualItems.get(currentIndex - 1);

                            // Insert a complex mission item if it hasn't been traced yet
                            insertComplexItemAfterCurrent(_missionController.corridorScanComplexItemName);

                            // Get the current visual item as polygonItem
                            polygonItem = _missionController.visualItems.get(currentIndex);

                            // If the polygonItem exists, set its camera footprint side value
                            if (polygonItem) 
                                polygonItem.cameraCalc.adjustedFootprintSide.value = 6;

                            // Check if the polygon's traceMode is enabled
                            if (polygonItem.corridorPolyline.traceMode) {
                                // If the polygon has fewer than 3 vertices, restore previous vertices
                                if (polygonItem.corridorPolyline.count < 3) {
                                    _restorePreviousVertices(polygonItem);
                                }
                                // Mark tracing as started
                                isTracedCorridor = true;
                                // Disable traceMode
                                polygonItem.corridorPolyline.traceMode = false;
                            }

                            // Enable traceMode if tracing is being edited
                            if (!polygonItem.corridorPolyline.traceMode && _editTracing) {
                                polygonItem.corridorPolyline.traceMode = true;
                                // Save the current vertices
                                _saveCurrentVertices(polygonItem);
                                // Clear the current polygon vertices
                                polygonItem.corridorPolyline.clear();
                                // Mark tracing as started
                                isTracedCorridor = true;
                            }
                        } else {
                            // If tracing was already started, disable traceMode
                            if (polygonItem && polygonItem.corridorPolyline && polygonItem.corridorPolyline.traceMode)
                            {
                                polygonItem.corridorPolyline.traceMode = false;
                            }
                        isTracedCorridor=false;

                        }
                    }
                }
            }   
        }

        // Add waypoint button
        Row {
            visible: bar.currentIndex == 0
            width: parent.width

            QGCButton {
                background: Rectangle {
                    color: _addWaypointOnClick ? "#FF6666" : "#ffffff" // When clicked turns light grey
                    radius: 5
                    border.color: "white"
                    anchors.fill: parent
                }
                text: _addWaypointOnClick ? "Finalizar" : "Novo ponto de rota"
                id: buttonTravel
                width: _rightPanelWidth - (_margin + 3)
                height: ScreenTools.isMobile ? 28 : 28
                enabled: !_editTracing
                checked: _addWaypointOnClick
                onClicked: {
                    // Emit signal to show or hide Rover WP button
                    if (!_addWaypointOnClick) {
                        GlobalSignals.showRoverWP();
                    } else {
                        GlobalSignals.hideRoverWP();
                    }
                    if (polygonItem) {
                        polygonItem.surveyAreaPolygon.traceMode = false;
                        _editTracing = false;
                    }
                    _addWaypointOnClick = !_addWaypointOnClick;
                    buttonTravel.color = _addWaypointOnClick ? "#d3d3d3" : "#ffffff"; // Change background color
                }
            }
        }

        // Row for mission buttons
        //Botões Set Vertex e Set Waypoint
        /*Row {
            visible: bar.currentIndex == 0
            width: parent.width
            //Layout.leftMargin: _margin + 12
            spacing: ScreenTools.defaultFontPixelWidth * 1
            QGCButton {
                background: Rectangle {
                    color: "#ffffff"  
                    radius: 14  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                id: buttonsetvtx
                width: (_rightPanelWidth / 2) - ScreenTools.defaultFontPixelWidth * 1
                height: ScreenTools.isMobile ? 28 : 28
                text: "Rover VT"
                onClicked: {
                var currentIndex = _missionController.visualItems.count;
                // Retrieve the last visual item as vertexItem
                var  vertexItem= _missionController.visualItems.get(currentIndex - 1);

                vertexItem.coordinate = _activeVehicle.coordinate
                }
            }

            QGCButton {
                background: Rectangle {
                    color: "#ffffff"  
                    radius: 14  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                id: buttonsetwp
                width: (_rightPanelWidth / 2) - ScreenTools.defaultFontPixelWidth * 1
                height: ScreenTools.isMobile ? 28 : 28
                text: "Rover WP"
                onClicked: {
                var currentIndex = _missionController.visualItems.count;
                // Retrieve the last visual item as waypointItem
                var  waypointItem= _missionController.visualItems.get(currentIndex - 1);
                waypointItem.coordinate = _activeVehicle.coordinate
                }
            }
        }*/

        Row {
            visible: bar.currentIndex == 0
            width: parent.width
            //Layout.leftMargin: _margin + 12
            spacing: ScreenTools.defaultFontPixelWidth * 1

            // Undo button
            /*QGCButton {
                background: Rectangle {
                    color: "#ffffff"  
                    radius: 14  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                width: (_rightPanelWidth / 2) - ScreenTools.defaultFontPixelWidth * 1
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
            }*/
            
            QGCButton {
                background: Rectangle {
                    color: "#ffffff"  
                    radius: 5 
                    border.color: "white"  
                    anchors.fill: parent  
                }
                text: qsTr("Salvar")
                width: (_rightPanelWidth / 2) - ScreenTools.defaultFontPixelWidth * 1
                height: ScreenTools.isMobile ? 28 : 28
                Layout.fillWidth: true
                enabled: !_planMasterController.syncInProgress && !_addWaypointOnClick && !_editTracing
                onClicked: {
                    if (polygonItem) {
                        polygonItem.surveyAreaPolygon.traceMode = false;
                        _editTracing = false;
                    }
                    _planMasterController.saveToSelectedFile();
                }
            }

            // Clear button
            QGCButton {
                background: Rectangle {
                    color: "#ffffff"  
                    radius: 5 
                    border.color: "white"  
                    anchors.fill: parent  
                }
                width: (_rightPanelWidth / 2) - ScreenTools.defaultFontPixelWidth * 1
                height: ScreenTools.isMobile ? 28 : 28
                text: "Limpar"
                Layout.fillWidth: true
                onClicked: {
                    
                    mainWindow.showMessageDialog(qsTr("Limpar"), qsTr("Tem certeza que deseja remover todos os itens e limpar a missão do veículo?"), Dialog.Yes | Dialog.Cancel, function () {
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

        }

        // Row for additional mission buttons
        /*Row {
            visible: bar.currentIndex == 0
            width: parent.width
            //Layout.topMargin: _margin * 1
            //spacing: ScreenTools.defaultFontPixelWidth * 1
            //Layout.leftMargin: _margin + 12

            // File dialog for loading KML or SHP files
            

            

            // Load button
            /*QGCButton {
                background: Rectangle {
                    color: "#ffffff"  
                    radius: 14  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                width: (_rightPanelWidth / 2) - ScreenTools.defaultFontPixelWidth * 1
                height: ScreenTools.isMobile ? 28 : 28
                id: loadButton
                text: "Load"
                Layout.fillWidth: true
                onClicked: {
                    loadChoice = true;
                }
            }

            // Save button
            
        }*/
        //Row for start button
        Row {
            visible: bar.currentIndex == 0
            width: parent.width
            //Layout.topMargin: _margin * 1
            spacing: ScreenTools.defaultFontPixelWidth * 1
            //Layout.leftMargin: _margin + 12

            // Start button
            QGCButton {
                background: Rectangle {
                    color: "#99ff8a"  
                    radius: 14  
                    border.color: "white"  
                    anchors.fill: parent  
                }
                width: _rightPanelWidth - (_margin + 3)
                height: ScreenTools.isMobile ? 28 : 28
                text: "Iniciar"
                //primary: true
                onClicked: {
                    QGroundControl.corePlugin.showGeoFence=true
                    if (polygonItem) {
                        polygonItem.surveyAreaPolygon.traceMode = false;
                        _editTracing = false;
                    }
                    //_planMasterController.saveToSelectedFile();
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

    Timer {
        interval: 100 // We update the polygonItem every 100ms based on the currentPlanViewVIIndex
        repeat: true
        running: true
        onTriggered: {
            if ( _missionController.visualItems.get(_missionController.currentPlanViewVIIndex ).surveyAreaPolygon)
            
            polygonItem =_missionController.visualItems.get(_missionController.currentPlanViewVIIndex ) 
        }
    }

    // Column for mission start confirmation
    Rectangle{
        radius: _radius
        visible: _confirmationStart && bar.currentIndex == 0
        anchors.topMargin: 5
        //anchors.top: sep.bottom
        height: 85
        width: _rightPanelWidth
        color: qgcPal.windowShadeDark
        
        Column {
            anchors.fill: parent
            anchors.margins: _margin
            spacing: _margin + 5
            //id: confirmationColumn
            
            /*SectionHeader {
                id: sepConfirmation
                anchors.left: parent.left
                anchors.right: parent.right
                text: "Recap Header"
            }*/
            QGCLabel {
                text: qsTr("Você tem certeza que deseja inicar a missão?")
                font.family: ScreenTools.demiboldFontFamily
                anchors.left:       parent.left
                anchors.right:      parent.right
                wrapMode:           Text.WordWrap
                anchors.leftMargin: _margin + 6
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20
                QGCButton {
                    text: "Não"
                    width: 70
                    onClicked: {
                                                                QGroundControl.corePlugin.showGeoFence=false
                        _confirmationStart = false;
                        QGroundControl.corePlugin.showGeoFence=false
                    }
                }
                QGCButton {
                    text: "Sim"
                    width: 70
                    onClicked: {
                                        QGroundControl.corePlugin.showGeoFence=false
                                            if (polygonItem) {
                            polygonItem.surveyAreaPolygon.traceMode = false;
                            _editTracing = false;
                        }
                        QGroundControl.corePlugin.showGeoFence=false
                        _confirmationStart = false;
                        _planMasterController.upload();
                        mainWindow.showFlyView()
                    }
                }
            }
            /*SectionHeader {
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
                }       
            }*/
        }
    }
    // Column for file load choice
    Rectangle {
        radius: _radius
        visible: bar.currentIndex == 2
        id: loadChoiceRect
        anchors.topMargin: 5
        anchors.top: sep.bottom
        height: 85
        width: _rightPanelWidth
        color: qgcPal.windowShadeDark
    
        Column {
            anchors.fill: parent
            anchors.margins: _margin
            spacing: _margin + 5
    
            QGCLabel {
                text: qsTr("Selecione o tipo de arquivo que deseja carregar")
                font.family: ScreenTools.demiboldFontFamily
                anchors.left:       parent.left
                anchors.right:      parent.right
                wrapMode:           Text.WordWrap
                anchors.leftMargin: _margin + 6
            }
    
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20 // Ajuste o espaçamento conforme necessário
    
                QGCButton {
                    text: "KML/SHP"
                    width: 80 // Ajuste conforme necessário
                    onClicked: {
                        loadChoice = false;
                        kmlOrSHPLoadDialog.openForLoad();
                        bar.currentIndex = 0
                    }
                }
    
                QGCButton {
                    text: "Missões"
                    width: 80 // Ajuste conforme necessário
                    onClicked: {
                        loadChoice = false;
                        _planMasterController.loadFromSelectedFile();
                        bar.currentIndex = 0
                    }
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
        width: _rightPanelWidth
        color: "transparent"//qgcPal.windowShadeDark
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