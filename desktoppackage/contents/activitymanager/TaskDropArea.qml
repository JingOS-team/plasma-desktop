/*
 *   Copyright (C) 2020 Ivan Cukic <ivan.cukic(at)kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License version 2,
 *   or (at your option) any later version, as published by the Free
 *   Software Foundation
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.0

import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.draganddrop 2.0 as DND

DND.DropArea {
    id: root

    signal taskDropped(variant mimeData, variant modifiers)
    signal clicked()
    signal entered()

    property int topPadding: 0
    property string activityName: ""
    property bool selected: false
    property string actionTitle: ""
    property bool isHovered: false
    property bool actionVisible: false

    PlasmaComponents.Highlight {
        id: dropHighlight
        anchors {
            fill: parent
            // topMargin: icon.height + 3 * units.smallSpacing
            topMargin: root.topPadding
        }
        visible: root.isHovered
        z: -1
    }

    Text {
        id: dropAreaLeftText
        anchors {
            fill: dropHighlight
            leftMargin: units.largeSpacing
            rightMargin: units.largeSpacing
        }

        color: theme.textColor
        visible: root.actionVisible

        text: root.actionTitle
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        maximumLineCount: 3
    }

    anchors {
        left: parent.left
        right: parent.horizontalCenter
        top: parent.top
        bottom: parent.bottom
    }

    preventStealing: true
    enabled: true

    onDrop: {
        root.taskDropped(event.mimeData, event.modifiers);
    }

    onDragEnter: {
        root.isHovered = true;
    }

    onDragLeave: {
        root.isHovered = false;
    }

    MouseArea {
        anchors.fill : parent
        onClicked    : root.clicked()
        hoverEnabled : true
        onEntered    : root.entered()

        Accessible.name          : root.activityName
        Accessible.role          : Accessible.Button
        Accessible.selected      : root.selected
        Accessible.onPressAction : root.clicked()
    }
}
