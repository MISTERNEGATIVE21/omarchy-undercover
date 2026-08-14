import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-search"

  implicitWidth: searchBox.implicitWidth
  implicitHeight: root.bar ? root.bar.barSize : 38

  Rectangle {
    id: searchBox
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: 160
    implicitHeight: root.bar ? root.bar.barSize - 10 : 28
    radius: 14
    color: mouseArea.containsMouse ? (root.bar && root.bar.hoverBackground !== undefined ? root.bar.hoverBackground : Qt.rgba(1, 1, 1, 0.12)) : (root.bar && root.bar.widgetBackground !== undefined ? root.bar.widgetBackground : Qt.rgba(1, 1, 1, 0.06))
    border.color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)
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
        opacity: 0.7
      }

      Text {
        text: "Search"
        font.family: root.bar && root.bar.fontFamily !== undefined ? root.bar.fontFamily : "sans-serif"
        font.pixelSize: 11
        color: root.bar && root.bar.foreground !== undefined ? root.bar.foreground : "#ffffff"
        opacity: 0.6
        Layout.fillWidth: true
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.IBeamCursor
      onClicked: {
        if (root.bar) {
          root.bar.run("omarchy-undercover-launcher")
        } else {
          Quickshell.execDetached(["omarchy-undercover-launcher"])
        }
      }
    }
  }
}
