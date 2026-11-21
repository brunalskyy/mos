import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var devices: backend.pointers()
    Card { visible: page.devices.length === 0; Hint { text: "No mouse or trackpad found." } }
    Repeater {
        model: page.devices
        delegate: Card {
            required property var modelData
            RowLayout {
                spacing: 14
                ToneIcon { name: "mouse"; tone: modelData.touchpad ? "#546E7A" : "#455A64"; size: 40 }
                ColumnLayout {
                    spacing: 0
                    Label { text: modelData.touchpad ? "Trackpad" : "Mouse"; color: Theme.textColour; font.pixelSize: 17; font.weight: Font.DemiBold }
                    Label { text: modelData.name; color: Theme.textVariant; font.pixelSize: 13 }
                }
            }
            Hint { text: "Pointer speed" }
            MSlider { Layout.fillWidth: true; from: -1; to: 1; step: 0.05; value: modelData.speed
                      onReleased: function (v) { backend.setPointer(modelData.dev, "pointerAcceleration", v) } }
            SettingRow {
                title: "Natural scrolling"
                sub: "Content moves the way your fingers move, like a phone"
                MSwitch { checked: modelData.natural; onToggled: function (v) { backend.setPointer(modelData.dev, "naturalScroll", v) } }
            }
            SettingRow {
                visible: modelData.touchpad
                title: "Tap to click"
                MSwitch { checked: modelData.tap; onToggled: function (v) { backend.setPointer(modelData.dev, "tapToClick", v) } }
            }
        }
    }
}
