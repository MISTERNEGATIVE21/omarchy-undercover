import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-start"

  implicitWidth: 40
  implicitHeight: root.bar ? root.bar.barSize : 44

  Rectangle {
    id: startBtn
    anchors.centerIn: parent
    implicitWidth: 38
    implicitHeight: root.bar ? root.bar.barSize - 6 : 38
    radius: 6
    color: startMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : "transparent"
    border.color: startMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
    border.width: 1

    // Authentic Windows 11 4-Square Vector Grid
    GridLayout {
      anchors.centerIn: parent
      columns: 2
      rowSpacing: 2
      columnSpacing: 2

      Rectangle {
        width: 7
        height: 7
        radius: 1
        color: startMouse.containsMouse ? "#60cdff" : "#0078d4"
      }
      Rectangle {
        width: 7
        height: 7
        radius: 1
        color: startMouse.containsMouse ? "#60cdff" : "#0078d4"
      }
      Rectangle {
        width: 7
        height: 7
        radius: 1
        color: startMouse.containsMouse ? "#60cdff" : "#0078d4"
      }
      Rectangle {
        width: 7
        height: 7
        radius: 1
        color: startMouse.containsMouse ? "#60cdff" : "#0078d4"
      }
    }

    // Tooltip
    Rectangle {
      id: tooltip
      visible: startMouse.containsMouse
      anchors.bottom: parent.top
      anchors.bottomMargin: 6
      anchors.horizontalCenter: parent.horizontalCenter
      implicitWidth: tooltipText.implicitWidth + 14
      implicitHeight: 24
      radius: 5
      color: Qt.rgba(0.13, 0.14, 0.18, 0.96)
      border.color: Qt.rgba(1, 1, 1, 0.15)
      border.width: 1
      z: 100

      Text {
        id: tooltipText
        anchors.centerIn: parent
        text: "Start (Super)"
        font.family: "Segoe UI"
        font.pixelSize: 11
        color: "#ffffff"
      }
    }

    MouseArea {
      id: startMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          if (root.bar) {
            root.bar.run("omarchy-undercover-settings")
          } else {
            Quickshell.execDetached(["omarchy-undercover-settings"])
          }
        } else {
          if (root.bar) {
            root.bar.run("omarchy-win11-start")
          } else {
            Quickshell.execDetached(["omarchy-win11-start"])
          }
        }
      }
    }
  }
}
