import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover"

  property string homeDir: Quickshell.env("HOME")
  property string configDir: homeDir + "/.config/omarchy-undercover"
  property string statePath: configDir + "/state"
  property string settingsPath: configDir + "/settings.conf"
  property string activeState: "mac-dark"
  property string currentMode: "mac" // "mac", "win11", "omarchy"
  property bool isLight: false
  property bool isAutohide: false
  property bool isTransparent: true
  property real activeOpacity: 0.95

  function updateFromState() {
    var raw = stateFile.text().trim()
    if (!raw) raw = "mac-dark"
    root.activeState = raw
    root.isLight = (raw.indexOf("light") !== -1)

    if (raw.indexOf("mac") !== -1 || raw.indexOf("apple") !== -1) {
      root.currentMode = "mac"
    } else if (raw.indexOf("win") !== -1) {
      root.currentMode = "win11"
    } else {
      root.currentMode = "omarchy"
    }
  }

  function updateFromSettings() {
    var raw = settingsFile.text()
    if (!raw) return
    var lines = raw.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line.indexOf("AUTOHIDE=") === 0) {
        root.isAutohide = (line.indexOf("true") !== -1 || line.indexOf("1") !== -1)
      } else if (line.indexOf("BAR_TRANSPARENT=") === 0) {
        root.isTransparent = (line.indexOf("true") !== -1)
      } else if (line.indexOf("ACTIVE_OPACITY=") === 0) {
        var op = parseFloat(line.substring(15))
        if (!isNaN(op)) root.activeOpacity = op
      }
    }
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    onLoaded: root.updateFromState()
    onFileChanged: { reload(); root.updateFromState() }
  }

  FileView {
    id: settingsFile
    path: root.settingsPath
    watchChanges: true
    onLoaded: root.updateFromSettings()
    onFileChanged: { reload(); root.updateFromSettings() }
  }

  Component.onCompleted: {
    updateFromState()
    updateFromSettings()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("widget" in target) target.widget = root
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  function switchMode(targetMode) {
    var cmd = "omarchy-undercover"
    if (targetMode === "mac-dark") cmd = "omarchy-undercover -mac"
    else if (targetMode === "mac-light") cmd = "omarchy-undercover -mac-light"
    else if (targetMode === "win11-dark") cmd = "omarchy-undercover -w11"
    else if (targetMode === "win11-light") cmd = "omarchy-undercover -w11-light"
    else if (targetMode === "omarchy") cmd = "omarchy-undercover --disable"
    else if (targetMode === "toggle") cmd = "omarchy-undercover --toggle"
    else if (targetMode === "next") {
      if (root.currentMode === "mac") cmd = "omarchy-undercover -w11"
      else if (root.currentMode === "win11") cmd = "omarchy-undercover --disable"
      else cmd = "omarchy-undercover -mac"
    }

    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  IpcHandler {
    target: "undercover"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
    function mac(): void { root.switchMode("mac-dark") }
    function macLight(): void { root.switchMode("mac-light") }
    function win11(): void { root.switchMode("win11-dark") }
    function win11Light(): void { root.switchMode("win11-light") }
    function omarchy(): void { root.switchMode("omarchy") }
    function next(): void { root.switchMode("next") }
    function toggleMode(): void { root.switchMode("toggle") }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.opened
    horizontalMargin: 8
    verticalPadding: 5

    tooltipText: "Omarchy Undercover (" + (root.currentMode === "mac" ? "Apple macOS Sequoia" : (root.currentMode === "win11" ? "Windows 11 Fluent" : "Default Omarchy")) + ")\n• Left-Click: Open Undercover Control Center\n• Right-Click: Fast-Cycle Camouflage\n• Middle-Click: Toggle Disguise On/Off"

    onWheelMoved: function(delta) {
      if (delta > 0) {
        root.switchMode("next")
      } else if (delta < 0) {
        root.switchMode("toggle")
      }
    }

    onPressed: function(btn) {
      if (btn === Qt.RightButton) {
        root.switchMode("next")
      } else if (btn === Qt.MiddleButton) {
        root.switchMode("toggle")
      } else {
        root.togglePanel()
      }
    }

    RowLayout {
      anchors.centerIn: parent
      spacing: 6

      // Vector OS Emblem / Glyphs
      Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        radius: 4
        color: "transparent"

        // macOS Apple Icon
        Text {
          visible: root.currentMode === "mac"
          anchors.centerIn: parent
          text: ""
          font.family: "SF Pro Text, -apple-system, Segoe UI, sans-serif"
          font.pixelSize: 15
          font.bold: true
          color: button.active ? Color.accent : (root.bar ? root.bar.foreground : "#ffffff")
        }

        // Windows 11 Fluent 4-Square Icon
        GridLayout {
          visible: root.currentMode === "win11"
          anchors.centerIn: parent
          columns: 2
          rowSpacing: 1.5
          columnSpacing: 1.5

          Rectangle { width: 5.5; height: 5.5; radius: 0.8; color: button.active ? Color.accent : "#0078d4" }
          Rectangle { width: 5.5; height: 5.5; radius: 0.8; color: button.active ? Color.accent : "#0078d4" }
          Rectangle { width: 5.5; height: 5.5; radius: 0.8; color: button.active ? Color.accent : "#0078d4" }
          Rectangle { width: 5.5; height: 5.5; radius: 0.8; color: button.active ? Color.accent : "#0078d4" }
        }

        // Omarchy / Tux Disguise Icon
        Text {
          visible: root.currentMode === "omarchy"
          anchors.centerIn: parent
          text: "󰈈"
          font.pixelSize: 15
          color: button.active ? Color.accent : (root.bar ? root.bar.foreground : "#ffffff")
        }
      }

      // Compact Mode Label (hidden in vertical bars)
      Text {
        visible: !root.vertical
        text: root.currentMode === "mac" ? "macOS" : (root.currentMode === "win11" ? "Win 11" : "Undercover")
        font.family: root.currentMode === "mac" ? "SF Pro Text" : (root.currentMode === "win11" ? "Segoe UI" : Style.font.family)
        font.pixelSize: Style.font.caption
        font.bold: true
        color: button.active ? Color.accent : (root.bar ? root.bar.foreground : "#ffffff")
      }
    }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: root.injectPanel()
  }
}
