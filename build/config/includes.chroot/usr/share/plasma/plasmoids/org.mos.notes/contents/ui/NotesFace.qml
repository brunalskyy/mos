import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// NotesFace: the look of the widget (also used for the previews in Add widgets)
Card {
    id: card
    property string text: ""
    signal edited(string text)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(Kirigami.Units.largeSpacing, card.unit * 0.1)
        spacing: Kirigami.Units.smallSpacing
        Text { text: "Notes"; color: card.strong; font.family: "Inter"; font.weight: Font.Bold
               font.pixelSize: Math.max(11, Math.min(18, card.unit * 0.1)) }
        QQC2.ScrollView {
            Layout.fillWidth: true; Layout.fillHeight: true
            QQC2.TextArea {
                id: area
                text: card.text
                placeholderText: "Write something…"
                placeholderTextColor: card.soft
                color: card.ink
                wrapMode: TextEdit.Wrap
                font.family: "Inter"
                font.pixelSize: Math.max(12, Math.min(18, card.unit * 0.085))
                background: null
                leftPadding: 0; rightPadding: 0; topPadding: 0
                onTextChanged: save.restart()
                Timer { id: save; interval: 600; onTriggered: card.edited(area.text) }
            }
        }
    }
}
