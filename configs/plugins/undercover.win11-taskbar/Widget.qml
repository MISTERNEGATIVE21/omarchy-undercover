import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "undercover.win11-taskbar"

  implicitWidth: taskbarRow.implicitWidth + 8
  implicitHeight: root.bar ? root.bar.barSize : 44

  property bool isDark: true
  property var winPinsConfig: ({})

  function runCmd(cmd) {
    if (root.bar) {
      root.bar.run(cmd)
    } else {
      Quickshell.execDetached(["bash", "-c", cmd])
    }
  }

  function matches(tl, matchers) {
    if (!tl || !matchers || matchers.length === 0) return false
    var target = ((tl.appId || "") + " " + (tl.title || "")).toLowerCase()
    return matchers.some(function(p) { return target.indexOf(p.toLowerCase()) !== -1 })
  }

  function isRunning(matchers) {
    var list = (ToplevelManager.toplevels && ToplevelManager.toplevels.values) ? ToplevelManager.toplevels.values : []
    return list.some(function(tl) { return root.matches(tl, matchers) })
  }

  function isFocused(matchers) {
    return root.matches(ToplevelManager.activeToplevel, matchers)
  }

  // Theme state poller
  Process {
    id: statePoller
    running: true
    command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'win11-dark'"]
    stdout: SplitParser {
      onRead: function(line) {
        var s = String(line).trim()
        root.isDark = (s.indexOf("light") === -1)
      }
    }
  }

  // Defaults & pinned apps poller
  Process {
    id: defaultsPoller
    running: true
    command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/defaults.json 2>/dev/null || echo '{}'"]
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var d = JSON.parse(String(line))
          if (d && d.win11_pins) {
            root.winPinsConfig = d.win11_pins
          }
        } catch(e) {}
      }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!statePoller.running) statePoller.running = true
      if (!defaultsPoller.running) defaultsPoller.running = true
    }
  }

  // Windows 11 Taskbar Apps with authentic Edge icon
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

  function getVisibleWinApps() {
    return root.winApps.filter(function(app) {
      if (root.winPinsConfig && root.winPinsConfig[app.id] !== undefined) {
        return root.winPinsConfig[app.id] === true
      }
      return true
    })
  }

  RowLayout {
    id: taskbarRow
    anchors.centerIn: parent
    spacing: 3

    Repeater {
      model: root.getVisibleWinApps()

      Rectangle {
        id: itemBox
        visible: true
        implicitWidth: 42
        implicitHeight: root.bar ? root.bar.barSize - 6 : 38
        radius: 5

        property bool appRunning: root.isRunning(modelData.matchers)
        property bool appFocused: root.isFocused(modelData.matchers)

        color: itemMouse.pressed
               ? (root.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10))
               : (appFocused
                  ? (root.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08))
                  : (itemMouse.containsMouse ? (root.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"))
        border.color: itemMouse.containsMouse ? (root.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.07)) : "transparent"
        border.width: 1

        scale: itemMouse.pressed ? 0.95 : (itemMouse.containsMouse ? 1.05 : 1.0)
        Behavior on scale {
          NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        // 1. Windows 11 Start Icon (Authentic Vector 4-Square Grid)
        Item {
          visible: modelData.isStart === true
          anchors.fill: parent

          GridLayout {
            anchors.centerIn: parent
            columns: 2
            rowSpacing: 2.2
            columnSpacing: 2.2

            Rectangle {
              width: 7.5
              height: 7.5
              radius: 1.2
              color: root.isDark ? (itemMouse.containsMouse ? "#60cdff" : "#0078d4") : (itemMouse.containsMouse ? "#0078d4" : "#005fb8")
            }
            Rectangle {
              width: 7.5
              height: 7.5
              radius: 1.2
              color: root.isDark ? (itemMouse.containsMouse ? "#60cdff" : "#0078d4") : (itemMouse.containsMouse ? "#0078d4" : "#005fb8")
            }
            Rectangle {
              width: 7.5
              height: 7.5
              radius: 1.2
              color: root.isDark ? (itemMouse.containsMouse ? "#60cdff" : "#0078d4") : (itemMouse.containsMouse ? "#0078d4" : "#005fb8")
            }
            Rectangle {
              width: 7.5
              height: 7.5
              radius: 1.2
              color: root.isDark ? (itemMouse.containsMouse ? "#60cdff" : "#0078d4") : (itemMouse.containsMouse ? "#0078d4" : "#005fb8")
            }
          }
        }

        // 2. Icon-Only Display with Authentic Windows 11 SVGs
        Item {
          visible: !modelData.isStart
          anchors.fill: parent

          Image {
            anchors.centerIn: parent
            width: modelData.isTaskView ? 20 : 24
            height: modelData.isTaskView ? 20 : 24
            source: (Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "mister")) + "/.local/share/icons/win11/" + modelData.iconFile
            sourceSize.width: 48
            sourceSize.height: 48
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
          }

          // Active Running Indicator Bar
          Rectangle {
            visible: itemBox.appRunning
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: itemBox.appFocused ? (itemMouse.containsMouse ? 24 : 20) : (itemMouse.containsMouse ? 16 : 8)
            height: 3
            radius: 1.5
            color: itemBox.appFocused
                   ? (root.isDark ? "#60cdff" : "#0067c0")
                   : (root.isDark ? "rgba(255, 255, 255, 0.45)" : "rgba(0, 0, 0, 0.35)")
            Behavior on width {
              NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
          }
        }

        // Tooltip
        Rectangle {
          id: tooltip
          visible: itemMouse.containsMouse
          anchors.bottom: parent.top
          anchors.bottomMargin: 6
          anchors.horizontalCenter: parent.horizontalCenter
          implicitWidth: tooltipText.implicitWidth + 14
          implicitHeight: 24
          radius: 5
          color: root.isDark ? Qt.rgba(0.13, 0.14, 0.18, 0.96) : Qt.rgba(0.98, 0.98, 0.99, 0.98)
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
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: function(mouse) {
            if (modelData.isStart) {
              if (mouse.button === Qt.RightButton) {
                root.runCmd("omarchy-undercover-settings")
              } else {
                root.runCmd("omarchy-win11-start")
              }
            } else {
              if (modelData.matchers && modelData.matchers.length > 0) {
                var matchStr = modelData.matchers.join(",")
                root.runCmd("omarchy-undercover-activate '" + matchStr + "' '" + modelData.exec.replace(/'/g, "\\'") + "'")
              } else {
                root.runCmd(modelData.exec)
              }
            }
          }
        }
      }
    }
  }
}
