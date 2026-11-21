import QtQuick
import QtQuick.Controls.Basic
import components

// Get / Open / Update, turning into a progress pill while it downloads (like the App Store)
Item {
    id: b
    property string appId
    property bool big: false
    readonly property var job: store.jobs[appId] || null
    readonly property string st: { store.jobs; store.updateCount; store.appCount; return store.stateOf(appId) }
    readonly property bool busy: job !== null && job.state !== "error" && job.state !== "done"
    implicitWidth: busy ? (big ? 200 : 96) : Math.max(big ? 120 : 76, lbl.implicitWidth + (big ? 44 : 32))
    implicitHeight: big ? 44 : 34
    Behavior on implicitWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: b.busy ? Theme.secondaryContainer : b.st === "installed" ? Theme.secondaryContainer : Theme.primary
        scale: ma.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Behavior on color { ColorAnimation { duration: 160 } }
        clip: true
        // download progress fills the pill
        Rectangle {
            visible: b.busy
            height: parent.height
            width: parent.width * (b.job ? b.job.percent : 0) / 100
            radius: parent.radius
            color: Theme.primary
            opacity: 0.35
            Behavior on width { NumberAnimation { duration: 240 } }
        }
        Label {
            id: lbl
            anchors.centerIn: parent
            text: b.busy ? (b.job.state === "queued" ? "Waiting" : b.job.state === "preparing" ? "Starting…"
                                                                    : b.job.percent + "%")
                 : b.st === "installed" ? "Open" : b.st === "update" ? "Update" : "Get"
            color: b.busy || b.st === "installed" ? Theme.primaryContainerText : Theme.primaryText
            font.pixelSize: b.big ? 15 : 13
            font.weight: Font.Bold
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (b.busy) store.cancel(b.appId)
            else if (b.st === "installed") store.launch(b.appId)
            else if (b.st === "update") store.update(b.appId)
            else store.install(b.appId)
        }
    }
    ToolTip.visible: b.busy && ma.containsMouse
    ToolTip.text: "Click to cancel"
}
