import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-taskbar"

  implicitWidth: taskbarRow.implicitWidth + 8
  implicitHeight: root.bar ? root.bar.barSize : 44

  function runCmd(cmd) {
    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  // Windows 11 Taskbar Apps (Clean, polished, authentic Fluent SVG assets)
  property var winApps: [
    { id: "start", name: "Start", isStart: true, iconFile: "start.svg", exec: "omarchy-win11-start", running: false, visible: true },
    { id: "taskview", name: "Task View", isTaskView: true, iconFile: "taskview.svg", exec: "rofi -show window -theme ~/.config/rofi/windows11.rasi", running: false, visible: true },
    { id: "explorer", name: "File Explorer", iconFile: "explorer.svg", exec: "nautilus computer:/// || thunar || dolphin", running: true, visible: true },
    { id: "browser", name: "Microsoft Edge", iconFile: "edge.svg", exec: "xdg-open https://microsoft.com || firefox || google-chrome-stable", running: true, visible: true },
    { id: "terminal", name: "Terminal", iconFile: "terminal.svg", exec: "xdg-terminal-exec", running: true, visible: true },
    { id: "notepad", name: "Notepad", iconFile: "notepad.svg", exec: "gedit || kate || mousepad || gnome-text-editor", running: false, visible: true },
    { id: "settings", name: "Settings", iconFile: "settings.svg", exec: "omarchy-undercover-settings", running: false, visible: true }
  ]

  RowLayout {
    id: taskbarRow
    anchors.centerIn: parent
    spacing: 3

    Repeater {
      model: root.winApps

      Rectangle {
        id: itemBox
        visible: modelData.visible
        implicitWidth: 42
        implicitHeight: root.bar ? root.bar.barSize - 6 : 38
        radius: 5

        color: itemMouse.pressed
               ? Qt.rgba(1, 1, 1, 0.14)
               : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
        border.color: itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
        border.width: 1

        scale: itemMouse.pressed ? 0.95 : (itemMouse.containsMouse ? 1.05 : 1.0)
        Behavior on scale {
          NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        // 1. Windows 11 Start Icon (Authentic Vector 4-Square Grid)
        Item {
          visible: modelData.isStart === true
          anchors.fill: parent

          GridLayout {
            anchors.centerIn: parent
            columns: 2
            rowSpacing: 2.2
            columnSpacing: 2.2

            Rectangle {
              width: 7.5
              height: 7.5
              radius: 1.2
              color: itemMouse.containsMouse ? "#60cdff" : "#0078d4"
            }
            Rectangle {
              width: 7.5
              height: 7.5
              radius: 1.2
              color: itemMouse.containsMouse ? "#60cdff" : "#0078d4"
            }
            Rectangle {
              width: 7.5
              height: 7.5
              radius: 1.2
              color: itemMouse.containsMouse ? "#60cdff" : "#0078d4"
            }
            Rectangle {
              width: 7.5
              height: 7.5
              radius: 1.2
              color: itemMouse.containsMouse ? "#60cdff" : "#0078d4"
            }
          }
        }

        // 2. Icon-Only Display with Authentic Windows 11 SVGs
        Item {
          visible: !modelData.isStart
          anchors.fill: parent

          Image {
            anchors.centerIn: parent
            width: modelData.isTaskView ? 20 : 24
            height: modelData.isTaskView ? 20 : 24
            source: "/home/mister/.local/share/icons/win11/" + modelData.iconFile
            sourceSize.width: 48
            sourceSize.height: 48
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
          }

          // Active Running Indicator Bar (Windows 11 blue indicator pill)
          Rectangle {
            visible: modelData.running
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: itemMouse.containsMouse ? 20 : 16
            height: 3
            radius: 1.5
            color: "#60cdff"
            Behavior on width {
              NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
          }
        }

        // Tooltip showing clean app name on hover
        Rectangle {
          id: tooltip
          visible: itemMouse.containsMouse
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
            text: modelData.name
            font.family: "Segoe UI"
            font.pixelSize: 11
            color: "#ffffff"
          }
        }

        MouseArea {
          id: itemMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: function(mouse) {
            if (modelData.isStart) {
              if (mouse.button === Qt.RightButton) {
                root.runCmd("omarchy-undercover-settings")
              } else {
                root.runCmd("omarchy-win11-start")
              }
            } else {
              root.runCmd(modelData.exec)
            }
          }
        }
      }
    }
  }
}
