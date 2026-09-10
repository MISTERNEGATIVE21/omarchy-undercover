import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.mac-controlcenter"

  readonly property int contentWidth: Style.bar.iconSlot > 0 ? Style.bar.iconSlot : 28

  implicitWidth: contentWidth
  implicitHeight: root.bar ? root.bar.barSize : 28

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: " "
    labelVisible: false
    fixedWidth: root.contentWidth
    tooltipText: "Control Center"

    onPressed: function() {
      if (root.bar) {
        root.bar.run("omarchy-mac-controlcenter")
      } else {
        Quickshell.execDetached(["omarchy-mac-controlcenter"])
      }
    }

    // Vector macOS Control Center Icon (Two horizontal toggle capsules)
    Item {
      anchors.centerIn: parent
      width: 16
      height: 14

      readonly property color iconColor: button.active ? Color.accent : (root.bar ? root.bar.foreground : "#ffffff")

      // Top Capsule (Knob on right)
      Rectangle {
        id: topCapsule
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 6
        radius: 3
        color: "transparent"
        border.color: parent.iconColor
        border.width: 1.2

        Rectangle {
          anchors.right: parent.right
          anchors.rightMargin: 1
          anchors.verticalCenter: parent.verticalCenter
          width: 4
          height: 4
          radius: 2
          color: parent.border.color
        }
      }

      // Bottom Capsule (Knob on left)
      Rectangle {
        id: bottomCapsule
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 6
        radius: 3
        color: "transparent"
        border.color: parent.iconColor
        border.width: 1.2

        Rectangle {
          anchors.left: parent.left
          anchors.leftMargin: 1
          anchors.verticalCenter: parent.verticalCenter
          width: 4
          height: 4
          radius: 2
          color: parent.border.color
        }
      }
    }
  }
}
