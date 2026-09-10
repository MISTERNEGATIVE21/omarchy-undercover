import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-siri"

  readonly property int slotWidth: Style.bar.iconSlot > 0 ? Style.bar.iconSlot : 28
  implicitWidth: slotWidth
  implicitHeight: root.bar ? root.bar.barSize : 28

  property bool isHovered: mouseArea.containsMouse
  property bool isListening: false

  Item {
    id: siriOrb
    anchors.centerIn: parent
    width: 20
    height: 20
    scale: root.isHovered ? 1.18 : 1.0

    Behavior on scale {
      NumberAnimation { duration: 150; easing.type: Easing.OutBack }
    }

    // Outer Glow Ring (Magenta / Pink)
    Rectangle {
      anchors.centerIn: parent
      width: 18
      height: 18
      radius: 9
      color: "transparent"
      border.color: "#ff2d55"
      border.width: 1.5
      opacity: 0.85
      rotation: ringRot.angle

      RotationAnimation on rotation {
        id: ringRot
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 4500
      }
    }

    // Secondary Ring (Cyan / Blue)
    Rectangle {
      anchors.centerIn: parent
      width: 15
      height: 15
      radius: 7.5
      color: "transparent"
      border.color: "#00f2fe"
      border.width: 1.5
      opacity: 0.80
      rotation: ringRot2.angle

      RotationAnimation on rotation {
        id: ringRot2
        loops: Animation.Infinite
        from: 360
        to: 0
        duration: 3200
      }
    }

    // Center Core (Purple / Indigo)
    Rectangle {
      anchors.centerIn: parent
      width: 11
      height: 11
      radius: 5.5
      color: Qt.rgba(0.35, 0.34, 0.84, 0.85)

      SequentialAnimation on opacity {
        loops: Animation.Infinite
        NumberAnimation { from: 0.6; to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
        NumberAnimation { from: 1.0; to: 0.6; duration: 1200; easing.type: Easing.InOutQuad }
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      if (root.bar) root.bar.showTooltip(root, "Siri (Ask anything or dictate)")
    }
    onExited: {
      if (root.bar) root.bar.hideTooltip(root)
    }

    onClicked: {
      if (root.bar) {
        root.bar.hideTooltip(root)
        root.bar.run("omarchy-mac-siri")
      } else {
        Quickshell.execDetached(["omarchy-mac-siri"])
      }
    }
  }
}