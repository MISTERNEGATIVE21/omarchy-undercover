import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-taskbar"

  implicitWidth: taskbarRow.implicitWidth + 8
  implicitHeight: root.bar ? root.bar.barSize : 44

  property bool showSearch: true
  property string searchMode: "icon" // "box", "icon", "hidden"
  property bool showTaskView: true
  property bool showCopilot: true

  function runCmd(cmd) {
    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  // Windows 11 Fluent App Definitions with original vector icon assets
  property var winApps: [
    { id: "start", name: "Start", isStart: true, iconFile: "start.svg", exec: "omarchy-win11-start", running: false, visible: true },
    { id: "search", name: "Search", isSearch: true, iconFile: "search.svg", exec: "omarchy-undercover-launcher", running: false, visible: root.showSearch && root.searchMode !== "hidden" },
    { id: "taskview", name: "Task View", isTaskView: true, iconFile: "taskview.svg", exec: "rofi -show window -theme ~/.config/rofi/windows11.rasi", running: false, visible: root.showTaskView },
    { id: "copilot", name: "Copilot", iconFile: "copilot.png", exec: "xdg-terminal-exec", running: false, visible: root.showCopilot },
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
        implicitWidth: modelData.isSearch && root.searchMode === "box" ? 140 : 40
        implicitHeight: root.bar ? root.bar.barSize - 6 : 38
        radius: modelData.isSearch && root.searchMode === "box" ? 19 : 4
        color: modelData.isSearch && root.searchMode === "box"
               ? (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))
               : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : "transparent")
        border.color: modelData.isSearch && root.searchMode === "box"
                      ? Qt.rgba(1, 1, 1, 0.10)
                      : (itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
        border.width: 1

        // 1. Windows 11 Start Icon (Authentic Vector 4-Square Grid)
        Item {
          visible: modelData.isStart === true
          anchors.fill: parent

          GridLayout {
            anchors.centerIn: parent
            columns: 2
            rowSpacing: 2
            columnSpacing: 2

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
          visible: !modelData.isStart && !(modelData.isSearch && root.searchMode === "box")
          anchors.fill: parent

          Image {
            anchors.centerIn: parent
            width: modelData.isSearch || modelData.isTaskView ? 20 : 24
            height: modelData.isSearch || modelData.isTaskView ? 20 : 24
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
            width: 16
            height: 3
            radius: 1.5
            color: "#60cdff"
          }
        }

        // 3. Optional Search Pill Mode (when searchMode is "box")
        RowLayout {
          visible: modelData.isSearch && root.searchMode === "box"
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          spacing: 8

          Image {
            width: 16
            height: 16
            source: "/home/mister/.local/share/icons/win11/search.svg"
            sourceSize.width: 24
            sourceSize.height: 24
            fillMode: Image.PreserveAspectFit
          }

          Text {
            text: "Search"
            font.family: "Segoe UI"
            font.pixelSize: 11
            color: Qt.rgba(1, 1, 1, 0.6)
            Layout.fillWidth: true
          }
        }

        // Tooltip showing clean app name on hover
        Rectangle {
          id: tooltip
          visible: itemMouse.containsMouse && !(modelData.isSearch && root.searchMode === "box")
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
