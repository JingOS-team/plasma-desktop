/*
 *  Copyright 2013 Marco Martin <mart@kde.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.5
import QtQuick.Layouts 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0

MouseArea {
    id: configurationArea

    z: 1000

    anchors.fill: currentLayout

    hoverEnabled: true

    property bool isResizingLeft: false
    property bool isResizingRight: false
    property Item currentApplet

    property int lastX
    property int lastY

    readonly property int spacerHandleSize: units.smallSpacing

    onHeightChanged: tooltip.visible = false;
    onWidthChanged: tooltip.visible = false;

    onPositionChanged: {
        if (currentApplet && currentApplet.applet &&
            currentApplet.applet.pluginName === "org.kde.plasma.panelspacer") {
            if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
                if ((mouse.y - handle.y) < spacerHandleSize ||
                    (mouse.y - handle.y) > (handle.height - spacerHandleSize)) {
                    configurationArea.cursorShape = Qt.SizeVerCursor;
                } else {
                    configurationArea.cursorShape = Qt.ArrowCursor;
                }
            } else {
                if ((mouse.x - handle.x) < spacerHandleSize ||
                    (mouse.x - handle.x) > (handle.width - spacerHandleSize)) {
                    configurationArea.cursorShape = Qt.SizeHorCursor;
                } else {
                    configurationArea.cursorShape = Qt.ArrowCursor;
                }
            }
        } else {
            if (configurationArea.containsPress) {
                configurationArea.cursorShape = Qt.ClosedHandCursor;
            } else {
                configurationArea.cursorShape = Qt.OpenHandCursor;
            }
        }

        if (pressed) {
            if (currentApplet && currentApplet.applet.pluginName === "org.kde.plasma.panelspacer") {

                if (isResizingLeft) {
                    if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
                        handle.y += (mouse.y - lastY);
                        handle.height = currentApplet.height + (currentApplet.y - handle.y);
                    } else {
                        handle.x += (mouse.x - lastX);
                        handle.width = currentApplet.width + (currentApplet.x - handle.x);
                    }

                    lastX = mouse.x;
                    lastY = mouse.y;
                    return;

                } else if (isResizingRight) {
                    if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
                        handle.height = mouse.y - handle.y;
                    } else {
                        handle.width = mouse.x - handle.x;
                    }

                    lastX = mouse.x;
                    lastY = mouse.y;
                    return;
                }
            }

            var padding = units.gridUnit * 3;
            if (currentApplet && (mouse.x < -padding || mouse.y < -padding ||
                mouse.x > width + padding || mouse.y > height + padding)) {
                var newCont = plasmoid.containmentAt(mouse.x, mouse.y);

                if (newCont && newCont !== plasmoid) {
                    var newPos = newCont.mapFromApplet(plasmoid, mouse.x, mouse.y);
                    var applet = currentApplet.applet;
                    currentApplet.destroy();
                    applet.anchors.fill = undefined
                    newCont.addApplet(applet, newPos.x, newPos.y);
                    return;
                }
            }

            if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
                currentApplet.y += (mouse.y - lastY);
                handle.y = currentApplet.y;
            } else {
                currentApplet.x += (mouse.x - lastX);
                handle.x = currentApplet.x;
            }

            lastX = mouse.x;
            lastY = mouse.y;

            var item = currentLayout.childAt(mouse.x, mouse.y);

            if (item && item !== placeHolder) {
                placeHolder.width = item.width;
                placeHolder.height = item.height;
                placeHolder.parent = configurationArea;
                var posInItem = mapToItem(item, mouse.x, mouse.y);

                if ((plasmoid.formFactor === PlasmaCore.Types.Vertical && posInItem.y < item.height/2) ||
                    (plasmoid.formFactor !== PlasmaCore.Types.Vertical && posInItem.x < item.width/2)) {
                    root.layoutManager.insertBefore(item, placeHolder);
                } else {
                    root.layoutManager.insertAfter(item, placeHolder);
                }
            }

        } else {
            var item = currentLayout.childAt(mouse.x, mouse.y);
            if (root.dragOverlay && item && item !== lastSpacer) {
                root.dragOverlay.currentApplet = item;
            } else {
                root.dragOverlay.currentApplet = null;
            }
        }

        if (root.dragOverlay.currentApplet) {
            hideTimer.stop();
            tooltip.visible = true;
            tooltip.raise();
        }
    }

    onEntered: hideTimer.stop();

    onExited: hideTimer.restart();

    onCurrentAppletChanged: {
        if (!currentApplet || !root.dragOverlay.currentApplet) {
            hideTimer.start();
            return;
        }
        handle.x = currentApplet.x;
        handle.y = currentApplet.y;
        handle.width = currentApplet.width;
        handle.height = currentApplet.height;
    }

    onPressed: {
        if (!root.dragOverlay.currentApplet) {
            return;
        }

        if (currentApplet.applet.pluginName === "org.kde.plasma.panelspacer") {
            if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
                if ((mouse.y - handle.y) < spacerHandleSize) {
                    configurationArea.isResizingLeft = true;
                    configurationArea.isResizingRight = false;
                } else if ((mouse.y - handle.y) > (handle.height - spacerHandleSize)) {
                    configurationArea.isResizingLeft = false;
                    configurationArea.isResizingRight = true;
                } else {
                    configurationArea.isResizingLeft = false;
                    configurationArea.isResizingRight = false;
                }

            } else {
                if ((mouse.x - handle.x) < spacerHandleSize) {
                    configurationArea.isResizingLeft = true;
                    configurationArea.isResizingRight = false;
                } else if ((mouse.x - handle.x) > (handle.width - spacerHandleSize)) {
                    configurationArea.isResizingLeft = false;
                    configurationArea.isResizingRight = true;
                } else {
                    configurationArea.isResizingLeft = false;
                    configurationArea.isResizingRight = false;
                }
            }
        }

        lastX = mouse.x;
        lastY = mouse.y;
        placeHolder.width = currentApplet.width;
        placeHolder.height = currentApplet.height;
        root.layoutManager.insertBefore(currentApplet, placeHolder);
        currentApplet.parent = moveAppletLayer;
        currentApplet.z = 900;
    }

    onReleased: {
        if (!root.dragOverlay.currentApplet) {
            return;
        }

        if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            currentApplet.applet.configuration.length = handle.height;
        } else {
            currentApplet.applet.configuration.length = handle.width;
        }

        configurationArea.isResizingLeft = false;
        configurationArea.isResizingRight = false;

        root.layoutManager.insertBefore(placeHolder, currentApplet);
        placeHolder.parent = configurationArea;
        currentApplet.z = 1;

        handle.x = currentApplet.x;
        handle.y = currentApplet.y;
        handle.width = currentApplet.width;
        handle.height = currentApplet.height;
        root.layoutManager.save();
    }

    Item {
        id: placeHolder
        visible: configurationArea.containsMouse
        Layout.fillWidth: currentApplet ? currentApplet.Layout.fillWidth : false
        Layout.fillHeight: currentApplet ? currentApplet.Layout.fillHeight : false
    }

    Timer {
        id: hideTimer
        interval: units.longDuration * 6
        onTriggered: tooltip.visible = false;
    }

    Connections {
        target: currentApplet
        onXChanged: handle.x = currentApplet.x
        onYChanged: handle.y = currentApplet.y
        onWidthChanged: handle.width = currentApplet.width
        onHeightChanged: handle.height = currentApplet.height
    }

    Rectangle {
        id: handle
        visible: configurationArea.containsMouse
        color: theme.backgroundColor
        radius: 3
        opacity: currentApplet ? 0.5 : 0
        PlasmaCore.IconItem {
            source: "transform-move"
            width: Math.min(parent.width, parent.height)
            height: width
            anchors.centerIn: parent
        }
        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: (plasmoid.formFactor !== PlasmaCore.Types.Vertical) ? parent.bottom : undefined
                right: (plasmoid.formFactor !== PlasmaCore.Types.Vertical) ? undefined : parent.right
            }
            visible: currentApplet && currentApplet.applet.pluginName === "org.kde.plasma.panelspacer"
            opacity: visible && !xAnim.running && !yAnim.running ? 1.0 : 0
            width: configurationArea.spacerHandleSize
            height: configurationArea.spacerHandleSize
            color: theme.textColor
            Behavior on opacity {
                NumberAnimation {
                    duration: units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
        Rectangle {
            anchors {
                right: parent.right
                top: (plasmoid.formFactor !== PlasmaCore.Types.Vertical) ? parent.top : undefined
                bottom: parent.bottom
                left: (plasmoid.formFactor !== PlasmaCore.Types.Vertical) ? undefined : parent.left
            }
            visible: currentApplet && currentApplet.applet.pluginName === "org.kde.plasma.panelspacer"
            opacity: visible && !xAnim.running && !yAnim.running ? 1.0 : 0
            width: configurationArea.spacerHandleSize
            height: configurationArea.spacerHandleSize
            color: theme.textColor
            Behavior on opacity {
                NumberAnimation {
                    duration: units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
        Behavior on x {
            enabled: !configurationArea.pressed
            NumberAnimation {
                id: xAnim
                duration: units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on y {
            id: yAnim
            enabled: !configurationArea.pressed
            NumberAnimation {
                duration: units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on width {
            enabled: !configurationArea.pressed
            NumberAnimation {
                duration: units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on height {
            enabled: !configurationArea.pressed
            NumberAnimation {
                duration: units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
    }
    PlasmaCore.Dialog {
        id: tooltip
        visualParent: currentApplet

        type: PlasmaCore.Dialog.Dock
        flags: Qt.WindowStaysOnTopHint|Qt.WindowDoesNotAcceptFocus|Qt.BypassWindowManagerHint
        location: plasmoid.location

        onVisualParentChanged: {
            if (visualParent) {
                currentApplet.applet.prepareContextualActions();
                alternativesButton.visible = currentApplet.applet.action("alternatives") && currentApplet.applet.action("alternatives").enabled;
                configureButton.visible = currentApplet.applet.action("configure") && currentApplet.applet.action("configure").enabled;
                label.text = currentApplet.applet.title;
            }
        }

        mainItem: MouseArea {
            enabled: currentApplet
            width: handleButtons.width
            height: handleButtons.height
            hoverEnabled: true
            onEntered: hideTimer.stop();
            onExited:  hideTimer.restart();

            ColumnLayout {
                id: handleButtons
                spacing: units.smallSpacing

                PlasmaExtras.Heading {
                    id: label
                    level: 3
                    Layout.fillWidth: true
                    Layout.leftMargin: units.smallSpacing * 2
                    Layout.rightMargin: units.smallSpacing * 2
                }
                PlasmaComponents.ToolButton {
                    Layout.fillWidth: true
                    // we want destructive actions to be far from the initial
                    // cursor position, so show this on the top unless it's on
                    // a top panel
                    visible: tooltip.location !== PlasmaCore.Types.TopEdge
                             && currentApplet.applet.action("remove")
                             && currentApplet.applet.action("remove").enabled
                    iconSource: "delete"
                    text: i18n("Remove")
                    onClicked: {
                        tooltip.visible = false;
                        currentApplet.applet.action("remove").trigger();
                    }
                }
                PlasmaComponents.ToolButton {
                    id: configureButton
                    Layout.fillWidth: true
                    iconSource: "configure"
                    text: i18n("Configure...")
                    onClicked: {
                        tooltip.visible = false;
                        currentApplet.applet.action("configure").trigger()
                    }
                }
                PlasmaComponents.ToolButton {
                    id: alternativesButton
                    Layout.fillWidth: true
                    iconSource: "widget-alternatives"
                    text: i18n("Show Alternatives...")
                    onClicked: {
                        tooltip.visible = false;
                        currentApplet.applet.action("alternatives").trigger()
                    }
                }
                PlasmaComponents.ToolButton {
                    Layout.fillWidth: true
                    // we want destructive actions to be far from the initial
                    // cursor position, so show this on the bottom for top panels
                    visible: tooltip.location === PlasmaCore.Types.TopEdge
                             && currentApplet.applet.action("remove")
                             && currentApplet.applet.action("remove").enabled
                    iconSource: "delete"
                    text: i18n("Remove")
                    onClicked: {
                        tooltip.visible = false;
                        currentApplet.applet.action("remove").trigger();
                    }
                }
            }
        }
    }
}
