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
  property string statePath: {
    var s = Quickshell.env("XDG_STATE_HOME")
    if (s && s.length > 0) return s + "/omarchy/undercover/state"
    return homeDir + "/.local/state/omarchy/undercover/state"
  }
  property string settingsConfPath: {
    var c = Quickshell.env("XDG_CONFIG_HOME")
    if (c && c.length > 0) return c + "/omarchy-undercover/settings.conf"
    return homeDir + "/.config/omarchy-undercover/settings.conf"
  }
  property string currentState: "omarchy"
  property string previousState: ""
  property bool disguisePersistent: false

  // macOS Screensaver Properties
  readonly property bool isMacMode: root.currentState.indexOf("mac") !== -1
  property bool screensaverEnabled: true
  property int screensaverTimeout: 300
  property string screensaverVideo: homeDir + "/.local/share/omarchy-undercover/screensavers/sonoma_horizon.opt.mp4"
  property string effectiveScreensaverVideo: ""
  property bool screensaverActive: false
  property bool screensaverPreviewMode: false
  property bool stayAwake: false
  readonly property bool screensaverEngineActive: root.isMacMode && root.screensaverEnabled && !root.stayAwake

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
        if (v && v.indexOf("screenrecording") === -1) {
          root.screensaverVideo = v
        }
      } else if (line.indexOf("DISGUISE_PERSISTENT=") === 0) {
        var p = line.substring(20).trim().toLowerCase()
        root.disguisePersistent = (p === "true" || p === "1" || p === "yes")
      }
    }
    if (!root.screensaverVideo || root.screensaverVideo === "") {
      root.screensaverVideo = root.homeDir + "/.local/share/omarchy-undercover/screensavers/sonoma_horizon.opt.mp4"
    }
    clipResolverProc.running = true
  }

  function triggerScreensaverPreview() {
    if (!root.screensaverVideo || root.screensaverVideo === "") {
      root.screensaverVideo = root.homeDir + "/.local/share/omarchy-undercover/screensavers/sonoma_horizon.opt.mp4"
    }
    clipResolverProc.running = true
    root.screensaverPreviewMode = true
    root.screensaverActive = true
  }

  function triggerLockscreenPreview() {
    root.dismissScreensaver()
    root.runCmd("omarchy-shell lock preview 2>/dev/null || omarchy-system-lock 2>/dev/null")
  }

  function lock(): string {
    root.dismissScreensaver()
    root.runCmd("omarchy-system-lock 2>/dev/null || hyprlock 2>/dev/null || loginctl lock-session 2>/dev/null || omarchy-lock 2>/dev/null")
    return "ok"
  }

  function dismissScreensaver() {
    root.screensaverActive = false
    root.screensaverPreviewMode = false
  }

  Process {
    id: clipResolverProc
    command: [root.pluginDir + "/scripts/omarchy-resolve-clip", root.screensaverVideo]
    stdout: StdioCollector {
      onStreamFinished: {
        var res = String(text || "").trim()
        if (res && res !== "") {
          root.effectiveScreensaverVideo = res
        }
      }
    }
  }

  onScreensaverVideoChanged: {
    clipResolverProc.running = true
  }

  Component.onDestruction: {
    Quickshell.execDetached(["python3", root.pluginDir + "/scripts/omarchy-undercover-tracker", "--stop"])
  }

  Component.onCompleted: {
    reloadScreensaverConfig()
    var s = stateFile.text().trim()
    if (s && s !== "") {
      root.currentState = s
    } else {
      root.currentState = "omarchy"
    }
    if (!root.screensaverVideo || root.screensaverVideo === "") {
      root.screensaverVideo = root.homeDir + "/.local/share/omarchy-undercover/screensavers/sonoma_horizon.opt.mp4"
    }
    clipResolverProc.running = true
  }

  onCurrentStateChanged: {
    // If transitioning away from macOS mode, immediately kill any active screensaver
    if (!root.isMacMode && root.screensaverActive) {
      root.dismissScreensaver()
    }
  }

  FileView {
    id: stayAwakeWatcher
    path: root.homeDir + "/.local/state/omarchy/indicators/stay-awake"
    watchChanges: true
    printErrors: false
    onLoaded: root.stayAwake = true
    onLoadFailed: root.stayAwake = false
    onFileChanged: reload()
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
          root.screensaverPreviewMode = false
          root.screensaverActive = true
        }
      }
    }
  }

  // Multi-monitor Wayland Overlay Instances
  Variants {
    model: Quickshell.screens

    MacScreensaverOverlay {
      required property var modelData

      screen: modelData
      owner: root
      clipUrl: root.effectiveScreensaverVideo !== "" ? root.effectiveScreensaverVideo : root.screensaverVideo
      active: root.screensaverActive
      isPreview: root.screensaverPreviewMode
    }
  }

  // Auto-dismiss screensaver overlay immediately when official omarchy.lock engages
  Timer {
    id: lockStatusPollTimer
    interval: 1000
    running: root.screensaverActive
    repeat: true
    onTriggered: lockStatusProc.running = true
  }

  Process {
    id: lockStatusProc
    command: ["bash", "-c", "if pidof hyprlock >/dev/null 2>&1 || [[ $(omarchy-shell lock isLocked 2>/dev/null) == \"true\" ]]; then echo locked; else echo unlocked; fi"]
    stdout: StdioCollector {
      onStreamFinished: {
        var s = String(text || "").trim()
        if (s === "locked" && root.screensaverActive) {
          root.dismissScreensaver()
        }
      }
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

    function status(): string {
      return root.currentState
    }

    function debugScreensaver(): string {
      return JSON.stringify({
        currentState: root.currentState,
        isMacMode: root.isMacMode,
        screensaverEnabled: root.screensaverEnabled,
        screensaverTimeout: root.screensaverTimeout,
        screensaverVideo: root.screensaverVideo,
        screensaverActive: root.screensaverActive,
        screensaverEngineActive: root.screensaverEngineActive
      })
    }

    function previewScreensaver(): string {
      root.triggerScreensaverPreview()
      return "ok"
    }

    function previewLockscreen(): string {
      root.triggerLockscreenPreview()
      return "ok"
    }

    function lock(): string {
      return root.lock()
    }

    function lockScreensaver(): string {
      return root.lock()
    }

    function dismissScreensaver(): string {
      root.dismissScreensaver()
      return "ok"
    }

    function reloadScreensaverConfig(): string {
      root.reloadScreensaverConfig()
      return "ok"
    }

    function trackerStatus(): string {
      return "ok"
    }

    function trackerFile(): string {
      return ""
    }

    function focusWindow(addr: string): string {
      var safeAddr = String(addr || "").trim()
      if (/^[a-zA-Z0-9:x_-]+$/.test(safeAddr)) {
        Quickshell.execDetached(["bash", "-c", "hyprctl dispatch \"hl.dsp.focus({ window = 'address:" + safeAddr + "' })\" 2>/dev/null || hyprctl dispatch focuswindow \"address:" + safeAddr + "\" 2>/dev/null || true"])
      }
      return "ok"
    }

    function focusWorkspace(id: string): string {
      var safeId = String(id || "").trim()
      if (/^[0-9]+$/.test(safeId)) {
        Quickshell.execDetached(["bash", "-c", "hyprctl dispatch \"hl.dsp.focus({ workspace = " + safeId + " })\" 2>/dev/null || hyprctl dispatch workspace \"" + safeId + "\" 2>/dev/null || true"])
      }
      return "ok"
    }

    function hideStockDock(): string {
      root.runCmd("omarchy-undercover --hide-stock-dock")
      return "ok"
    }

    function restoreStockDock(): string {
      root.runCmd("omarchy-undercover --restore-stock-dock")
      return "ok"
    }
  }
}
