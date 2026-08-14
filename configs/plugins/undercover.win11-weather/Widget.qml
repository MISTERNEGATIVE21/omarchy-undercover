import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-weather"

  implicitWidth: weatherContainer.implicitWidth
  implicitHeight: root.bar ? root.bar.barSize : 40

  Rectangle {
    id: weatherContainer
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + 16
    implicitHeight: root.bar ? root.bar.barSize - 8 : 32
    radius: 4
    color: weatherMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
    border.color: weatherMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
    border.width: 1

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: "🌤️"
        font.pixelSize: 14
      }

      ColumnLayout {
        spacing: -1
        Text {
          text: "72°F"
          font.family: "Segoe UI"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: root.bar && root.bar.foreground !== undefined ? root.bar.foreground : "#ffffff"
        }
        Text {
          text: "Partly sunny"
          font.family: "Segoe UI"
          font.pixelSize: 9
          color: Qt.rgba(1, 1, 1, 0.7)
        }
      }
    }

    MouseArea {
      id: weatherMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          if (root.bar) {
            root.bar.run("xdg-open https://www.msn.com/weather")
          } else {
            Quickshell.execDetached("xdg-open https://www.msn.com/weather")
          }
        } else {
          if (root.bar) {
            root.bar.run("omarchy-win11-widgets")
          } else {
            Quickshell.execDetached("omarchy-win11-widgets")
          }
        }
      }
    }
  }
}
