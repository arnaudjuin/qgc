import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Dialogs          1.2

import QGroundControl.FactSystem    1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

QGCTextField {
    id: _textField

    text:       fact ? fact.valueString : ""
    unitsLabel: fact ? fact.units : ""
    showUnits:  true
    showHelp:   true

    signal updated()

    property Fact   fact: null

    property string _validateString

    inputMethodHints: ((fact && fact.typeIsString) || ScreenTools.isiOS) ?
                          Qt.ImhNone :                // iOS numeric keyboard has no done button, we can't use it
                          Qt.ImhFormattedNumbersOnly  // Forces use of virtual numeric keyboard

    onEditingFinished: {
        var errorString = fact.validate(text, false /* convertOnly */)
        if (errorString === "") {
            fact.value = text
            _textField.updated()
        } else {
            _validateString = text
            validationErrorDialogComponent.createObject(mainWindow).open()
        }
    }

    onHelpClicked: helpDialogComponent.createObject(mainWindow).open()

    Component {
        id: validationErrorDialogComponent

        ParameterEditorDialog {
            title:          qsTr("Invalid Value")
            validate:       true
            validateValue:  _validateString
            fact:           _textField.fact
            destroyOnClose: true
        }
    }

    Component {
        id: helpDialogComponent

        ParameterEditorDialog {
            title:          qsTr("Value Details")
            fact:           _textField.fact
            destroyOnClose: true
        }
    }
}
