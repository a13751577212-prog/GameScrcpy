pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import GameScrcpy.Theme
import GameScrcpy.Controls
import GameScrcpy.Icons
import GameScrcpy.App

Item {
    id: overlay

    property var cells: []
    readonly property var chosen: overlay.cells.find(entry => entry.master === true) ?? null
    readonly property real topInset: titleBar.height
    readonly property int footerHeight: Theme.size.control
    readonly property int edge: 0
    readonly property int gap: Theme.space.sm
    readonly property int margin: Theme.space.sm
    readonly property int inset: 0
    readonly property bool popupOpen: cellMenu.visible || syncDialog.visible || remarkEdit.visible
                                      || sizePanel.visible
    readonly property rect noticeArea: notice.visible ? Qt.rect(notice.x, notice.y, notice.width, notice.height)
                                                      : Qt.rect(0, 0, 0, 0)
    readonly property var syncHues: ["azure", "teal", "rose", "lime", "amber", "orange"].filter(
                                        hue => Theme.toneHues[hue] !== Theme.accentName)
    readonly property bool allFollowChecked: {
        let total = 0
        let checked = 0
        for (const entry of overlay.cells) {
            if (entry.master === true || entry.separate === true)
                continue
            total++
            if (entry.checked === true)
                checked++
        }
        return total > 0 && total === checked
    }

    signal releaseWanted()

    function toast(text, icon) {
        if (notice.visible)
            notice.close()
        notice.iconName = icon ?? ""
        notice.show(text, "info")
    }

    function cellOf(serial: string): var {
        return overlay.cells.find(entry => entry.serial === serial) ?? null
    }

    function hueOf(tone: int): string {
        return tone >= 0 && overlay.syncHues.length > 0 ? overlay.syncHues[tone % overlay.syncHues.length] : ""
    }

    function openMenu(button: Item, serial: string) {
        cellMenu.serial = serial
        const corner = button.mapToItem(overlay, button.width, button.height)
        cellMenu.x = corner.x - cellMenu.width
        cellMenu.y = corner.y + Theme.space.xs
        cellMenu.open()
    }

    function openSync(serial: string) {
        if (serial === "")
            return
        internal.syncSerial = serial
        syncDialog.show()
    }

    function editRemark(serial: string, at: Item) {
        if (serial === "")
            return
        const corner = at.mapToItem(overlay, 0, 0)
        internal.remarkSerial = serial
        remarkEdit.x = corner.x
        remarkEdit.y = corner.y
        remarkEdit.width = at.width
        remarkEdit.height = at.height
        remarkEdit.text = overlay.cellOf(serial)?.remark ?? ""
        remarkEdit.visible = true
        remarkEdit.forceActiveFocus()
        remarkEdit.selectAll()
    }

    function commitRemark() {
        if (!remarkEdit.visible)
            return
        DeviceManager.setDeviceRemark(internal.remarkSerial, remarkEdit.text)
        remarkEdit.visible = false
    }

    function cancelRemark() {
        remarkEdit.visible = false
    }

    objectName: "gridOverlay"
    Window.onWindowChanged: internal.attachChrome()
    Component.onCompleted: internal.attachChrome()
    onCellsChanged: {
        if (cellMenu.visible && overlay.cellOf(cellMenu.serial) === null)
            cellMenu.close()
        if (syncDialog.visible && overlay.cellOf(internal.syncSerial) === null)
            syncDialog.close()
    }

    QtObject {
        id: internal

        property bool chromeAttached: false
        property string syncSerial
        property string remarkSerial

        function attachChrome() {
            if (chromeAttached || overlay.Window.window === null)
                return
            chrome.window = overlay.Window.window
            chromeAttached = chrome.attach()
            if (chromeAttached) {
                for (const control of [titleIcon, retryButton, actions])
                    chrome.setHitTestVisible(control, true)
            }
        }
    }

    Binding {
        target: selectAll
        property: "checked"
        value: overlay.allFollowChecked
    }

    TextField {
        id: remarkEdit

        objectName: "gridRemarkEdit"
        visible: false
        z: 10
        dense: true
        bare: true
        placeholderText: qsTr("Number or name")
        onAccepted: overlay.commitRemark()
        onActiveFocusChanged: {
            if (!activeFocus && visible)
                overlay.cancelRemark()
        }
        Keys.onEscapePressed: overlay.cancelRemark()
    }

    WindowChrome {
        id: chrome

        titleBar: titleBar
        minimizeButton: minimizeButton
        maximizeButton: maximizeButton
        closeButton: closeButton
        darkMode: Theme.dark
    }

    Binding {
        target: overlay.Window.window
        property: "color"
        value: Theme.colors.bgBase
        when: overlay.Window.window !== null
    }

    CommandState {
        id: muteCommand

        command: "device.mute"
        target: cellMenu.serial
    }

    CommandState {
        id: menuFollowCommand

        command: "device.orientation.follow"
        target: cellMenu.serial
    }

    CommandState {
        id: menuPortraitCommand

        command: "device.orientation.portrait"
        target: cellMenu.serial
    }

    CommandState {
        id: menuLandscapeCommand

        command: "device.orientation.landscape"
        target: cellMenu.serial
    }

    Item {
        id: titleBar

        objectName: "gridTitleBar"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Theme.size.control + 2 * Theme.size.stroke

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.size.stroke
            color: Theme.colors.strokeSubtle
        }

        Button {
            id: titleIcon

            objectName: "gridWindowSize"
            anchors.left: parent.left
            anchors.leftMargin: Theme.space.md
            anchors.verticalCenter: parent.verticalCenter
            small: true
            tone: "ghost"
            iconName: "layout-grid"
            text: qsTr("Window sizes")
            onClicked: sizePanel.visible ? sizePanel.close() : sizePanel.open()
        }

        Text {
            id: gridTitle

            objectName: "gridTitle"
            anchors.left: titleIcon.right
            anchors.leftMargin: Theme.space.sm + Theme.space.xxs
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, Math.min(implicitWidth, actions.x - x - Theme.space.md))
            textFormat: Text.PlainText
            text: overlay.Window.window !== null ? overlay.Window.window.title : ""
            elide: Text.ElideRight
            color: Theme.colors.textSecondary
            font.pixelSize: Theme.type.caption.size
            font.weight: Font.Medium
        }

        Button {
            id: retryButton

            objectName: "gridRetry"
            anchors.left: gridTitle.right
            anchors.leftMargin: Theme.space.sm
            anchors.verticalCenter: parent.verticalCenter
            small: true
            tone: "ghost"
            iconName: "refresh-cw"
            text: ""
            toolTip: qsTr("Reconnect disconnected devices")
            onClicked: {
                const count = DeviceManager.retryGridConnections()
                overlay.toast(count > 0 ? qsTr("Reconnecting %1 phone(s)").arg(count)
                                        : qsTr("Nothing to reconnect"))
            }
        }

        Row {
            id: captions

            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height

            CaptionButton {
                id: minimizeButton

                height: parent.height
                glyph: "\uE921"
                onClicked: overlay.Window.window.showMinimized()
            }

            CaptionButton {
                id: maximizeButton

                height: parent.height
                glyph: overlay.Window.visibility === Window.Maximized ? "\uE923" : "\uE922"
                onClicked: {
                    if (overlay.Window.visibility === Window.Maximized)
                        overlay.Window.window.showNormal()
                    else
                        overlay.Window.window.showMaximized()
                }
            }

            CaptionButton {
                id: closeButton

                height: parent.height
                glyph: "\uE8BB"
                destructive: true
                onClicked: overlay.Window.window.close()
            }
        }

        Row {
            id: actions

            anchors.right: captions.left
            anchors.rightMargin: Theme.space.sm
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.space.sm

            Button {
                id: settingsButton

                objectName: "gridSettings"
                anchors.verticalCenter: parent.verticalCenter
                small: true
                tone: "ghost"
                iconName: "settings-2"
                text: ""
                toolTip: qsTr("Settings")
                onClicked: AiAssistant.openSettings()
            }

            Checkbox {
                id: selectAll

                objectName: "gridSelectAll"
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Select all")
                onClicked: DeviceManager.setGridFollowAll(checked)
            }

            Button {
                id: selectNone

                objectName: "gridSelectNone"
                anchors.verticalCenter: parent.verticalCenter
                tone: "ghost"
                small: true
                text: qsTr("Select none")
                onClicked: DeviceManager.setGridFollowAll(false)
            }
        }
    }

    component CellButton: T.AbstractButton {
        id: button

        property string iconName
        property string tip
        property bool selected: false

        width: Theme.size.controlSmall
        height: Theme.size.controlSmall
        hoverEnabled: true
        focusPolicy: Qt.TabFocus
        Accessible.name: tip

        Tooltip {
            y: -Theme.size.tooltip
            text: button.tip
            visible: button.tip !== "" && button.hovered && !button.down
        }

        contentItem: Icon {
            anchors.centerIn: parent
            name: button.iconName
            size: Theme.size.iconSmall
            color: !button.enabled ? Theme.colors.textTertiary
                 : button.selected ? Theme.colors.accentText
                 : button.hovered ? Theme.colors.textPrimary : Theme.colors.textSecondary
        }

        background: Rectangle {
            radius: Theme.radius.xs
            color: button.hovered ? Theme.colors.statePress : "transparent"
        }
    }

    Repeater {
        model: overlay.cells.length

        delegate: Item {
            id: cell

            required property int index
            readonly property var entry: overlay.cells[index] ?? ({})
            readonly property bool chosen: entry.master === true
            readonly property bool away: entry.separate === true
            readonly property real rate: entry.rate ?? -1
            readonly property bool following: !chosen && !away && entry.checked === true
            readonly property bool narrow: width < 300
            readonly property real middleGap: Theme.size.controlSmall * 2 + Theme.space.md

            objectName: "gridCell"
            x: entry.x ?? 0
            y: entry.y ?? 0
            width: entry.width ?? 0
            height: entry.height ?? 0

            CommandState { id: backCommand; command: "device.back"; target: cell.entry.serial ?? "" }
            CommandState { id: homeCommand; command: "device.home"; target: cell.entry.serial ?? "" }
            CommandState { id: recentCommand; command: "device.appSwitch"; target: cell.entry.serial ?? "" }
            CommandState { id: screenCommand; command: "device.screenOff"; target: cell.entry.serial ?? "" }

            Rectangle {
                id: gridFrame

                readonly property color edge: cell.chosen ? Theme.colors.accent
                                           : cell.following ? Theme.colors.info : Theme.colors.strokeSubtle
                objectName: "gridFrame"
                anchors.fill: parent
                radius: Theme.radius.lg
                color: Theme.colors.bgRaised
                border.width: Theme.size.stroke
                border.color: gridFrame.edge
            }

            Rectangle {
                objectName: "gridPicture"

                readonly property real pad: overlay.inset + overlay.edge

                x: pad
                y: pad
                width: Math.max(0, parent.width - 2 * pad)
                height: Math.max(0, parent.height - overlay.footerHeight - 2 * pad)
                topLeftRadius: Math.max(0, Theme.radius.lg - pad)
                topRightRadius: Math.max(0, Theme.radius.lg - pad)
                color: Theme.colors.bgSunken
            }

            Item {
                id: footer

                objectName: "gridFooter"
                y: Math.max(0, parent.height - overlay.footerHeight)
                width: parent.width
                height: overlay.footerHeight

                Rectangle {
                    x: overlay.inset
                    anchors.top: parent.top
                    width: Math.max(0, parent.width - 2 * overlay.inset)
                    height: Theme.size.stroke
                    color: Theme.colors.strokeSubtle
                }

                Rectangle {
                    id: dot

                    objectName: "gridStatusDot"
                    x: Theme.space.md
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.size.pillDot
                    height: width
                    radius: width / 2
                    color: cell.entry.tone === "warn" ? Theme.colors.warning
                         : cell.entry.tone === "ok" ? Theme.colors.success : Theme.colors.textTertiary
                }

                Item {
                    id: labelArea

                    anchors.left: parent.left
                    anchors.leftMargin: Theme.space.md + Theme.size.pillDot + Theme.space.sm
                    anchors.right: buttonRow.left
                    anchors.rightMargin: cell.middleGap
                    anchors.verticalCenter: parent.verticalCenter
                    height: Math.max(0, overlay.footerHeight - 2 * Theme.space.xxs)

                    Text {
                        id: nameText

                        objectName: "gridName"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(0, Math.min(implicitWidth, labelArea.width
                                     - (screenButton.visible ? screenButton.width + Theme.space.xs : 0)))
                        textFormat: Text.PlainText
                        text: {
                            const remark = cell.entry.remark ?? ""
                            return remark !== "" ? remark : (cell.entry.name ?? "")
                        }
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        color: cell.chosen ? Theme.colors.accentText : Theme.colors.textPrimary
                        font.pixelSize: Theme.type.caption.size
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: nameText
                        acceptedButtons: Qt.LeftButton
                        onDoubleClicked: overlay.editRemark(cell.entry.serial ?? "", labelArea)
                    }

                    CellButton {
                        id: screenButton

                        objectName: "gridScreen"
                        visible: !cell.narrow
                        x: Math.max(0, Math.min(nameText.width + Theme.space.xs,
                                   labelArea.width - width))
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "power"
                        tip: screenCommand.title
                        enabled: screenCommand.enabled
                        onClicked: DeviceManager.gridScreen(cell.entry.serial ?? "", !screenCommand.checked)
                    }
                }

                Item {
                    id: midArea

                    anchors.left: labelArea.right
                    anchors.leftMargin: Theme.space.xs
                    anchors.right: buttonRow.left
                    anchors.rightMargin: Theme.space.xs
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height

                    MouseArea {
                        id: midClick

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        onClicked: DeviceManager.toggleGridFollow(cell.entry.serial ?? "")

                        Tooltip {
                            y: -Theme.size.tooltip
                            text: cell.following ? qsTr("Stop following the master")
                                                 : qsTr("Follow the master")
                            visible: midClick.containsMouse && !midClick.pressed
                        }
                    }
                }

                Row {
                    id: buttonRow

                    anchors.right: parent.right
                    anchors.rightMargin: Theme.space.xs
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.space.xxs

                    CellButton {
                        objectName: "gridPaw"
                        iconName: "paw-print"
                        selected: cell.chosen
                        tip: cell.chosen ? qsTr("Stop being the master") : qsTr("Make this the master")
                        onClicked: DeviceManager.setGridMaster(cell.entry.serial ?? "")
                    }

                    CellButton {
                        objectName: "gridBack"
                        iconName: "arrow-left"
                        tip: qsTr("Back")
                        enabled: backCommand.enabled
                        onClicked: DeviceManager.gridNavigation(cell.entry.serial ?? "", "back")
                    }

                    CellButton {
                        objectName: "gridRecents"
                        visible: !cell.narrow
                        iconName: "square"
                        tip: qsTr("Recent apps")
                        enabled: recentCommand.enabled
                        onClicked: DeviceManager.gridNavigation(cell.entry.serial ?? "", "appSwitch")
                    }

                    CellButton {
                        objectName: "gridHome"
                        iconName: "house"
                        tip: qsTr("Home")
                        enabled: homeCommand.enabled
                        onClicked: DeviceManager.gridNavigation(cell.entry.serial ?? "", "home")
                    }

                    CellButton {
                        id: moreButton

                        objectName: "gridMore"
                        iconName: "ellipsis"
                        tip: qsTr("More")
                        onClicked: overlay.openMenu(moreButton, cell.entry.serial ?? "")
                    }

                    CellButton {
                        objectName: "gridExpand"
                        visible: !cell.narrow
                        iconName: "popout"
                        tip: qsTr("Open in its own window")
                        onClicked: DeviceManager.showWindow(cell.entry.serial ?? "")
                    }
                }
            }

            Column {
                objectName: "gridSeparate"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -overlay.footerHeight / 2
                width: Math.max(0, parent.width - 2 * Theme.space.md)
                visible: cell.away
                spacing: Theme.space.sm

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "popout"
                    size: Theme.size.iconLarge
                    color: Theme.colors.textTertiary
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    textFormat: Text.PlainText
                    text: qsTr("In its own window · double-click to bring it back")
                    wrapMode: Text.Wrap
                    color: Theme.colors.textSecondary
                    font.pixelSize: Theme.type.label.size
                    font.weight: Font.Medium
                }
            }
        }
    }

    Column {
        objectName: "gridEmpty"
        anchors.centerIn: parent
        anchors.verticalCenterOffset: overlay.topInset / 2
        visible: overlay.cells.length === 0
        spacing: Theme.space.lg

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "layout-grid"
            size: Theme.size.iconHero
            color: Theme.colors.textTertiary
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            textFormat: Text.PlainText
            text: qsTr("No phone is mirroring")
            color: Theme.colors.textSecondary
            font.pixelSize: Theme.type.body.size
        }
    }

    T.Popup {
        id: sizePanel

        objectName: "gridSizePanel"
        x: Theme.space.md
        y: titleBar.height + Theme.space.xs
        padding: Theme.space.md
        modal: true
        dim: false
        background: PopupSurface {}

        contentItem: Column {
            spacing: Theme.space.md

            Text {
                text: qsTr("Window sizes")
                textFormat: Text.PlainText
                color: Theme.colors.textPrimary
                font.pixelSize: Theme.type.label.size
                font.weight: Font.DemiBold
            }

            Column {
                spacing: Theme.space.xs

                Text {
                    text: qsTr("Grid window size")
                    textFormat: Text.PlainText
                    color: Theme.colors.textSecondary
                    font.pixelSize: Theme.type.caption.size
                }

                Slider {
                    id: gridSizeSlider

                    from: 40
                    to: 100
                    stepSize: 5
                    valueText: Math.round(value) + "%"
                    onMoved: AppSettings.setValue("display.gridWindowShare", Math.round(value))

                    Binding {
                        target: gridSizeSlider
                        property: "value"
                        value: AppSettings.values["display.gridWindowShare"] ?? 80
                    }
                }
            }

            Column {
                spacing: Theme.space.xs

                Text {
                    text: qsTr("Mirror window size")
                    textFormat: Text.PlainText
                    color: Theme.colors.textSecondary
                    font.pixelSize: Theme.type.caption.size
                }

                Slider {
                    id: mirrorSizeSlider

                    from: 40
                    to: 100
                    stepSize: 5
                    valueText: Math.round(value) + "%"
                    onMoved: AppSettings.setValue("display.mirrorWindowShare", Math.round(value))

                    Binding {
                        target: mirrorSizeSlider
                        property: "value"
                        value: AppSettings.values["display.mirrorWindowShare"] ?? 85
                    }
                }
            }

            Text {
                width: Math.max(gridSizeSlider.implicitWidth, mirrorSizeSlider.implicitWidth)
                text: qsTr("Kept after a restart. Open windows change at once.")
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: Theme.colors.textTertiary
                font.pixelSize: Theme.type.caption.size
            }
        }
    }

    Menu {
        id: cellMenu

        property string serial

        objectName: "gridCellMenu"
        modal: true
        dim: false

        MenuItem {
            objectName: "gridMenuVolume"
            iconName: muteCommand.checked ? "volume-x" : "volume-2"
            text: qsTr("Volume")
            description: muteCommand.checked ? qsTr("Muted") : qsTr("Sound on")
            enabled: muteCommand.enabled
            onTriggered: muteCommand.trigger()
        }

        MenuSeparator {}

        Item {
            implicitWidth: orientationLabel.implicitWidth + 2 * (Theme.space.sm + Theme.space.xxs)
            implicitHeight: Theme.size.pill + Theme.space.xs
            height: visible ? implicitHeight : 0
            visible: menuFollowCommand.enabled

            Text {
                id: orientationLabel

                x: Theme.space.sm + Theme.space.xxs
                anchors.bottom: parent.bottom
                textFormat: Text.PlainText
                text: qsTr("Orientation")
                color: Theme.colors.textTertiary
                font.pixelSize: Theme.type.caption.size
                font.weight: Font.DemiBold
            }
        }

        CommandMenuItem {
            objectName: "gridMenuOrientationFollow"
            commandState: menuFollowCommand
            choice: true
        }

        CommandMenuItem {
            objectName: "gridMenuOrientationPortrait"
            commandState: menuPortraitCommand
            choice: true
        }

        CommandMenuItem {
            objectName: "gridMenuOrientationLandscape"
            commandState: menuLandscapeCommand
            choice: true
        }

        MenuSeparator {}

        MenuItem {
            objectName: "gridMenuDisconnect"
            danger: true
            iconName: "x"
            text: qsTr("Disconnect this phone")
            onTriggered: DeviceManager.disconnectDevice(cellMenu.serial)
        }
    }

    SyncDialog {
        id: syncDialog

        serial: internal.syncSerial
        syncing: overlay.cellOf(internal.syncSerial)?.syncRole === "master"
        onNotified: message => overlay.toast(message, "triangle-alert")
    }

    Toast {
        id: notice

        capsule: true
        y: overlay.topInset + Theme.space.sm
    }
}
