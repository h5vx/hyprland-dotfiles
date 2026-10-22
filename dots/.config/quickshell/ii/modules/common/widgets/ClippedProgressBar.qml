import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell

/**
 * A progress bar with both ends rounded and text acts as clipping like OneUI 7's battery indicator.
 */
ProgressBar {
    id: root
    property bool vertical: false
    property real valueBarWidth: 30
    property real valueBarHeight: 18
    property color highlightColor: Appearance?.colors.colOnSecondaryContainer ?? "#685496"
    property color trackColor: ColorUtils.transparentize(highlightColor, 0.5) ?? "#F1D3F9"
    property alias radius: contentItem.radius
    property string text
    // Layers are rendered above device resolution so masks stay sharp with fractional scaling
    property real layerTextureScale: ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1) * 2
    default property Item textMask: Item {
        width: valueBarWidth
        height: valueBarHeight
        StyledText {
            anchors.centerIn: parent
            font: root.font
            text: root.text
        }
    }

    text: Math.round(value * 100)
    font {
        pixelSize: 13
        weight: text.length > 2 ? Font.Medium : Font.DemiBold
    }

    background: Item {
        implicitHeight: valueBarHeight
        implicitWidth: valueBarWidth
    }

    contentItem: Rectangle {
        id: contentItem
        anchors.fill: parent
        radius: 9999
        color: root.trackColor
        visible: false
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(Math.ceil(width * root.layerTextureScale), Math.ceil(height * root.layerTextureScale))

        Rectangle {
            id: progressFill
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: undefined
            }
            width: parent.width * root.visualPosition
            height: parent.height

            states: State {
                name: "vertical"
                when: root.vertical
                AnchorChanges {
                    target: progressFill
                    anchors {
                        top: undefined
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }
                }
                PropertyChanges {
                    target: progressFill
                    width: parent.width
                    height: parent.height * root.visualPosition
                }
            }

            radius: Appearance.rounding.unsharpen
            color: root.highlightColor
        }
    }

    OpacityMask {
        id: roundingMask
        visible: false
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(Math.ceil(width * root.layerTextureScale), Math.ceil(height * root.layerTextureScale))
        source: contentItem
        maskSource: Rectangle {
            width: contentItem.width
            height: contentItem.height
            radius: contentItem.radius
        }
    }

    Item {
        id: textMaskContainer
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(Math.ceil(width * root.layerTextureScale), Math.ceil(height * root.layerTextureScale))
        data: [root.textMask]
    }

    OpacityMask {
        anchors.fill: parent
        source: roundingMask
        invert: true
        maskSource: textMaskContainer
    }
}
