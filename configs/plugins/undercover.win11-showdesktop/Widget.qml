import QtQuick
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-showdesktop"

  implicitWidth: 12
  implicitHeight: root.bar ? root.bar.barSize : 24

  readonly property bool isBarLight: {
    if (root.bar && root.bar.foreground !== undefined) {
      var f = root.bar.foreground
      var lumF = 0.299 * f.r + 0.587 * f.g + 0.114 * f.b
      return lumF < 0.5
    }
    return false
  }

  Rectangle {
    anchors.fill: parent
    anchors.topMargin: 4
    anchors.bottomMargin: 4
    color: sliverMouse.containsMouse ? (root.isBarLight ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.18)) : "transparent"
    radius: 2

    // 1px left separator line
    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 1
      color: root.isBarLight ? Qt.rgba(0, 0, 0, 0.18) : Qt.rgba(1, 1, 1, 0.18)
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
