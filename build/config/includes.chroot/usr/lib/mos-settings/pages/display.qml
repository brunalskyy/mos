import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var d: backend.display()
    Connections { target: backend; function onJobDone(key) { if (key === "display") page.d = backend.display() } }

    Card {
        visible: page.d.brightness >= 0
        SectionTitle { text: "Brightness"; Layout.topMargin: 0 }
        RowLayout {
            Image { source: Theme.ink("sun"); Layout.preferredWidth: 20; Layout.preferredHeight: 20; sourceSize: Qt.size(40, 40); opacity: 0.6 }
            MSlider { Layout.fillWidth: true; from: 1; to: 100; value: page.d.brightness; onMoved: function (v) { backend.setBrightness(v) } }
            Image { source: Theme.ink("sun"); Layout.preferredWidth: 26; Layout.preferredHeight: 26; sourceSize: Qt.size(52, 52) }
        }
    }

    Repeater {
        model: page.d.outputs || []
        delegate: Card {
            required property var modelData
            SectionTitle { text: (page.d.outputs.length > 1 ? modelData.name + " — " : "") + "Screen"; Layout.topMargin: 0 }
            SettingRow {
                title: "Resolution"
                sub: modelData.current
                ComboBox {
                    id: res
                    implicitWidth: 200
                    model: modelData.modes
                    textRole: "label"
                    currentIndex: { for (var i = 0; i < modelData.modes.length; i++) if (modelData.modes[i].label === modelData.current) return i; return 0 }
                    onActivated: function (i) { backend.setResolution(modelData.name, modelData.modes[i].id) }
                    background: Rectangle { radius: 22; color: Theme.surfaceContainer; border.width: 1; border.color: Theme.outline }
                    contentItem: Label { leftPadding: 16; text: res.displayText; color: Theme.textColour; verticalAlignment: Text.AlignVCenter }
                }
            }
            Divider {}
            Hint { text: "Scale (makes everything bigger)" }
            Segmented {
                Layout.fillWidth: true
                options: [{ value: 1, label: "100%" }, { value: 1.25, label: "125%" }, { value: 1.5, label: "150%" }, { value: 1.75, label: "175%" }, { value: 2, label: "200%" }]
                current: Math.round(modelData.scale * 100) / 100
                onSelected: function (v) { backend.setScale(modelData.name, v) }
            }
        }
    }
    Card {
        visible: (page.d.outputs || []).length === 0
        Hint { text: "Couldn't read your screen settings." }
    }

    Card {
        SettingRow {
            title: "Night Shift"
            sub: "Warmer colours in the evening, easier on your eyes"
            MSwitch { checked: page.d.nightLight; onToggled: function (v) { backend.setNightLight(v) } }
        }
        ColumnLayout {
            visible: page.d.nightLight
            Layout.fillWidth: true
            spacing: 12
            Hint { text: "When" }
            Segmented {
                Layout.fillWidth: true
                options: [{ value: "sun", label: "Sunset to sunrise" }, { value: "times", label: "Set times" }]
                current: page.d.nightMode
                onSelected: function (v) { backend.setNightSchedule(v, page.d.nightEvening, page.d.nightMorning) }
            }
            RowLayout {
                visible: page.d.nightMode === "times"
                spacing: 10
                Label { text: "From"; color: Theme.textColour }
                MField { implicitWidth: 100; text: page.d.nightEvening; inputMask: "99:99"
                         onEditingFinished: backend.setNightSchedule("times", text, page.d.nightMorning) }
                Label { text: "to"; color: Theme.textColour }
                MField { implicitWidth: 100; text: page.d.nightMorning; inputMask: "99:99"
                         onEditingFinished: backend.setNightSchedule("times", page.d.nightEvening, text) }
            }
            Hint { text: "Warmth" }
            MSlider { Layout.fillWidth: true; from: 6500; to: 2500; step: 100; value: page.d.nightLightTemp
                      onReleased: function (v) { backend.setNightLightTemp(v) } }
        }
    }
    Connections { target: backend; function onChanged() { page.d = backend.display() } }
}
