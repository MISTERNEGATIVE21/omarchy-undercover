import QtQuick
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-showdesktop"

  implicitWidth: 8
  implicitHeight: root.bar ? root.bar.barSize : 40

  Rectangle {
    anchors.fill: parent
    anchors.topMargin: 6
    anchors.bottomMargin: 6
    color: sliverMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : "transparent"
    radius: 2

    // 1px left separator line
    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 1
      color: Qt.rgba(1, 1, 1, 0.12)
    }

    MouseArea {
      id: sliverMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.ArrowCursor
      onClicked: {
        if (root.bar) {
          root.bar.run("omarchy-undercover-show-desktop")
        } else {
          Quickshell.execDetached(["omarchy-undercover-show-desktop"])
        }
      }
    }
  }
}
