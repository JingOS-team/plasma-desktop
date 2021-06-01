/*
   Copyright (c) 2014 Marco Martin <mart@kde.org>

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License version 2 as published by the Free Software Foundation.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public License
   along with this library; see the file COPYING.LIB.  If not, write to
   the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

import QtQuick 2.1
import QtQuick.Window 2.2
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.0 as QtControls
import org.kde.kirigami 2.4 as Kirigami
import org.kde.newstuff 1.62 as NewStuff
import org.kde.kcm 1.3 as KCM

KCM.GridViewKCM {
    id: root
    KCM.ConfigModule.quickHelp: i18n("This module lets you choose the splash screen theme.")

    KCM.SettingStateBinding {
        configObject: kcm.splashScreenSettings
        settingName: "theme"
        extraEnabledConditions: !kcm.testing
    }

    view.model: kcm.splashModel
    //NOTE: pay attention to never break this binding
    view.currentIndex: kcm.pluginIndex(kcm.splashScreenSettings.theme)

    // putting the InlineMessage as header item causes it to show up initially despite visible false
    header: ColumnLayout {
        Kirigami.InlineMessage {
            id: testingFailedLabel
            Layout.fillWidth: true
            showCloseButton: true
            type: Kirigami.MessageType.Error
            text: i18n("Failed to test the splash screen.")

            Connections {
                target: kcm
                onTestingFailed: testingFailedLabel.visible = true
            }
        }
    }

    view.delegate: KCM.GridDelegate {
        id: delegate

        text: model.display
        toolTip: model.description

        thumbnailAvailable: !!model.screenshot
        thumbnail: Image {
            anchors.fill: parent
            source: model.screenshot || ""
            sourceSize: Qt.size(delegate.GridView.view.cellWidth * Screen.devicePixelRatio,
                                delegate.GridView.view.cellHeight * Screen.devicePixelRatio)
        }
        actions: [
            Kirigami.Action {
                visible: model.pluginName !== "None"
                iconName: "media-playback-start"
                tooltip: i18n("Preview Splash Screen")
                onTriggered: kcm.test(model.pluginName)
            }
        ]
        onClicked: {
            kcm.splashScreenSettings.theme = model.pluginName;
            view.forceActiveFocus();
        }
    }

    footer: RowLayout {
        Item {
            Layout.fillWidth: true
        }
        NewStuff.Button {
            id: newStuffButton
            text: i18n("&Get New Splash Screens...")
            configFile: "ksplash.knsrc"
            viewMode: NewStuff.Page.ViewMode.Preview
            onChangedEntriesChanged: kcm.ghnsEntriesChanged(newStuffButton.changedEntries);
        }
    }
}
