/***************************************************************************
 *   Copyright 2012,2015 by Sebastian Kügler <sebas@kde.org>               *
 *   Copyright 2015 by Kai Uwe Broulik <kde@privat.broulik.de>             *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.4
import QtQuick.Layouts 1.4
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons
import org.kde.plasma.plasmoid 2.0

Item {
    id: toolBoxButton

    transform: Translate {
        y: plasmoid.editMode ? 0
           : state == "top" || state == "topcenter" ? -height
           : state == "bottom" || state == "bottomcenter" ? height
           : 0

        Behavior on y {
            NumberAnimation {
                duration: units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
    }
    transformOrigin: Item.Center
    opacity: plasmoid.editMode
    visible: plasmoid.editMode
    Behavior on opacity {
        OpacityAnimator {
            duration: units.longDuration
            easing.type: Easing.InOutQuad
        }
        enabled: visible
    }
    Behavior on rotation {
        NumberAnimation {
            duration: units.shortDuration;
            easing.type: Easing.InOutExpo;
        }
        enabled: visible
    }
    Behavior on x {
        NumberAnimation {
            duration: units.shortDuration;
            easing.type: Easing.InOutExpo;
        }
        enabled: visible

    }
    Behavior on y {
        NumberAnimation {
            duration: units.shortDuration;
            easing.type: Easing.InOutExpo;
        }
        enabled: visible
    }

    width: buttonLayout.width
    height: buttonLayout.height

    state: "topcenter"

    onXChanged: stateTimer.restart()
    onYChanged: stateTimer.restart()

    Timer {
        id: stateTimer
        interval: 0
        onTriggered: updateState()
    }
    function updateState() {
        var container = main;
        //print("    w: " + container.width +"x"+container.height+" : "+x+"/"+y+" tbw: " + toolBoxButton.width);

        var x = toolBoxButton.x - main.x;
        var y = toolBoxButton.y - main.y;

        var cornerSnap = iconWidth

        //top
        if (y + height / 2 < container.height / 2) {
            if (Math.abs(container.width/2 - (x + width/2)) < units.gridUnit) {
                toolBoxButton.state = "topcenter";
            } else {
                toolBoxButton.state = "top";
            }
        //bottom
        } else {
            if (Math.abs(container.width/2 - (x + height/2)) < units.gridUnit) {
                toolBoxButton.state = "bottomcenter";
            } else {
                toolBoxButton.state = "bottom";
            }
        }

        if (!buttonMouse.pressed) {
            main.placeToolBox(toolBoxButton.state);
        }

        stateTimer.running = false;
    }

    PlasmaCore.FrameSvgItem {
        id: backgroundFrame
        anchors {
            fill: parent
            leftMargin: -backgroundFrame.margins.left
            topMargin: -backgroundFrame.margins.top
            rightMargin: -backgroundFrame.margins.right
            bottomMargin: -backgroundFrame.margins.bottom
        }
        imagePath: "widgets/background"
        width: Math.round(buttonLayout.width + margins.horizontal)
        height: Math.round(buttonLayout.height + margins.vertical)
    }

    MouseArea {
        id: buttonMouse

        property QtObject container: main
        property int pressedX
        property int pressedY
        property int snapStartX
        property bool snapX: false;
        property bool dragging: false

        anchors.fill: parent

        drag {
            filterChildren: true
            target: main.Plasmoid.immutable ? undefined : toolBoxButton
            minimumX: 0
            maximumX: container.width - toolBoxButton.width
            minimumY: 0
            maximumY: container.height
        }

        hoverEnabled: true

        onPressed: {
            pressedX = toolBoxButton.x
            pressedY = toolBoxButton.y
        }
        onPositionChanged: {
            if (pressed && (Math.abs(toolBoxButton.x - pressedX) > iconSize ||
                Math.abs(toolBoxButton.y - pressedY) > iconSize)) {
                dragging = true;
            }

            // Center snapping X
            if (snapX && Math.abs(snapStartX - mouse.x) > units.gridUnit) {
                toolBoxButton.anchors.horizontalCenter = undefined;
                snapX = false;
            } else if (!snapX && Math.abs(main.width/2 - (toolBoxButton.x + toolBoxButton.width/2)) < units.gridUnit) {
                toolBoxButton.anchors.horizontalCenter = main.horizontalCenter;
                snapStartX = mouse.x;
                snapX = true;
            }
        }

        onReleased: {
            toolBoxButton.anchors.horizontalCenter = undefined;
            toolBoxButton.anchors.verticalCenter = undefined;
            snapX = false;
            main.Plasmoid.configuration.ToolBoxButtonState = toolBoxButton.state;
            main.Plasmoid.configuration.ToolBoxButtonX = toolBoxButton.x;
            main.Plasmoid.configuration.ToolBoxButtonY = toolBoxButton.y;
            //print("Saved coordinates for ToolBox in config: " + toolBoxButton.x + ", " +toolBoxButton.x);
            if (dragging) {
                main.placeToolBox();
            }
            dragging = false;
            stateTimer.stop();
            updateState();
        }
        onCanceled: dragging = false;

        RowLayout {
            id: buttonLayout
            anchors.centerIn: parent
            spacing: units.smallSpacing


            PlasmaComponents3.ToolButton {
                property QtObject qAction: plasmoid.action("add widgets")
                text: qAction.text
                icon.name: "list-add"
                onClicked: qAction.trigger()
            }
            PlasmaComponents3.ToolButton {
                property QtObject qAction: plasmoid.globalAction("manage activities")
                text: qAction.text
                icon.name: "activities"
                onClicked: qAction.trigger()
            }
            PlasmaComponents3.ToolButton {
                property QtObject qAction: plasmoid.action("configure")
                text: qAction.text
                icon.name: "preferences-desktop-wallpaper"
                onClicked: qAction.trigger()
            }
            PlasmaComponents3.ToolButton {
                icon.name: "window-close"
                Layout.preferredWidth: height
                onClicked: plasmoid.editMode = false
                PlasmaComponents3.ToolTip {
                    text: i18n("Exit Edit Mode")
                }
            }
        }
    }
}
