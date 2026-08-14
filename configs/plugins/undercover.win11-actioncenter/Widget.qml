import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-actioncenter"

  implicitWidth: pillContainer.implicitWidth
  implicitHeight: root.bar ? root.bar.barSize : 40

  Rectangle {
    id: pillContainer
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + 16
    implicitHeight: root.bar ? root.bar.barSize - 8 : 32
    radius: 4
    color: pillMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    border.color: pillMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
    border.width: 1

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 8

      Text {
        text: "󰤨"
        font.pixelSize: 13
        color: root.bar && root.bar.foreground !== undefined ? root.bar.foreground : "#ffffff"
      }

      Text {
        text: "󰕾"
        font.pixelSize: 13
        color: root.bar && root.bar.foreground !== undefined ? root.bar.foreground : "#ffffff"
      }

      Text {
        text: "󰁹"
        font.pixelSize: 14
        color: root.bar && root.bar.foreground !== undefined ? root.bar.foreground : "#ffffff"
      }
    }

    MouseArea {
      id: pillMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        if (root.bar) {
          root.bar.run("omarchy-win11-actioncenter")
        } else {
          Quickshell.execDetached("omarchy-win11-actioncenter")
        }
      }
    }
  }
}
