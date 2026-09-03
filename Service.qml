import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string homeDir: Quickshell.env("HOME")
  property string configDir: homeDir + "/.config/omarchy-undercover"
  property string statePath: configDir + "/state"
  property string settingsPath: configDir + "/settings.conf"
  property string currentState: "mac-dark"
  property string previousState: ""

  function runCmd(cmd) {
    Quickshell.execDetached(["bash", "-c", cmd])
  }

  function playSwitchSound(mode) {
    var soundFile = (mode.indexOf("win") !== -1)
      ? root.homeDir + "/.config/omarchy-undercover/sounds/win11-switch.wav"
      : root.homeDir + "/.config/omarchy-undercover/sounds/mac-switch.wav"
    Quickshell.execDetached(["omarchy-play-sound", soundFile])
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
