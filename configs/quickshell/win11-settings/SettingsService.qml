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

  function runCmd(cmd) {
    Quickshell.execDetached([
      "bash", "-c",
      "export PATH=\"" + root.pluginDir + "/scripts:$PATH\"; " + cmd
    ])
  }

  function refresh() {
    if (!statePoller.running) statePoller.running = true
  }

  function setMonitorScale(desc, scale) {
    runCmd("omarchy-settings-engine monitors scale '" + desc + "' " + scale)
    refreshTimer.restart()
  }

  function setMonitorMode(desc, mode) {
    runCmd("omarchy-settings-engine monitors mode '" + desc + "' '" + mode + "'")
    refreshTimer.restart()
  }

  function setMonitorTransform(desc, transform) {
    runCmd("omarchy-settings-engine monitors transform '" + desc + "' " + transform)
    refreshTimer.restart()
  }

  function setMonitorVrr(desc, vrr) {
    runCmd("omarchy-settings-engine monitors vrr '" + desc + "' " + vrr)
    refreshTimer.restart()
  }

  function setMonitorMirror(desc, target) {
    runCmd("omarchy-settings-engine monitors mirror '" + desc + "' '" + (target || "none") + "'")
    refreshTimer.restart()
  }

  function setMonitorDisabled(desc, disabled) {
    runCmd("omarchy-settings-engine monitors disabled '" + desc + "' " + (disabled ? "true" : "false"))
    refreshTimer.restart()
  }

  function setProjectionMode(mode) {
    root.projectionMode = mode
    runCmd("omarchy-settings-engine monitors project " + mode)
    refreshTimer.restart()
  }

  function saveMonitorProfile(name) {
    if (!name) return
    runCmd("omarchy-settings-engine monitors profile save '" + name + "'")
    refreshTimer.restart()
  }

  function applyMonitorProfile(name) {
    if (!name) return
    runCmd("omarchy-settings-engine monitors profile apply '" + name + "'")
    refreshTimer.restart()
  }

  function deleteMonitorProfile(name) {
    if (!name) return
    runCmd("omarchy-settings-engine monitors profile delete '" + name + "'")
    refreshTimer.restart()
  }

  function identifyDisplays() {
    runCmd("omarchy-display-identify 2>/dev/null || omarchy-settings-engine monitors identify 2>/dev/null")
  }

  function scanWifi() {
    root.wifiScanning = true
    runCmd("omarchy-settings-engine wifi rescan")
    refreshTimer.restart()
  }

  function connectWifi(ssid, password) {
    var pwArg = password ? (" '" + password + "'") : ""
    runCmd("omarchy-settings-engine wifi connect '" + ssid + "'" + pwArg)
    refreshTimer.restart()
  }

  function disconnectWifi() {
    runCmd("omarchy-settings-engine wifi disconnect")
    refreshTimer.restart()
  }

  function toggleWifi(on) {
    root.wifiEnabled = on
    runCmd("omarchy-settings-engine wifi radio " + (on ? "on" : "off"))
    refreshTimer.restart()
  }

  function toggleBluetooth(on) {
    root.btEnabled = on
    runCmd("omarchy-settings-engine bluetooth power " + (on ? "on" : "off"))
    refreshTimer.restart()
  }

  function scanBluetooth() {
    root.btDiscovering = true
    runCmd("omarchy-settings-engine bluetooth scan")
    refreshTimer.restart()
  }

  function connectBluetooth(address) {
    runCmd("omarchy-settings-engine bluetooth connect '" + address + "'")
    refreshTimer.restart()
  }

  function disconnectBluetooth(address) {
    runCmd("omarchy-settings-engine bluetooth disconnect '" + address + "'")
    refreshTimer.restart()
  }

  function setPowerProfile(profile) {
    root.powerProfile = profile
    runCmd("omarchy-settings-engine power profile ac " + profile + " 2>/dev/null; omarchy-settings-engine power profile battery " + profile + " 2>/dev/null; powerprofilesctl set " + profile + " 2>/dev/null")
    refreshTimer.restart()
  }

  function setDeviceOption(device, opt, val, kind) {
    runCmd("omarchy-settings-engine devices set '" + device + "' '" + opt + "' '" + val + "' " + (kind || "pointer"))
    refreshTimer.restart()
  }

  function setHyprOption(key, val) {
    runCmd("omarchy-settings-engine set " + key + " " + val)
    refreshTimer.restart()
  }

  Process {
    id: statePoller
    running: true
    command: [
      "bash", "-c",
      "export PATH=\"" + root.pluginDir + "/scripts:$PATH\"; " +
      "omarchy-settings-engine state 2>/dev/null || bash " + root.pluginDir + "/scripts/omarchy-settings-engine state 2>/dev/null"
    ]
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
