import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy-undercover"

  property string homeDir: Quickshell.env("HOME")
  property string configDir: {
    var resolved = Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, "");
    if (resolved && resolved.length > 1 && resolved.indexOf("/") !== -1) return resolved;
    return homeDir + "/.config/omarchy/plugins/omarchy-undercover";
  }
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
    printErrors: false
    onLoaded: root.updateFromState()
    onFileChanged: { reload(); root.updateFromState() }
  }

  FileView {
    id: settingsFile
    path: root.settingsPath
    watchChanges: true
    printErrors: false
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

    var fullCmd = cmd.replace(/^omarchy-([a-zA-Z0-9_-]+)/, function(match) {
      return root.configDir + "/scripts/" + match
    })

    if (root.bar) {
      root.bar.run(fullCmd)
    } else {
      Quickshell.execDetached(["bash", "-c", fullCmd])
    }
  }

  IpcHandler {
    target: "omarchy-undercover"

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
        Item {
          visible: root.currentMode === "mac"
          anchors.centerIn: parent
          width: 16
          height: 16

          Shape {
            anchors.centerIn: parent
            width: 24
            height: 24
            scale: 14 / 24
            layer.enabled: true
            layer.samples: 4

            ShapePath {
              fillColor: button.active ? Color.accent : (root.bar ? root.bar.foreground : "#ffffff")
              strokeWidth: 0
              PathSvg {
                path: "M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 4.15c.66-.8 1.11-1.92.99-3.04-1 .04-2.2.67-2.92 1.5-.64.74-1.2 1.92-1.05 3.03 1.12.09 2.26-.59 2.98-1.49z"
              }
            }
          }
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
          text: "\ue900"
          font.family: "omarchy"
          font.pixelSize: 15
          color: button.active ? Color.accent : (root.bar ? root.bar.foreground : "#ffffff")
        }
      }

      // Compact Mode Label (hidden in vertical bars)
      Text {
        visible: !root.vertical
        text: root.currentMode === "mac" ? "macOS" : (root.currentMode === "win11" ? "Win 11" : "Omarchy")
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
