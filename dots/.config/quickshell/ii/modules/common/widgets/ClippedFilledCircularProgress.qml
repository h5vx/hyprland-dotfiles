import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell

Item {
    id: root

    property int implicitSize: 18
    property int lineWidth: 2
    property real value: 0
    property color colPrimary: Appearance?.colors.colOnSecondaryContainer ?? "#685496"
    property color colSecondary: ColorUtils.transparentize(colPrimary, 0.5) ?? "#F1D3F9"
    property real gapAngle: 360 / 18
    property bool fill: true
    property int fillOverflow: 2
    property bool enableAnimation: true
    property int animationDuration: 800
    property var easingType: Easing.OutCubic
    property bool accountForLightBleeding: true
    default property Item textMask: Item {
        width: implicitSize
        height: implicitSize
        StyledText {
            anchors.centerIn: parent
            text: Math.round(root.value * 100)
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    property real degree: value * 360
    property real centerX: root.width / 2
    property real centerY: root.height / 2
    property real arcRadius: root.implicitSize / 2 - root.lineWidth / 2 - (0.5 * root.accountForLightBleeding)
    property real startAngle: -90
    // Layers are rendered above device resolution so masks stay sharp with fractional scaling
    property real layerTextureScale: ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1) * 2

    Behavior on degree {
        enabled: root.enableAnimation
        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.easingType
        }

    }

    Rectangle {
        id: contentItem
        anchors.fill: parent
        radius: implicitSize / 2
        color: root.colSecondary
        visible: false
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(Math.ceil(width * root.layerTextureScale), Math.ceil(height * root.layerTextureScale))

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: primaryPath
                pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting
                strokeColor: root.colPrimary
                strokeWidth: root.lineWidth
                capStyle: ShapePath.RoundCap
                fillColor: root.colPrimary

                startX: root.centerX
                startY: root.centerY

                PathAngleArc {
                    moveToStart: false
                    centerX: root.centerX
                    centerY: root.centerY
                    radiusX: root.arcRadius
                    radiusY: root.arcRadius
                    startAngle: root.startAngle
                    sweepAngle: root.degree
                }
                PathLine {
                    x: primaryPath.startX
                    y: primaryPath.startY
                }
            }
        }
    }

    // Holds the mask at its own size, centered, so it isn't stretched to fill the circle
    Item {
        id: maskContainer
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(Math.ceil(width * root.layerTextureScale), Math.ceil(height * root.layerTextureScale))
        data: [root.textMask]
    }
    Binding {
        target: root.textMask
        property: "x"
        value: (maskContainer.width - root.textMask.width) / 2
    }
    Binding {
        target: root.textMask
        property: "y"
        value: (maskContainer.height - root.textMask.height) / 2
    }

    OpacityMask {
        anchors.fill: parent
        source: contentItem
        invert: true
        maskSource: maskContainer
    }
}
