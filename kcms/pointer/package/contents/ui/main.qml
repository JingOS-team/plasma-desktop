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

    // property int screenWidth: Screen.width
    // property int screenHeight: Screen.height
    // property real appScale: 1.3 * screenWidth / 1920
    // property int appFontSize: theme.defaultFont.pixelSize
    // property real marginLeftAndRight: 72 * appScale

    // anchors.fill:parent 
    property bool loading: false
    property QtObject device
    property int deviceCount: kcm.backend.deviceCount
    property bool isLeftHand : false 
    property bool isMouseEnable: false 
    property alias deviceIndex: deviceSelector.currentIndex
    property int usedIndex ; 
    // signal changeSignal()

    Component.onCompleted :{
        console.log("::::::pointer :onCompleted::::")
        console.log("mouse device count::::::::::::", deviceCount)
        if(deviceCount > 1){
            resetModel(1)
        }
        
        syncValuesFromBackend()
    }

    Connections {
        target: kcm.backend
        onDeviceAdded: {
            console.log("onDeviceAdded--------------" , success )
            // kcm.deviceModel = kcm.getDeviceList(kcm.backend)
            kcm.getDeviceList(kcm.backend)
            // resetModel(0)
            resetModel(1)
            syncValuesFromBackend()
        }

        onDeviceRemoved: {
             console.log("onDeviceRemoved--------------" , index)
             resetModel(0)
             syncValuesFromBackend()
        }
    
    }

    function resetModel(index) {
        deviceCount = kcm.backend.deviceCount
        console.log("resetModel--------------" , deviceCount)
        deviceSelector.enabled = deviceCount > 1
        isMouseEnable = deviceCount > 1
        loading = true
        if(deviceCount > 1){
            console.log("Configuration of device 0' : " + kcm.deviceModel[0].name + "' opened")
            console.log("Configuration of device 1' : " + kcm.deviceModel[1].name + "' opened")
        }
        if (deviceCount) {
            device = kcm.deviceModel[index]
            // deviceSelector.model = kcm.deviceModel
            // deviceSelector.currentIndex = index
            usedIndex = index 
            console.log("Configuration of device '" +
                        (index + 1) + " : " + device.name + "' opened")
        } else {
            deviceSelector.model = [""]
            console.log("No device found")
        }
        loading = false
    }

    function syncValuesFromBackend() {
        loading = true

        scrolling_speed_slider.load()
        accelSpeed.load()
        naturalScroll.load() 
        secondary_click_item.load()
        

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
            text: i18n("Mouse")
            font.pixelSize: 20 
            font.weight: Font.Bold
        }

        // device 
        Rectangle {
            id: device_item

            anchors {
                top: tracking_title.bottom
                left:parent.left 
                right:parent.right 
                topMargin: marginItem2Title
                leftMargin: marginLeftAndRight
                rightMargin: marginLeftAndRight
            }

            width: parent.width
            height: default_setting_item_height
            color: "white"
            radius: radiusCommon

            Text {
                id: device_title
                anchors {
                    left: parent.left
                    leftMargin:  marginLeftAndRight
                    verticalCenter: parent.verticalCenter
                }
                width: 280
                height: fontNormal
                verticalAlignment:Text.AlignVCenter
                text: i18n("Device")
                color: isMouseEnable ? "black" :"#4D3C3C43"
                font.pixelSize: fontNormal
            }

            Image {
                id: device_icon_right 
                anchors {
                    right: parent.right
                    rightMargin: marginLeftAndRight
                    verticalCenter: parent.verticalCenter
                }

                source: "../image/icon_right.png"
                sourceSize.width: 17
                sourceSize.height: 17
            }

            Text {
                id : usedDeviceName
                anchors {
                    right: device_icon_right.left
                    rightMargin: 7 
                    verticalCenter: parent.verticalCenter
                }
                text: isMouseEnable ? (kcm.deviceModel[usedIndex]).name :"None"
                font.pixelSize: 14
                color: "#4D000000" 
            }

            ComboBox {
                id: deviceSelector

                anchors {
                    right: device_icon_right.left
                    rightMargin: 7 
                    verticalCenter: parent.verticalCenter
                }
                enabled: deviceCount > 1
                width: 250 
                model: kcm.deviceModel
                visible: false  
                textRole: "name"

                onCurrentIndexChanged: {
                    if (deviceCount) {
                        device = kcm.deviceModel[currentIndex]
                        if (!loading) {
                            
                            kcm.save()
                            // changeSignal()
                        }
                        resetModel(currentIndex)
                        console.log("Configuration of device '" +
                                    (currentIndex+1) + " : " + device.name + "' opened")
                    }
                    trackpad_root.syncValuesFromBackend()
                }
            }

            MouseArea {
                anchors.fill:parent
                onClicked: {
                    if(!isMouseEnable){
                        return 
                    }
                    deviceDialog.px = (device_item.x + device_item.width) - (deviceDialog.width * 1.05)
                    deviceDialog.py = device_item.y - 45
                    deviceDialog.selectIndex = usedIndex
                    deviceDialog.open()

                }
            }

            JrDialog {
                id: deviceDialog
                onMenuSelectChanged: {
                    console.log("-----selectIndex : -----"  ,selectIndex)

                    if (deviceCount) {
                        device = kcm.deviceModel[selectIndex]
                        if (!loading) {
                            kcm.save()
                        }
                        resetModel(selectIndex)
                        console.log("Configuration of device '" +
                                    (selectIndex+1) + " : " + device.name + "' opened")
                    }
                    trackpad_root.syncValuesFromBackend()
                    deviceDialog.close()
                }
            }

        }

        // Secondary Click 
        Rectangle {
            id: secondary_click_item

            anchors {
                top: device_item.bottom
                left:parent.left 
                right:parent.right 
                topMargin: marginItem2Top
                leftMargin: marginLeftAndRight
                rightMargin: marginLeftAndRight
            }

            width: parent.width
            height: default_setting_item_height
            color: "white"
            visible: isMouseEnable
            radius: radiusCommon

            Text {
                id: secondary_click
                anchors {
                    left: parent.left
                    leftMargin: marginLeftAndRight
                    verticalCenter: parent.verticalCenter
                }
                width: 331
                height: fontNormal
                verticalAlignment:Text.AlignVCenter
                text: i18n("Secondary Click")
                font.pixelSize: fontNormal
            }

            Image {
                id: icon_right 
                anchors {
                    right: parent.right
                    rightMargin: marginLeftAndRight
                    verticalCenter: parent.verticalCenter
                }

                source: "../image/icon_right.png"
                sourceSize.width: 17
                sourceSize.height: 17
            }

            Text {
                id: leftHand_txt
                anchors {
                    right: icon_right.left
                    rightMargin: 7 
                    verticalCenter: parent.verticalCenter
                }
                text: isLeftHand ? i18n("Left"):i18n("Right")  
                font.pixelSize: fontNormal
            }

            function load() {

                enabled = device.supportsLeftHanded

                isLeftHand = enabled && device.leftHanded
                console.log("isLeft HAND :::: enabled  -",enabled)
                console.log("isLeft HAND :::: isLeftHand - ",isLeftHand)
                // leftHand_txt.text =  isLeftHand ? "Right" : "Left"

            }

            MouseArea {
                anchors.fill :parent 
                onClicked: {
                    // isLeftHand = !isLeftHand 
                    // device.leftHanded = isLeftHand
                    // console.log("isLeft HAND :::: enabled  -",device.leftHanded)
                    // kcm.save() 
                    handDialog.px = (secondary_click_item.x + secondary_click_item.width) - (handDialog.width * 1.05)
                    handDialog.py = secondary_click_item.y - 45 * 3+ 22
                    handDialog.selectIndex = isLeftHand ? 0 : 1
                    handDialog.open()
                }
            }

             JrHandDialog {
                id: handDialog
                onMenuSelectChanged: {
                    console.log("-----selectIndex : -----"  ,selectIndex)

                    isLeftHand = selectIndex== 0 ? true : false 
                    device.leftHanded = isLeftHand
                    console.log("changed isLeft hand :::: enabled  -",device.leftHanded)
                    kcm.save() 
                }
            }

        }

        Rectangle {
            id: tracking_area1

            anchors {
                left: parent.left
                top: secondary_click_item.bottom
                leftMargin: marginLeftAndRight
                topMargin: marginItem2Top
            }

            width: parent.width - marginLeftAndRight* 2
            height: default_setting_item_height
            color: "#fff"
            visible: isMouseEnable
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
                    height: fontNormal
                    verticalAlignment:Text.AlignVCenter
                    text: i18n("Natural Scrolling")
                    font.pixelSize: fontNormal
                }

                Kirigami.JSwitch {
                    id: naturalScroll

                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        rightMargin: 17
                    }

                    function load() {
                        enabled = device.supportsNaturalScroll
                        checked = enabled && device.naturalScroll
                        console.log("naturalScroll load()")
                    }

                    onCheckedChanged: {
                        // switchLocation(value)
                         if (enabled && !trackpad_root.loading) {
                            device.naturalScroll = checked
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
            // font.pixelSize: 12
            font.pixelSize: 12
            visible: isMouseEnable
            color: "#4D000000"
        }

        Rectangle {
            id: pointer_size_area

            anchors {
                left: parent.left
                top: natural_scrolling.bottom
                leftMargin: marginLeftAndRight
                topMargin: marginItem2Top
            }

            width: parent.width -  marginLeftAndRight * 2
            height: default_setting_item_height + default_setting_title_height
            color: "#fff"
            visible: isMouseEnable
            radius: radiusCommon

            Rectangle {
                id: pointer_size_title_area
                anchors {
                    top:parent.top
                }

                width : parent.width
                height: default_setting_title_height

                color:"transparent"

                Text {
                    id:pointer_size_title
                    anchors {
                        left:pointer_size_title_area.left
                        leftMargin: marginLeftAndRight
                        verticalCenter: parent.verticalCenter
                    }
                    text: i18n("Tracking Speed")
                    font.pixelSize: 12
                    color: "#4D000000"
                }
            }

            Rectangle {
                id: pointer_size_item_1

                anchors {
                    top: pointer_size_title_area.bottom
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
                    height: fontNormal
                    verticalAlignment: Text.AlignVCenter
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
                    height: fontNormal
                    verticalAlignment: Text.AlignVCenter
                    text: i18n("Fast")
                    font.pixelSize: fontNormal
                }

                Kirigami.JSlider {
                    Kirigami.FormData.label: i18nd("kcmmouse", "Tracking speed:")
                    id: accelSpeed

                    anchors {
                        verticalCenter: parent.verticalCenter
                        // left:parent.left
                        // right: parent.right 
                        // leftMargin: marginLeftAndRight * 2.5
                        // rightMargin: marginLeftAndRight * 2.5
                        left:tracking_slow.right
                        right: tracking_fast.left 
                        leftMargin: marginLeftAndRight 
                        rightMargin: marginLeftAndRight 
                    }

                    from: 1
                    to: 11
                    stepSize: 1

                    function load() {
                        enabled = device.supportsPointerAcceleration
                        if (!enabled) {
                            value = 0.2
                            return
                        }
                        // transform libinput's pointer acceleration range [-1, 1] to slider range [1, 11]
                        //value = 4.5 * device.pointerAcceleration + 5.5
                        value = 6 + device.pointerAcceleration / 0.2
                    }

                    onValueChanged: {
                        if (device != undefined && enabled && !trackpad_root.loading) {
                            // transform slider range [1, 10] to libinput's pointer acceleration range [-1, 1]
                            // by *10 and /10, we ignore the floating points after 1 digit. This prevents from
                            // having a libinput value like 0.60000001
                            device.pointerAcceleration = Math.round(((value-6) * 0.2) * 10) / 10
                             kcm.save()
                        }
                    }
                }
            }
        }

        Rectangle {
            id: scrolling_speed_area

            anchors {
                left: parent.left
                top: pointer_size_area.bottom
                leftMargin: marginLeftAndRight
                topMargin: marginItem2Top
            }

            width: parent.width - marginLeftAndRight * 2
            height: default_setting_item_height + default_setting_title_height
            color: "#fff"
            visible: isMouseEnable
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
                    text: i18n("Scrolling Speed")
                    font.pixelSize: 12
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
                    height: fontNormal
                    verticalAlignment: Text.AlignVCenter
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
                    height: fontNormal
                    verticalAlignment: Text.AlignVCenter
                    text: i18n("Fast")
                    font.pixelSize: fontNormal
                }
                
                Kirigami.JSlider {
                    id: scrolling_speed_slider

                    anchors {
                        verticalCenter: scrolling_speed_item_1.verticalCenter
                        left: scrolling_speed_slow.right
                        right: scrolling_speed_fast.left
                        // left:scrolling_speed_item_1.left
                        // right: scrolling_speed_item_1.right 
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
                        
                        let index = values.indexOf(device.scrollFactor)
                        if (index === -1) {
                            index = values.indexOf(1);
                        }
                        value = index
                         console.log("------------load22222222---------", value)
                    }

                    onValueChanged: {
                        // console.log("tracking speed : ",value )

                        device.scrollFactor = values[value]
                        kcm.save()
                        // console.log("------------onValu eChanged----------" , device.name , device.scrollFactor)
                        // kcm.valueWriter(device.name , device.scrollFactor)
                    }
                }

            }

            
        }
    }
}
