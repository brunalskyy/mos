pragma Singleton
import QtQuick

// Which page is showing, with a back button for pages inside General
QtObject {
    property string page: typeof startPage !== "undefined" ? startPage : "style"
    property var trail: []
    function go(p) { if (p !== page) { var t = trail.slice(); t.push(page); trail = t; page = p } }
    function top(p) { trail = []; page = p }
    function back() { if (trail.length) { var t = trail.slice(); page = t.pop(); trail = t } }
    readonly property bool canGoBack: trail.length > 0
}
