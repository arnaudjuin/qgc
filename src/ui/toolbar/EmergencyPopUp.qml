import QtQuick 2.12
import QtQuick.Controls 2.12

Popup {
    id: emergencyPopup
    width: 200
    height: 100
    visible: false
    modal: true
    focus: true

    Column {
        Text {
            text: "Emergency: Actuator OK"
            font.pixelSize: 20
            color: "red"
        }
        Button {
            text: "Close"
            onClicked: emergencyPopup.close()
        }
    }
}