import QtQuick
import QtQuick.Effects
import GameScrcpy.Theme

Item {
    id: toolbar

    default property alias content: row.data
    property bool vertical: false
    property bool pinned: false
    property bool blocked: false
    property bool flat: false
    property int hideDelay: Theme.motion.toolbarHideDelay
    readonly property bool shown: internal.revealed
    readonly property bool hovered: hover.hovered

    function reveal() {
        if (blocked)
            return
        internal.revealed = true
        internal.schedule()
    }

    function conceal() {
        if (pinned || hovered)
            return
        idle.stop()
        internal.revealed = false
    }

    function distribute() {
        const from = vertical ? row : column
        const to = vertical ? column : row
        const items = []
        for (let i = 0; i < from.children.length; ++i)
            items.push(from.children[i])
        for (const item of items) {
            item.parent = to
            if (vertical)
                item.x = 0
            else
                item.y = 0
        }
    }

    implicitWidth: (vertical ? column.implicitWidth : row.implicitWidth) + 2 * Theme.space.xs
    implicitHeight: vertical ? column.implicitHeight + 2 * Theme.space.xs : Theme.size.toolbar
    opacity: internal.revealed ? 1 : 0
    visible: opacity > 0

    Accessible.role: Accessible.ToolBar

    onVerticalChanged: distribute()
    Component.onCompleted: distribute()

    onPinnedChanged: internal.schedule()
    onHideDelayChanged: internal.schedule()
    onHoveredChanged: {
        if (hovered && visible && !blocked)
            internal.revealed = true
        internal.schedule()
    }

    Behavior on opacity {
        id: fade

        NumberAnimation {
            duration: fade.targetValue > 0 ? Theme.motion.fast : Theme.motion.base
            easing.type: Easing.BezierSpline
            easing.bezierCurve: fade.targetValue > 0 ? Theme.motion.standard : Theme.motion.exit
        }
    }

    QtObject {
        id: internal

        property bool revealed: false

        function schedule() {
            if (revealed && !toolbar.pinned && !toolbar.hovered)
                idle.restart()
            else
                idle.stop()
        }
    }

    Timer {
        id: idle

        interval: toolbar.hideDelay
        onTriggered: toolbar.conceal()
    }

    HoverHandler {
        id: hover
    }

    Item {
        anchors.fill: parent
        transform: Translate {
            x: toolbar.vertical ? (toolbar.opacity - 1) * (Theme.space.xs + Theme.space.xxs) : 0
            y: toolbar.vertical ? 0 : (toolbar.opacity - 1) * (Theme.space.xs + Theme.space.xxs)
        }

        RectangularShadow {
            anchors.fill: face
            visible: !toolbar.flat
            radius: face.radius
            offset.y: Theme.shadow.keyOffset
            blur: Theme.shadow.keyBlur
            color: Theme.shadow.key
        }

        Rectangle {
            id: face

            objectName: "face"
            anchors.fill: parent
            visible: !toolbar.flat
            radius: toolbar.vertical ? width / 2 : height / 2
            color: Theme.reducedTransparency ? Theme.colors.bgElevated : Theme.colors.bgFrosted
            border.width: Theme.size.stroke
            border.color: Theme.colors.strokeStrong
        }

        Row {
            id: row

            anchors.centerIn: parent
            spacing: Theme.space.xxs
        }

        Column {
            id: column

            anchors.centerIn: parent
            spacing: Theme.space.xxs
        }
    }
}
