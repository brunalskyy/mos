import QtQuick
import org.kde.notificationmanager as NotificationManager

// Notification history (the same list the Plasma bell uses)
NotificationManager.Notifications {
    id: m
    showExpired: true
    showDismissed: true
    showJobs: false
    groupMode: NotificationManager.Notifications.GroupDisabled
    sortMode: NotificationManager.Notifications.SortByDate

    function closeAt(row) { m.close(m.index(row, 0)) }
    function open(row) { m.invokeDefaultAction(m.index(row, 0), NotificationManager.Notifications.Close) }
    function clearAll() {
        m.clear(NotificationManager.Notifications.ClearExpired)
        for (var i = m.count - 1; i >= 0; i--) m.close(m.index(i, 0))
    }
}
