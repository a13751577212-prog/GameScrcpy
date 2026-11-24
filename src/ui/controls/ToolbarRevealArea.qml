import QtQuick
import GameScrcpy.Theme

Item {
    id: area

    required property FloatingToolbar toolbar
    property bool active: true
    property bool vertical: false
    property int zoneTop: 0
    property int zoneHeight: Theme.size.toolbarReveal
    property int zoneWidth: Theme.size.toolbarReveal
    property int dwell: Theme.motion.toolbarDwell
    property int cooldown: Theme.motion.toolbarCooldown
    readonly property bool hoveringTop: zoneHover.hovered
    readonly property bool holding: presses.active
    readonly property bool cooling: cooldownTimer.running

    Binding {
        target: area.toolbar
        property: "blocked"
        value: area.holding || area.cooling
    }

    Item {
        x: area.vertical ? parent.width - area.zoneWidth : 0
        y: area.vertical ? 0 : area.zoneTop
        width: area.vertical ? area.zoneWidth : parent.width
        height: area.vertical ? parent.height : area.zoneHeight

        HoverHandler {
            id: zoneHover

            property point last: Qt.point(-1, -1)

            enabled: area.active
            onHoveredChanged: {
                if (hovered)
                    return
                last = Qt.point(-1, -1)
                dwellTimer.stop()
            }
            onPointChanged: {
                const position = point.position
                if (!hovered || (position.x === last.x && position.y === last.y))
                    return
                last = position
                if (!area.holding && !area.cooling)
                    dwellTimer.restart()
            }
        }
    }

    Rectangle {
        id: grip

        objectName: "grip"
        x: area.vertical ? parent.width - (area.zoneWidth + width) / 2 : (parent.width - width) / 2
        y: area.vertical ? (parent.height - height) / 2 : area.zoneTop + Theme.space.xs + Theme.space.xxs
        width: area.vertical ? Theme.size.gripHeight : Theme.size.gripWidth
        height: area.vertical ? Theme.size.gripWidth : Theme.size.gripHeight
        radius: area.vertical ? width / 2 : height / 2
        color: Theme.colors.grip
        opacity: zoneHover.hovered && area.active && !area.holding && !area.toolbar.shown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.motion.fast
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.motion.standard
            }
        }
    }

    Item {
        anchors.centerIn: grip
        width: area.vertical ? Theme.size.gripTargetHeight : Theme.size.gripTargetWidth
        height: area.vertical ? Theme.size.gripTargetWidth : Theme.size.gripTargetHeight

        HoverHandler {
            enabled: area.active
            onHoveredChanged: {
                if (hovered && !area.holding && !area.cooling)
                    area.toolbar.reveal()
            }
        }
    }

    PointHandler {
        id: presses

        acceptedButtons: Qt.AllButtons
        onActiveChanged: {
            if (active) {
                dwellTimer.stop()
                area.toolbar.conceal()
            } else {
                cooldownTimer.restart()
            }
        }
    }

    Timer {
        id: dwellTimer

        interval: area.dwell
        onTriggered: {
            if (area.active && zoneHover.hovered && !area.holding && !area.cooling)
                area.toolbar.reveal()
        }
    }

    Timer {
        id: cooldownTimer

        interval: area.cooldown
    }
}
