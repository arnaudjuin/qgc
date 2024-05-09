import QtQuick 2.15
import QtQuick.Controls 2.15
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools

Switch {
    id: control

    readonly property int _radius: 3

    QGCPalette {
        id: qgcPal
        colorGroupEnabled: true
    }

    contentItem: QGCLabel {
        text: control.text
        verticalAlignment: Text.AlignVCenter
        rightPadding: control.indicator.width + control.spacing
    }

    indicator: Rectangle {
        implicitWidth: knob.width * 2
        implicitHeight: knob.height
        x: control.width - width - control.rightPadding
        y: parent.height / 2 - height / 2
        radius: knob.radius
        color: control.checked ? "green" : qgcPal.button

        Behavior on color {
            ColorAnimation {
                duration: 200 // Duração da animação em milissegundos
                easing.type: Easing.InOutQuad
            }
        }

        Rectangle {
            id: knob
            x: control.checked ? parent.width - width : 0
            width: ScreenTools.defaultFontPixelHeight
            height: ScreenTools.defaultFontPixelHeight
            radius: height / 2
            color: "white"

            Behavior on x {
                NumberAnimation {
                    duration: 200 // Duração da animação em milissegundos
                    easing.type: Easing.InOutQuad // Tipo de efeito de easing
                }
            }
        }
    }
}
