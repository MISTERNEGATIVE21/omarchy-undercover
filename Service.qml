import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string homeDir: Quickshell.env("HOME")
  property string pluginDir: {
    var resolved = Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, "");
    if (resolved && resolved.length > 1 && resolved.indexOf("/") !== -1) return resolved;
    return homeDir + "/.config/omarchy/plugins/omarchy-undercover";
  }
  property string statePath: pluginDir + "/state"
  property string settingsPath: pluginDir + "/settings.conf"
  property string currentState: "mac-dark"
  property string previousState: ""

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

  function ensureHyprlandToggle() {
    var undercoverScript = root.pluginDir + "/scripts/omarchy-undercover";
    Quickshell.execDetached([undercoverScript, "--sync-hyprland"]);
  }

  Component.onCompleted: {
    root.ensureHyprlandToggle()
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    onLoaded: {
      var s = text().trim()
      if (s) {
        root.previousState = root.currentState
        root.currentState = s
        root.ensureHyprlandToggle()
      }
    }
    onFileChanged: {
      reload()
      var s = text().trim()
      if (s && s !== root.currentState) {
        root.previousState = root.currentState
        root.currentState = s
        root.playSwitchSound(s)
        root.ensureHyprlandToggle()
      }
    }
  }

  IpcHandler {
    target: "omarchy-undercover-service"

    function toggle(): void {
      root.runCmd("omarchy-undercover --toggle")
    }

    function mac(): void {
      root.runCmd("omarchy-undercover -mac")
    }

    function macLight(): void {
      root.runCmd("omarchy-undercover -mac-light")
    }

    function win11(): void {
      root.runCmd("omarchy-undercover -w11")
    }

    function win11Light(): void {
      root.runCmd("omarchy-undercover -w11-light")
    }

    function restore(): void {
      root.runCmd("omarchy-undercover --disable")
    }

    function autohide(val: string): void {
      root.runCmd("omarchy-undercover --autohide " + (val === "on" || val === "true" ? "1" : "0"))
    }

    function transparency(val: string): void {
      root.runCmd("omarchy-undercover --transparency " + (val === "off" || val === "false" ? "off" : "on"))
    }

    function status(): string {
      return root.currentState
    }
  }

  IpcHandler {
    target: "undercover-service"

    function toggle(): void {
      root.runCmd("omarchy-undercover --toggle")
    }

    function mac(): void {
      root.runCmd("omarchy-undercover -mac")
    }

    function macLight(): void {
      root.runCmd("omarchy-undercover -mac-light")
    }

    function win11(): void {
      root.runCmd("omarchy-undercover -w11")
    }

    function win11Light(): void {
      root.runCmd("omarchy-undercover -w11-light")
    }

    function restore(): void {
      root.runCmd("omarchy-undercover --disable")
    }

    function autohide(val: string): void {
      root.runCmd("omarchy-undercover --autohide " + (val === "on" || val === "true" ? "1" : "0"))
    }

    function transparency(val: string): void {
      root.runCmd("omarchy-undercover --transparency " + (val === "off" || val === "false" ? "off" : "on"))
    }

    function status(): string {
      return root.currentState
    }
  }
}
