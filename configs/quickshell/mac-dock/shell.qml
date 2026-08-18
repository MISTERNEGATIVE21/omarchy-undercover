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
      bottom: 8
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "omarchy-bar"
    exclusionMode: ExclusionMode.Auto
    color: "transparent"

    implicitWidth: dockCard.implicitWidth + 24
    implicitHeight: 74

    property real baseIconSize: 48
    property real maxMagnification: 1.35
    property string homeDir: Quickshell.env("HOME")
    property string iconBasePath: homeDir + "/.local/share/icons/mac-dock/"

    // Strict Theme Isolation Watcher: If state is not macOS mode, exit immediately
    Process {
      id: stateWatcher
      running: true
      command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'mac-dark'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          if (s && s.indexOf("mac") !== 0) {
            Qt.quit()
          }
        }
      }
    }

    Timer {
      interval: 1500
      running: true
      repeat: true
      onTriggered: {
        if (!stateWatcher.running) stateWatcher.running = true
      }
    }

    function matches(tl, matchers) {
      if (!tl || !matchers || matchers.length === 0) return false
      var target = ((tl.appId || "") + " " + (tl.title || "")).toLowerCase()
      return matchers.some(function(p) { return target.indexOf(p.toLowerCase()) !== -1 })
    }

    function isRunning(matchers) {
      var list = (ToplevelManager.toplevels && ToplevelManager.toplevels.values) ? ToplevelManager.toplevels.values : []
      return list.some(function(tl) { return dockWindow.matches(tl, matchers) })
    }

    function isFocused(matchers) {
      return dockWindow.matches(ToplevelManager.activeToplevel, matchers)
    }

    // Defaults & pinned apps poller
    property var macPinsConfig: ({})

    Process {
      id: defaultsPoller
      running: true
      command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/defaults.json 2>/dev/null || echo '{}'"]
      stdout: SplitParser {
        onRead: function(line) {
          try {
            var d = JSON.parse(String(line))
            if (d && d.mac_pins) {
              dockWindow.macPinsConfig = d.mac_pins
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
        if (!defaultsPoller.running) defaultsPoller.running = true
      }
    }

    property var dockApps: [
      { id: "finder", name: "Finder", icon: "finder.svg", exec: "nautilus computer:/// || thunar || dolphin", matchers: ["nautilus", "thunar", "dolphin", "files", "org.gnome.nautilus"] },
      { id: "launchpad", name: "Launchpad", icon: "launchpad.svg", exec: "rofi -show drun -theme ~/.config/rofi/mac.rasi", matchers: [] },
      { id: "safari", name: "Safari", icon: "safari.svg", exec: "omarchy-browser || xdg-open https://apple.com", matchers: ["chrome", "chromium", "firefox", "vivaldi", "edge", "brave", "zen", "safari"] },
      { id: "antigravity", name: "Antigravity IDE", icon: "antigravity.svg", exec: "antigravity-ide || code || vscodium", matchers: ["antigravity", "code", "vscodium", "vscode", "codium"] },
      { id: "messages", name: "Messages", icon: "messages.svg", exec: "omarchy-mac-widgets", matchers: ["messages"] },
      { id: "music", name: "Music", icon: "music.svg", exec: "spotify || omarchy-mac-widgets", matchers: ["spotify", "music"] },
      { id: "photos", name: "Photos", icon: "photos.svg", exec: "loupe || eog || gwenview", matchers: ["eog", "gwenview", "loupe", "photos"] },
      { id: "terminal", name: "Terminal", icon: "terminal.svg", exec: "xdg-terminal-exec || alacritty || kitty", matchers: ["kitty", "alacritty", "foot", "terminal", "wezterm", "ghostty", "ptyxis", "xterm"] },
      { id: "settings", name: "System Settings", icon: "settings.svg", exec: "omarchy-undercover-settings", matchers: ["omarchy-undercover-settings", "org.omarchy.undercover.settings", "settings", "gnome-control-center"] },
      { id: "appstore", name: "App Store", icon: "appstore.svg", exec: "pamac-manager || gnome-software || discover", matchers: ["pamac", "software", "discover"] }
    ]

    function getVisibleDockApps() {
      return dockWindow.dockApps.filter(function(app) {
        if (dockWindow.macPinsConfig && dockWindow.macPinsConfig[app.id] !== undefined) {
          return dockWindow.macPinsConfig[app.id] === true
        }
        return true
      })
    }

    Rectangle {
      id: dockCard
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 2

      implicitWidth: mainRow.implicitWidth + 22
      implicitHeight: 64

      radius: 20
      color: Qt.rgba(0.12, 0.12, 0.16, 0.85)
      border.color: Qt.rgba(1, 1, 1, 0.22)
      border.width: 1

      RowLayout {
        id: mainRow
        anchors.centerIn: parent
        spacing: 10

        Repeater {
          model: dockWindow.getVisibleDockApps()

          Item {
            id: appItem
            implicitWidth: dockWindow.baseIconSize
            implicitHeight: dockWindow.baseIconSize + 8

            property bool isHovered: mouseArea.containsMouse
            property bool appRunning: dockWindow.isRunning(modelData.matchers)
            property bool appFocused: dockWindow.isFocused(modelData.matchers)
            property real currentScale: isHovered ? dockWindow.maxMagnification : 1.0

            Behavior on currentScale {
              NumberAnimation { duration: 150; easing.type: Easing.OutBack }
            }

            // Tooltip
            Rectangle {
              visible: appItem.isHovered
              anchors.bottom: iconImage.top
              anchors.bottomMargin: 8
              anchors.horizontalCenter: parent.horizontalCenter
              radius: 6
              color: Qt.rgba(0.08, 0.08, 0.10, 0.94)
              border.color: Qt.rgba(1, 1, 1, 0.22)
              border.width: 1
              implicitWidth: tooltipText.implicitWidth + 12
              implicitHeight: tooltipText.implicitHeight + 6
              z: 100

              Text {
                id: tooltipText
                anchors.centerIn: parent
                text: modelData.name
                color: "#ffffff"
                font.pixelSize: 11
                font.weight: Font.DemiBold
              }
            }

            // App Icon
            Image {
              id: iconImage
              anchors.centerIn: parent
              width: Math.round(dockWindow.baseIconSize * appItem.currentScale)
              height: Math.round(dockWindow.baseIconSize * appItem.currentScale)
              source: dockWindow.iconBasePath + modelData.icon
              sourceSize.width: 64
              sourceSize.height: 64
              fillMode: Image.PreserveAspectFit
              smooth: true
              mipmap: true
              z: appItem.isHovered ? 20 : 1
            }

            // Active Dot Indicator (macOS style running indicator)
            Rectangle {
              visible: appItem.appRunning
              anchors.bottom: parent.bottom
              anchors.bottomMargin: -3
              anchors.horizontalCenter: parent.horizontalCenter
              width: appItem.appFocused ? 6 : 4
              height: appItem.appFocused ? 6 : 4
              radius: appItem.appFocused ? 3 : 2
              color: appItem.appFocused ? "#60cdff" : "#ffffff"
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (modelData.matchers && modelData.matchers.length > 0) {
                  var matchStr = modelData.matchers.join(",")
                  Quickshell.execDetached(["omarchy-undercover-activate", matchStr, modelData.exec])
                } else {
                  Quickshell.execDetached(["bash", "-c", modelData.exec])
                }
              }
            }
          }
        }

        // Separator
        Rectangle {
          implicitWidth: 1
          implicitHeight: 36
          color: Qt.rgba(1, 1, 1, 0.22)
          Layout.alignment: Qt.AlignVCenter
          Layout.leftMargin: 2
          Layout.rightMargin: 2
        }

        // Trash Bin Item
        Item {
          id: trashItem
          implicitWidth: dockWindow.baseIconSize
          implicitHeight: dockWindow.baseIconSize + 8

          property bool isTrashHovered: trashMouse.containsMouse
          property real trashScale: isTrashHovered ? dockWindow.maxMagnification : 1.0

          Behavior on trashScale {
            NumberAnimation { duration: 150; easing.type: Easing.OutBack }
          }

          Rectangle {
            visible: trashItem.isTrashHovered
            anchors.bottom: trashText.top
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 6
            color: Qt.rgba(0.08, 0.08, 0.10, 0.94)
            border.color: Qt.rgba(1, 1, 1, 0.22)
            border.width: 1
            implicitWidth: trashTip.implicitWidth + 12
            implicitHeight: trashTip.implicitHeight + 6
            z: 100

            Text {
              id: trashTip
              anchors.centerIn: parent
              text: "Trash"
              color: "#ffffff"
              font.pixelSize: 11
              font.weight: Font.DemiBold
            }
          }

          Text {
            id: trashText
            anchors.centerIn: parent
            text: "🗑️"
            font.pixelSize: Math.round(26 * trashItem.trashScale)
            z: trashItem.isTrashHovered ? 20 : 1
          }

          MouseArea {
            id: trashMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Quickshell.execDetached(["bash", "-c", "nautilus trash:/// || thunar trash:/// || dolphin trash:/"])
            }
          }
        }
      }
    }
  }
}
