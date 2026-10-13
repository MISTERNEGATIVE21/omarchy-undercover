import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var monitors: []
  property string projectionMode: "extend"
  property var monitorProfiles: []
  property bool wifiEnabled: true
  property bool wifiScanning: false
  property string wifiActiveSsid: ""
  property var wifiNetworks: []
  property bool btEnabled: true
  property bool btDiscovering: false
  property var btDevices: []
  property int batteryPct: 100
  property bool isCharging: false
  property string powerProfile: "balanced"
  property real mouseSpeed: 0.0
  property bool mouseNaturalScroll: false
  property bool touchpadTapToClick: true
  property bool touchpadNaturalScroll: true
  property int windowRounding: 10
  property int windowGaps: 8
  property int borderSize: 2
  property bool blurEnabled: true
  property bool animationsEnabled: true
  property bool ready: false

  property string pluginDir: {
    var p = Quickshell.env("OMARCHY_PLUGIN_DIR")
    if (p) return p
    return Quickshell.env("HOME") + "/omarchy-undercover"
  }

  function refresh() {
    if (!statePoller.running) statePoller.running = true
  }

  function setMonitorScale(desc, scale) {
    if (typeof desc !== "string" || !desc) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "monitors", "scale", desc, String(scale)])
    refreshTimer.restart()
  }

  function setMonitorMode(desc, mode) {
    if (typeof desc !== "string" || !desc || typeof mode !== "string" || !mode) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "monitors", "mode", desc, mode])
    refreshTimer.restart()
  }

  function setMonitorTransform(desc, transform) {
    if (typeof desc !== "string" || !desc) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "monitors", "transform", desc, String(transform)])
    refreshTimer.restart()
  }

  function setMonitorVrr(desc, vrr) {
    if (typeof desc !== "string" || !desc) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "monitors", "vrr", desc, String(vrr)])
    refreshTimer.restart()
  }

  function setMonitorMirror(desc, target) {
    if (typeof desc !== "string" || !desc) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "monitors", "mirror", desc, String(target || "none")])
    refreshTimer.restart()
  }

  function setMonitorDisabled(desc, disabled) {
    if (typeof desc !== "string" || !desc) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "monitors", "disabled", desc, disabled ? "true" : "false"])
    refreshTimer.restart()
  }

  function setProjectionMode(mode) {
    root.projectionMode = mode
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "monitors", "project", String(mode)])
    refreshTimer.restart()
  }

  function saveMonitorProfile(name) {
    if (typeof name !== "string" || !name) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "monitors", "profile", "save", name])
    refreshTimer.restart()
  }

  function applyMonitorProfile(name) {
    if (typeof name !== "string" || !name) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "monitors", "profile", "apply", name])
    refreshTimer.restart()
  }

  function deleteMonitorProfile(name) {
    if (typeof name !== "string" || !name) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "monitors", "profile", "delete", name])
    refreshTimer.restart()
  }

  function identifyDisplays() {
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "monitors", "identify"])
  }

  function scanWifi() {
    root.wifiScanning = true
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "wifi", "rescan"])
    refreshTimer.restart()
  }

  Process {
    id: wifiConnectProc
    property string secret: ""
    stdinEnabled: true
    onStarted: {
      if (secret) {
        write(secret + "\n")
        secret = ""
      }
    }
    onExited: {
      refreshTimer.restart()
    }
  }

  function connectWifi(ssid, password) {
    if (typeof ssid !== "string" || ssid.length === 0 || ssid.length > 32 || /[\x00-\x1f]/.test(ssid)) return
    if (wifiConnectProc.running) wifiConnectProc.running = false
    wifiConnectProc.secret = (typeof password === "string") ? password : ""
    if (wifiConnectProc.secret) {
      wifiConnectProc.command = [root.pluginDir + "/scripts/omarchy-settings-engine", "wifi", "connect", ssid, "--password-stdin"]
    } else {
      wifiConnectProc.command = [root.pluginDir + "/scripts/omarchy-settings-engine", "wifi", "connect", ssid]
    }
    wifiConnectProc.running = true
    refreshTimer.restart()
  }

  function disconnectWifi() {
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "wifi", "disconnect"])
    refreshTimer.restart()
  }

  function toggleWifi(on) {
    root.wifiEnabled = on
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "wifi", "radio", on ? "on" : "off"])
    refreshTimer.restart()
  }

  function toggleBluetooth(on) {
    root.btEnabled = on
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "bluetooth", "power", on ? "on" : "off"])
    refreshTimer.restart()
  }

  function scanBluetooth() {
    root.btDiscovering = true
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "bluetooth", "scan"])
    refreshTimer.restart()
  }

  function connectBluetooth(address) {
    if (typeof address !== "string" || address.length === 0 || address.length > 32 || /[\x00-\x1f]/.test(address)) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "bluetooth", "connect", address])
    refreshTimer.restart()
  }

  function disconnectBluetooth(address) {
    if (typeof address !== "string" || address.length === 0 || address.length > 32 || /[\x00-\x1f]/.test(address)) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "bluetooth", "disconnect", address])
    refreshTimer.restart()
  }

  function setPowerProfile(profile) {
    if (typeof profile !== "string" || !profile) return
    root.powerProfile = profile
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "power", "profile", "ac", profile])
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "power", "profile", "battery", profile])
    refreshTimer.restart()
  }

  function setDeviceOption(device, opt, val, kind) {
    if (typeof device !== "string" || !device) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "devices", "set", device, String(opt), String(val), String(kind || "pointer")])
    refreshTimer.restart()
  }

  function setHyprOption(key, val) {
    if (typeof key !== "string" || !key) return
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-settings-engine", "set", key, String(val)])
    refreshTimer.restart()
  }

  Process {
    id: statePoller
    running: true
    command: [root.pluginDir + "/scripts/omarchy-settings-engine", "state"]
    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(line) {
        var str = String(line).trim()
        if (!str || str.charAt(0) !== "{") return
        try {
          var data = JSON.parse(str)
          if (!data) return

          if (data.monitors && Array.isArray(data.monitors)) {
            root.monitors = data.monitors
          }
          if (data.projectionMode) {
            root.projectionMode = data.projectionMode
          }
          if (data.monitorProfiles && Array.isArray(data.monitorProfiles)) {
            root.monitorProfiles = data.monitorProfiles
          }
          if (data.wifi) {
            root.wifiEnabled = (data.wifi.enabled !== false)
            root.wifiActiveSsid = data.wifi.activeSsid || ""
            if (Array.isArray(data.wifi.networks)) {
              root.wifiNetworks = data.wifi.networks
            }
          }
          if (data.bluetooth) {
            root.btEnabled = (data.bluetooth.enabled !== false)
            if (Array.isArray(data.bluetooth.devices)) {
              root.btDevices = data.bluetooth.devices
            }
          }
          if (data.power) {
            if (data.power.battery !== undefined && data.power.battery !== null) {
              root.batteryPct = data.power.battery
            }
            if (data.power.charging !== undefined) {
              root.isCharging = data.power.charging
            }
            if (data.power.activeProfile) {
              root.powerProfile = data.power.activeProfile
            }
          }
          if (data.hypr) {
            if (data.hypr.rounding !== undefined) root.windowRounding = data.hypr.rounding
            if (data.hypr.gaps_in !== undefined) root.windowGaps = data.hypr.gaps_in
            if (data.hypr.border_size !== undefined) root.borderSize = data.hypr.border_size
            if (data.hypr.blur !== undefined) root.blurEnabled = (data.hypr.blur !== false)
            if (data.hypr.animations !== undefined) root.animationsEnabled = (data.hypr.animations !== false)
          }
          root.wifiScanning = false
          root.ready = true
        } catch (e) {}
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 300
    repeat: false
    onTriggered: {
      if (!statePoller.running) statePoller.running = true
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!statePoller.running) statePoller.running = true
    }
  }
}
