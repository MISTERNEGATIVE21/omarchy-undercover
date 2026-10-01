import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "win11-taskview"

  readonly property int barH: root.bar ? root.bar.barSize : 24
  readonly property int tileHeight: barH <= 28 ? (barH - 2) : Math.max(34, barH - 8)
  readonly property int tileWidth: Math.round(tileHeight * 1.25)
  readonly property int iconSize: barH <= 28 ? 16 : Math.round(tileHeight * 0.60)

  property int activeWorkspaceId: 1
  property var workspaceList: [1, 2, 3, 4]

  Process {
    id: wsWatcher
    command: [
      "bash", "-c",
      "hyprctl --batch 'j/activeworkspace ; j/workspaces' 2>/dev/null | jq -s -c '{actWs: (.[0] // {}), allWs: (.[1] // [])}'"
    ]
    running: true
    stdout: SplitParser {
      onRead: function(line) {
        if (!line) return
        try {
          var d = JSON.parse(line.trim())
          if (d.actWs && d.actWs.id) root.activeWorkspaceId = d.actWs.id
          if (Array.isArray(d.allWs)) {
            var ids = d.allWs.map(function(w) { return w.id }).filter(function(id) { return id > 0 && id <= 10 })
            ids.sort(function(a, b) { return a - b })
            if (ids.indexOf(root.activeWorkspaceId) === -1 && root.activeWorkspaceId > 0) {
              ids.push(root.activeWorkspaceId)
              ids.sort(function(a, b) { return a - b })
            }
            if (ids.length === 0) ids = [1]
            root.workspaceList = ids
          }
        } catch(e) {}
      }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: {
      if (!wsWatcher.running) wsWatcher.running = true
    }
  }

  property string homeDir: Quickshell.env("HOME")
  property string configDir: homeDir + "/.config/omarchy/plugins/omarchy-undercover"

  function resolveCmd(cmd) {
    if (!cmd) return ""
    var pluginScripts = root.configDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    return cmd.replace(/\b(omarchy-[a-zA-Z0-9_-]+)\b/g, function(match) {
      return pluginScripts + "/" + match
    })
  }

  function runCmd(cmd) {
    var pluginScripts = root.configDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    var fullCmd = root.resolveCmd(cmd)
    var wrapped = "export PATH=\"" + pluginScripts + ":" + devScripts + ":$PATH\"; " + fullCmd
    Quickshell.execDetached(["bash", "-c", wrapped])
  }

  function seekWorkspace(delta) {
    var wsArg = delta > 0 ? "e-1" : "e+1"
    var cmd = "hyprctl dispatch workspace " + wsArg
    Quickshell.execDetached(["bash", "-c", cmd])
    if (!wsWatcher.running) wsWatcher.running = true
  }

  implicitWidth: root.tileWidth
  implicitHeight: root.tileHeight

  Rectangle {
    id: buttonBox
    anchors.fill: parent
    radius: 4
    color: mouseArea.pressed ? Qt.rgba(1, 1, 1, 0.16) : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
    border.color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
    border.width: 1

    Item {
      anchors.centerIn: parent
      width: Math.round(root.iconSize * 0.88)
      height: Math.round(root.iconSize * 0.88)

      // Back rectangle
      Rectangle {
        x: 0; y: 0
        width: Math.round(parent.width * 0.72)
        height: Math.round(parent.height * 0.72)
        radius: 2
        color: "transparent"
        border.width: 1.6
        border.color: Qt.rgba(1, 1, 1, 0.85)
      }

      // Front rectangle
      Rectangle {
        x: Math.round(parent.width * 0.28)
        y: Math.round(parent.height * 0.28)
        width: Math.round(parent.width * 0.72)
        height: Math.round(parent.height * 0.72)
        radius: 2
        color: Qt.rgba(0, 0.47, 0.83, 0.35)
        border.width: 1.6
        border.color: "#60cdff"
      }
    }

    // Active Desktop Badge
    Rectangle {
      visible: root.workspaceList.length > 1
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: 2
      width: 13
      height: 13
      radius: 6.5
      color: "#60cdff"
      z: 5

      Text {
        anchors.centerIn: parent
        text: root.activeWorkspaceId.toString()
        font.family: "Segoe UI"
        font.pixelSize: 8
        font.bold: true
        color: "#000000"
      }
    }

    // Tooltip
    Rectangle {
      visible: mouseArea.containsMouse
      anchors.bottom: parent.top
      anchors.bottomMargin: 6
      anchors.horizontalCenter: parent.horizontalCenter
      implicitWidth: tipText.implicitWidth + 16
      implicitHeight: 24
      radius: 4
      color: Qt.rgba(0.12, 0.13, 0.17, 0.98)
      border.color: Qt.rgba(1, 1, 1, 0.15)
      border.width: 1
      z: 100

      Text {
        id: tipText
        anchors.centerIn: parent
        text: "Task View · Desktop " + root.activeWorkspaceId + " (Win + Tab)"
        font.family: "Segoe UI"
        font.pixelSize: 11
        color: "#ffffff"
      }
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

      onWheel: function(wheel) {
        root.seekWorkspace(wheel.angleDelta.y)
      }

      onClicked: function(mouse) {
        if (mouse.button === Qt.MiddleButton) {
          Quickshell.execDetached(["bash", "-c", "hyprctl dispatch workspace empty"])
        } else if (mouse.button === Qt.RightButton) {
          root.runCmd("omarchy-win11-taskmanager")
        } else {
          root.runCmd("omarchy-win11-taskview")
        }
      }
    }
  }
}
