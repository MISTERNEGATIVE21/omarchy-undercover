import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-weather"

  implicitWidth: weatherContainer.implicitWidth
  implicitHeight: root.bar ? root.bar.barSize : 40

  property bool showWeather: true

  Rectangle {
    id: weatherContainer
    visible: root.showWeather
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + 14
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

    // Hover tooltip with full weather details
    Rectangle {
      id: tooltip
      visible: weatherMouse.containsMouse
      anchors.bottom: parent.top
      anchors.bottomMargin: 6
      anchors.left: parent.left
      implicitWidth: tooltipText.implicitWidth + 12
      implicitHeight: 24
      radius: 5
      color: Qt.rgba(0.15, 0.16, 0.20, 0.96)
      border.color: Qt.rgba(1, 1, 1, 0.15)
      border.width: 1
      z: 100

      Text {
        id: tooltipText
        anchors.centerIn: parent
        text: "Widgets • 72°F Partly Sunny • MSN Weather"
        font.family: "Segoe UI"
        font.pixelSize: 10.5
        color: "#ffffff"
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
