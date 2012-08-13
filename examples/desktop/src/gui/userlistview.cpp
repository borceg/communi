/*
* Copyright (C) 2008-2012 J-P Nurmi <jpnurmi@gmail.com>
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*/

#include "userlistview.h"
#include "sortedusermodel.h"
#include "usermodel.h"
#include "session.h"
#include <QItemSelectionModel>
#include <QContextMenuEvent>
#include <QAction>
#include <QMenu>

UserListView::UserListView(QWidget* parent) : QListView(parent)
{
    d.userModel = new UserModel(this);
    connect(this, SIGNAL(doubleClicked(QModelIndex)), SLOT(onDoubleClicked(QModelIndex)));
}

UserListView::~UserListView()
{
}

Session* UserListView::session() const
{
    return d.userModel->session();
}

void UserListView::setSession(Session* session)
{
    delete model();
    if (session)
        setModel(new SortedUserModel(session->prefixModes(), d.userModel));

    d.userModel->setSession(session);
}

QString UserListView::channel() const
{
    return d.userModel->channel();
}

void UserListView::setChannel(const QString &channel)
{
    d.userModel->setChannel(channel);
}

UserModel* UserListView::userModel() const
{
    return d.userModel;
}

bool UserListView::hasUser(const QString &user) const
{
    return d.userModel->hasUser(user);
}

void UserListView::processMessage(IrcMessage* message)
{
    d.userModel->processMessage(message);
}

void UserListView::contextMenuEvent(QContextMenuEvent* event)
{
    QModelIndex index = indexAt(event->pos());
    if (index.isValid())
    {
        QMenu menu;
        QAction* action = menu.addAction(tr("Whois"), this, SLOT(onWhoisTriggered()));
        action->setData(index.data(Qt::EditRole));
        menu.exec(event->globalPos());
    }
}

void UserListView::mousePressEvent(QMouseEvent* event)
{
    QListView::mousePressEvent(event);
    if (!indexAt(event->pos()).isValid())
        selectionModel()->clear();
}

void UserListView::onDoubleClicked(const QModelIndex& index)
{
    if (index.isValid())
        emit queried(index.data(Qt::EditRole).toString());
}

void UserListView::onWhoisTriggered()
{
    QAction* action = qobject_cast<QAction*>(sender());
    if (action)
        emit commanded("WHOIS", QStringList() << action->data().toString());
}
