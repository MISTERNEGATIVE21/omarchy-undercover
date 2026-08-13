import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-search"

  implicitWidth: 160
  implicitHeight: root.bar ? root.bar.barSize : 26

  Rectangle {
    id: bg
    anchors.fill: parent
    anchors.margins: 2
    radius: 8
    color: mouseArea.containsMouse ? (root.bar && root.bar.hoverBackground !== undefined ? root.bar.hoverBackground : Qt.rgba(1, 1, 1, 0.14)) : Qt.rgba(1, 1, 1, 0.07)
    border.color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.10)
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      spacing: 6

      Text {
        text: "🔍"
        font.pixelSize: 11
        color: root.bar && root.bar.foreground !== undefined ? root.bar.foreground : "#ffffff"
      }

      Text {
        text: "Search"
        font.family: root.bar && root.bar.fontFamily !== undefined ? root.bar.fontFamily : "Segoe UI"
        font.pixelSize: 11.5
        color: Qt.rgba(1, 1, 1, 0.65)
        Layout.fillWidth: true
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: function() {
        if (root.bar) {
          root.bar.run("omarchy-undercover-launcher")
        } else {
          Quickshell.execDetached("omarchy-undercover-launcher")
        }
      }
    }
  }
}
