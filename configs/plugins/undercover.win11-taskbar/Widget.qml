import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-taskbar"

  property string homeDir: Quickshell.env("HOME")
  property bool isDark: true
  property var winPinsConfig: ({})

  readonly property real scaleFactor: (root.screen && root.screen.devicePixelRatio) ? root.screen.devicePixelRatio : 1.0
  readonly property int tileHeight: Math.max(34, (root.bar ? root.bar.barSize - 8 : 40))
  readonly property int tileWidth: Math.round(tileHeight * 1.15)
  readonly property int iconSize: Math.round(tileHeight * 0.60)

  implicitWidth: taskbarRow.implicitWidth + Math.round(24 * root.scaleFactor)
  implicitHeight: root.bar ? root.bar.barSize : 48

  function runCmd(cmd) {
    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  // Workspaces seeking state
  property var workspaceList: [1, 2, 3, 4]
  property int activeWorkspaceId: 1

  Process {
    id: wsProc
    command: ["bash", "-c", "hyprctl activeworkspace -j 2>/dev/null; echo '---'; hyprctl workspaces -j 2>/dev/null"]
    stdout: StdioCollector {
      onCollected: {
        try {
          var parts = text.split("---")
          if (parts.length >= 1 && parts[0].trim()) {
            var act = JSON.parse(parts[0].trim())
            if (act && act.id) root.activeWorkspaceId = act.id
          }
          if (parts.length >= 2 && parts[1].trim()) {
            var all = JSON.parse(parts[1].trim())
            if (Array.isArray(all)) {
              var ids = all.map(function(w) { return w.id }).filter(function(id) { return id > 0 && id <= 10 })
              ids.sort(function(a, b) { return a - b })
              if (ids.indexOf(root.activeWorkspaceId) === -1 && root.activeWorkspaceId > 0) {
                ids.push(root.activeWorkspaceId)
                ids.sort(function(a, b) { return a - b })
              }
              if (ids.length === 0) ids = [1]
              root.workspaceList = ids
            }
          }
        } catch(e) {}
      }
    }
  }

  Timer {
    interval: 1500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!wsProc.running) wsProc.start()
    }
  }

  function matches(tl, matchers) {
    if (!tl || !matchers || matchers.length === 0) return false
    var target = ((tl.appId || "") + " " + (tl.title || "")).toLowerCase()
    return matchers.some(function(p) { return target.indexOf(p.toLowerCase()) !== -1 })
  }

  function findRunningToplevel(matchers) {
    var list = (ToplevelManager.toplevels && ToplevelManager.toplevels.values) ? ToplevelManager.toplevels.values : []
    return list.find(function(tl) { return root.matches(tl, matchers) })
  }

  function isRunning(matchers) {
    return findRunningToplevel(matchers) !== undefined
  }

  function isFocused(matchers) {
    return root.matches(ToplevelManager.activeToplevel, matchers)
  }

  // Reactive Theme state watcher via FileView
  FileView {
    id: stateWatcher
    path: root.homeDir + "/.config/omarchy-undercover/state"
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
    path: root.homeDir + "/.config/omarchy-undercover/defaults.json"
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
    { id: "explorer", name: "File Explorer", iconFile: "explorer.svg", exec: "nautilus computer:/// || thunar || dolphin", matchers: ["nautilus", "thunar", "dolphin", "files", "org.gnome.nautilus"] },
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
    var list = (ToplevelManager.toplevels && ToplevelManager.toplevels.values) ? ToplevelManager.toplevels.values : []
    var pinned = root.getVisiblePinnedApps()
    var unpinned = []
    var seenAppIds = {}

    for (var i = 0; i < list.length; i++) {
      var tl = list[i]
      if (!tl) continue
      var isPinned = pinned.some(function(p) { return root.matches(tl, p.matchers) })
      if (!isPinned) {
        var aid = (tl.appId || "app").toLowerCase()
        if (!seenAppIds[aid]) {
          seenAppIds[aid] = true
          unpinned.push({
            id: "running_" + aid,
            name: tl.title || tl.appId || "Application",
            toplevel: tl,
            isStart: false,
            isTaskView: false,
            isDynamic: true,
            appId: tl.appId || "",
            iconFile: "",
            exec: "",
            matchers: [tl.appId || ""]
          })
        }
      }
    }
    return unpinned
  }

  function getAllTaskbarItems() {
    var pinned = root.getVisiblePinnedApps()
    var running = root.getUnpinnedRunningApps()
    return pinned.concat(running)
  }

  RowLayout {
    id: taskbarRow
    anchors.centerIn: parent
    spacing: Math.max(4, Math.round(6 * root.scaleFactor))

    Repeater {
      model: root.getAllTaskbarItems()

      Rectangle {
        id: itemBox
        implicitWidth: root.tileWidth
        implicitHeight: root.tileHeight
        radius: 4

        property bool appRunning: modelData.isDynamic ? true : root.isRunning(modelData.matchers)
        property bool appFocused: modelData.isDynamic ? (ToplevelManager.activeToplevel === modelData.toplevel) : root.isFocused(modelData.matchers)
        property var activeTl: modelData.isDynamic ? modelData.toplevel : root.findRunningToplevel(modelData.matchers)

        color: itemMouse.pressed
               ? (root.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.12))
               : (appFocused
                  ? (root.isDark ? Qt.rgba(1, 1, 1, 0.11) : Qt.rgba(0, 0, 0, 0.08))
                  : (itemMouse.containsMouse ? (root.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"))

        border.color: itemMouse.containsMouse
                      ? (root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                      : "transparent"
        border.width: 1

        scale: itemMouse.pressed ? 0.94 : (itemMouse.containsMouse ? 1.04 : 1.0)
        Behavior on scale {
          NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }

        // 1. Windows 11 Start Icon (Vector 4-Square Grid)
        Item {
          visible: modelData.isStart === true
          anchors.fill: parent

          GridLayout {
            anchors.centerIn: parent
            columns: 2
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
              model: 4
              Rectangle {
                width: Math.round(root.iconSize * 0.40)
                height: Math.round(root.iconSize * 0.40)
                radius: 1
                color: root.isDark ? (itemMouse.containsMouse ? "#60cdff" : "#0078d4") : (itemMouse.containsMouse ? "#0078d4" : "#005fb8")
              }
            }
          }
        }

        // 2. Icon-Only Display with Authentic Windows 11 SVGs
        Item {
          visible: !modelData.isStart && !modelData.isDynamic
          anchors.fill: parent

          Image {
            anchors.centerIn: parent
            width: modelData.isTaskView ? Math.round(root.iconSize * 0.85) : root.iconSize
            height: modelData.isTaskView ? Math.round(root.iconSize * 0.85) : root.iconSize
            source: "file://" + root.homeDir + "/.local/share/icons/win11/" + modelData.iconFile
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
          }
        }

        // 3. Dynamic Application Icon (For unpinned running windows)
        Item {
          visible: modelData.isDynamic === true
          anchors.fill: parent

          Text {
            anchors.centerIn: parent
            text: "🗖"
            font.pixelSize: Math.round(root.iconSize * 0.8)
            color: root.isDark ? "#ffffff" : "#1a1a1a"
          }
        }

        // 4. Windows 11 Running/Focus Pill Indicator Under Icon
        Rectangle {
          id: bottomIndicator
          visible: !modelData.isStart && !modelData.isTaskView && itemBox.appRunning
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 1
          anchors.horizontalCenter: parent.horizontalCenter
          width: itemBox.appFocused ? Math.round(root.tileWidth * 0.45) : 6
          height: 3
          radius: 1.5
          color: itemBox.appFocused ? (root.isDark ? "#60cdff" : "#0067c0") : (root.isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.40))

          Behavior on width {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
          }
        }

        // 5. Windows 11 Preview Card with Close (✕) and Minimize (—) Controls
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
              text: itemBox.activeTl ? (itemBox.activeTl.title || modelData.name) : modelData.name
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
                  if (itemBox.activeTl) {
                    itemBox.activeTl.close()
                  } else {
                    Quickshell.execDetached(["hyprctl", "dispatch", "killactive"])
                  }
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
                  implicitWidth: 64
                  implicitHeight: 36
                  radius: 4
                  color: (modelData === root.activeWorkspaceId) ? (root.isDark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)) : (deskM.containsMouse ? (root.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")
                  border.color: (modelData === root.activeWorkspaceId) ? (root.isDark ? "#60cdff" : "#0067c0") : (root.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10))
                  border.width: (modelData === root.activeWorkspaceId) ? 2 : 1

                  ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: "Desktop " + modelData
                      font.family: "Segoe UI"
                      font.pixelSize: 10
                      font.bold: (modelData === root.activeWorkspaceId)
                      color: root.isDark ? "#ffffff" : "#1a1a1a"
                    }
                  }

                  MouseArea {
                    id: deskM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      Quickshell.execDetached(["hyprctl", "dispatch", "workspace", modelData.toString()])
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
                    Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "empty"])
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
            // Taskbar workspace seeking
            if (wheel.angleDelta.y > 0) {
              Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "e-1"])
            } else if (wheel.angleDelta.y < 0) {
              Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "e+1"])
            }
          }

          onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton) {
              // Windows behavior: Middle click closes the running window
              if (itemBox.activeTl) {
                itemBox.activeTl.close()
              }
            } else if (mouse.button === Qt.RightButton) {
              if (modelData.isStart) {
                root.runCmd("omarchy-undercover-settings")
              } else if (itemBox.activeTl) {
                // Toggle close on right click or open window switcher
                itemBox.activeTl.close()
              } else {
                root.runCmd("rofi -show window -theme ~/.config/rofi/windows11.rasi")
              }
            } else {
              // Left click: Toggle Focus / Minimize
              if (itemBox.appRunning && itemBox.activeTl) {
                if (itemBox.appFocused) {
                  root.runCmd("omarchy-undercover-minimize")
                } else {
                  itemBox.activeTl.activate()
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
