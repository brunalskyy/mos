import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    readonly property var f: backend.fonts
    Hint { text: "The font apps and menus use. Inter is the mOS font." }
    Card {
        Label { text: "Aa Bb Cc 123"; color: Theme.textColour; font.family: page.f.family; font.pointSize: page.f.size * 2.2
                Layout.fillWidth: true; elide: Text.ElideRight }
        Label { text: "The quick brown fox jumps over the lazy dog"; color: Theme.textVariant; font.family: page.f.family
                font.pointSize: page.f.size; Layout.fillWidth: true; wrapMode: Text.WordWrap }
    }
    Card {
        SettingRow {
            title: "Font"
            MCombo {
                id: fam
                width: 240
                model: backend.fontFamilies
                currentIndex: Math.max(0, backend.fontFamilies.indexOf(page.f.family))
                onActivated: backend.setFont(currentText, page.f.size)
            }
        }
        Divider {}
        SettingRow { title: "Size"; sub: Math.round(page.f.size) + " pt" }
        MSlider {
            Layout.fillWidth: true
            from: 8; to: 16; step: 1
            value: page.f.size
            onReleased: function (v) { backend.setFont(page.f.family, Math.round(v)) }
        }
        Divider {}
        SettingRow {
            title: "Typing font"; sub: "For Terminal and code"
            MCombo {
                width: 240
                model: backend.fontFamilies.filter(function (n) { return /mono|code|hack|courier|consol/i.test(n) })
                currentIndex: Math.max(0, model.indexOf(page.f.mono))
                onActivated: backend.setMonoFont(currentText, page.f.monoSize)
            }
        }
    }
    RowLayout { PillButton { tonal: true; text: "Back to Inter"; onClicked: { backend.setFont("Inter", 10); backend.setMonoFont("Hack", 10) } } }
}
