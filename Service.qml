import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
  id: root

  property string homeDir: Quickshell.env("HOME")
  property string pluginDir: {
    var resolved = Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, "");
    if (resolved && resolved.length > 1 && resolved.indexOf("/") !== -1) return resolved;
    return homeDir + "/.config/omarchy/plugins/omarchy-undercover";
  }
  property string statePath: pluginDir + "/state"
  property string settingsConfPath: pluginDir + "/settings.conf"
  property string currentState: "mac-dark"
  property string previousState: ""

  // macOS Screensaver Properties
  readonly property bool isMacMode: root.currentState.indexOf("mac") !== -1
  property bool screensaverEnabled: true
  property int screensaverTimeout: 300
  property string screensaverVideo: ""
  property bool screensaverActive: false
  readonly property bool screensaverEngineActive: root.isMacMode && root.screensaverEnabled

  function runCmd(cmd) {
    var fullCmd = cmd.replace(/^omarchy-([a-zA-Z0-9_-]+)/, function(match) {
      return root.pluginDir + "/scripts/" + match
    })
    Quickshell.execDetached(["bash", "-c", fullCmd])
  }

  function playSwitchSound(mode) {
    var soundFile = (mode.indexOf("win") !== -1)
      ? root.pluginDir + "/assets/sounds/win11-switch.wav"
      : root.pluginDir + "/assets/sounds/mac-switch.wav"
    var soundScript = root.pluginDir + "/scripts/omarchy-play-sound"
    Quickshell.execDetached([soundScript, soundFile])
  }

  function reloadScreensaverConfig() {
    var txt = settingsConfFile.text()
    if (!txt) return

    var lines = txt.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line.indexOf("SCREENSAVER_ENABLED=") === 0) {
        var en = line.substring(20).trim().toLowerCase()
        root.screensaverEnabled = (en === "true" || en === "1" || en === "yes")
      } else if (line.indexOf("SCREENSAVER_TIMEOUT=") === 0) {
        var t = parseInt(line.substring(20).trim())
        if (!isNaN(t) && t > 0) root.screensaverTimeout = t
      } else if (line.indexOf("SCREENSAVER_VIDEO=") === 0) {
        var v = line.substring(18).trim()
        root.screensaverVideo = v
      }
    }
    if (!root.screensaverVideo || root.screensaverVideo === "") {
      root.screensaverVideo = root.homeDir + "/.local/share/omarchy-undercover/screensavers/sonoma_horizon.mp4"
    }
  }

  function triggerScreensaverPreview() {
    if (!root.screensaverVideo || root.screensaverVideo === "") {
      root.screensaverVideo = root.homeDir + "/.local/share/omarchy-undercover/screensavers/sonoma_horizon.mp4"
    }
    root.screensaverActive = true
  }

  function dismissScreensaver() {
    root.screensaverActive = false
  }

  Component.onCompleted: {
    var s = stateFile.text().trim()
    if (s) root.currentState = s
    reloadScreensaverConfig()
    if (!root.screensaverVideo || root.screensaverVideo === "") {
      root.screensaverVideo = root.homeDir + "/.local/share/omarchy-undercover/screensavers/sonoma_horizon.mp4"
    }
  }

  onCurrentStateChanged: {
    // If transitioning away from macOS mode, immediately kill any active screensaver
    if (!root.isMacMode && root.screensaverActive) {
      root.dismissScreensaver()
    }
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onLoaded: {
      var s = text().trim()
      if (s) {
        root.previousState = root.currentState
        root.currentState = s
      }
    }
    onFileChanged: {
      reload()
      var s = text().trim()
      if (s && s !== root.currentState) {
        root.previousState = root.currentState
        root.currentState = s
        root.playSwitchSound(s)
      }
    }
  }

  FileView {
    id: settingsConfFile
    path: root.settingsConfPath
    watchChanges: true
    printErrors: false
    onLoaded: root.reloadScreensaverConfig()
    onFileChanged: {
      reload()
      root.reloadScreensaverConfig()
    }
  }

  // Wayland Idle Monitor for macOS Mode
  IdleMonitor {
    id: idleMon
    enabled: root.screensaverEngineActive
    timeout: root.screensaverTimeout
    respectInhibitors: true
    onIsIdleChanged: {
      if (idleMon.isIdle) {
        if (root.screensaverEngineActive) {
          root.screensaverActive = true
        }
      } else {
        root.dismissScreensaver()
      }
    }
  }

  // Multi-monitor Wayland Overlay Instances
  Variants {
    model: Quickshell.screens

    MacScreensaverOverlay {
      owner: root
      modelData: modelData
      clipUrl: root.screensaverVideo
      active: root.screensaverActive
    }
  }

  IpcHandler {
    target: "omarchy-undercover-service"

    function toggle() {
      root.runCmd("omarchy-undercover --toggle")
    }

    function mac() {
      root.runCmd("omarchy-undercover -mac")
    }

    function macLight() {
      root.runCmd("omarchy-undercover -mac-light")
    }

    function win11() {
      root.runCmd("omarchy-undercover -w11")
    }

    function win11Light() {
      root.runCmd("omarchy-undercover -w11-light")
    }

    function restore() {
      root.runCmd("omarchy-undercover --disable")
    }

    function autohide(val: string) {
      root.runCmd("omarchy-undercover --autohide " + (val === "on" || val === "true" ? "1" : "0"))
    }

    function transparency(val: string) {
      root.runCmd("omarchy-undercover --transparency " + (val === "off" || val === "false" ? "off" : "on"))
    }

    function status() {
      return root.currentState
    }

    function previewScreensaver() {
      root.triggerScreensaverPreview()
      return "ok"
    }

    function dismissScreensaver() {
      root.dismissScreensaver()
      return "ok"
    }

    function reloadScreensaverConfig() {
      root.reloadScreensaverConfig()
      return "ok"
    }
  }

  IpcHandler {
    target: "undercover-service"

    function toggle() {
      root.runCmd("omarchy-undercover --toggle")
    }

    function mac() {
      root.runCmd("omarchy-undercover -mac")
    }

    function macLight() {
      root.runCmd("omarchy-undercover -mac-light")
    }

    function win11() {
      root.runCmd("omarchy-undercover -w11")
    }

    function win11Light() {
      root.runCmd("omarchy-undercover -w11-light")
    }

    function restore() {
      root.runCmd("omarchy-undercover --disable")
    }

    function autohide(val: string) {
      root.runCmd("omarchy-undercover --autohide " + (val === "on" || val === "true" ? "1" : "0"))
    }

    function transparency(val: string) {
      root.runCmd("omarchy-undercover --transparency " + (val === "off" || val === "false" ? "off" : "on"))
    }

    function status() {
      return root.currentState
    }

    function previewScreensaver() {
      root.triggerScreensaverPreview()
      return "ok"
    }

    function dismissScreensaver() {
      root.dismissScreensaver()
      return "ok"
    }

    function reloadScreensaverConfig() {
      root.reloadScreensaverConfig()
      return "ok"
    }
  }
}
