/*
 * Copyright 2021 Wang Rui <wangrui@jingos.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License or (at your option) version 3 or any later version
 * accepted by the membership of KDE e.V. (or its successor approved
 * by the membership of KDE e.V.), which shall act as a proxy
 * defined in Section 14 of version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import QtQuick 2.7
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.15 as Kirigami
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.0

Popup {
    id: root

    property string uid
    property var description: ""
    property int px: 0
    property int py: 0
    property int selectIndex

    property int statusbar_height : 22
    property int statusbar_icon_size: 22
    property int default_setting_item_height: 45

    property int screenWidth: 888
    property int screenHeight: 648

    property int marginTitle2Top : 44 
    property int marginItem2Title : 36 
    property int marginLeftAndRight : 10 
    property int marginItem2Top : 24 
    property int radiusCommon: 10 
    property int fontNormal: 14

    signal menuSelectChanged(int selectIndex)

    x: px
    y: py
    width: 240 + 80
    height: contentItem.height

    modal: true
    focus: true

    background: Rectangle {
        id: background
        color: "transparent"
    }

    contentItem: Rectangle {
        id: contentItem

        anchors.left: parent.left
        anchors.right: parent.right

        width: parent.width
        height: default_setting_item_height  * 3 + 8 * 2 + 4
        radius: 10
        color: "#fff"

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            radius: 10
            samples: 25
            color: "#1A000000"
            verticalOffset: 0
            spread: 0
        }

        Rectangle {
            id: menu_content

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: 8
                bottomMargin: 0
                leftMargin: marginLeftAndRight
                rightMargin: marginLeftAndRight
            }

            width: root.width - marginLeftAndRight * 2 
            color: "transparent"

            ListView {
                id: listview 
                width: parent.width
                height: default_setting_item_height * 3
                model: kcm.deviceModel
                delegate: Rectangle {
                    width: listview.width
                    height : 45
                    Text {
                        anchors {
                            left: parent.left 
                            verticalCenter: parent.verticalCenter
                        }
                        text:{
                            // if(index == 0){
                            //     return i18n("Device list :")
                            // }else {
                            //     return modelData.name
                            // }
                            return modelData.name 
                        }
                        font.pixelSize: 14
                    }

                    Image {
                        sourceSize.width: 17 
                        sourceSize.height: 17
                        visible:selectIndex == index
                        source:"../image/menu_select.png"
                        anchors {
                            right: parent.right
                            rightMargin: 20
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill:parent
                        onClicked: {
                            // if(index == 0 ){
                            //     return
                            // }
                            menuSelectChanged(index)
                            root.close()
                        }
                    }
                }
            }
        }
    }
}
