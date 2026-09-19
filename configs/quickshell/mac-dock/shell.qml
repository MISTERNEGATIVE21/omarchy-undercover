import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
  PanelWindow {
    id: dockWindow
    screen: Quickshell.screens[0]

    anchors {
      bottom: true
    }
    margins {
      bottom: 0
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "mac-dock"
    
    // Always overlays on top of windows without resizing them (the dock's
    // magnified icons + tooltips paint over whatever is behind it).
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property real screenWidth: dockWindow.screen ? dockWindow.screen.width : 1920
    readonly property real screenHeight: dockWindow.screen ? dockWindow.screen.height : 1080
    readonly property real dpiScale: (dockWindow.screen && dockWindow.screen.devicePixelRatio) ? dockWindow.screen.devicePixelRatio : 1.0

    // Responsive scale factor based on screen height and DPI
    readonly property real responsiveScale: Math.max(0.85, Math.min(1.4, (screenHeight >= 1440 ? 1.15 : (screenHeight >= 1080 ? 1.0 : 0.9))))

    // Configured icon size (px) from settings.conf DOCK_SIZE
    property int dockSize: 44
    // Max number of app icons to show (DOCK_MAX_ITEMS), caps runaway running apps
    property int maxDockItems: 24
    // User-defined apps from defaults.json mac_custom_apps
    property var customDockApps: []

    readonly property real baseIconSize: Math.round(Math.max(24, dockWindow.dockSize) * dockWindow.responsiveScale)

    // Icon size dynamically re-computed so the whole dock always fits the screen
    readonly property real effectiveIconSize: {
      var count = dockWindow.dockItemCount
      if (count <= 1) return dockWindow.baseIconSize
      var spacing = Math.round(4 * dockWindow.responsiveScale)
      var avail = dockWindow.screenWidth * 0.94 - spacing * (count - 1)
      var fit = Math.floor(avail / count)
      return Math.max(Math.round(24 * dockWindow.responsiveScale), Math.min(dockWindow.baseIconSize, fit))
    }

    // Vertical headroom for magnified icons + tooltips (no top clipping / overlap)
    readonly property real magnifyRoom: Math.round((dockWindow.maxMagnification - 1.0) * dockWindow.effectiveIconSize + 28 * dockWindow.responsiveScale)

    implicitWidth: dockCard.implicitWidth + Math.round(32 * responsiveScale)
    implicitHeight: dockCard.height + Math.round(36 * responsiveScale) + (dockWindow.isMouseOverDock ? dockWindow.magnifyRoom : Math.round(6 * responsiveScale))

    property real maxMagnification: 1.24
    property real effectRadius: Math.round(70.0 * responsiveScale)
    property bool isMouseOverDock: false
    property real currentMouseX: 0
    // Dock background transparency (0-100, 100 = fully opaque)
    property int dockTransparency: 76

    property string homeDir: Quickshell.env("HOME")
    property string iconBasePath: homeDir + "/.local/share/icons/mac-dock/"
    property bool isLight: false
    property bool isAutohide: false
    property bool isDockRevealed: true

    // Workspaces & Running Windows Tracking via Native Hyprland State
    property var dockAppsList: []
    property var hyprClients: []
    property var hyprActiveWindow: ({})
    property int activeWorkspaceId: 1

    Process {
      id: hyprStateProc
      // ponytail: hyprctl --batch gets all 4 queries in 1 socket round-trip, 3x faster than subshell chains
      command: [
        "bash", "-c",
        "hyprctl --batch 'j/activeworkspace ; j/workspaces ; j/clients ; j/activewindow' 2>/dev/null | jq -s -c '{actWs: (.[0] // {}), allWs: (.[1] // []), cls: (.[2] // []), actWin: (.[3] // {})}'"
      ]
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          try {
            var data = JSON.parse(line.trim())
            if (data.actWs && data.actWs.id) {
              dockWindow.activeWorkspaceId = data.actWs.id
            }
            if (Array.isArray(data.cls)) {
              dockWindow.hyprClients = data.cls.filter(function(c) { return c && c.mapped && !c.hidden })
            }
            if (data.actWin && data.actWin.address) {
              dockWindow.hyprActiveWindow = data.actWin
            } else {
              dockWindow.hyprActiveWindow = ({})
            }
          } catch(e) {}
          dockWindow.refreshDock()
        }
      }
    }

    Timer {
      id: fastPoller
      interval: 8000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!hyprStateProc.running) hyprStateProc.running = true
      }
    }

    Timer {
      id: refreshTimer
      interval: 85
      running: false
      repeat: false
      onTriggered: {
        if (!hyprStateProc.running) hyprStateProc.running = true
      }
    }

    Process {
      id: socketListener
      command: [
        "bash", "-c",
        "sock=\"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock\"; if [ -S \"$sock\" ]; then exec socat -u UNIX-CONNECT:\"$sock\" -; fi"
      ]
      running: true
      stdout: SplitParser {
        onRead: function(line) {
          var l = String(line)
          if (l.indexOf("activewindow>>") === 0 ||
              l.indexOf("activewindowv2>>") === 0 ||
              l.indexOf("openwindow>>") === 0 ||
              l.indexOf("closewindow>>") === 0 ||
              l.indexOf("workspace>>") === 0 ||
              l.indexOf("focusedmon>>") === 0) {
            refreshTimer.restart()
          }
        }
      }
    }

    // Quick macOS-style autohide delay (400ms) after mouse exits dock
    Timer {
      id: hideTimer
      interval: 400
      running: false
      repeat: false
      onTriggered: {
        if (dockWindow.isAutohide && !dockWindow.isMouseOverDock) {
          dockWindow.isDockRevealed = false
        }
      }
    }

    // Timer if cursor revealed dock from edge but didn't enter dock items
    Timer {
      id: edgeInactivityTimer
      interval: 1500
      running: false
      repeat: false
      onTriggered: {
        if (dockWindow.isAutohide && !dockWindow.isMouseOverDock) {
          dockWindow.isDockRevealed = false
        }
      }
    }

    // Strict Theme Isolation Watcher via reactive FileView
    FileView {
      id: stateWatcher
      path: dockWindow.homeDir + "/.config/omarchy-undercover/state"
      watchChanges: true
      onLoaded: {
        var s = text().trim()
        dockWindow.isLight = (s.indexOf("light") !== -1)
        if (s && s.indexOf("mac") !== 0) Qt.quit()
      }
      onFileChanged: {
        reload()
        var s = text().trim()
        dockWindow.isLight = (s.indexOf("light") !== -1)
        if (s && s.indexOf("mac") !== 0) Qt.quit()
      }
    }

    // Settings Watcher for dynamic autohide
    FileView {
      id: settingsWatcher
      path: dockWindow.homeDir + "/.config/omarchy-undercover/settings.conf"
      watchChanges: true
      onLoaded: {
        var s = text()
        dockWindow.isAutohide = (s.indexOf("AUTOHIDE=true") !== -1 || s.indexOf("AUTOHIDE=1") !== -1)
        var dm = s.match(/DOCK_SIZE=(\d+)/)
        if (dm && dm[1]) dockWindow.dockSize = Math.max(24, parseInt(dm[1]))
        var mm = s.match(/DOCK_MAX_ITEMS=(\d+)/)
        if (mm && mm[1]) dockWindow.maxDockItems = Math.max(4, parseInt(mm[1]))
        var dt = s.match(/DOCK_TRANSPARENCY=(\d+)/)
        if (dt && dt[1]) dockWindow.dockTransparency = Math.max(10, Math.min(100, parseInt(dt[1])))
        if (!dockWindow.isAutohide) dockWindow.isDockRevealed = true
      }
      onFileChanged: {
        reload()
        var s = text()
        dockWindow.isAutohide = (s.indexOf("AUTOHIDE=true") !== -1 || s.indexOf("AUTOHIDE=1") !== -1)
        var dm = s.match(/DOCK_SIZE=(\d+)/)
        if (dm && dm[1]) dockWindow.dockSize = Math.max(24, parseInt(dm[1]))
        var mm = s.match(/DOCK_MAX_ITEMS=(\d+)/)
        if (mm && mm[1]) dockWindow.maxDockItems = Math.max(4, parseInt(mm[1]))
        var dt = s.match(/DOCK_TRANSPARENCY=(\d+)/)
        if (dt && dt[1]) dockWindow.dockTransparency = Math.max(10, Math.min(100, parseInt(dt[1])))
        if (!dockWindow.isAutohide) dockWindow.isDockRevealed = true
      }
    }

    function findRunningClient(matchers) {
      if (!matchers || matchers.length === 0) return null
      var firstMatch = null
      for (var i = 0; i < dockWindow.hyprClients.length; i++) {
        var c = dockWindow.hyprClients[i]
        if (!c) continue
        var target = ((c.class || "") + " " + (c.initialClass || "") + " " + (c.title || "")).toLowerCase()
        for (var j = 0; j < matchers.length; j++) {
          if (target.indexOf(matchers[j].toLowerCase()) !== -1) {
            if (dockWindow.hyprActiveWindow && dockWindow.hyprActiveWindow.address && c.address === dockWindow.hyprActiveWindow.address) {
              return c
            }
            if (!firstMatch) firstMatch = c
            break
          }
        }
      }
      return firstMatch
    }

    function isClientFocused(client) {
      if (!client || !client.address || !dockWindow.hyprActiveWindow || !dockWindow.hyprActiveWindow.address) return false
      return client.address === dockWindow.hyprActiveWindow.address
    }

    function shellQuote(val) {
      return "'" + String(val || "").replace(/'/g, "'\\''") + "'"
    }

    function shiftToClient(client) {
      if (!client || !client.address) return
      var rawAddr = String(client.address).trim()
      if (!/^0x[0-9a-fA-F]+$/.test(rawAddr)) return
      if (client.workspace && client.workspace.id < 0) {
        Quickshell.execDetached(["omarchy-undercover-minimize", rawAddr])
        refreshTimer.restart()
        return
      }
      var wsId = (client.workspace && client.workspace.id) ? parseInt(client.workspace.id) : 0
      var safeWs = (wsId > 0) ? ("hyprctl dispatch workspace " + wsId + " 2>/dev/null; ") : ""
      var cmd = "if hyprctl dispatch " + dockWindow.shellQuote("hl.dsp.focus({ window = 'address:" + rawAddr + "' })") + " 2>/dev/null; then :; else " +
                safeWs +
                "hyprctl dispatch focuswindow " + dockWindow.shellQuote("address:" + rawAddr) + " 2>/dev/null; fi"
      Quickshell.execDetached(["bash", "-c", cmd])
      refreshTimer.restart()
    }

    function closeClient(client) {
      if (!client || !client.address) {
        var fallbackCmd = "if hyprctl dispatch \"hl.dsp.window.close()\" 2>/dev/null; then :; else hyprctl dispatch killactive 2>/dev/null; fi"
        Quickshell.execDetached(["bash", "-c", fallbackCmd])
        refreshTimer.restart()
        return
      }
      var rawAddr = String(client.address).trim()
      if (!/^0x[0-9a-fA-F]+$/.test(rawAddr)) return
      var cmd = "if hyprctl dispatch " + dockWindow.shellQuote("hl.dsp.window.close({ window = 'address:" + rawAddr + "' })") + " 2>/dev/null; then :; else hyprctl dispatch closewindow " + dockWindow.shellQuote("address:" + rawAddr) + " 2>/dev/null; fi"
      Quickshell.execDetached(["bash", "-c", cmd])
      refreshTimer.restart()
    }

    function resolveAppIcon(c) {
      if (!c) return ""
      var cls = c.class || ""
      var initCls = c.initialClass || ""
      var lowerCls = cls.toLowerCase()
      var lowerInit = initCls.toLowerCase()

      if (lowerCls.indexOf("telegram") !== -1 || lowerInit.indexOf("telegram") !== -1) {
        return "file://" + dockWindow.iconBasePath + "messages.svg"
      }
      if (lowerCls.indexOf("antigravity") !== -1 || lowerInit.indexOf("antigravity") !== -1) {
        return "file://" + dockWindow.iconBasePath + "antigravity-ide.svg"
      }
      if (lowerCls.indexOf("flea") !== -1 || lowerInit.indexOf("flea") !== -1 || lowerCls.indexOf("nautilus") !== -1 || lowerCls.indexOf("thunar") !== -1 || lowerCls.indexOf("dolphin") !== -1 || lowerCls.indexOf("nemo") !== -1 || lowerCls.indexOf("pcmanfm") !== -1) {
        return "file://" + dockWindow.iconBasePath + "finder.svg"
      }
      if (lowerCls.indexOf("terminal") !== -1 || lowerCls.indexOf("kitty") !== -1 || lowerCls.indexOf("alacritty") !== -1 || lowerCls.indexOf("foot") !== -1 || lowerCls.indexOf("ghostty") !== -1) {
        return "file://" + dockWindow.iconBasePath + "terminal.svg"
      }

      var candidates = [cls, initCls, lowerCls, lowerInit]
      var parts = cls.split(".")
      for (var i = parts.length - 1; i >= 0; i--) {
        if (parts[i]) {
          candidates.push(parts[i])
          candidates.push(parts[i].toLowerCase())
        }
      }

      for (var k = 0; k < candidates.length; k++) {
        var name = candidates[k]
        if (!name) continue
        var ip = Quickshell.iconPath(name)
        if (ip && ip.length > 0) {
          if (ip.indexOf("image://") === 0 || ip.indexOf("file://") === 0) return ip
          if (ip.indexOf("/") === 0) return "file://" + ip
          return ip
        }
      }

      return "image://icon/" + (initCls || cls || "application-x-executable")
    }

    function resolveModelIcon(modelData) {
      if (!modelData) return ""
      if (modelData.iconUrl) {
        return modelData.iconUrl
      }
      if (modelData.isDynamic && modelData.hyprClient) {
        return dockWindow.resolveAppIcon(modelData.hyprClient)
      }
      if (modelData.icon) {
        if (modelData.icon.indexOf("/") === 0) return "file://" + modelData.icon
        if (modelData.icon.indexOf("image://") === 0 || modelData.icon.indexOf("file://") === 0) return modelData.icon
        return "file://" + dockWindow.iconBasePath + modelData.icon
      }
      if (modelData.appId) {
        var ip = Quickshell.iconPath(modelData.appId)
        if (ip) {
          if (ip.indexOf("image://") === 0 || ip.indexOf("file://") === 0) return ip
          if (ip.indexOf("/") === 0) return "file://" + ip
          return ip
        }
        return "image://icon/" + modelData.appId
      }
      return ""
    }

    // Pinned apps configuration
    property var macPinsConfig: ({})
    FileView {
      id: defaultsFile
      path: dockWindow.homeDir + "/.config/omarchy-undercover/defaults.json"
      watchChanges: true
      onLoaded: {
        try {
          var d = JSON.parse(text())
          if (d && d.mac_pins) dockWindow.macPinsConfig = d.mac_pins
          if (d && d.mac_custom_apps) dockWindow.customDockApps = d.mac_custom_apps
        } catch(e) {}
        dockWindow.refreshDock()
      }
      onFileChanged: {
        reload()
        try {
          var d = JSON.parse(text())
          if (d && d.mac_pins) dockWindow.macPinsConfig = d.mac_pins
          if (d && d.mac_custom_apps) dockWindow.customDockApps = d.mac_custom_apps
        } catch(e) {}
        dockWindow.refreshDock()
      }
    }

    // Primary Curated macOS Sequoia Applications
    property var primaryDockApps: [
      { id: "finder", name: "Finder", icon: "finder.svg", exec: "omarchy-undercover-filemanager ~ || flea", matchers: ["flea", "nautilus", "thunar", "dolphin", "nemo", "pcmanfm", "files", "org.gnome.nautilus"] },
      { id: "launchpad", name: "Launchpad", icon: "launchpad.svg", exec: "rofi -show drun -theme ~/.config/rofi/mac.rasi", matchers: [] },
      { id: "safari", name: "Safari", icon: "safari.svg", exec: "omarchy-browser", matchers: ["safari", "chrome", "chromium", "firefox", "vivaldi", "brave", "zen", "browser", "epiphany"] },
      { id: "messages", name: "Messages", icon: "messages.svg", exec: "telegram-desktop || discord || signal-desktop || vesktop", matchers: ["telegram", "discord", "signal", "vesktop"] },
      { id: "mail", name: "Mail", icon: "mail.svg", exec: "thunderbird || geary || evolution || omarchy-browser https://mail.google.com", matchers: ["thunderbird", "geary", "evolution"] },
      { id: "maps", name: "Maps", icon: "maps.svg", exec: "gnome-maps || omarchy-browser https://maps.google.com", matchers: ["maps"] },
      { id: "photos", name: "Photos", icon: "photos.svg", exec: "eog || gwenview || loupe || shotwell", matchers: ["eog", "gwenview", "loupe", "shotwell"] },
      { id: "calendar", name: "Calendar", icon: "calendar.svg", exec: "gnome-calendar || korganizer || omarchy-browser https://calendar.google.com", matchers: ["calendar", "korganizer"] },
      { id: "notes", name: "Notes", icon: "notes.svg", exec: "gnome-notes || bijiben || obsidian", matchers: ["notes", "bijiben", "obsidian"] },
      { id: "reminders", name: "Reminders", icon: "reminders.svg", exec: "gnome-todo || korganizer", matchers: ["todo", "reminders"] },
      { id: "music", name: "Music", icon: "music.svg", exec: "spotify || rhythmbox || amberol", matchers: ["spotify", "rhythmbox", "amberol", "music"] },
      { id: "antigravity", name: "Antigravity IDE", icon: "antigravity-ide.svg", exec: "antigravity-ide || code || vscodium", matchers: ["antigravity", "code", "vscodium", "vscode", "codium"] },
      { id: "terminal", name: "Terminal", icon: "terminal.svg", exec: "xdg-terminal-exec || alacritty || kitty", matchers: ["kitty", "alacritty", "foot", "terminal", "wezterm", "ghostty", "ptyxis", "xterm"] },
      { id: "settings", name: "System Settings", icon: "settings.svg", exec: "omarchy-mac-settings", matchers: ["omarchy-mac-settings", "omarchy-undercover-settings", "org.omarchy.undercover.settings", "settings", "gnome-control-center"] },
      { id: "appstore", name: "App Store", icon: "appstore.svg", exec: "pamac-manager || gnome-software || discover", matchers: ["pamac", "software", "discover"] }
    ]

    function getVisibleDockApps() {
      var pinned = dockWindow.primaryDockApps.filter(function(app) {
        if (dockWindow.macPinsConfig && dockWindow.macPinsConfig[app.id] !== undefined) {
          return dockWindow.macPinsConfig[app.id] === true
        }
        return true
      })

      // Merge user-defined custom apps (respecting per-app mac_pins toggles)
      var custom = (dockWindow.customDockApps || []).filter(function(app) {
        if (dockWindow.macPinsConfig && dockWindow.macPinsConfig[app.id] !== undefined) {
          return dockWindow.macPinsConfig[app.id] === true
        }
        return true
      })

      var pinnedAndCustom = pinned.concat(custom)

      // Unpinned running applications from native Hyprland clients
      var unpinned = []
      var seenKeys = {}

      for (var i = 0; i < dockWindow.hyprClients.length; i++) {
        var c = dockWindow.hyprClients[i]
        if (!c || !c.address) continue
        var cls = (c.class || "").toLowerCase()
        var initCls = (c.initialClass || "").toLowerCase()
        var title = (c.title || "").toLowerCase()

        // Skip internal quickshell desktop overlays / bars / panels
        if (cls === "org.quickshell" || cls === "quickshell") continue

        var isPinned = pinnedAndCustom.some(function(p) {
          if (!p.matchers || p.matchers.length === 0) return false
          var target = (cls + " " + initCls + " " + title)
          return p.matchers.some(function(m) { return target.indexOf(m.toLowerCase()) !== -1 })
        })

        if (!isPinned) {
          var baseKey = (initCls || cls || "app")
          if (baseKey.indexOf("telegram") !== -1) baseKey = "telegram"
          if (!seenKeys[baseKey]) {
            seenKeys[baseKey] = true
            unpinned.push({
              id: "running_" + c.address,
              name: c.title || c.initialTitle || c.class || "Application",
              hyprClient: c,
              isDynamic: true,
              iconUrl: dockWindow.resolveAppIcon(c),
              appId: c.class || c.initialClass || "",
              icon: "",
              exec: "",
              matchers: [c.class || "", c.initialClass || ""]
            })
          }
        }
      }

      // Control the dock element count: keep pinned + custom, then cap running apps
      var fixed = pinnedAndCustom.length
      var dynamicBudget = Math.max(0, dockWindow.maxDockItems - fixed)
      var runningApps = unpinned.slice(0, dynamicBudget)

      return pinnedAndCustom.concat(runningApps)
    }

    function refreshDock() {
      dockAppsList = getVisibleDockApps()
    }

    Component.onCompleted: {
      dockWindow.refreshDock()
    }

    // Total slots used by the full dock row (apps + divider + trash), drives fit-scaling
    readonly property int dockItemCount: (dockWindow.dockAppsList && dockWindow.dockAppsList.length) ? (dockWindow.dockAppsList.length + 2) : 2

    // Native Wayland Bottom Edge Trigger Strip
    MouseArea {
      id: edgeTrigger
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 12
      hoverEnabled: true
      z: 20
      enabled: dockWindow.isAutohide && !dockWindow.isDockRevealed
      onEntered: {
        dockWindow.isDockRevealed = true
        hideTimer.stop()
        edgeInactivityTimer.restart()
      }
    }

    // Drop Shadow under dock
    Rectangle {
      anchors.horizontalCenter: dockCard.horizontalCenter
      anchors.bottom: dockCard.bottom
      anchors.bottomMargin: -2
      width: dockCard.width + 6
      height: dockCard.height + 4
      radius: dockCard.radius + 2
      color: Qt.rgba(0, 0, 0, 0.35)
      z: 0

      transform: Translate {
        y: (dockWindow.isAutohide && !dockWindow.isDockRevealed) ? (dockCard.height + Math.round(30 * dockWindow.responsiveScale)) : 0
        Behavior on y {
          NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
      }
    }

    // Sequoia Frosted Glass Dock Pill
    Rectangle {
      id: dockCard
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 6
      z: 1

      // Auto-Hide animated sliding translation
      transform: Translate {
        id: dockCardTranslate
        y: (dockWindow.isAutohide && !dockWindow.isDockRevealed) ? (dockCard.height + Math.round(30 * dockWindow.responsiveScale)) : 0
        Behavior on y {
          NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
      }

      implicitWidth: dockLayoutRow.implicitWidth + Math.round(20 * dockWindow.responsiveScale)
      implicitHeight: dockWindow.effectiveIconSize + Math.round(16 * dockWindow.responsiveScale)
      radius: Math.round(18 * dockWindow.responsiveScale)

      // Authentic Sequoia Glassmorphism
      color: dockWindow.isLight ? Qt.rgba(0.98, 0.98, 1.0, dockWindow.dockTransparency / 100.0) : Qt.rgba(0.12, 0.12, 0.16, dockWindow.dockTransparency / 100.0)
      border.color: dockWindow.isLight ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(1, 1, 1, 0.22)
      border.width: 1

      // Top Specular Highlight
      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 1
        color: Qt.rgba(1, 1, 1, 0.38)
      }

      RowLayout {
        id: dockLayoutRow
        anchors.centerIn: parent
        spacing: Math.round(4 * dockWindow.responsiveScale)

        // 1. Primary & Dynamic App Icons
        Repeater {
          id: appsRepeater
          model: dockWindow.dockAppsList

          Item {
            id: appItem
            // Fixed slot: layout never reflows during magnification, so the
            // icon wave stays perfectly stable under the cursor (no shaking).
            implicitWidth: dockWindow.effectiveIconSize
            implicitHeight: dockCard.height

            property var appData: modelData

            property var activeClient: {
              if (modelData.isDynamic) {
                if (dockWindow.hyprActiveWindow && dockWindow.hyprActiveWindow.address) {
                  var act = dockWindow.hyprActiveWindow
                  var actKey = ((act.initialClass || "") + " " + (act.class || "")).toLowerCase()
                  var myKey = (modelData.appId || "").toLowerCase()
                  if (myKey && actKey.indexOf(myKey) !== -1) {
                    return act
                  }
                }
                return modelData.hyprClient
              }
              return dockWindow.findRunningClient(modelData.matchers)
            }

            property bool appRunning: activeClient !== null && activeClient !== undefined
            property bool appFocused: dockWindow.isClientFocused(activeClient)
            property real bounceOffset: 0

            // Distance to mouse in dock coordinates (reactive)
            readonly property real itemCenterX: dockLayoutRow.x + appItem.x + appItem.width / 2
            readonly property real distToMouse: Math.abs(dockWindow.currentMouseX - itemCenterX)
            
            // Cosine Wave Magnification
            readonly property real targetScale: {
              if (!dockWindow.isMouseOverDock) return 1.0
              if (distToMouse >= dockWindow.effectRadius) return 1.0
              var ratio = distToMouse / dockWindow.effectRadius
              var factor = Math.cos(ratio * (Math.PI / 2))
              return 1.0 + (dockWindow.maxMagnification - 1.0) * factor * factor
            }

            property real currentScale: 1.0
            Behavior on currentScale {
              NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
            }
            Binding {
              target: appItem
              property: "currentScale"
              value: appItem.targetScale
            }

            function bounce() {
              bounceAnim.restart()
            }

            function launch(mouse) {
              bounce()
              if (mouse && (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton)) {
                if (appRunning && activeClient) {
                  dockWindow.closeClient(activeClient)
                  return
                }
              }
              if (appRunning && activeClient && activeClient.address) {
                if (appFocused) {
                  Quickshell.execDetached(["omarchy-undercover-minimize"])
                } else {
                  dockWindow.shiftToClient(activeClient)
                }
                return
              }
              if (appData && appData.exec) {
                Quickshell.execDetached(["bash", "-c", appData.exec])
              }
            }

            // Authentic 3-Stage macOS Launch Bounce
            SequentialAnimation {
              id: bounceAnim
              running: false
              NumberAnimation { target: appItem; property: "bounceOffset"; to: -24; duration: 140; easing.type: Easing.OutQuad }
              NumberAnimation { target: appItem; property: "bounceOffset"; to: 0; duration: 130; easing.type: Easing.InQuad }
              NumberAnimation { target: appItem; property: "bounceOffset"; to: -14; duration: 110; easing.type: Easing.OutQuad }
              NumberAnimation { target: appItem; property: "bounceOffset"; to: 0; duration: 90; easing.type: Easing.InQuad }
              NumberAnimation { target: appItem; property: "bounceOffset"; to: -5; duration: 70; easing.type: Easing.OutQuad }
              NumberAnimation { target: appItem; property: "bounceOffset"; to: 0; duration: 60; easing.type: Easing.InQuad }
            }

            // Tooltip
            Rectangle {
              id: tooltip
              visible: dockWindow.isMouseOverDock && appItem.distToMouse < Math.round(dockWindow.effectiveIconSize * 0.42)
              anchors.bottom: iconContainer.top
              anchors.bottomMargin: 8
              anchors.horizontalCenter: parent.horizontalCenter
              implicitWidth: Math.min(320, tooltipText.implicitWidth + 16)
              implicitHeight: 22
              radius: 5
              color: Qt.rgba(0.12, 0.12, 0.16, 0.94)
              border.color: Qt.rgba(1, 1, 1, 0.18)
              border.width: 1
              z: 99

              Text {
                id: tooltipText
                anchors.centerIn: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                width: Math.min(300, implicitWidth)
                text: modelData.name || "Application"
                font.family: "SF Pro Text, -apple-system, sans-serif"
                font.pixelSize: 11
                font.bold: true
                color: "#ffffff"
                elide: Text.ElideRight
              }
            }

            // Icon Container
            Item {
              id: iconContainer
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: Math.round(9 * dockWindow.responsiveScale)
              width: dockWindow.effectiveIconSize
              height: dockWindow.effectiveIconSize
              scale: appItem.currentScale
              transformOrigin: Item.Bottom
              z: Math.round(appItem.currentScale * 10)

              transform: Translate {
                y: appItem.bounceOffset
              }

              Image {
                id: appIcon
                anchors.fill: parent
                source: dockWindow.resolveModelIcon(modelData)
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                onStatusChanged: {
                  if (status === Image.Error && source !== ("file://" + dockWindow.iconBasePath + "appstore.svg")) {
                    source = "file://" + dockWindow.iconBasePath + "appstore.svg"
                  }
                }
              }
            }

            // Glowing Active Running Indicator Dot
            Rectangle {
              visible: appItem.appRunning
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 2
              width: appItem.appFocused ? 7.5 : 4
              height: 4
              radius: 2
              color: appItem.appFocused ? "#007aff" : (dockWindow.isLight ? Qt.rgba(0, 0, 0, 0.5) : Qt.rgba(1, 1, 1, 0.70))

              Behavior on width {
                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
              }
            }
          }
        }

        // 2. Vertical Glass Divider Separator
        Rectangle {
          Layout.preferredWidth: 1
          Layout.preferredHeight: Math.round(dockWindow.effectiveIconSize * 0.75)
          Layout.alignment: Qt.AlignVCenter
          color: dockWindow.isLight ? Qt.rgba(0, 0, 0, 0.16) : Qt.rgba(1, 1, 1, 0.20)
        }

        // 3. Special App: Trash Can
        Item {
          id: trashItem
          // Fixed slot (same stability principle as app items above)
          implicitWidth: dockWindow.effectiveIconSize
          implicitHeight: dockCard.height

          property real bounceOffset: 0
          readonly property real itemCenterX: dockLayoutRow.x + trashItem.x + trashItem.width / 2
          readonly property real distToMouse: Math.abs(dockWindow.currentMouseX - itemCenterX)
          readonly property real targetScale: {
            if (!dockWindow.isMouseOverDock) return 1.0
            if (distToMouse >= dockWindow.effectRadius) return 1.0
            var ratio = distToMouse / dockWindow.effectRadius
            var factor = Math.cos(ratio * (Math.PI / 2))
            return 1.0 + (dockWindow.maxMagnification - 1.0) * factor * factor
          }

          property real currentScale: 1.0
          Behavior on currentScale {
            NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
          }
          Binding {
            target: trashItem
            property: "currentScale"
            value: trashItem.targetScale
          }

          function bounce() {
            trashBounceAnim.restart()
          }

          function launch() {
            bounce()
            Quickshell.execDetached(["bash", "-c", "omarchy-undercover-filemanager trash:/// || flea trash:/// || thunar trash:/// || pcmanfm trash:/// || dolphin trash:///"])
          }

          SequentialAnimation {
            id: trashBounceAnim
            running: false
            NumberAnimation { target: trashItem; property: "bounceOffset"; to: -22; duration: 140; easing.type: Easing.OutQuad }
            NumberAnimation { target: trashItem; property: "bounceOffset"; to: 0; duration: 130; easing.type: Easing.InQuad }
            NumberAnimation { target: trashItem; property: "bounceOffset"; to: -10; duration: 100; easing.type: Easing.OutQuad }
            NumberAnimation { target: trashItem; property: "bounceOffset"; to: 0; duration: 80; easing.type: Easing.InQuad }
          }

          // Tooltip
          Rectangle {
            visible: dockWindow.isMouseOverDock && trashItem.distToMouse < Math.round(dockWindow.effectiveIconSize * 0.42)
            anchors.bottom: trashContainer.top
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: trashText.implicitWidth + 16
            implicitHeight: 22
            radius: 5
            color: Qt.rgba(0.12, 0.12, 0.16, 0.94)
            border.color: Qt.rgba(1, 1, 1, 0.18)
            border.width: 1
            z: 99

            Text {
              id: trashText
              anchors.centerIn: parent
              text: "Trash"
              font.family: "SF Pro Text, -apple-system, sans-serif"
              font.pixelSize: 11
              font.bold: true
              color: "#ffffff"
            }
          }

          Item {
            id: trashContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(9 * dockWindow.responsiveScale)
            width: dockWindow.effectiveIconSize
            height: dockWindow.effectiveIconSize
            scale: trashItem.currentScale
            transformOrigin: Item.Bottom
            z: Math.round(trashItem.currentScale * 10)

            transform: Translate {
              y: trashItem.bounceOffset
            }

            Image {
              anchors.fill: parent
              source: "file://" + dockWindow.iconBasePath + "trash.svg"
              fillMode: Image.PreserveAspectFit
              smooth: true
              mipmap: true
            }
          }
        }
      }

      // Unified MouseArea across dock for continuous wave tracking & click handling
      MouseArea {
        id: dockMouseArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        anchors.topMargin: -Math.round(dockWindow.effectiveIconSize * 0.75)
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onEntered: {
          dockWindow.isMouseOverDock = true
          dockWindow.isDockRevealed = true
          edgeInactivityTimer.stop()
          hideTimer.stop()
        }

        onExited: {
          dockWindow.isMouseOverDock = false
          if (dockWindow.isAutohide) {
            hideTimer.restart()
          }
        }

        onPositionChanged: function(mouse) {
          dockWindow.currentMouseX = mouse.x
        }

        onClicked: function(mouse) {
          var mx = mouse.x
          for (var i = 0; i < appsRepeater.count; i++) {
            var item = appsRepeater.itemAt(i)
            if (item) {
              var leftX = dockLayoutRow.x + item.x
              if (mx >= leftX && mx <= (leftX + item.width)) {
                item.launch(mouse)
                return
              }
            }
          }

          var trashLeft = dockLayoutRow.x + trashItem.x
          if (mx >= trashLeft && mx <= (trashLeft + trashItem.width)) {
            trashItem.launch()
          }
        }
      }
    }
  }
}
