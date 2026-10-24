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
  property string toggleShortcut: "SUPER + ALT + U"

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
      } else if (line.indexOf("BIND_UNDERCOVER_TOGGLE=") === 0) {
        var sc = line.substring(23).trim()
        if (sc) root.toggleShortcut = sc
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

  property bool panelRequested: false

  function togglePanel() {
    if (!panelRequested) {
      panelRequested = true
    } else if (panelLoader.item && panelLoader.item.toggle) {
      panelLoader.item.toggle()
    }
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    panelRequested = true
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

    function open() { root.open() }
    function close() { root.close() }
    function show() { root.open() }
    function hide() { root.close() }
    function toggle() { root.togglePanel() }
    function mac() { root.switchMode("mac-dark") }
    function macLight() { root.switchMode("mac-light") }
    function win11() { root.switchMode("win11-dark") }
    function win11Light() { root.switchMode("win11-light") }
    function omarchy() { root.switchMode("omarchy") }
    function next() { root.switchMode("next") }
    function toggleMode() { root.switchMode("toggle") }
  }

  IpcHandler {
    target: "undercover"

    function open() { root.open() }
    function close() { root.close() }
    function show() { root.open() }
    function hide() { root.close() }
    function toggle() { root.togglePanel() }
    function mac() { root.switchMode("mac-dark") }
    function macLight() { root.switchMode("mac-light") }
    function win11() { root.switchMode("win11-dark") }
    function win11Light() { root.switchMode("win11-light") }
    function omarchy() { root.switchMode("omarchy") }
    function next() { root.switchMode("next") }
    function toggleMode() { root.switchMode("toggle") }
  }

  visible: root.currentMode === "omarchy"
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.opened
    horizontalMargin: 8
    verticalPadding: 5

    tooltipText: "Omarchy Undercover Settings & Camouflage\n• Click: Configure & Switch Camouflage Beforehand\n• Shortcut: " + root.toggleShortcut + " (Toggle Camouflage)\n• Middle-Click: Toggle Quick Switch"

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

      Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        radius: 4
        color: "transparent"

        Image {
          anchors.centerIn: parent
          width: 16
          height: 16
          source: "file://" + root.configDir + "/assets/icon.svg"
          sourceSize: Qt.size(32, 32)
          fillMode: Image.PreserveAspectFit
          smooth: true
        }
      }

      Text {
        visible: !root.vertical
        text: "Undercover"
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
        color: button.active ? Color.accent : (root.bar ? root.bar.foreground : "#ffffff")
      }
    }
  }

  Loader {
    id: panelLoader
    active: root.panelRequested
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
    }
  }
}
