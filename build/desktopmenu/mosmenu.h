/*
    mOS desktop menu: what you get when you right-click the desktop.
    SPDX-FileCopyrightText: 2026 Bruno Woznicki
    SPDX-License-Identifier: GPL-2.0-or-later
*/
#pragma once

#include <plasma/containmentactions.h>

class QAction;

class MosMenu : public Plasma::ContainmentActions
{
    Q_OBJECT
public:
    MosMenu(QObject *parent, const QVariantList &args);
    QList<QAction *> contextualActions() override;

private:
    QAction *makeAction(const QString &icon, const QString &text);
    QList<QAction *> m_actions;
    QAction *m_paste = nullptr;
};
