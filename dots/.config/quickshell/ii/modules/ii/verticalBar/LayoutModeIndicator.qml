import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Layout mode (dwindle/floating/scrolling) of the focused workspace, as written by the
 * ~/.config/hypr/custom/layoutmodes.lua Hyprland module. Hidden when that module isn't in use.
 * Click to cycle the mode.
 */
MouseArea {
    id: root
    readonly property bool hovered: containsMouse
    property var modes: ({})
    property bool available: false
    readonly property string mode: root.modes[Hyprland.focusedWorkspace?.id] ?? "dwindle"
    readonly property var icons: ({
        "dwindle": "view_quilt",
        "floating": "filter_none",
        "scrolling": "view_week"
    })

    visible: available
    implicitWidth: Appearance.sizes.verticalBarWidth
    implicitHeight: modeIcon.implicitHeight + 4
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onClicked: Hyprland.dispatch("function() require('custom.layoutmodes').cycleMode() end")

    function parse(text) {
        const parsed = {};
        for (const line of text.split("\n")) {
            const match = line.match(/^(-?\d+) (\w+)$/);
            if (match)
                parsed[parseInt(match[1])] = match[2];
        }
        root.modes = parsed;
    }

    FileView {
        id: stateFile
        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/hypr-layoutmodes`
        watchChanges: true
        onFileChanged: this.reload()
        onLoaded: {
            root.available = true;
            root.parse(stateFile.text());
        }
        onLoadFailed: root.available = false
    }

    MaterialSymbol {
        id: modeIcon
        anchors.centerIn: parent
        text: root.icons[root.mode] ?? "view_quilt"
        iconSize: Appearance.font.pixelSize.large
        color: root.mode === "dwindle" ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
    }

    PopupToolTip {
        text: Translation.tr("Layout: %1").arg(root.mode)
    }
}
