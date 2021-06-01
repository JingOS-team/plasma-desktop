/*
 *   Copyright 2020 Dimitris Kardarakos <dimkard@posteo.net>
 *   Copyright 2021 Wang Rui <wangrui@jingos.com>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import org.kde.kcm 1.2 as KCM
import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 2.10

import org.kde.kirigami 2.15 as Kirigami

Rectangle {
    id: trackpad_root

    // property int screenWidth: Screen.width
    // property int screenHeight: Screen.height
    // property real appScale: 1.3 * screenWidth / 1920
    // property int appFontSize: theme.defaultFont.pointSize
    // property real marginLeftAndRight: marginLeftAndRight

    // anchors.fill:parent 

    property int screenWidth: 888
    property int screenHeight: 648

    property int statusbar_height : 22
    property int statusbar_icon_size: 22
    property int default_setting_item_height: 45
    property int default_setting_title_height: 30

    property int marginTitle2Top : 44 
    property int marginItem2Title : 36
    property int marginLeftAndRight : 20 
    property int marginItem2Top : 24
    property int radiusCommon: 10 
    property int fontNormal: 14 

    width: screenWidth * 0.7
    height: screenHeight

    property QtObject touchpad
    property int touchpadCount: kcm.backend.touchpadCount
    property bool loading: false

    Component.onCompleted: {
        console.log("trackpad .... oncomplete......." )
        resetModel(0)
        syncValuesFromBackend();
    }

    function resetModel(index) {
        touchpadCount = kcm.backend.touchpadCount
        console.log("trackpad .... resetModel......." , touchpadCount)

        loading = true
        if (touchpadCount) {
            touchpad = kcm.deviceModel[index]
            console.log("Touchpad configuration of device '" +
                        (index + 1) + " : " + touchpad.name + "' opened")
        } else {
            console.log("No touchpad found")
        }
        loading = false
    }

    function syncValuesFromBackend() {
        loading = true

        accelSpeedSlider.load()
        scrolling_speed_slider.load()
        tap_to_click_switch.load()
        naturalScroll.load()
        two_finger_switch.load()

        // dwt.load()
        // leftHanded.load()
        // accelProfile.load()
        // tapAndDrag.load()
        // tapAndDragLock.load()
        // multiTap.load()
        // scrollMethod.load()
        // scrollFactor.load()
        // rightClickMethod.load()
        // middleClickMethod.load()
        // disableHorizontalScrolling.load()

        loading = false
    }


    Rectangle {
        anchors.fill: parent
        color: "#FFF6F9FF"

        Text {
            id: tracking_title

            anchors {
                left: parent.left
                top: parent.top
                leftMargin: marginLeftAndRight
                topMargin: marginTitle2Top
            }

            width: 329
            height: 14
            text: i18n("Trackpad")
            // font.pointSize: appFontSize + 11
            font.pixelSize: 20
            font.weight: Font.Bold
        }

        Rectangle {
            id: tracking_speed_area

            anchors {
                left: parent.left
                top: tracking_title.bottom
                leftMargin: marginLeftAndRight
                topMargin: marginItem2Title
            }

            width: parent.width - marginLeftAndRight * 2
            height: default_setting_item_height + default_setting_title_height
            color: "#fff"
            radius: radiusCommon

            Rectangle {
                id: tracking_speed_title_area
                anchors {
                    top:parent.top
                }

                width : parent.width
                height: default_setting_title_height

                color:"transparent"

                Text {
                    id:tracking_speed_title
                    anchors {
                        left:tracking_speed_title_area.left
                        leftMargin: marginLeftAndRight
                        verticalCenter: parent.verticalCenter
                    }
                    verticalAlignment:Text.AlignVCenter
                    text: i18n("Tracking Speed")
                    font.pixelSize:  12
                    color: "#4D000000"
                }
            }

            Rectangle {
                id: tracking_speed_item_1

                anchors {
                    top: tracking_speed_title_area.bottom
                }

                width: parent.width
                height: default_setting_item_height
                color: "transparent"

                Text {
                    id: tracking_slow
                    anchors {
                        left: parent.left
                        leftMargin: marginLeftAndRight
                        verticalCenter: parent.verticalCenter
                    }
                    height: 14
                    verticalAlignment:Text.AlignVCenter
                    text: i18n("Slow")
                    font.pixelSize: fontNormal
                }

                Text {
                    id: tracking_fast
                    anchors {
                        right: parent.right
                        rightMargin: marginLeftAndRight
                        verticalCenter: parent.verticalCenter
                    }
                    height: 14
                    verticalAlignment:Text.AlignVCenter
                    text: i18n("Fast")
                    font.pixelSize: fontNormal
                }


                Kirigami.JSlider {
                    id: accelSpeedSlider

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: tracking_slow.right
                        right: tracking_fast.left
                        leftMargin: marginLeftAndRight
                        rightMargin: marginLeftAndRight
                    }

                    from: 1
                    to: 11
                    stepSize: 1
                    property int accelSpeedValue: 0 // [-100, 100]

                    function load() {
                        console.log("accelSpeedSlider..........load111")
                        enabled = touchpad.supportsPointerAcceleration
                        if (!enabled) {
                            return
                        }

                        accelSpeedValue = Math.round(touchpad.pointerAcceleration * 100)

                        // convert libinput pointer acceleration range [-1, 1] to slider range [1, 11]
                        value = Math.round(6 + touchpad.pointerAcceleration / 0.2)
                        console.log("accelSpeedSlider..........load222 :: " , value )
                    }

                    function onAccelSpeedChanged(val) {
                        // check slider
                        if (val != accelSpeedSlider.accelSpeedValue) {
                            accelSpeedSlider.accelSpeedValue = val
                            accelSpeedSlider.value = Math.round(6 + (val / 100) / 0.2)
                        }

                        // // check spinbox
                        // if (val != accelSpeedSpinbox.value) {
                        //     accelSpeedSpinbox.value = val
                        // }

                        // check libinput accelspeed
                        if ((val / 100) != touchpad.pointerAcceleration) {
                            touchpad.pointerAcceleration = val / 100
                            kcm.save()
                        }
                    }

                    onValueChanged: {
                        if (touchpad != undefined && enabled && !trackpad_root.loading) {
                            // convert slider range [1, 11] to accelSpeedValue range [-100, 100]
                            accelSpeedValue = Math.round(((value - 6) * 0.2) * 100)

                            accelSpeedSlider.onAccelSpeedChanged(accelSpeedValue)
                        }
                    }
                }

            }
        }

        //Natural Scrolling
        Rectangle {
            id: tracking_area1

            anchors {
                left: parent.left
                top: tracking_speed_area.bottom
                leftMargin: marginLeftAndRight
                topMargin: marginItem2Top
            }

            width: parent.width - marginLeftAndRight * 2
            height: default_setting_item_height
            color: "#fff"
            radius: radiusCommon

            Rectangle {
                id: tracking_item1

                anchors {
                    top: parent.top
                }

                width: parent.width
                height: parent.height
                color: "transparent"

                Text {
                    id: slince_title1
                    anchors {
                        left: parent.left
                        leftMargin: marginLeftAndRight
                        verticalCenter: parent.verticalCenter
                    }
                    width: 331
                    height: 14
                    verticalAlignment:Text.AlignVCenter
                    text: i18n("Natural Scrolling")
                    font.pixelSize: fontNormal
                }

                Kirigami.JSwitch {
                    id: naturalScroll

                    function load() {
                        enabled = touchpad.supportsNaturalScroll
                        checked = enabled && touchpad.naturalScroll
                    }

                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        rightMargin: marginLeftAndRight
                    }
                    onCheckedChanged: {
                        if (enabled && !trackpad_root.loading) {
                            console.log("-------onCheckedChanged-------" , checked)
                            touchpad.naturalScroll = checked
                            kcm.save()
                        }
                    }
                }

            }

        }

        Text {
            id:natural_scrolling
            anchors {
                top:tracking_area1.bottom
                topMargin: 8 
                left:tracking_area1.left
                leftMargin: marginLeftAndRight
            }
            text: i18n("Content will track the movement of your fingers.")
            font.pixelSize:  12
            color: "#4D000000"
        }

        Rectangle {
            id: scrolling_speed_area

            anchors {
                left: parent.left
                top: natural_scrolling.bottom
                leftMargin: marginLeftAndRight
                topMargin: marginItem2Top
            }

            width: parent.width - marginLeftAndRight * 2
            height: default_setting_item_height + default_setting_title_height
            color: "#fff"
            radius: radiusCommon

            Rectangle {
                id: scrolling_speed_title_area
                anchors {
                    top:parent.top
                }

                width : parent.width
                height: default_setting_title_height

                color:"transparent"

                Text {
                    id:scrolling_speed_title
                    anchors {
                        left:scrolling_speed_title_area.left
                        leftMargin: marginLeftAndRight
                        verticalCenter: parent.verticalCenter
                    }
                    verticalAlignment:Text.AlignVCenter
                    text: i18n("Scrolling Speed")
                    font.pixelSize:  12
                    color: "#4D000000"
                }
            }

            Rectangle {
                id: scrolling_speed_item_1

                anchors {
                    top: scrolling_speed_title_area.bottom
                }

                width: parent.width
                height: default_setting_item_height
                color: "transparent"

                Text {
                    id: scrolling_speed_slow
                    anchors {
                        left: parent.left
                        leftMargin: marginLeftAndRight
                        verticalCenter: parent.verticalCenter
                    }
                    height: 14
                    verticalAlignment:Text.AlignVCenter
                    text: i18n("Slow")
                    font.pixelSize: fontNormal
                }

                Text {
                    id: scrolling_speed_fast
                    anchors {
                        right: parent.right
                        rightMargin: marginLeftAndRight
                        verticalCenter: parent.verticalCenter
                    }
                    height: 14
                    verticalAlignment:Text.AlignVCenter
                    text: i18n("Fast")
                    font.pixelSize: fontNormal
                }
                
                Kirigami.JSlider {
                    id: scrolling_speed_slider

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: scrolling_speed_slow.right
                        right: scrolling_speed_fast.left
                        // left:parent.left
                        // right: parent.right 
                        leftMargin: marginLeftAndRight 
                        rightMargin: marginLeftAndRight 
                    }

                    from: 0
                    to: 14
                    stepSize: 1

                    property variant values : [
                        0.1,
                        0.3,
                        0.5,
                        0.75,
                        1, // default
                        1.5,
                        2,
                        3,
                        4,
                        5,
                        7,
                        9,
                        12,
                        15,
                        20
                    ]

                    function load() {
                        
                        let index = values.indexOf(touchpad.scrollFactor)
                        if (index === -1) {
                            index = values.indexOf(1);
                        }
                        value = index
                        console.log("------------load22222222---------", value)
                    }

                    onValueChanged: {
                        // console.log("tracking speed : ",value )

                        touchpad.scrollFactor = values[value]
                        kcm.save()
                        // console.log("------------onValu eChanged----------" , device.name , device.scrollFactor)
                        // kcm.valueWriter(device.name , device.scrollFactor)
                    }
                }

            }
        }

        Rectangle {
            id: tracking_area3

            anchors {
                left: parent.left
                top: scrolling_speed_area.bottom
                leftMargin: marginLeftAndRight
                topMargin: marginItem2Top
            }

            width: parent.width - marginLeftAndRight * 2
            height: default_setting_item_height * 3
            color: "#fff"
            radius: radiusCommon
            visible: false 

            Rectangle {
                id: trackpad_title_area
                anchors {
                    top:parent.top
                }
                width : parent.width
                height: default_setting_item_height

                Text {
                    id:trackpad_title
                    anchors {
                        left:trackpad_title_area.left
                        leftMargin: marginLeftAndRight
                        verticalCenter: parent.verticalCenter
                    }
                    text: i18n("Trackpad")
                    font.pixelSize:  12
                    color: "#4D000000"
                }
            }

            // tap_to_click
            Rectangle {
                id: trackpad_item_1

                anchors {
                    top: trackpad_title_area.bottom
                }

                width: parent.width
                height: default_setting_item_height
                color: "transparent"

                Text {
                    id: tap_to_click
                    anchors {
                        left: parent.left
                        leftMargin: marginLeftAndRight
                        verticalCenter: parent.verticalCenter
                    }
                    width: 331
                    height: 14
                    text: i18n("Tap to Click")
                    font.pixelSize: fontNormal
                }

                Kirigami.JSwitch {
                    id: tap_to_click_switch

                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        rightMargin: marginLeftAndRight
                    }

                    function load() {

                        enabled = touchpad.tapFingerCount > 0
                        checked = enabled && touchpad.tapToClick
                    }

                    function updateDependents() {
                        loading = true
                        // multiTap.load()
                        loading = false
                    }



                    onCheckedChanged: {

                        if (enabled && !trackpad_root.loading) {
                            touchpad.tapToClick = checked
                            console.log("=====touchpad.tapToClick========" , touchpad.tapToClick)
                            updateDependents()
                            kcm.save()
                        }
                    }
                }

            }

            Rectangle {
                id: trackpad_item_2

                anchors {
                    top: trackpad_item_1.bottom
                }

                width: parent.width
                height: default_setting_item_height
                color: "transparent"

                

                Text {
                    id: two_finger
                    anchors {
                        left: parent.left
                        leftMargin: marginLeftAndRight
                        verticalCenter: parent.verticalCenter
                    }
                    width: 331
                    height: 14
                    text: i18n("Two Finger Secondary Click")
                    font.pixelSize: fontNormal
                }

                Kirigami.JSwitch {
                    id: two_finger_switch

                    function load() {
                        enabled = touchpad.supportsLmrTapButtonMap && tap_to_click_switch.checked

                        if (!enabled) {
                            
                            return
                        }

                        console.log("====two finger load======", touchpad.lmrTapButtonMap)
                        checked = touchpad.lmrTapButtonMap
                    }

                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        rightMargin: marginLeftAndRight
                    }

                    onCheckedChanged: {

                        if (enabled && !trackpad_root.loading) {
                            console.log("====two finger======")
                            touchpad.lmrTapButtonMap = checked
                            kcm.save()
                        }
                    }
                }

            }

        }
    }
}
