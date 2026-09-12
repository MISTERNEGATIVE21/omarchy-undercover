import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-taskbar"

  property string homeDir: Quickshell.env("HOME")
  property string configDir: homeDir + "/.config/omarchy/plugins/undercover"
  property bool isDark: true
  property var winPinsConfig: ({})
  onWinPinsConfigChanged: root.refreshTaskbar()

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

  function runCmd(cmd) {
    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  function shiftToClient(client) {
    if (!client || !client.address) return
    var addr = client.address
    if (client.workspace && client.workspace.id < 0) {
      Quickshell.execDetached(["omarchy-undercover-minimize", addr])
      refreshTimer.restart()
      return
    }
    var wsId = (client.workspace && client.workspace.id) ? client.workspace.id : ""
    var cmd = "if hyprctl dispatch \"hl.dsp.focus({ window = 'address:" + addr + "' })\" 2>/dev/null; then :; else " +
              (wsId ? "hyprctl dispatch workspace " + wsId + " 2>/dev/null; " : "") +
              "hyprctl dispatch focuswindow \"address:" + addr + "\" 2>/dev/null; fi"
    Quickshell.execDetached(["bash", "-c", cmd])
    refreshTimer.restart()
  }

  function closeClient(client) {
    if (!client || !client.address) {
      var cmd = "if hyprctl dispatch \"hl.dsp.window.close()\" 2>/dev/null; then :; else hyprctl dispatch killactive 2>/dev/null; fi"
      Quickshell.execDetached(["bash", "-c", cmd])
      refreshTimer.restart()
      return
    }
    var addr = client.address
    var cmd = "if hyprctl dispatch \"hl.dsp.window.close({ window = 'address:" + addr + "' })\" 2>/dev/null; then :; else hyprctl dispatch closewindow \"address:" + addr + "\" 2>/dev/null; fi"
    Quickshell.execDetached(["bash", "-c", cmd])
    refreshTimer.restart()
  }

  function switchToWorkspace(ws) {
    var cmd = "if hyprctl dispatch \"hl.dsp.focus({ workspace = '" + ws + "' })\" 2>/dev/null; then :; else hyprctl dispatch workspace \"" + ws + "\" 2>/dev/null; fi"
    Quickshell.execDetached(["bash", "-c", cmd])
    refreshTimer.restart()
  }

  function seekWorkspace(delta) {
    var wsArg = delta > 0 ? "e-1" : "e+1"
    var cmd = "if hyprctl dispatch \"hl.dsp.focus({ workspace = '" + wsArg + "' })\" 2>/dev/null; then :; else hyprctl dispatch workspace \"" + wsArg + "\" 2>/dev/null; fi"
    Quickshell.execDetached(["bash", "-c", cmd])
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
      "echo \"$(hyprctl activeworkspace -j 2>/dev/null | tr -d '\\n')|||$(hyprctl workspaces -j 2>/dev/null | tr -d '\\n')|||$(hyprctl clients -j 2>/dev/null | tr -d '\\n')|||$(hyprctl activewindow -j 2>/dev/null | tr -d '\\n')\""
    ]
    stdout: SplitParser {
      onRead: function(line) {
        if (!line) return
        try {
          var parts = line.split("|||")
          if (parts.length >= 1 && parts[0].trim()) {
            var actWs = JSON.parse(parts[0].trim())
            if (actWs && actWs.id) root.activeWorkspaceId = actWs.id
          }
          if (parts.length >= 2 && parts[1].trim()) {
            var allWs = JSON.parse(parts[1].trim())
            if (Array.isArray(allWs)) {
              var ids = allWs.map(function(w) { return w.id }).filter(function(id) { return id > 0 && id <= 10 })
              ids.sort(function(a, b) { return a - b })
              if (ids.indexOf(root.activeWorkspaceId) === -1 && root.activeWorkspaceId > 0) {
                ids.push(root.activeWorkspaceId)
                ids.sort(function(a, b) { return a - b })
              }
              if (ids.length === 0) ids = [1]
              root.workspaceList = ids
            }
          }
          if (parts.length >= 3 && parts[2].trim()) {
            var cls = JSON.parse(parts[2].trim())
            if (Array.isArray(cls)) {
              root.hyprClients = cls.filter(function(c) { return c && c.mapped && !c.hidden })
            }
          }
          if (parts.length >= 4 && parts[3].trim()) {
            var actWin = JSON.parse(parts[3].trim())
            if (actWin && actWin.address) {
              root.hyprActiveWindow = actWin
            } else {
              root.hyprActiveWindow = ({})
            }
          }
        } catch(e) {}
        root.refreshTaskbar()
      }
    }
  }

  Timer {
    id: fastPoller
    interval: 300
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!hyprStateProc.running) hyprStateProc.running = true
    }
  }

  Timer {
    id: refreshTimer
    interval: 60
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

  function findRunningClient(matchers) {
    if (!matchers || matchers.length === 0) return null
    var firstMatch = null
    for (var i = 0; i < root.hyprClients.length; i++) {
      var c = root.hyprClients[i]
      if (!c) continue
      var target = ((c.class || "") + " " + (c.initialClass || "") + " " + (c.title || "")).toLowerCase()
      for (var j = 0; j < matchers.length; j++) {
        if (target.indexOf(matchers[j].toLowerCase()) !== -1) {
          if (root.hyprActiveWindow && root.hyprActiveWindow.address && c.address === root.hyprActiveWindow.address) {
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
    if (!client || !client.address || !root.hyprActiveWindow || !root.hyprActiveWindow.address) return false
    return client.address === root.hyprActiveWindow.address
  }

  function resolveAppIcon(c) {
    if (!c) return ""
    var cls = (c.initialClass || c.class || "").toLowerCase()
    if (cls.indexOf("telegram") !== -1) {
      return Quickshell.iconPath("telegram") || Quickshell.iconPath("org.telegram.desktop") || ("file://" + root.homeDir + "/.local/share/icons/win11/discord.svg")
    }
    if (cls.indexOf("antigravity") !== -1) {
      return "file://" + root.homeDir + "/.local/share/icons/win11/antigravity-ide.svg"
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

  // Reactive Theme state watcher via FileView
  FileView {
    id: stateWatcher
    path: root.configDir + "/state"
    watchChanges: true
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

  // Defaults & pinned apps poller via FileView
  FileView {
    id: defaultsFile
    path: root.configDir + "/defaults.json"
    watchChanges: true
    onLoaded: {
      try {
        var d = JSON.parse(text())
        if (d && d.win11_pins) root.winPinsConfig = d.win11_pins
      } catch(e) {}
    }
    onFileChanged: {
      reload()
      try {
        var d = JSON.parse(text())
        if (d && d.win11_pins) root.winPinsConfig = d.win11_pins
      } catch(e) {}
    }
  }

  // Windows 11 Taskbar Pinned Apps
  property var winApps: [
    { id: "start", name: "Start", isStart: true, iconFile: "start.svg", exec: "omarchy-win11-start", matchers: [] },
    { id: "taskview", name: "Task View", isTaskView: true, iconFile: "taskview.svg", exec: "rofi -show window -theme ~/.config/rofi/windows11.rasi", matchers: [] },
    { id: "explorer", name: "File Explorer", iconFile: "explorer.svg", exec: "omarchy-undercover-filemanager ~ || flea", matchers: ["flea", "nautilus", "thunar", "dolphin", "files", "org.gnome.nautilus"] },
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

  // Dynamically discover all running unpinned applications
  function getUnpinnedRunningApps() {
    var pinned = root.getVisiblePinnedApps()
    var unpinned = []
    var seenKeys = {}

    for (var i = 0; i < root.hyprClients.length; i++) {
      var c = root.hyprClients[i]
      if (!c || !c.address) continue
      var cls = (c.class || "").toLowerCase()
      var initCls = (c.initialClass || "").toLowerCase()
      var title = (c.title || "").toLowerCase()

      // Skip internal quickshell desktop overlays
      if (cls === "org.quickshell" && (title === "" || title === "quickshell")) continue

      var isPinned = pinned.some(function(p) {
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
            isStart: false,
            isTaskView: false,
            isDynamic: true,
            iconUrl: root.resolveAppIcon(c),
            appId: c.class || c.initialClass || "",
            iconFile: "",
            exec: "",
            matchers: [c.class || "", c.initialClass || ""]
          })
        }
      }
    }
    return unpinned
  }

  function getAllTaskbarItems() {
    var pinned = root.getVisiblePinnedApps()
    var showRunning = (root.winPinsConfig && root.winPinsConfig["running_apps"] !== undefined) ? (root.winPinsConfig["running_apps"] === true) : true
    var running = showRunning ? root.getUnpinnedRunningApps() : []
    return pinned.concat(running)
  }

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

        property var activeClient: {
          if (modelData.isDynamic) {
            if (root.hyprActiveWindow && root.hyprActiveWindow.address) {
              var act = root.hyprActiveWindow
              var actKey = ((act.initialClass || "") + " " + (act.class || "")).toLowerCase()
              var myKey = (modelData.appId || "").toLowerCase()
              if (myKey && actKey.indexOf(myKey) !== -1) {
                return act
              }
            }
            return modelData.hyprClient
          }
          return root.findRunningClient(modelData.matchers)
        }
        property bool appRunning: activeClient !== null && activeClient !== undefined
        property bool appFocused: root.isClientFocused(activeClient)

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

        // 1. Windows 11 Start Icon (Authentic Fluent SVG)
        Item {
          visible: modelData.isStart === true
          anchors.fill: parent

          Image {
            anchors.centerIn: parent
            width: Math.round(root.iconSize * 0.92)
            height: Math.round(root.iconSize * 0.92)
            sourceSize: Qt.size(Math.round(root.iconSize * 0.92), Math.round(root.iconSize * 0.92))
            source: "file://" + root.homeDir + "/.local/share/icons/win11/start.svg"
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

            // Back rectangle (high contrast outline)
            Rectangle {
              x: 0; y: 0
              width: Math.round(parent.width * 0.72)
              height: Math.round(parent.height * 0.72)
              radius: 2
              color: "transparent"
              border.width: 1.6
              border.color: root.isBarLight ? Qt.rgba(0, 0, 0, 0.75) : Qt.rgba(1, 1, 1, 0.85)
            }

            // Front rectangle (vibrant blue accent)
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
            source: modelData.iconFile ? ("file://" + root.homeDir + "/.local/share/icons/win11/" + modelData.iconFile) : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
          }
        }

        // 4. Dynamic Application Icon (For unpinned running windows like Telegram)
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

        // 5. Windows 11 Running/Focus Pill Indicator Under Icon
        Rectangle {
          id: bottomIndicator
          visible: !modelData.isStart && !modelData.isTaskView && itemBox.appRunning
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

        // 6. Windows 11 Preview Card with Close (✕) and Minimize (—) Controls
        Rectangle {
          id: previewCard
          visible: itemMouse.containsMouse && !modelData.isStart && !modelData.isTaskView
          anchors.bottom: parent.top
          anchors.bottomMargin: 8
          anchors.horizontalCenter: parent.horizontalCenter
          implicitWidth: Math.max(140, cardRow.implicitWidth + 16)
          implicitHeight: 32
          radius: 6
          color: root.isDark ? Qt.rgba(0.13, 0.14, 0.18, 0.98) : Qt.rgba(0.96, 0.96, 0.98, 0.98)
          border.color: root.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.12)
          border.width: 1
          z: 100

          RowLayout {
            id: cardRow
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 6
            spacing: 8

            Text {
              text: itemBox.activeClient ? (itemBox.activeClient.title || modelData.name) : modelData.name
              font.family: "Segoe UI"
              font.pixelSize: 11
              color: root.isDark ? "#ffffff" : "#1a1a1a"
              Layout.fillWidth: true
              elide: Text.ElideRight
            }

            // Quick Minimize Button inside Preview
            Rectangle {
              visible: itemBox.appRunning
              implicitWidth: 20
              implicitHeight: 20
              radius: 3
              color: minM.containsMouse ? (root.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.10)) : "transparent"

              Text { anchors.centerIn: parent; text: "—"; font.pixelSize: 10; color: root.isDark ? "#ffffff" : "#1a1a1a" }

              MouseArea {
                id: minM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached(["omarchy-undercover-minimize"])
                }
              }
            }

            // Quick Close Button inside Preview
            Rectangle {
              visible: itemBox.appRunning
              implicitWidth: 20
              implicitHeight: 20
              radius: 3
              color: closeM.containsMouse ? "#c42b1c" : "transparent"

              Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 10; color: closeM.containsMouse ? "#ffffff" : (root.isDark ? "#ffffff" : "#1a1a1a") }

              MouseArea {
                id: closeM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.closeClient(itemBox.activeClient)
                }
              }
            }
          }
        }

        // Windows 11 Virtual Desktops Preview & Workspace Seeking Card
        Rectangle {
          id: taskViewCard
          visible: itemMouse.containsMouse && modelData.isTaskView
          anchors.bottom: parent.top
          anchors.bottomMargin: 8
          anchors.horizontalCenter: parent.horizontalCenter
          implicitWidth: Math.max(220, deskRow.implicitWidth + 24)
          implicitHeight: 74
          radius: 8
          color: root.isDark ? Qt.rgba(0.12, 0.13, 0.17, 0.98) : Qt.rgba(0.96, 0.96, 0.98, 0.98)
          border.color: root.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)
          border.width: 1
          z: 110

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

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
              spacing: 6

              Repeater {
                model: root.workspaceList
                Rectangle {
                  implicitWidth: 36
                  implicitHeight: 36
                  radius: 4
                  color: (modelData === root.activeWorkspaceId)
                         ? (root.isDark ? "#0078d4" : "#0067c0")
                         : (deskM.containsMouse ? (root.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.08)) : (root.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)))
                  border.color: (modelData === root.activeWorkspaceId)
                                ? (root.isDark ? "#60cdff" : "#004275")
                                : (root.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08))
                  border.width: 1

                  ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                      Layout.alignment: Qt.AlignHCenter
                      text: "󰍹"
                      font.pixelSize: 12
                      color: (modelData === root.activeWorkspaceId) ? "#ffffff" : (root.isDark ? "#ffffff" : "#1a1a1a")
                    }
                    Text {
                      Layout.alignment: Qt.AlignHCenter
                      text: modelData.toString()
                      font.family: "Segoe UI"
                      font.pixelSize: 9
                      font.bold: true
                      color: (modelData === root.activeWorkspaceId) ? "#ffffff" : (root.isDark ? "#ffffff" : "#1a1a1a")
                    }
                  }

                  MouseArea {
                    id: deskM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      root.switchToWorkspace(modelData.toString())
                      root.activeWorkspaceId = modelData
                    }
                  }
                }
              }

              // + New Desktop Button
              Rectangle {
                implicitWidth: 36
                implicitHeight: 36
                radius: 4
                color: newDeskM.containsMouse ? (root.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                border.color: root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: "+"
                  font.pixelSize: 16
                  font.family: "Segoe UI"
                  color: root.isDark ? "#ffffff" : "#1a1a1a"
                }

                MouseArea {
                  id: newDeskM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.switchToWorkspace("empty")
                  }
                }
              }
            }
          }
        }

        // Standard Tooltip for Start
        Rectangle {
          visible: itemMouse.containsMouse && modelData.isStart
          anchors.bottom: parent.top
          anchors.bottomMargin: 6
          anchors.horizontalCenter: parent.horizontalCenter
          implicitWidth: tooltipText.implicitWidth + 14
          implicitHeight: 24
          radius: 4
          color: root.isDark ? Qt.rgba(0.13, 0.14, 0.18, 0.96) : Qt.rgba(0.96, 0.96, 0.98, 0.96)
          border.color: root.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)
          border.width: 1
          z: 100

          Text {
            id: tooltipText
            anchors.centerIn: parent
            text: modelData.name
            font.family: "Segoe UI"
            font.pixelSize: 11
            color: root.isDark ? "#ffffff" : "#1a1a1a"
          }
        }

        MouseArea {
          id: itemMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

          onWheel: function(wheel) {
            root.seekWorkspace(wheel.angleDelta.y)
          }

          onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton) {
              root.closeClient(itemBox.activeClient)
            } else if (mouse.button === Qt.RightButton) {
              if (modelData.isStart) {
                root.runCmd("omarchy-undercover-settings")
              } else if (itemBox.appRunning && itemBox.activeClient) {
                root.closeClient(itemBox.activeClient)
              } else {
                root.runCmd("rofi -show window -theme ~/.config/rofi/windows11.rasi")
              }
            } else {
              // Left click
              if (modelData.isStart) {
                root.runCmd(modelData.exec)
                return
              }
              if (modelData.isTaskView) {
                root.runCmd(modelData.exec)
                return
              }
              if (itemBox.appRunning && itemBox.activeClient && itemBox.activeClient.address) {
                if (itemBox.appFocused) {
                  root.runCmd("omarchy-undercover-minimize")
                } else {
                  root.shiftToClient(itemBox.activeClient)
                }
                return
              }
              if (modelData.exec) {
                root.runCmd(modelData.exec)
              }
            }
          }
        }
      }
    }
  }
}
