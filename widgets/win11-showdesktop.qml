import QtQuick
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "win11-showdesktop"

  implicitWidth: 12
  implicitHeight: root.bar ? root.bar.barSize : 24

  readonly property bool interactive: true
  readonly property bool pressable: true
  readonly property bool concealed: false

  function triggerPress(button) {
    root.runCmd("omarchy-undercover-show-desktop")
  }

  property var registeredBar: null
  function syncClickRegistration() {
    if (registeredBar && registeredBar.unregisterClickTarget) registeredBar.unregisterClickTarget(root)
    registeredBar = root.bar
    if (registeredBar && registeredBar.registerClickTarget) registeredBar.registerClickTarget(root)
  }
  onBarChanged: syncClickRegistration()
  Component.onCompleted: syncClickRegistration()
  Component.onDestruction: if (registeredBar && registeredBar.unregisterClickTarget) registeredBar.unregisterClickTarget(root)

  readonly property bool isBarLight: {
    if (root.bar && root.bar.foreground !== undefined) {
      var f = root.bar.foreground
      var lumF = 0.299 * f.r + 0.587 * f.g + 0.114 * f.b
      return lumF < 0.5
    }
    return false
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
        root.runCmd("omarchy-undercover-show-desktop")
      }
    }
  }
}
