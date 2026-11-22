/*
    mOS desktop menu: what you get when you right-click the desktop.
    Add widgets (mOS gallery), Edit widgets, New folder, Paste, Open in Terminal,
    Change wallpaper, Display settings and Settings. Right-clicking files still
    gives the full file menu.
    SPDX-FileCopyrightText: 2026 Bruno Woznicki
    SPDX-License-Identifier: GPL-2.0-or-later
*/
#include "mosmenu.h"

#include <QAction>
#include <QDir>
#include <QIcon>
#include <QProcess>
#include <QStandardPaths>

#include <KPluginFactory>

#include <plasma/containment.h>
#include <plasma/corona.h>

using namespace Qt::StringLiterals;

static QString desktopFolder()
{
    const QString d = QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);
    return d.isEmpty() ? QDir::homePath() + u"/Desktop"_s : d;
}

static void run(const QString &program, const QStringList &args = {})
{
    QProcess::startDetached(program, args, desktopFolder());
}

MosMenu::MosMenu(QObject *parent, const QVariantList &args)
    : Plasma::ContainmentActions(parent, args)
{
    connect(makeAction(u"list-add"_s, u"Add widgets…"_s), &QAction::triggered, this, [] {
        run(u"mos-widgets"_s);
    });
    connect(makeAction(u"transform-move"_s, u"Edit widgets"_s), &QAction::triggered, this, [this] {
        if (auto *c = containment(); c && c->corona()) {
            c->corona()->setEditMode(true);
        }
    });
    m_actions << makeAction({}, {}); // separator
    m_actions.last()->setSeparator(true);
    connect(makeAction(u"folder-new"_s, u"New folder"_s), &QAction::triggered, this, [] {
        QDir desk(desktopFolder());
        desk.mkpath(u"."_s);
        QString name = u"New folder"_s;
        for (int i = 2; desk.exists(name); ++i) {
            name = u"New folder (%1)"_s.arg(i);
        }
        desk.mkdir(name);
    });
    m_paste = makeAction(u"edit-paste"_s, u"Paste"_s);
    connect(makeAction(u"utilities-terminal"_s, u"Open in Terminal"_s), &QAction::triggered, this, [] {
        run(u"konsole"_s, {u"--workdir"_s, desktopFolder()});
    });
    m_actions << makeAction({}, {});
    m_actions.last()->setSeparator(true);
    connect(makeAction(u"preferences-desktop-wallpaper"_s, u"Change wallpaper…"_s), &QAction::triggered, this, [] {
        run(u"mos-settings"_s, {u"style"_s});
    });
    connect(makeAction(u"preferences-desktop-display"_s, u"Display settings"_s), &QAction::triggered, this, [] {
        run(u"mos-settings"_s, {u"display"_s});
    });
    connect(makeAction(u"preferences-system"_s, u"Settings"_s), &QAction::triggered, this, [] {
        run(u"mos-settings"_s);
    });
}

QAction *MosMenu::makeAction(const QString &icon, const QString &text)
{
    auto *a = new QAction(QIcon::fromTheme(icon), text, this);
    if (!text.isEmpty()) {
        m_actions << a;
    }
    return a;
}

QList<QAction *> MosMenu::contextualActions()
{
    // Paste: use the desktop's own paste (it knows what's on the clipboard), if it has one
    QAction *folderPaste = nullptr;
    if (auto *c = containment()) {
        const auto own = c->contextualActions();
        for (QAction *a : own) {
            if (a && a->objectName() == u"paste"_s) {
                folderPaste = a;
            }
        }
    }
    QList<QAction *> out;
    for (QAction *a : std::as_const(m_actions)) {
        if (a == m_paste) {
            if (folderPaste) {
                out << folderPaste;
            }
            continue;
        }
        out << a;
    }
    return out;
}

K_PLUGIN_CLASS_WITH_JSON(MosMenu, "mosmenu.json")

#include "mosmenu.moc"
