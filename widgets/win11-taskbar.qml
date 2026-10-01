import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "win11-taskbar"

  readonly property bool interactive: true
  readonly property bool pressable: false
  readonly property bool concealed: false

  property string homeDir: Quickshell.env("HOME")
  property string configDir: homeDir + "/.config/omarchy/plugins/omarchy-undercover"
  property bool isDark: true
  property var winPinsConfig: ({})
  onWinPinsConfigChanged: root.refreshTaskbar()

  property var monitorsList: []

  function getMonitorLabel(monitorId) {
    if (root.monitorsList && root.monitorsList.length > 0) {
      for (var i = 0; i < root.monitorsList.length; i++) {
        var m = root.monitorsList[i]
        if (m && (m.id === monitorId || m.name === String(monitorId))) {
          var num = (i + 1)
          return "Screen " + num + (m.name ? " (" + m.name + ")" : "")
        }
      }
    }
    var mid = (typeof monitorId === "number") ? (monitorId + 1) : 1
    return "Screen " + mid
  }

  // Live Wayland Toplevel handles mapping for ScreencopyView
  property var toplevelByAddress: ({})
  property var handleByAddress: ({})

  function refreshToplevelMap() {
    var map = {}
    try {
      if (Hyprland && Hyprland.workspaces && Hyprland.workspaces.values) {
        var wss = Hyprland.workspaces.values
        for (var i = 0; i < wss.length; i++) {
          var tls = wss[i].toplevels ? wss[i].toplevels.values : []
          for (var j = 0; j < tls.length; j++) {
            var tl = tls[j]
            var raw = tl.address
            if (raw !== undefined && raw !== null) {
              var addrStr = String(raw).toLowerCase().trim()
              if (addrStr && addrStr !== "0") {
                map[addrStr] = tl.wayland
                if (addrStr.indexOf("0x") === 0) {
                  map[addrStr.slice(2)] = tl.wayland
                } else {
                  map["0x" + addrStr] = tl.wayland
                }
              }
            }
          }
        }
      }
    } catch(e) {}
    root.toplevelByAddress = map
  }

  function buildHandles() {
    var map = {}
    try {
      var tls = (ToplevelManager && ToplevelManager.toplevels) ? ToplevelManager.toplevels.values : []
      for (var i = 0; i < tls.length; i++) {
        var t = tls[i]
        var h = t.HyprlandToplevel
        if (h) {
          if (!t._boundAddress) {
            t._boundAddress = true
            h.addressChanged.connect(root.buildHandles)
          }
          var raw = h.address
          if (raw !== undefined && raw !== null) {
            var addrStr = String(raw).toLowerCase().trim()
            if (addrStr && addrStr !== "0") {
              map[addrStr] = t
              if (addrStr.indexOf("0x") === 0) {
                map[addrStr.slice(2)] = t
              } else {
                map["0x" + addrStr] = t
              }
            }
            if (typeof raw === "number") {
              var hex = raw.toString(16).toLowerCase()
              map[hex] = t
              map["0x" + hex] = t
            }
          }
        }
      }
    } catch(e) {}
    root.handleByAddress = map
  }

  Connections {
    target: (ToplevelManager && ToplevelManager.toplevels) ? ToplevelManager.toplevels : null
    function onValuesChanged() { root.buildHandles() }
  }

  Component.onCompleted: {
    root.buildHandles()
    root.refreshToplevelMap()
    if (Hyprland && Hyprland.refreshToplevels) {
      Hyprland.refreshToplevels()
    }
  }

  // Dynamic Bar-Aware Contrast Detection
  readonly property bool isBarLight: !root.isDark

  readonly property real scaleFactor: (root.screen && root.screen.devicePixelRatio) ? root.screen.devicePixelRatio : 1.0
  readonly property int barH: root.bar ? root.bar.barSize : 24
  readonly property int tileHeight: barH <= 28 ? (barH - 2) : Math.max(34, barH - 8)
  readonly property int tileWidth: Math.round(tileHeight * 1.25)
  readonly property int iconSize: barH <= 28 ? 16 : Math.round(tileHeight * 0.60)
  readonly property int itemSpacing: Math.max(2, Math.round(4 * root.scaleFactor))

  property var taskbarItems: []

  function refreshTaskbar() {
    root.taskbarItems = root.getAllTaskbarItems()
  }

  readonly property int dynamicContentWidth: (root.taskbarItems.length * root.tileWidth) + (Math.max(0, root.taskbarItems.length - 1) * root.itemSpacing) + Math.round(16 * root.scaleFactor)

  implicitWidth: Math.max(dynamicContentWidth, taskbarRow.implicitWidth + Math.round(16 * root.scaleFactor))
  implicitHeight: root.bar ? root.bar.barSize : 24

  Behavior on implicitWidth {
    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
  }

  function shellQuote(val) {
    return "'" + String(val || "").replace(/'/g, "'\\''") + "'"
  }

  function resolveCmd(cmd) {
    if (!cmd) return ""
    var pluginScripts = root.configDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    return cmd.replace(/\b(omarchy-[a-zA-Z0-9_-]+)\b/g, function(match) {
      return pluginScripts + "/" + match
    })
  }

  function runCmd(cmd) {
    var pluginScripts = root.configDir + "/scripts"
    var devScripts = root.homeDir + "/omarchy-undercover/scripts"
    var fullCmd = root.resolveCmd(cmd)
    var wrapped = "export PATH=\"" + pluginScripts + ":" + devScripts + ":$PATH\"; " + fullCmd
    Quickshell.execDetached(["bash", "-c", wrapped])
  }

  function shiftToClient(client) {
    if (!client || !client.address) return
    var rawAddr = String(client.address).toLowerCase().trim()
    if (!rawAddr.startsWith("0x")) rawAddr = "0x" + rawAddr
    if (!/^0x[0-9a-fA-F]+$/.test(rawAddr)) return

    var wsId = 0
    if (client.workspace) {
      wsId = (client.workspace.id !== undefined) ? parseInt(client.workspace.id) : (typeof client.workspace === "number" ? client.workspace : 0)
    }
    if (wsId < 0) {
      var minScript = root.configDir + "/scripts/omarchy-undercover-minimize"
      Quickshell.execDetached([minScript, rawAddr])
      refreshTimer.restart()
      return
    }

    var monArg = (client.monitor !== undefined && client.monitor !== null && client.monitor !== "")
      ? ('hyprctl dispatch "hl.dsp.focus({ monitor = ' + client.monitor + ' })" >/dev/null 2>&1 || true; ') : ""
    var cmd = monArg +
              'if hyprctl dispatch "hl.dsp.focus({ window = \\"address:' + rawAddr + '\\" })" >/dev/null 2>&1; then :; else ' +
              'hyprctl dispatch focuswindow "address:' + rawAddr + '" >/dev/null 2>&1; fi; ' +
              'hyprctl dispatch "hl.dsp.window.bring_to_top()" >/dev/null 2>&1 || true;'
    Quickshell.execDetached(["bash", "-c", cmd])
    refreshTimer.restart()
  }

  function closeClient(client) {
    if (!client || !client.address) {
      var fallbackCmd = 'if hyprctl dispatch "hl.dsp.window.close()" 2>/dev/null; then :; else hyprctl dispatch killactive 2>/dev/null; fi'
      if (root.bar) root.bar.run(fallbackCmd)
      else Quickshell.execDetached(["bash", "-c", fallbackCmd])
      refreshTimer.restart()
      return
    }
    var rawAddr = String(client.address).toLowerCase().trim()
    if (!rawAddr.startsWith("0x")) rawAddr = "0x" + rawAddr
    if (!/^0x[0-9a-fA-F]+$/.test(rawAddr)) return
    var cmd = 'if hyprctl dispatch "hl.dsp.window.close({ window = \\"address:' + rawAddr + '\\" })" >/dev/null 2>&1; then :; else hyprctl dispatch closewindow "address:' + rawAddr + '" >/dev/null 2>&1; fi'
    if (root.bar) root.bar.run(cmd)
    else Quickshell.execDetached(["bash", "-c", cmd])
    refreshTimer.restart()
  }

  function switchToWorkspace(ws) {
    var rawWs = String(ws).trim()
    if (!/^[0-9a-zA-Z_+-]+$/.test(rawWs)) return
    var wsArg = /^[0-9]+$/.test(rawWs) ? rawWs : ('\\"' + rawWs + '\\"')
    var cmd = 'if hyprctl dispatch "hl.dsp.focus({ workspace = ' + wsArg + ' })" >/dev/null 2>&1; then :; else hyprctl dispatch workspace "' + rawWs + '" >/dev/null 2>&1; fi'
    if (root.bar) root.bar.run(cmd)
    else Quickshell.execDetached(["bash", "-c", cmd])
    refreshTimer.restart()
  }

  function seekWorkspace(delta) {
    var wsArg = delta > 0 ? "e-1" : "e+1"
    var cmd = 'if hyprctl dispatch "hl.dsp.focus({ workspace = \\"' + wsArg + '\\" })" >/dev/null 2>&1; then :; else hyprctl dispatch workspace "' + wsArg + '" >/dev/null 2>&1; fi'
    if (root.bar) root.bar.run(cmd)
    else Quickshell.execDetached(["bash", "-c", cmd])
    refreshTimer.restart()
  }

  function getClientsForWorkspace(wsId) {
    if (!root.hyprClients || root.hyprClients.length === 0) return []
    return root.hyprClients.filter(function(c) {
      return c && c.workspace && c.workspace.id === wsId
    })
  }

  function closeWorkspace(wsId) {
    var cls = root.getClientsForWorkspace(wsId)
    var targetWs = (wsId > 1) ? (wsId - 1) : 1
    for (var i = 0; i < cls.length; i++) {
      if (cls[i] && cls[i].address) {
        Quickshell.execDetached(["hyprctl", "dispatch", "movetoworkspacesilent", targetWs + ",address:" + cls[i].address])
      }
    }
    if (root.activeWorkspaceId === wsId) {
      root.switchToWorkspace(targetWs.toString())
    }
    refreshTimer.restart()
  }

  // Workspaces & Running Windows Tracking via Native Hyprland State
  property var workspaceList: [1, 2, 3, 4]
  property int activeWorkspaceId: 1
  property var hyprClients: []
  property var hyprActiveWindow: ({})

  Process {
    id: hyprStateProc
    command: [
      "bash", "-c",
      "hyprctl --batch 'j/activeworkspace ; j/workspaces ; j/clients ; j/activewindow ; j/monitors' 2>/dev/null | jq -s -c '{actWs: (.[0] // {}), allWs: (.[1] // []), cls: (.[2] // []), actWin: (.[3] // {}), mons: (.[4] // [])}'"
    ]
    stdout: SplitParser {
      onRead: function(line) {
        if (!line) return
        try {
          var data = JSON.parse(line.trim())
          if (data.actWs && data.actWs.id) {
            root.activeWorkspaceId = data.actWs.id
          }
          if (Array.isArray(data.allWs)) {
            var ids = data.allWs.map(function(w) { return w.id }).filter(function(id) { return id > 0 && id <= 10 })
            ids.sort(function(a, b) { return a - b })
            if (ids.indexOf(root.activeWorkspaceId) === -1 && root.activeWorkspaceId > 0) {
              ids.push(root.activeWorkspaceId)
              ids.sort(function(a, b) { return a - b })
            }
            if (ids.length === 0) ids = [1]
            root.workspaceList = ids
          }
          if (Array.isArray(data.cls)) {
            var rawList = data.cls.filter(function(c) { return c && c.mapped && !c.hidden })
            for (var k = 0; k < rawList.length; k++) {
              var a = String(rawList[k].address || "").toLowerCase().trim()
              rawList[k].toplevel = root.toplevelByAddress[a] || root.handleByAddress[a] || null
            }
            root.hyprClients = rawList
          }
          if (data.actWin && data.actWin.address) {
            root.hyprActiveWindow = data.actWin
          } else {
            root.hyprActiveWindow = ({})
          }
          if (Array.isArray(data.mons)) {
            root.monitorsList = data.mons
          }
        } catch(e) {}
        root.refreshTaskbar()
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
      root.refreshToplevelMap()
      if (!hyprStateProc.running) hyprStateProc.running = true
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      switch (event.name) {
      case "activewindowv2":
      case "closewindow":
      case "openwindow":
      case "movewindow":
      case "movewindowv2":
      case "changefloatingmode":
      case "windowtitle":
      case "windowtitlev2":
        refreshDebounce.restart()
        break
      }
    }
  }

  Timer {
    id: refreshDebounce
    interval: 100
    onTriggered: {
      if (Hyprland && Hyprland.refreshToplevels) {
        Hyprland.refreshToplevels()
      }
      root.refreshToplevelMap()
      refreshTimer.restart()
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

  function isClientMatching(c, matchers) {
    if (!c || !matchers || matchers.length === 0) return false
    var cls = String(c.class || "").toLowerCase().trim()
    var initCls = String(c.initialClass || "").toLowerCase().trim()
    for (var j = 0; j < matchers.length; j++) {
      var m = String(matchers[j] || "").toLowerCase().trim()
      if (!m) continue
      if (cls === m || initCls === m) return true
      if (cls.indexOf(m) !== -1 || initCls.indexOf(m) !== -1) return true
    }
    return false
  }

  function findAllRunningClients(matchers) {
    if (!matchers || matchers.length === 0) return []
    var list = []
    for (var i = 0; i < root.hyprClients.length; i++) {
      var c = root.hyprClients[i]
      if (!c || !c.address) continue
      if (root.isClientMatching(c, matchers)) {
        list.push(c)
      }
    }
    return list
  }

  function isClientFocused(client) {
    if (!client || !client.address) return false
    var addr = String(client.address).toLowerCase().trim().replace(/^0x/, "")
    if (root.hyprActiveWindow && root.hyprActiveWindow.address) {
      var actAddr = String(root.hyprActiveWindow.address).toLowerCase().trim().replace(/^0x/, "")
      if (addr === actAddr) return true
    }
    try {
      if (Hyprland.activeToplevel && Hyprland.activeToplevel.address) {
        var hAddr = String(Hyprland.activeToplevel.address).toLowerCase().trim().replace(/^0x/, "")
        if (addr === hAddr) return true
      }
    } catch(e) {}
    return false
  }

  function resolveAppIcon(c) {
    if (!c) return ""
    var cls = (c.initialClass || c.class || "").toLowerCase()
    if (cls.indexOf("telegram") !== -1) {
      return Quickshell.iconPath("telegram") || Quickshell.iconPath("org.telegram.desktop") || ("file://" + root.configDir + "/assets/icons/win11/discord.svg")
    }
    if (cls.indexOf("antigravity") !== -1) {
      return "file://" + root.configDir + "/assets/icons/win11/antigravity-ide.svg"
    }
    var ip = Quickshell.iconPath(c.class) || Quickshell.iconPath(c.initialClass)
    if (ip) return ip
    var parts = cls.split(".")
    for (var i = parts.length - 1; i >= 0; i--) {
      var p = Quickshell.iconPath(parts[i])
      if (p) return p
    }
    return "image://icon/" + (c.initialClass || c.class)
  }

  function formatAppName(c) {
    if (!c) return "Application"
    var raw = c.initialClass || c.class || ""
    if (raw) {
      var parts = raw.split(".")
      var base = parts[parts.length - 1]
      if (base.toLowerCase().indexOf("org.") === 0) base = base.slice(4)
      base = base.replace(/-stable$|-bin$|-desktop$/i, "")
      base = base.replace(/[-_]/g, " ")
      if (base.length > 0) {
        return base.charAt(0).toUpperCase() + base.slice(1)
      }
    }
    return c.title || c.initialTitle || "Application"
  }

  FileView {
    id: stateWatcher
    path: root.configDir + "/state"
    watchChanges: true
    printErrors: false
    onLoaded: {
      var s = text().trim()
      root.isDark = (s.indexOf("light") === -1)
    }
    onFileChanged: {
      reload()
      var s = text().trim()
      root.isDark = (s.indexOf("light") === -1)
    }
  }

  function applyDefaultsConfig(d) {
    if (!d) return
    if (d.win11_pins) root.winPinsConfig = d.win11_pins
    var term = d.terminal || "kitty"
    var ed = d.editor || "antigravity-ide"
    var fm = d.file_manager || "flea"
    var br = d.browser || "microsoft-edge"

    for (var i = 0; i < root.winApps.length; i++) {
      var app = root.winApps[i]
      if (app.id === "browser" && br && br !== "auto") {
        app.exec = (br === "microsoft-edge") ? "omarchy-browser" : (br + " || omarchy-browser")
        if (app.matchers.indexOf(br) === -1) app.matchers.unshift(br)
      } else if (app.id === "terminal" && term && term !== "auto") {
        app.exec = term + " || xdg-terminal-exec || alacritty"
        if (app.matchers.indexOf(term) === -1) app.matchers.unshift(term)
      } else if (app.id === "antigravity" && ed && ed !== "auto") {
        app.exec = ed + " || antigravity-ide || code"
        if (app.matchers.indexOf(ed) === -1) app.matchers.unshift(ed)
      } else if (app.id === "explorer" && fm && fm !== "auto") {
        app.exec = "omarchy-undercover-filemanager ~ || " + fm
        if (app.matchers.indexOf(fm) === -1) app.matchers.unshift(fm)
      }
    }
    root.refreshTaskbar()
  }

  FileView {
    id: defaultsFile
    path: root.configDir + "/defaults.json"
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var d = JSON.parse(text())
        root.applyDefaultsConfig(d)
      } catch(e) {}
    }
    onFileChanged: {
      reload()
      try {
        var d = JSON.parse(text())
        root.applyDefaultsConfig(d)
      } catch(e) {}
    }
  }

  property var winApps: [
    { id: "start", name: "Start", isStart: true, iconFile: "start.svg", exec: "omarchy-win11-start", matchers: [] },
    { id: "taskview", name: "Task View", isTaskView: true, iconFile: "taskview.svg", exec: "omarchy-win11-taskview", matchers: [] },
    { id: "explorer", name: "File Explorer", iconFile: "explorer.svg", exec: "omarchy-undercover-filemanager ~ || flea", matchers: ["flea", "nautilus", "thunar", "dolphin", "nemo", "pcmanfm", "files", "org.gnome.nautilus"] },
    { id: "browser", name: "Microsoft Edge", iconFile: "microsoft-edge.svg", exec: "omarchy-browser", matchers: ["edge", "microsoft-edge", "chrome", "chromium", "firefox", "vivaldi", "brave", "zen", "browser", "google-chrome"] },
    { id: "antigravity", name: "Antigravity IDE", iconFile: "antigravity-ide.svg", exec: "antigravity-ide || code || vscodium", matchers: ["antigravity", "code", "vscodium", "vscode", "codium"] },
    { id: "terminal", name: "Terminal", iconFile: "terminal.svg", exec: "xdg-terminal-exec || alacritty || kitty", matchers: ["kitty", "alacritty", "foot", "terminal", "wezterm", "ghostty", "ptyxis", "xterm", "console"] },
    { id: "notepad", name: "Notepad", iconFile: "notepad.svg", exec: "gedit || kate || mousepad || gnome-text-editor", matchers: ["gedit", "kate", "mousepad", "gnome-text-editor", "text-editor", "sublime_text", "nvim", "kwrite"] },
    { id: "settings", name: "Settings", iconFile: "settings.svg", exec: "omarchy-undercover-settings", matchers: ["omarchy-undercover-settings", "org.omarchy.undercover.settings", "settings", "gnome-control-center"] }
  ]

  function getVisiblePinnedApps() {
    return root.winApps.filter(function(app) {
      if (root.winPinsConfig && root.winPinsConfig[app.id] !== undefined) {
        return root.winPinsConfig[app.id] === true
      }
      return true
    })
  }

  function getUnpinnedRunningApps() {
    var pinned = root.getVisiblePinnedApps()
    var unpinnedMap = {}
    var order = []

    for (var i = 0; i < root.hyprClients.length; i++) {
      var c = root.hyprClients[i]
      if (!c || !c.address) continue
      var cls = (c.class || "").toLowerCase().trim()
      var initCls = (c.initialClass || "").toLowerCase().trim()
      var title = (c.title || "").toLowerCase().trim()

      if (cls === "org.quickshell" && (title === "" || title === "quickshell")) continue

      var isPinned = pinned.some(function(p) {
        return root.isClientMatching(c, p.matchers)
      })

      if (!isPinned) {
        var baseKey = (initCls || cls || "app")
        if (baseKey.indexOf("telegram") !== -1) baseKey = "telegram"
        if (!unpinnedMap[baseKey]) {
          var rawMatchers = []
          if (c.class) rawMatchers.push(c.class)
          if (c.initialClass && rawMatchers.indexOf(c.initialClass) === -1) rawMatchers.push(c.initialClass)
          unpinnedMap[baseKey] = {
            id: "running_" + (c.class || c.address),
            name: root.formatAppName(c),
            hyprClient: c,
            isStart: false,
            isTaskView: false,
            isDynamic: true,
            iconUrl: root.resolveAppIcon(c),
            appId: c.class || c.initialClass || "",
            iconFile: "",
            exec: "",
            matchers: rawMatchers,
            instances: [c]
          }
          order.push(baseKey)
        } else {
          unpinnedMap[baseKey].instances.push(c)
        }
      }
    }

    var result = []
    for (var k = 0; k < order.length; k++) {
      result.push(unpinnedMap[order[k]])
    }
    return result
  }

  function getAllTaskbarItems() {
    var pinned = root.getVisiblePinnedApps()
    var showRunning = (root.winPinsConfig && root.winPinsConfig["running_apps"] !== undefined) ? (root.winPinsConfig["running_apps"] === true) : true
    var running = showRunning ? root.getUnpinnedRunningApps() : []
    return pinned.concat(running)
  }

  // ------------------------------------------------------------ Preview Popup Coordination (PopupCard)
  property var previewTargetItem: null
  property var previewTargetClients: []
  property string previewMode: "none" // "app" | "taskview" | "tooltip"
  property bool previewOpen: false
  property bool previewPinned: false
  property string tooltipString: ""

  Item {
    id: previewAnchor
    property bool animate: false
    visible: false

    Behavior on x { enabled: previewAnchor.animate; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    Behavior on y { enabled: previewAnchor.animate; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    onXChanged: if (previewPopup.visible) previewPopup.anchor.updateAnchor()
    onYChanged: if (previewPopup.visible) previewPopup.anchor.updateAnchor()
  }

  QtObject {
    id: previewBar
    readonly property string position: root.bar ? root.bar.position : "bottom"
    property var activePopout: null
    function requestPopout(owner) {}
    function releasePopout(owner) {}
  }

  function placePreviewAnchor(itemBox) {
    if (!itemBox) return
    var p = itemBox.mapToItem(root, 0, 0)
    previewAnchor.animate = root.previewOpen
    previewAnchor.x = p.x
    previewAnchor.y = p.y
    previewAnchor.width = itemBox.width
    previewAnchor.height = itemBox.height
  }

  function showAppPreview(itemBox, pinned) {
    if (!itemBox) return
    root.previewTargetItem = itemBox
    root.previewTargetClients = itemBox.activeClients || []
    root.previewMode = "app"
    root.placePreviewAnchor(itemBox)
    if (pinned !== undefined) root.previewPinned = pinned
    root.previewOpen = true
    previewHideTimer.stop()
  }

  function showTaskViewPreview(itemBox, pinned) {
    if (!itemBox) return
    root.previewTargetItem = itemBox
    root.previewTargetClients = []
    root.previewMode = "taskview"
    root.placePreviewAnchor(itemBox)
    if (pinned !== undefined) root.previewPinned = pinned
    root.previewOpen = true
    previewHideTimer.stop()
  }

  function showTooltipFor(itemBox, text) {
    if (!itemBox || !text) return
    root.previewTargetItem = itemBox
    root.previewTargetClients = []
    root.tooltipString = text
    root.previewMode = "tooltip"
    root.placePreviewAnchor(itemBox)
    root.previewPinned = false
    root.previewOpen = true
    previewHideTimer.stop()
  }

  function toggleAppPreview(itemBox) {
    if (root.previewOpen && root.previewTargetItem === itemBox && root.previewMode === "app") {
      root.hidePreview(true)
    } else {
      root.showAppPreview(itemBox, true)
    }
  }

  function toggleTaskViewPreview(itemBox) {
    if (root.previewOpen && root.previewTargetItem === itemBox && root.previewMode === "taskview") {
      root.hidePreview(true)
    } else {
      root.showTaskViewPreview(itemBox, true)
    }
  }

  function hidePreview(force) {
    if (root.previewPinned && !force) return
    previewHideTimer.stop()
    root.previewOpen = false
    root.previewPinned = false
    root.previewMode = "none"
    root.previewTargetItem = null
    root.previewTargetClients = []
  }

  function scheduleHidePreview() {
    if (root.previewPinned) return
    previewHideTimer.restart()
  }

  Timer {
    id: previewHideTimer
    interval: 220
    repeat: false
    onTriggered: {
      if (!root.previewPinned && !previewPopup.containsMouse) {
        root.hidePreview(true)
      }
    }
  }

  function calcPopupWidth() {
    if (root.previewMode === "taskview") {
      var wCount = (root.hyprClients && root.hyprClients.length > 0) ? Math.min(4, root.hyprClients.length) : 0
      var wWidth = wCount * 172
      var dWidth = (root.workspaceList ? root.workspaceList.length : 4) * 112 + 96
      return Math.min(previewPopup.availableCardWidth > 0 ? previewPopup.availableCardWidth : 920, Math.max(340, Math.max(dWidth, wWidth) + 24))
    }
    if (root.previewMode === "tooltip") {
      return Math.max(70, tooltipText.implicitWidth + 24)
    }
    if (root.previewMode === "app") {
      var count = (root.previewTargetClients && root.previewTargetClients.length > 0) ? root.previewTargetClients.length : 1
      var itemW = 208
      var totalW = (count * itemW) + ((count - 1) * 8) + 24
      var maxW = previewPopup.availableCardWidth > 0 ? previewPopup.availableCardWidth : 960
      return Math.min(maxW, Math.max(220, totalW))
    }
    return 240
  }

  function calcPopupHeight() {
    if (root.previewMode === "taskview") {
      return (root.hyprClients && root.hyprClients.length > 0) ? 250 : 120
    }
    if (root.previewMode === "tooltip") {
      return 26
    }
    if (root.previewMode === "app") {
      var hasHeader = root.previewTargetClients && root.previewTargetClients.length > 1
      return hasHeader ? 180 : 154
    }
    return 100
  }

  // ------------------------------------------------------------ Main Taskbar Items Row
  RowLayout {
    id: taskbarRow
    anchors.centerIn: parent
    spacing: root.itemSpacing

    Repeater {
      model: root.taskbarItems

      Rectangle {
        id: itemBox
        implicitWidth: root.tileWidth
        implicitHeight: root.tileHeight
        Layout.preferredWidth: root.tileWidth
        Layout.preferredHeight: root.tileHeight
        Layout.alignment: Qt.AlignVCenter
        radius: 4
        property var itemData: modelData

        property var activeClients: {
          if (modelData.matchers && modelData.matchers.length > 0) {
            return root.findAllRunningClients(modelData.matchers)
          }
          if (modelData.instances && modelData.instances.length > 0) {
            return modelData.instances
          }
          if (modelData.hyprClient) {
            return [modelData.hyprClient]
          }
          return []
        }

        property var activeClient: {
          if (activeClients && activeClients.length > 0) {
            for (var i = 0; i < activeClients.length; i++) {
              if (root.isClientFocused(activeClients[i])) return activeClients[i];
            }
            return activeClients[0];
          }
          return null
        }
        property bool appRunning: activeClients && activeClients.length > 0
        property bool appFocused: root.isClientFocused(activeClient)

        readonly property bool interactive: true
        readonly property bool pressable: true
        readonly property bool concealed: false

        property var registeredBar: null

        function syncClickRegistration() {
          if (registeredBar && registeredBar.unregisterClickTarget) {
            registeredBar.unregisterClickTarget(itemBox)
            registeredBar = null
          }
          if (root.bar && root.bar.registerClickTarget) {
            registeredBar = root.bar
            registeredBar.registerClickTarget(itemBox)
          }
        }

        Connections {
          target: root
          function onBarChanged() {
            itemBox.syncClickRegistration()
          }
        }

        Component.onCompleted: {
          itemBox.syncClickRegistration()
        }

        Component.onDestruction: {
          if (registeredBar && registeredBar.unregisterClickTarget) {
            registeredBar.unregisterClickTarget(itemBox)
            registeredBar = null
          }
        }

        function triggerPress(button) {
          itemBox.handleClick(button)
        }

        function handleClick(button) {
          if (button === Qt.MiddleButton) {
            if (itemBox.appRunning && itemBox.activeClient) {
              root.closeClient(itemBox.activeClient)
            } else if (modelData.exec) {
              root.runCmd(modelData.exec)
            }
          } else if (button === Qt.RightButton) {
            if (modelData.isStart) {
              root.runCmd("omarchy-undercover-settings")
            } else if (itemBox.appRunning && itemBox.activeClient) {
              root.closeClient(itemBox.activeClient)
            } else {
              root.runCmd("omarchy-win11-taskmanager || omarchy-win11-taskview")
            }
          } else {
            // Left Click
            if (modelData.isStart) {
              root.hidePreview(true)
              root.runCmd(modelData.exec)
              return
            }
            if (modelData.isTaskView) {
              root.toggleTaskViewPreview(itemBox)
              return
            }
            if (itemBox.appRunning) {
              var clients = itemBox.activeClients || []
              if (clients.length > 1) {
                root.toggleAppPreview(itemBox)
                return
              } else if (clients.length === 1 && itemBox.activeClient) {
                if (itemBox.appFocused) {
                  root.runCmd("omarchy-undercover-minimize")
                } else {
                  root.shiftToClient(itemBox.activeClient)
                }
                root.hidePreview(true)
                return
              }
            }
            root.hidePreview(true)
            if (modelData.exec) {
              root.runCmd(modelData.exec)
            }
          }
        }

        color: itemMouse.pressed
               ? (root.isBarLight ? Qt.rgba(0, 0, 0, 0.16) : Qt.rgba(1, 1, 1, 0.18))
               : (appFocused
                  ? (root.isBarLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.12))
                  : (itemMouse.containsMouse ? (root.isBarLight ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.08)) : "transparent"))

        border.color: itemMouse.containsMouse
                      ? (root.isBarLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.14))
                      : (appFocused ? (root.isBarLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.10)) : "transparent")
        border.width: 1

        scale: itemMouse.pressed ? 0.94 : (itemMouse.containsMouse ? 1.04 : 1.0)
        Behavior on scale {
          NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }

        // 1. Windows 11 Start Icon
        Item {
          visible: modelData.isStart === true
          anchors.fill: parent

          Image {
            anchors.centerIn: parent
            width: Math.round(root.iconSize * 0.92)
            height: Math.round(root.iconSize * 0.92)
            sourceSize: Qt.size(Math.round(root.iconSize * 0.92), Math.round(root.iconSize * 0.92))
            source: "file://" + root.configDir + "/assets/icons/win11/start.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
          }
        }

        // 2. Windows 11 Task View Dynamic High-Contrast Icon
        Item {
          visible: modelData.isTaskView === true
          anchors.fill: parent

          Item {
            anchors.centerIn: parent
            width: Math.round(root.iconSize * 0.88)
            height: Math.round(root.iconSize * 0.88)

            Rectangle {
              x: 0; y: 0
              width: Math.round(parent.width * 0.72)
              height: Math.round(parent.height * 0.72)
              radius: 2
              color: "transparent"
              border.width: 1.6
              border.color: root.isBarLight ? Qt.rgba(0, 0, 0, 0.75) : Qt.rgba(1, 1, 1, 0.85)
            }

            Rectangle {
              x: Math.round(parent.width * 0.28)
              y: Math.round(parent.height * 0.28)
              width: Math.round(parent.width * 0.72)
              height: Math.round(parent.height * 0.72)
              radius: 2
              color: root.isBarLight ? Qt.rgba(0, 0.4, 0.8, 0.22) : Qt.rgba(0, 0.47, 0.83, 0.35)
              border.width: 1.6
              border.color: root.isBarLight ? "#0067c0" : "#60cdff"
            }
          }

          Rectangle {
            visible: root.workspaceList.length > 1
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 1
            width: 13
            height: 13
            radius: 6.5
            color: root.isBarLight ? "#0067c0" : "#60cdff"
            z: 5

            Text {
              anchors.centerIn: parent
              text: root.activeWorkspaceId.toString()
              font.family: "Segoe UI"
              font.pixelSize: 8
              font.bold: true
              color: root.isBarLight ? "#ffffff" : "#000000"
            }
          }
        }

        // 3. Pinned Apps with Authentic Windows 11 SVGs
        Item {
          visible: !modelData.isStart && !modelData.isTaskView && !modelData.isDynamic
          anchors.fill: parent

          Image {
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            sourceSize: Qt.size(root.iconSize, root.iconSize)
            source: modelData.iconFile ? ("file://" + root.configDir + "/assets/icons/win11/" + modelData.iconFile) : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
          }
        }

        // 4. Dynamic Application Icon
        Item {
          visible: modelData.isDynamic === true
          anchors.fill: parent

          Image {
            id: dynamicAppIcon
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            sourceSize: Qt.size(root.iconSize, root.iconSize)
            source: modelData.iconUrl || ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
          }

          Text {
            visible: dynamicAppIcon.status !== Image.Ready
            anchors.centerIn: parent
            text: "🗔"
            font.pixelSize: Math.round(root.iconSize * 0.75)
            color: root.isBarLight ? "#111111" : "#ffffff"
          }
        }

        // 5. Numeric Multi-Instance Notification Badge (e.g. "2", "3")
        Rectangle {
          id: instanceBadge
          visible: !modelData.isStart && !modelData.isTaskView && itemBox.appRunning && itemBox.activeClients.length > 1
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.topMargin: 1
          anchors.rightMargin: 1
          implicitWidth: Math.max(14, badgeText.implicitWidth + 6)
          implicitHeight: 14
          radius: 7
          color: root.isBarLight ? "#0067c0" : "#60cdff"
          z: 20

          Text {
            id: badgeText
            anchors.centerIn: parent
            text: itemBox.activeClients.length.toString()
            font.family: "Segoe UI"
            font.pixelSize: 9
            font.bold: true
            color: root.isBarLight ? "#ffffff" : "#000000"
          }
        }

        // 6a. Single Instance Pill Indicator Under Icon
        Rectangle {
          id: bottomIndicator
          visible: !modelData.isStart && !modelData.isTaskView && itemBox.appRunning && (itemBox.activeClients.length <= 1)
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 0
          anchors.horizontalCenter: parent.horizontalCenter
          width: itemBox.appFocused ? (root.barH <= 28 ? 14 : 16) : (itemMouse.containsMouse ? (root.barH <= 28 ? 9 : 10) : 6)
          height: (root.barH <= 28) ? 2 : 3
          radius: 1
          z: 10
          color: itemBox.appFocused
                 ? (root.isBarLight ? "#0067c0" : "#60cdff")
                 : (root.isBarLight ? Qt.rgba(0.25, 0.25, 0.25, 0.85) : Qt.rgba(0.9, 0.9, 0.9, 0.85))
          border.width: itemBox.appFocused ? 0 : 1
          border.color: root.isBarLight ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.4)

          Behavior on width {
            NumberAnimation { duration: 160; easing.type: Easing.OutBack }
          }
        }

        // 6b. Multi-Instance Visual Indicator Under Icon
        Row {
          id: multiIndicatorRow
          visible: !modelData.isStart && !modelData.isTaskView && itemBox.appRunning && (itemBox.activeClients.length > 1)
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 0
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 2
          z: 10

          Repeater {
            model: Math.min(3, itemBox.activeClients.length)
            Rectangle {
              width: itemBox.appFocused ? (root.barH <= 28 ? 7 : 8) : (itemMouse.containsMouse ? 6 : 4)
              height: (root.barH <= 28) ? 2 : 3
              radius: 1
              color: itemBox.appFocused
                     ? (root.isBarLight ? "#0067c0" : "#60cdff")
                     : (root.isBarLight ? Qt.rgba(0.25, 0.25, 0.25, 0.85) : Qt.rgba(0.9, 0.9, 0.9, 0.85))
              border.width: itemBox.appFocused ? 0 : 1
              border.color: root.isBarLight ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.4)
            }
          }
        }

        MouseArea {
          id: itemMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

          onEntered: {
            if (modelData.isStart) return
            if (modelData.isTaskView) {
              root.showTaskViewPreview(itemBox, false)
            } else if (itemBox.appRunning) {
              root.showAppPreview(itemBox, false)
            } else {
              root.showTooltipFor(itemBox, modelData.name || "")
            }
          }

          onExited: {
            root.scheduleHidePreview()
          }

          onWheel: function(wheel) {
            root.seekWorkspace(wheel.angleDelta.y)
          }

          onClicked: function(mouse) {
            itemBox.handleClick(mouse.button)
          }
        }
      }
    }
  }

  // ------------------------------------------------------------ External Floating PopupCard
  PopupCard {
    id: previewPopup
    anchorItem: previewAnchor
    bar: previewBar
    triggerMode: root.previewPinned ? "click" : "hover"
    open: root.previewOpen
    contentWidth: previewPopup.fittedContentWidth(root.calcPopupWidth())
    contentHeight: previewPopup.fittedContentHeight(root.calcPopupHeight())

    onContainsMouseChanged: {
      if (containsMouse) {
        previewHideTimer.stop()
      } else {
        if (!root.previewPinned) previewHideTimer.restart()
      }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: -Math.max(0, previewPopup.padding - Style.space(2))
      radius: Math.max(0, Style.cornerRadius - Style.space(2))
      color: root.isDark ? Qt.rgba(0.12, 0.13, 0.17, 0.98) : Qt.rgba(0.96, 0.96, 0.98, 0.98)
      border.color: root.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.12)
      border.width: 1
    }

    // 1. Tooltip Content for Unlaunched Apps
    Item {
      id: tooltipContent
      visible: root.previewMode === "tooltip"
      anchors.fill: parent

      Text {
        id: tooltipText
        anchors.centerIn: parent
        text: root.tooltipString
        font.family: "Segoe UI"
        font.pixelSize: 11
        color: root.isDark ? "#ffffff" : "#1a1a1a"
      }
    }

    // 2. Application Instances Live Preview Content
    Item {
      id: appPreviewContent
      visible: root.previewMode === "app" && root.previewTargetClients.length > 0
      anchors.fill: parent

      ColumnLayout {
        id: appCol
        anchors.fill: parent
        spacing: 4

        // Multi-instance Header
        RowLayout {
          visible: root.previewTargetClients.length > 1
          Layout.fillWidth: true
          Layout.preferredHeight: 18
          spacing: 6

          Image {
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            sourceSize: Qt.size(14, 14)
            source: (root.previewTargetItem && root.previewTargetItem.itemData && root.previewTargetItem.itemData.iconFile)
                    ? ("file://" + root.configDir + "/assets/icons/win11/" + root.previewTargetItem.itemData.iconFile)
                    : (root.previewTargetItem && root.previewTargetItem.itemData ? (root.previewTargetItem.itemData.iconUrl || "") : "")
            fillMode: Image.PreserveAspectFit
            smooth: true
          }

          Text {
            text: ((root.previewTargetItem && root.previewTargetItem.itemData && root.previewTargetItem.itemData.name) ? root.previewTargetItem.itemData.name : "Application") + " — " + root.previewTargetClients.length + " windows open"
            font.family: "Segoe UI"
            font.pixelSize: 11
            font.bold: true
            color: root.isDark ? "#ffffff" : "#1a1a1a"
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          Text {
            text: "Click an instance to switch"
            font.family: "Segoe UI"
            font.pixelSize: 9
            color: root.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.5)
          }
        }

        Flickable {
          id: previewFlickable
          Layout.alignment: Qt.AlignHCenter
          Layout.fillWidth: true
          Layout.preferredHeight: 154
          contentWidth: previewRow.implicitWidth
          contentHeight: 154
          boundsBehavior: Flickable.StopAtBounds
          clip: true

          RowLayout {
            id: previewRow
            spacing: 8

            Repeater {
              model: root.previewTargetClients

              Rectangle {
                id: thumbTile
                property var clientObj: modelData
                property bool isThumbFocused: root.isClientFocused(clientObj)
                property bool thumbHovered: thumbArea.containsMouse || closeM.containsMouse || minM.containsMouse
                implicitWidth: 204
                implicitHeight: 154
                Layout.preferredWidth: 204
                Layout.preferredHeight: 154
                radius: 6
                color: thumbHovered
                       ? (root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                       : (isThumbFocused
                          ? (root.isDark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.05))
                          : (root.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(1, 1, 1, 0.50)))
                border.color: isThumbFocused
                              ? (root.isBarLight ? "#0067c0" : "#60cdff")
                              : (thumbHovered ? (root.isDark ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0, 0, 0, 0.20)) : (root.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)))
                border.width: isThumbFocused ? 1.5 : 1

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 6
                  spacing: 4

                  // Row 1: Title Bar & Controls
                  RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    spacing: 6

                    Image {
                      Layout.preferredWidth: 14
                      Layout.preferredHeight: 14
                      sourceSize: Qt.size(14, 14)
                      source: root.resolveAppIcon(clientObj) || ((root.previewTargetItem && root.previewTargetItem.itemData && root.previewTargetItem.itemData.iconFile) ? ("file://" + root.configDir + "/assets/icons/win11/" + root.previewTargetItem.itemData.iconFile) : "")
                      fillMode: Image.PreserveAspectFit
                      smooth: true
                    }

                    Text {
                      text: clientObj ? (clientObj.title || (root.previewTargetItem && root.previewTargetItem.itemData ? root.previewTargetItem.itemData.name : "") || "") : ""
                      font.family: "Segoe UI"
                      font.pixelSize: 11
                      font.bold: isThumbFocused
                      color: root.isDark ? "#ffffff" : "#1a1a1a"
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }

                    // Quick Minimize Button
                    Rectangle {
                      implicitWidth: 18
                      implicitHeight: 18
                      radius: 3
                      color: minM.containsMouse ? (root.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.10)) : "transparent"
                      z: 10

                      Text {
                        anchors.centerIn: parent
                        text: "—"
                        font.pixelSize: 9
                        color: root.isDark ? "#ffffff" : "#1a1a1a"
                      }

                      MouseArea {
                        id: minM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          if (clientObj && clientObj.address) {
                            Quickshell.execDetached(["omarchy-undercover-minimize", clientObj.address])
                          }
                        }
                      }
                    }

                    // Quick Close Button
                    Rectangle {
                      implicitWidth: 18
                      implicitHeight: 18
                      radius: 3
                      color: closeM.containsMouse ? "#c42b1c" : "transparent"
                      z: 10

                      Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 9
                        color: closeM.containsMouse ? "#ffffff" : (root.isDark ? "#ffffff" : "#1a1a1a")
                      }

                      MouseArea {
                        id: closeM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          root.closeClient(clientObj)
                          root.scheduleHidePreview()
                        }
                      }
                    }
                  }

                  // Row 2: Screen & Workspace Badge
                  RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18
                    spacing: 4

                    Rectangle {
                      radius: 3
                      color: isThumbFocused
                             ? (root.isBarLight ? Qt.rgba(0, 0, 0.4, 0.18) : Qt.rgba(0.2, 0.6, 1.0, 0.25))
                             : (root.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06))
                      border.color: isThumbFocused
                                    ? (root.isBarLight ? "#0067c0" : "#60cdff")
                                    : (root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10))
                      border.width: 1
                      implicitHeight: 18
                      implicitWidth: monWsRow.implicitWidth + 8

                      RowLayout {
                        id: monWsRow
                        anchors.centerIn: parent
                        spacing: 4

                        Item {
                          implicitWidth: 10
                          implicitHeight: 9
                          Layout.alignment: Qt.AlignVCenter

                          Rectangle {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 10
                            height: 7
                            radius: 1
                            color: "transparent"
                            border.width: 1
                            border.color: isThumbFocused
                                          ? (root.isBarLight ? "#0067c0" : "#60cdff")
                                          : (root.isDark ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(0, 0, 0, 0.65))
                          }
                          Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 4
                            height: 1
                            color: isThumbFocused
                                   ? (root.isBarLight ? "#0067c0" : "#60cdff")
                                   : (root.isDark ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(0, 0, 0, 0.65))
                          }
                        }

                        Text {
                          text: root.getMonitorLabel(clientObj ? clientObj.monitor : 0)
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 9
                          font.bold: true
                          color: isThumbFocused
                                 ? (root.isBarLight ? "#0067c0" : "#60cdff")
                                 : (root.isDark ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(0, 0, 0, 0.75))
                        }

                        Text {
                          text: "• Desktop " + ((clientObj && clientObj.workspace) ? (clientObj.workspace.name || clientObj.workspace.id) : "1")
                          font.family: "Segoe UI, sans-serif"
                          font.pixelSize: 9
                          color: root.isDark ? Qt.rgba(1, 1, 1, 0.60) : Qt.rgba(0, 0, 0, 0.50)
                        }
                      }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                      visible: isThumbFocused
                      radius: 3
                      color: root.isBarLight ? "#0067c0" : "#60cdff"
                      implicitHeight: 16
                      implicitWidth: focText.implicitWidth + 8
                      Text {
                        id: focText
                        anchors.centerIn: parent
                        text: "Active"
                        font.family: "Segoe UI"
                        font.pixelSize: 8
                        font.bold: true
                        color: "#ffffff"
                      }
                    }
                  }

                  // Row 3: Screencopy Live Visual Thumbnail Frame
                  Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 4
                    clip: true
                    color: root.isDark ? Qt.rgba(0, 0, 0, 0.5) : Qt.rgba(0, 0, 0, 0.08)
                    border.width: 1
                    border.color: root.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.05)

                    ScreencopyView {
                      id: scView
                      anchors.fill: parent
                      anchors.margins: 1
                      visible: scView.hasContent
                      captureSource: {
                        var addr = String((clientObj && clientObj.address) || "").toLowerCase().trim()
                        return clientObj.toplevel || root.toplevelByAddress[addr] || root.handleByAddress[addr] || null
                      }
                      live: true
                    }

                    Item {
                      anchors.fill: parent
                      visible: !scView.hasContent

                      ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Image {
                          Layout.alignment: Qt.AlignHCenter
                          Layout.preferredWidth: 32
                          Layout.preferredHeight: 32
                          sourceSize: Qt.size(32, 32)
                          source: root.resolveAppIcon(clientObj) || ((root.previewTargetItem && root.previewTargetItem.itemData && root.previewTargetItem.itemData.iconFile) ? ("file://" + root.configDir + "/assets/icons/win11/" + root.previewTargetItem.itemData.iconFile) : "")
                          fillMode: Image.PreserveAspectFit
                        }

                        Text {
                          Layout.alignment: Qt.AlignHCenter
                          text: clientObj ? (clientObj.title || "") : ""
                          font.family: "Segoe UI"
                          font.pixelSize: 10
                          color: root.isDark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.6)
                          elide: Text.ElideRight
                          Layout.maximumWidth: 160
                        }
                      }
                    }
                  }
                }

                MouseArea {
                  id: thumbArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  z: 1
                  onClicked: {
                    root.shiftToClient(clientObj)
                    root.hidePreview(true)
                  }
                  onWheel: function(wheel) {
                    previewFlickable.contentX = Math.max(0, Math.min(previewFlickable.contentWidth - previewFlickable.width, previewFlickable.contentX - wheel.angleDelta.y))
                  }
                }
              }
            }
          }
        }
      }
    }

    // 3. Task View Overview Content
    Item {
      id: taskViewContent
      visible: root.previewMode === "taskview"
      anchors.fill: parent

      ColumnLayout {
        id: taskViewCol
        anchors.fill: parent
        spacing: 6

        Item {
          visible: root.hyprClients && root.hyprClients.length > 0
          Layout.fillWidth: true
          Layout.preferredHeight: 126

          ColumnLayout {
            anchors.fill: parent
            spacing: 4

            RowLayout {
              Layout.fillWidth: true
              Text {
                text: "Open Windows"
                font.family: "Segoe UI"
                font.pixelSize: 11
                font.bold: true
                color: root.isDark ? "#ffffff" : "#1a1a1a"
              }
              Item { Layout.fillWidth: true }
              Text {
                text: "Click to switch"
                font.family: "Segoe UI"
                font.pixelSize: 9
                color: root.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.5)
              }
            }

            Flickable {
              Layout.fillWidth: true
              Layout.fillHeight: true
              contentWidth: winRow.implicitWidth
              contentHeight: 100
              boundsBehavior: Flickable.StopAtBounds
              clip: true

              RowLayout {
                id: winRow
                spacing: 6

                Repeater {
                  model: root.hyprClients

                  Rectangle {
                    id: winThumb
                    property var winObj: modelData
                    property bool isWinFocused: root.isClientFocused(winObj)
                    implicitWidth: 160
                    implicitHeight: 96
                    radius: 5
                    color: winThumbM.containsMouse
                           ? (root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                           : (isWinFocused
                              ? (root.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))
                              : (root.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(1, 1, 1, 0.50)))
                    border.color: isWinFocused
                                  ? (root.isBarLight ? "#0067c0" : "#60cdff")
                                  : (winThumbM.containsMouse ? (root.isDark ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0, 0, 0, 0.20)) : (root.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)))
                    border.width: isWinFocused ? 1.5 : 1

                    ColumnLayout {
                      anchors.fill: parent
                      anchors.margins: 4
                      spacing: 3

                      RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 14
                        spacing: 4

                        Image {
                          Layout.preferredWidth: 12
                          Layout.preferredHeight: 12
                          sourceSize: Qt.size(12, 12)
                          source: root.resolveAppIcon(winObj)
                          fillMode: Image.PreserveAspectFit
                        }

                        Text {
                          text: winObj ? (winObj.title || "") : ""
                          font.family: "Segoe UI"
                          font.pixelSize: 10
                          font.bold: isWinFocused
                          color: root.isDark ? "#ffffff" : "#1a1a1a"
                          Layout.fillWidth: true
                          elide: Text.ElideRight
                        }
                      }

                      Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 3
                        clip: true
                        color: root.isDark ? Qt.rgba(0, 0, 0, 0.5) : Qt.rgba(0, 0, 0, 0.06)

                        ScreencopyView {
                          id: winScView
                          anchors.fill: parent
                          visible: winScView.hasContent
                          captureSource: {
                            var addr = String((winObj && winObj.address) || "").toLowerCase().trim()
                            return winObj.toplevel || root.toplevelByAddress[addr] || root.handleByAddress[addr] || null
                          }
                          live: true
                        }

                        Item {
                          anchors.fill: parent
                          visible: !winScView.hasContent

                          Image {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            sourceSize: Qt.size(24, 24)
                            source: root.resolveAppIcon(winObj)
                            fillMode: Image.PreserveAspectFit
                          }
                        }
                      }
                    }

                    MouseArea {
                      id: winThumbM
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        root.shiftToClient(winObj)
                        root.hidePreview(true)
                      }
                    }
                  }
                }
              }
            }
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: 96

          ColumnLayout {
            anchors.fill: parent
            spacing: 4

            RowLayout {
              Layout.fillWidth: true
              Text {
                text: "Desktops (Seek & Switch)"
                font.family: "Segoe UI"
                font.pixelSize: 11
                font.bold: true
                color: root.isDark ? "#ffffff" : "#1a1a1a"
              }
              Item { Layout.fillWidth: true }
              Text {
                text: "Scroll taskbar to seek"
                font.family: "Segoe UI"
                font.pixelSize: 9
                color: root.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.5)
              }
            }

            RowLayout {
              id: deskRow
              spacing: 8

              Repeater {
                model: root.workspaceList

                Rectangle {
                  id: deskCard
                  property int wsNum: modelData
                  property bool isCurrentWs: wsNum === root.activeWorkspaceId
                  property var wsClients: root.getClientsForWorkspace(wsNum)
                  property bool cardHovered: deskM.containsMouse || deskCloseM.containsMouse
                  implicitWidth: 104
                  implicitHeight: 68
                  radius: 6
                  color: cardHovered
                         ? (root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                         : (isCurrentWs
                            ? (root.isDark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.04))
                            : (root.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(1, 1, 1, 0.45)))
                  border.color: isCurrentWs
                                ? (root.isBarLight ? "#0067c0" : "#60cdff")
                                : (cardHovered ? (root.isDark ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(0, 0, 0, 0.15)) : (root.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)))
                  border.width: isCurrentWs ? 1.5 : 1

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2

                    Rectangle {
                      Layout.fillWidth: true
                      Layout.preferredHeight: 38
                      radius: 4
                      color: root.isDark ? Qt.rgba(0.08, 0.10, 0.14, 0.8) : Qt.rgba(0.90, 0.92, 0.95, 0.8)
                      border.width: 1
                      border.color: root.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.05)
                      clip: true

                      RowLayout {
                        anchors.centerIn: parent
                        spacing: 3
                        visible: deskCard.wsClients.length > 0

                        Repeater {
                          model: deskCard.wsClients.slice(0, 3)
                          Image {
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            sourceSize: Qt.size(14, 14)
                            source: root.resolveAppIcon(modelData)
                            fillMode: Image.PreserveAspectFit
                          }
                        }
                      }

                      Text {
                        anchors.centerIn: parent
                        visible: deskCard.wsClients.length === 0
                        text: "󰍹"
                        font.pixelSize: 14
                        color: root.isDark ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(0, 0, 0, 0.4)
                      }

                      Rectangle {
                        visible: deskCard.cardHovered && root.workspaceList.length > 1
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 2
                        color: deskCloseM.containsMouse ? "#c42b1c" : Qt.rgba(0, 0, 0, 0.6)
                        z: 10

                        Text {
                          anchors.centerIn: parent
                          text: "✕"
                          font.pixelSize: 8
                          color: "#ffffff"
                        }

                        MouseArea {
                          id: deskCloseM
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            root.closeWorkspace(deskCard.wsNum)
                          }
                        }
                      }
                    }

                    Text {
                      Layout.alignment: Qt.AlignHCenter
                      text: "Desktop " + deskCard.wsNum
                      font.family: "Segoe UI"
                      font.pixelSize: 10
                      font.bold: deskCard.isCurrentWs
                      color: deskCard.isCurrentWs ? (root.isBarLight ? "#0067c0" : "#60cdff") : (root.isDark ? "#ffffff" : "#1a1a1a")
                    }
                  }

                  MouseArea {
                    id: deskM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: -1
                    onClicked: {
                      root.switchToWorkspace(deskCard.wsNum.toString())
                      root.activeWorkspaceId = deskCard.wsNum
                      root.hidePreview(true)
                    }
                  }
                }
              }

              Rectangle {
                implicitWidth: 84
                implicitHeight: 68
                radius: 6
                color: newDeskM.containsMouse ? (root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : (root.isDark ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(1, 1, 1, 0.35))
                border.color: newDeskM.containsMouse ? (root.isDark ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0, 0, 0, 0.18)) : (root.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08))
                border.width: 1

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 4

                  Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    color: newDeskM.containsMouse ? (root.isBarLight ? "#0067c0" : "#60cdff") : (root.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08))

                    Text {
                      anchors.centerIn: parent
                      text: "+"
                      font.pixelSize: 16
                      font.family: "Segoe UI"
                      font.bold: true
                      color: newDeskM.containsMouse ? "#ffffff" : (root.isDark ? "#ffffff" : "#1a1a1a")
                    }
                  }

                  Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "New desktop"
                    font.family: "Segoe UI"
                    font.pixelSize: 9
                    color: root.isDark ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(0, 0, 0, 0.75)
                  }
                }

                MouseArea {
                  id: newDeskM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.switchToWorkspace("empty")
                    root.hidePreview(true)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
