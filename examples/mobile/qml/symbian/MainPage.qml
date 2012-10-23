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

import QtQuick 1.1
import Communi 1.0
import com.nokia.symbian 1.1
import com.nokia.extras 1.1
import "UIConstants.js" as UI

CommonPage {
    id: root

    property alias bouncer: bouncer

    function showAbout() {
        var dialog = about.createObject(root, {showPolicy: !Settings.policyAgreed});
        dialog.open();
    }

    function applySettings() {
        for (var i = 0; i < SessionModel.length; ++i) {
            SessionModel[i].timeStamp = Settings.timeStamp;
            SessionModel[i].stripNicks = Settings.stripNicks;
            for (var j = 0; j < SessionModel[i].childItems.length; ++j) {
                SessionModel[i].childItems[j].timeStamp = Settings.timeStamp;
                SessionModel[i].childItems[j].stripNicks = Settings.stripNicks;
            }
        }
    }

    header: Header {
        id: header
        title: qsTr("Communi")
        icon.visible: pressed
        icon.source: "../images/about.png"
        onClicked: root.showAbout()
    }

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: confirmexitDialog.open()
            platformInverted: true
        }
        ToolButton {
            iconSource: "toolbar-menu"
            onClicked: contextMenu.open()
            platformInverted: true
        }
        ToolButton {
            iconSource: "toolbar-add"
            onClicked: connectionDialog.open()
            platformInverted: true
        }
    }

    ListView {
        id: listView

        property QtObject currentSessionItem
        property QtObject currentSession
        property QtObject currentChildItem

        anchors.fill: parent
        model: SessionModel
        delegate: Column {
            width: parent.width
            ListDelegate {
                title: modelData.title
                subtitle: modelData.subtitle
                iconSource: modelData.session.currentLag > 10000 ? "../images/unknown.png" :
                            modelData.session.active && !modelData.session.connected ? "../images/server.png" :
                            modelData.session.connected ? "../images/connected.png" : "../images/disconnected.png"
                highlighted: modelData.highlighted
                active: modelData.session.active
                unreadCount: modelData.unreadCount
                busy: modelData.busy
                onClicked: chatPage.push(modelData)
                onPressAndHold: {
                    channelDialog.session = modelData.session;
                    listView.currentSessionItem = modelData;
                    listView.currentSession = modelData.session;
                    if (modelData.session.active)
                        activeSessionMenu.open();
                    else
                        inactiveSessionMenu.open();
                }
            }
            Repeater {
                id: repeater
                model: modelData.childItems
                ListDelegate {
                    title: modelData.title
                    subtitle: modelData.subtitle
                    iconSource: modelData.channel ? "../images/channel.png" : "../images/query.png"
                    highlighted: modelData.highlighted
                    active: modelData.session.active
                    unreadCount: modelData.unreadCount
                    busy: modelData.busy
                    onClicked: chatPage.push(modelData)
                    onPressAndHold: {
                        listView.currentChildItem = modelData;
                        listView.currentSession = modelData.session;
                        childMenu.open();
                    }
                }
            }
            ListHeading {
                height: 2
                visible: index < listView.count - 1
            }
        }
    }

    ScrollDecorator {
        flickableItem: listView
        platformInverted: true
    }

    Component {
        id: bannerComponent
        InfoBanner {
            id: banner
            timeout: 5000
            property QtObject item
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    bouncer.bounce(item, null);
                    banner.close();
                }
            }
            Connections {
                target: root.pageStack
                onCurrentPageChanged: banner.close()
            }
            onVisibleChanged: {
                if (!banner.visible)
                    banner.destroy();
            }
            platformInverted: true
        }
    }

    property variant effect: null
    Component.onCompleted: {
        var component = Qt.createComponent("Feedback.qml");
        if (component.status === Component.Ready)
            effect = component.createObject(root);
    }

    Connections {
        target: SessionManager
        onAlert: {
            var banner = bannerComponent.createObject(pageStack.currentPage);
            banner.text = text;
            banner.item = item;
            banner.open();
            if (root.effect)
                root.effect.play();
        }
    }

    ChatPage {
        id: chatPage
        function push(data) {
            modelData = data;
            root.pageStack.push(chatPage);
        }
        onStatusChanged: {
            if (modelData) {
                modelData.current = (chatPage.status === PageStatus.Active);
                if (status === PageStatus.Inactive) {
                    modelData.unseenIndex = chatPage.count - 1;
                    modelData = null;
                }
                else if (status === PageStatus.Active && bouncer.cmd) {
                    modelData.session.sendUiCommand(bouncer.cmd);
                    bouncer.cmd = null;
                }
            }
            if (status === PageStatus.Inactive && bouncer.item)
                bouncer.start();
        }
    }

    Timer {
        id: bouncer
        interval: 50
        property QtObject item
        property QtObject cmd
        function bounce(item, cmd) {
            bouncer.cmd = cmd;
            if (root.status === PageStatus.Active) {
                bouncer.item = null;
                chatPage.push(item);
            } else {
                bouncer.item = item;
                pageStack.pop();
            }
        }
        onTriggered: {
            chatPage.push(bouncer.item);
            bouncer.item = null;
        }
    }

    ContextMenu {
        id: activeSessionMenu

        MenuLayout {
            MenuItem {
                text: qsTr("Join channel")
                onClicked: channelDialog.open()
                platformInverted: true
            }
            MenuItem {
                text: qsTr("Open query")
                onClicked: queryDialog.open()
                platformInverted: true
            }
            MenuItem {
                text: qsTr("Set nick")
                onClicked: {
                    nickDialog.name = listView.currentSession.nickName;
                    nickDialog.open();
                }
                platformInverted: true
            }
            MenuItem {
                text: qsTr("Disconnect")
                onClicked: {
                    listView.currentSession.quit(ApplicationName);
                }
                platformInverted: true
            }
        }
        platformInverted: true
    }

    ContextMenu {
        id: inactiveSessionMenu

        MenuLayout {
            MenuItem {
                text: qsTr("Reconnect")
                onClicked: {
                    listView.currentSession.reconnect();
                }
                platformInverted: true
            }
            MenuItem {
                text: qsTr("Close")
                onClicked: {
                    SessionManager.removeSession(listView.currentSession);
                    listView.currentSession.destructLater();
                }
                platformInverted: true
            }
        }
        platformInverted: true
    }

    ConnectionDialog {
        id: connectionDialog

        Component.onCompleted: {
            connectionDialog.host = Settings.host;
            connectionDialog.port = Settings.port;
            connectionDialog.name = Settings.name;
            if (Settings.user !== "") connectionDialog.user = Settings.user
            if (Settings.real !== "") connectionDialog.real = Settings.real;
            connectionDialog.channel = Settings.channel;
            connectionDialog.secure = Settings.secure;
        }

        Component {
            id: sessionComponent
            Session { }
        }

        onAccepted: {
            var session = sessionComponent.createObject(root);
            session.nickName = connectionDialog.name;
            session.userName = connectionDialog.user.length ? connectionDialog.user : "communi";
            session.realName = connectionDialog.real.length ? connectionDialog.real : "Communi for Symbian user";
            session.host = connectionDialog.host;
            session.port = connectionDialog.port;
            session.password = connectionDialog.password;
            session.secure = connectionDialog.secure;
            if (connectionDialog.channel.length)
                session.addChannel(connectionDialog.channel);

            SessionManager.addSession(session);
            session.reconnect();

            connectionDialog.password = "";
            Settings.host = connectionDialog.host;
            Settings.port = connectionDialog.port;
            Settings.name = connectionDialog.name;
            Settings.user = connectionDialog.user;
            Settings.real = connectionDialog.real;
            Settings.channel = connectionDialog.channel;
            Settings.secure = connectionDialog.secure;
        }
    }

    QueryDialog {
        id: confirmexitDialog
        titleText: qsTr("Confirm exit")
        message: "Really exit Communi?"
        acceptButtonText: "Yes"
        rejectButtonText: "No"
        onAccepted: Qt.quit()
        platformInverted: true
        height: privateStyle.dialogMinSize
    }

    IrcCommand {
        id: ircCommand
    }

    ChannelDialog {
        id: channelDialog
        titleText: qsTr("Join channel")
        onAccepted: {
            var child = listView.currentSessionItem.addChild(channel);
            var cmd = ircCommand.createJoin(channel, password);
            listView.currentSession.sendUiCommand(cmd);
            bouncer.bounce(child, null);
        }
        Connections {
            target: SessionManager
            onChannelKeyRequired: {
                channelDialog.session = session;
                channelDialog.channel = channel;
                channelDialog.passwordRequired = true;
                channelDialog.open();
            }
        }
    }

    NameDialog {
        id: queryDialog
        titleText: qsTr("Open query")
        onAccepted: {
            var child = listView.currentSessionItem.addChild(name);
            bouncer.bounce(child, null);
        }
    }

    NameDialog {
        id: nickDialog
        titleText: qsTr("Set nick")
        onAccepted: {
            listView.currentSession.nickName = name;
        }
    }

    ContextMenu {
        id: childMenu

        MenuLayout {
            MenuItem {
                text: listView.currentChildItem && listView.currentChildItem.channel && listView.currentSession && listView.currentSession.connected ? qsTr("Part") : qsTr("Close")
                onClicked: {
                    var item = listView.currentChildItem;
                    if (item.channel) {
                        var cmd = ircCommand.createPart(item.title, ApplicationName);
                        item.session.sendUiCommand(cmd);
                    }
                    item.sessionItem.removeChild(item.title);
                }
                platformInverted: true
            }
        }
        platformInverted: true
    }

    Component {
        id: about
        AboutDialog {
            id: dialog

            property bool showPolicy: false
            property string policy: qsTr("<p>PLEASE REVIEW THE <a href='http://github.com/communi/communi/wiki/Privacy-Policy'>PRIVACY POLICY</a>.</p>")
            property string license: qsTr("<p><small>This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.</small></p>" +
                                          "<p><small>This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.</small></p>")

            titleText: ApplicationName
            message: qsTr("<p>Communi is an IRC (Internet Relay Chat) client used to communicate with others on IRC networks around the world.</p>" +
                          "%1" +
                          "<p>Copyright (C) 2012 J-P Nurmi <a href=\"mailto:jpnurmi@gmail.com\">jpnurmi@gmail.com</a><br/></p>").arg(showPolicy ? policy : license)
            onLinkActivated: Qt.openUrlExternally(link)

            acceptButtonText: showPolicy ? qsTr("I AGREE") : qsTr("OK")
            onAccepted: { Settings.policyAgreed = true; dialog.destroy(1000) }

            rejectButtonText: showPolicy ? qsTr("I DISAGREE") : ""
            onRejected: { showPolicy ? Qt.quit() : dialog.destroy(1000) }
            platformInverted: true
        }
    }

    SettingsDialog {
        id: settingsDialog
        onAccepted: {
            Settings.timeStamp = settingsDialog.timeStamp;
            Settings.stripNicks = settingsDialog.stripNicks;
            applySettings();
        }
        Component.onCompleted: {
            timeStamp = Settings.timeStamp;
            stripNicks = Settings.stripNicks;
        }
    }

    ContextMenu {
        id: contextMenu
        MenuLayout {
            MenuItem {
                id: settingsItem
                text: qsTr("Settings")
                onClicked: settingsDialog.open()
                platformInverted: true
            }
        }
        platformInverted: true
    }
}
