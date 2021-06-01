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
        height: default_setting_item_height  * 2 + 8 * 2 
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
                bottomMargin: 8
                leftMargin: marginLeftAndRight
                rightMargin: marginLeftAndRight
            }

            width: root.width - marginLeftAndRight * 2 
            color: "transparent"

            Rectangle {
                id: left_item
                width:parent.width
                height: default_setting_item_height
                anchors{
                    left:parent.left
                    top:parent.top
                }
                Text {
                    id:leftHand_txt
                    text:i18n("Left")
                    font.pixelSize:14
                    verticalAlignment:Text.AlignVCenter
                    anchors.verticalCenter:parent.verticalCenter
                    anchors.left:parent.left
                    anchors.leftMargin: marginLeftAndRight
                }
                Image {
                    id:left_select
                    width: 17
                    height: 17
                    sourceSize.width: 17
                    sourceSize.height : 17
                    source: "../image/menu_select.png"
                    visible: selectIndex == 0 
                    anchors.verticalCenter:parent.verticalCenter
                    anchors.right:parent.right
                    anchors.rightMargin: marginLeftAndRight
                }

                MouseArea {
                    anchors.fill: parent 
                    onClicked: {
                        menuSelectChanged(0)
                        root.close()
                    }
                }
            }

            Rectangle {
                id: right_item
                width:parent.width
                height: default_setting_item_height
                anchors{
                    left:parent.left
                    top:left_item.bottom
                }
                Text {
                    id:rightHand_txt
                    text:i18n("Right")
                    font.pixelSize:14
                    verticalAlignment:Text.AlignVCenter
                    anchors.verticalCenter:parent.verticalCenter
                    anchors.left:parent.left
                    anchors.leftMargin: marginLeftAndRight
                }
                Image {
                    id:right_select
                    width: 17
                    height: 17
                    sourceSize.width: 17
                    sourceSize.height : 17
                    source: "../image/menu_select.png"
                    visible: selectIndex == 1 
                    anchors.verticalCenter:parent.verticalCenter
                    anchors.right:parent.right
                    anchors.rightMargin: marginLeftAndRight
                }

                MouseArea {
                    anchors.fill: parent 
                    onClicked: {
                        menuSelectChanged(1)
                        root.close()
                    }
                }
            }
        }
    }
}
