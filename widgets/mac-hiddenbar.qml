import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "mac-hiddenbar"

  readonly property int contentWidth: Style.bar.iconSlot > 0 ? Style.bar.iconSlot : 22
  implicitWidth: contentWidth
  implicitHeight: root.bar ? root.bar.barSize : 28

  readonly property string stateHome: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
  readonly property string statePath: stateHome + "/omarchy/undercover/hiddenbar_state"
  property bool isCollapsed: false

  function updateState() {
    var raw = stateFile.text().trim()
    root.isCollapsed = (raw === "collapsed")
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onLoaded: root.updateState()
    onFileChanged: { reload(); root.updateState() }
  }

  Component.onCompleted: updateState()

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

  function toggle() {
    root.runCmd("omarchy-undercover-hiddenbar --toggle")
  }

  function showDesktop() {
    root.runCmd("omarchy-undercover-show-desktop")
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: " "
    labelVisible: false
    fixedWidth: root.contentWidth
    tooltipText: root.isCollapsed
      ? "Unhide Menu Bar Items (Hidden Bar)\n• Click: Show Hidden Icons\n• Right-Click: Toggle Show Desktop"
      : "Hide Menu Bar Items (Hidden Bar)\n• Click: Hide Extra Icons\n• Right-Click: Toggle Show Desktop"

    onPressed: function(btn) {
      if (btn === Qt.RightButton) {
        root.showDesktop()
      } else {
        root.toggle()
      }
    }

    Text {
      anchors.centerIn: parent
      text: root.isCollapsed ? "󰅂" : "󰅁"
      font.pixelSize: 13
      font.weight: Font.DemiBold
      color: button.active ? Color.accent : (root.bar ? root.bar.foreground : "#ffffff")
      opacity: button.containsMouse ? 1.0 : 0.82

      Behavior on opacity {
        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
      }
    }
  }
}
