import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  FloatingWindow {
    id: settingsWin
    title: "System Settings"

    implicitWidth: Math.min(960, (Quickshell.screens[0] ? Quickshell.screens[0].width - 40 : 960))
    implicitHeight: Math.min(620, (Quickshell.screens[0] ? Quickshell.screens[0].height - 60 : 620))
    minimumSize: Qt.size(Math.min(760, (Quickshell.screens[0] ? Quickshell.screens[0].width - 40 : 760)), Math.min(480, (Quickshell.screens[0] ? Quickshell.screens[0].height - 60 : 480)))
    color: "transparent"

    property string homeDir: Quickshell.env("HOME")
    property string userName: Quickshell.env("USER") || "User"
    property bool isDark: true
    property bool isTransparent: true
    property string activeAccent: "007aff"
    property int currentCategory: 0
    property string searchQuery: ""
    property real sidebarWidth: 250

    // Authentic macOS Sequoia Dynamic Accent Colors
    readonly property color accentColor: {
      if (activeAccent && activeAccent.length === 6) {
        return "#" + activeAccent
      }
      return isDark ? "#0a84ff" : "#007aff"
    }

    readonly property color accentTextColor: {
      var c = settingsWin.accentColor
      var lum = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
      return lum > 0.55 ? "#000000" : "#ffffff"
    }

    readonly property color windowBg: isDark
      ? (isTransparent ? Qt.rgba(0.12, 0.13, 0.16, 0.96) : "#1c1d22")
      : (isTransparent ? Qt.rgba(0.95, 0.95, 0.97, 0.96) : "#f1f1f4")
    readonly property color sidebarBg: isDark
      ? Qt.rgba(0, 0, 0, 0.28)
      : (isTransparent ? Qt.rgba(0.90, 0.91, 0.94, 0.70) : "#e8e9ed")
    readonly property color cardBg: isDark
      ? Qt.rgba(1, 1, 1, 0.08)
      : "#ffffff"
    readonly property color cardBorder: isDark
      ? Qt.rgba(1, 1, 1, 0.12)
      : Qt.rgba(0, 0, 0, 0.11)
    readonly property color textPrimary: isDark ? "#ffffff" : "#1d1d1f"
    readonly property color textSecondary: isDark ? Qt.rgba(1, 1, 1, 0.78) : "#515154"
    readonly property color separatorColor: isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.10)

    property int volumeLevel: 75
    property int brightnessLevel: 80
    property bool wifiEnabled: true
    property string wifiSsid: "Connected"
    property bool btEnabled: true
    property bool autohideActive: false
    property int dockSize: 52
    property int maxDockItems: 24
    property int dockTransparency: 76
    property string dockPosition: "bottom"
    property int windowGaps: 8
    property int windowRounding: 10
    property string currentDisguise: "mac-dark"

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    function saveSetting(key, val) {
      var cmd = "mkdir -p " + homeDir + "/.config/omarchy-undercover && " +
                "touch " + homeDir + "/.config/omarchy-undercover/settings.conf && " +
                "if grep -q '^" + key + "=' " + homeDir + "/.config/omarchy-undercover/settings.conf; then " +
                "  sed -i 's/^" + key + "=.*/" + key + "=" + val + "/' " + homeDir + "/.config/omarchy-undercover/settings.conf; " +
                "else " +
                "  echo '" + key + "=" + val + "' >> " + homeDir + "/.config/omarchy-undercover/settings.conf; " +
                "fi"
      runCmd(cmd)
    }

    // Reactive Watcher on State
    FileView {
      id: stateWatcher
      path: settingsWin.homeDir + "/.config/omarchy-undercover/state"
      watchChanges: true
      onLoaded: {
        var s = text().trim()
        settingsWin.currentDisguise = s || "mac-dark"
        settingsWin.isDark = (s.indexOf("light") === -1)
      }
      onFileChanged: {
        reload()
        var s = text().trim()
        settingsWin.currentDisguise = s || "mac-dark"
        settingsWin.isDark = (s.indexOf("light") === -1)
      }
    }

    // Reactive Watcher on settings.conf
    FileView {
      id: settingsWatcher
      path: settingsWin.homeDir + "/.config/omarchy-undercover/settings.conf"
      watchChanges: true
      onLoaded: {
        var s = text()
        settingsWin.autohideActive = (s.indexOf("AUTOHIDE=true") !== -1)
        settingsWin.isTransparent = (s.indexOf("BAR_TRANSPARENT=false") === -1)
        var m = s.match(/ACCENT=([0-9a-fA-F]+)/)
        if (m && m[1]) settingsWin.activeAccent = m[1]
        var md = s.match(/DOCK_SIZE=([0-9]+)/)
        if (md && md[1]) settingsWin.dockSize = parseInt(md[1])
        var mm = s.match(/DOCK_MAX_ITEMS=([0-9]+)/)
        if (mm && mm[1]) settingsWin.maxDockItems = parseInt(mm[1])
        var dt = s.match(/DOCK_TRANSPARENCY=([0-9]+)/)
        if (dt && dt[1]) settingsWin.dockTransparency = Math.max(10, Math.min(100, parseInt(dt[1])))
        var mg = s.match(/WINDOW_GAPS=([0-9]+)/)
        if (mg && mg[1]) settingsWin.windowGaps = parseInt(mg[1])
        var mr = s.match(/WINDOW_ROUNDING=([0-9]+)/)
        if (mr && mr[1]) settingsWin.windowRounding = parseInt(mr[1])
      }
      onFileChanged: {
        reload()
        var s = text()
        settingsWin.autohideActive = (s.indexOf("AUTOHIDE=true") !== -1)
        settingsWin.isTransparent = (s.indexOf("BAR_TRANSPARENT=false") === -1)
        var m = s.match(/ACCENT=([0-9a-fA-F]+)/)
        if (m && m[1]) settingsWin.activeAccent = m[1]
        var md = s.match(/DOCK_SIZE=([0-9]+)/)
        if (md && md[1]) settingsWin.dockSize = parseInt(md[1])
        var mm = s.match(/DOCK_MAX_ITEMS=([0-9]+)/)
        if (mm && mm[1]) settingsWin.maxDockItems = parseInt(mm[1])
        var dt = s.match(/DOCK_TRANSPARENCY=([0-9]+)/)
        if (dt && dt[1]) settingsWin.dockTransparency = Math.max(10, Math.min(100, parseInt(dt[1])))
        var mg = s.match(/WINDOW_GAPS=([0-9]+)/)
        if (mg && mg[1]) settingsWin.windowGaps = parseInt(mg[1])
        var mr = s.match(/WINDOW_ROUNDING=([0-9]+)/)
        if (mr && mr[1]) settingsWin.windowRounding = parseInt(mr[1])
      }
    }

    // Background Hardware State Poller
    Process {
      id: hwPoller
      command: ["bash", "-c",
        "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo 70; " +
        "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo 80; " +
        "nmcli -t -f WIFI g 2>/dev/null || echo 'enabled'; " +
        "nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo 'Wi-Fi'; " +
        "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'"
      ]
      stdout: SplitParser {
        onRead: function(data) {
          var parts = data.trim().split("\n")
          if (parts.length >= 5) {
            var v = parseInt(parts[0]); if (!isNaN(v)) settingsWin.volumeLevel = v
            var b = parseInt(parts[1]); if (!isNaN(b)) settingsWin.brightnessLevel = b
            settingsWin.wifiEnabled = (parts[2].indexOf("enabled") !== -1)
            if (parts[3]) settingsWin.wifiSsid = parts[3]
            settingsWin.btEnabled = (parts[4] === "1")
          }
        }
      }
    }

    Timer {
      interval: 3500
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!hwPoller.running) hwPoller.running = true
      }
    }

    // Main macOS Glass Container
    Rectangle {
      id: windowBox
      anchors.fill: parent
      radius: 14
      color: settingsWin.windowBg
      border.color: settingsWin.cardBorder
      border.width: 1
      clip: true

      ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ==========================================
        // 1. TOP macOS TITLEBAR WITH DRAG & CONTROLS
        // ==========================================
        Rectangle {
          id: titleBar
          Layout.fillWidth: true
          implicitHeight: 52
          color: "transparent"

          // Window Dragging & Maximizing on Double-Click
          MouseArea {
            anchors.fill: parent
            z: 0
            onPressed: settingsWin.startSystemMove()
            onDoubleClicked: settingsWin.runCmd("hyprctl dispatch fullscreen 1")
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 14
            z: 1

            // Authentic Traffic Lights on Top-Left
            RowLayout {
              spacing: 8

              // Close (Red)
              Rectangle {
                width: 13; height: 13; radius: 6.5
                color: closeM.containsMouse ? "#ff5f57" : (settingsWin.isDark ? "#ff5f57" : "#ff5f56")
                border.color: Qt.rgba(0, 0, 0, 0.20)
                border.width: 0.5

                Text {
                  anchors.centerIn: parent
                  text: "✕"
                  font.pixelSize: 8
                  font.bold: true
                  visible: closeM.containsMouse
                  color: "#4a0002"
                }

                MouseArea {
                  id: closeM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Qt.quit()
                }
              }

              // Minimize (Yellow)
              Rectangle {
                width: 13; height: 13; radius: 6.5
                color: minM.containsMouse ? "#febc2e" : (settingsWin.isDark ? "#febc2e" : "#ffbd2e")
                border.color: Qt.rgba(0, 0, 0, 0.20)
                border.width: 0.5

                Text {
                  anchors.centerIn: parent
                  text: "—"
                  font.pixelSize: 8
                  font.bold: true
                  visible: minM.containsMouse
                  color: "#593b00"
                }

                MouseArea {
                  id: minM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: settingsWin.runCmd("hyprctl dispatch movetoworkspacesilent special:minimized 2>/dev/null || true")
                }
              }

              // Zoom / Fullscreen (Green)
              Rectangle {
                width: 13; height: 13; radius: 6.5
                color: zoomM.containsMouse ? "#28c840" : (settingsWin.isDark ? "#28c840" : "#27c93f")
                border.color: Qt.rgba(0, 0, 0, 0.20)
                border.width: 0.5

                Text {
                  anchors.centerIn: parent
                  text: "+"
                  font.pixelSize: 9
                  font.bold: true
                  visible: zoomM.containsMouse
                  color: "#004709"
                }

                MouseArea {
                  id: zoomM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: settingsWin.runCmd("hyprctl dispatch fullscreen 1")
                }
              }
            }

            // Window Title
            Text {
              Layout.leftMargin: 8
              text: "System Settings"
              font.family: "SF Pro Display, -apple-system, Segoe UI, sans-serif"
              font.pixelSize: 13
              font.weight: Font.DemiBold
              color: settingsWin.textPrimary
            }

            Item { Layout.fillWidth: true }

            // Mode Badge
            Rectangle {
              implicitWidth: badgeRow.implicitWidth + 16
              implicitHeight: 26
              radius: 13
              color: Qt.rgba(settingsWin.accentColor.r, settingsWin.accentColor.g, settingsWin.accentColor.b, 0.14)
              border.color: Qt.rgba(settingsWin.accentColor.r, settingsWin.accentColor.g, settingsWin.accentColor.b, 0.35)
              border.width: 1

              RowLayout {
                id: badgeRow
                anchors.centerIn: parent
                spacing: 6
                Image {
                  width: 12; height: 12
                  source: "file://" + settingsWin.homeDir + "/.local/share/icons/apple-logo.svg"
                  fillMode: Image.PreserveAspectFit
                }
                Text {
                  text: "macOS Sequoia"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 11
                  font.weight: Font.Medium
                  color: settingsWin.accentColor
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: settingsWin.separatorColor
        }

        // ==========================================
        // 2. MAIN SPLIT VIEW (Sidebar + Splitter + Content)
        // ==========================================
        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 0

          // ------------------------------------------
          // LEFT NAVIGATION SIDEBAR (Resizable Width)
          // ------------------------------------------
          Rectangle {
            id: sidebarBox
            Layout.preferredWidth: settingsWin.sidebarWidth
            Layout.minimumWidth: 220
            Layout.maximumWidth: 380
            Layout.fillHeight: true
            color: settingsWin.sidebarBg

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 14
              spacing: 12

              // Apple Account Header Card
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 56
                radius: 8
                color: settingsWin.cardBg
                border.color: settingsWin.cardBorder
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  anchors.rightMargin: 12
                  spacing: 10

                  Rectangle {
                    width: 36; height: 36; radius: 18
                    color: settingsWin.accentColor
                    Text {
                      anchors.centerIn: parent
                      text: settingsWin.userName.charAt(0).toUpperCase()
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 15
                      font.bold: true
                      color: "#ffffff"
                    }
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                      text: settingsWin.userName
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 12
                      font.weight: Font.DemiBold
                      color: settingsWin.textPrimary
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                    Text {
                      text: "Apple Account, iCloud & Media"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 10
                      color: settingsWin.textSecondary
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                  }
                }
              }

              // Search Box
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 7
                color: searchInput.activeFocus
                       ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : "#ffffff")
                       : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : "#ffffff")
                border.color: searchInput.activeFocus ? settingsWin.accentColor : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.12))
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  spacing: 7

                  Image {
                    width: 13; height: 13
                    source: "file://" + settingsWin.homeDir + "/.local/share/icons/mac-settings/search.svg"
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.6
                  }

                  TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 12
                    color: settingsWin.textPrimary
                    clip: true
                    Text {
                      visible: !searchInput.text
                      text: "Search"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 12
                      color: settingsWin.textSecondary
                    }
                    onTextChanged: settingsWin.searchQuery = text.toLowerCase()
                  }
                }
              }

              // Sidebar Categories List with Vector Squircle Badges
              property var categories: [
                { id: 0, iconBg: "#007aff", icon: "appearance.svg", name: "Appearance" },
                { id: 1, iconBg: "#5856d6", icon: "dock.svg", name: "Desktop & Dock" },
                { id: 2, iconBg: "#34c759", icon: "wallpaper.svg", name: "Wallpaper" },
                { id: 3, iconBg: "#007aff", icon: "wifi.svg", name: "Wi-Fi" },
                { id: 4, iconBg: "#007aff", icon: "bluetooth.svg", name: "Bluetooth" },
                { id: 5, iconBg: "#ff2d55", icon: "sound.svg", name: "Sound" },
                { id: 6, iconBg: "#af52de", icon: "disguise.svg", name: "Undercover Disguise" },
                { id: 7, iconBg: "#8e8e93", icon: "general.svg", name: "General & About" }
              ]

              ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 3
                model: parent.categories

                delegate: Rectangle {
                  width: parent ? parent.width : 220
                  implicitHeight: 36
                  radius: 7

                  readonly property bool isSelected: settingsWin.currentCategory === modelData.id
                  visible: (!settingsWin.searchQuery) || (modelData.name.toLowerCase().indexOf(settingsWin.searchQuery) !== -1)
                  height: visible ? implicitHeight : 0

                  color: isSelected
                         ? settingsWin.accentColor
                         : (catMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    // Colorful Squircle Icon Badge
                    Rectangle {
                      width: 24; height: 24; radius: 6
                      color: isSelected ? Qt.rgba(1, 1, 1, 0.25) : modelData.iconBg

                      Image {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/mac-settings/" + modelData.icon
                        fillMode: Image.PreserveAspectFit
                      }
                    }

                    Text {
                      Layout.fillWidth: true
                      text: modelData.name
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 12
                      font.weight: isSelected ? Font.DemiBold : Font.Normal
                      color: isSelected ? "#ffffff" : settingsWin.textPrimary
                      elide: Text.ElideRight
                    }

                    Text {
                      text: "›"
                      font.pixelSize: 14
                      color: isSelected ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(settingsWin.textSecondary.r, settingsWin.textSecondary.g, settingsWin.textSecondary.b, 0.4)
                    }
                  }

                  MouseArea {
                    id: catMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsWin.currentCategory = modelData.id
                  }
                }
              }
            }
          }

          // ------------------------------------------
          // DRAGGABLE SIDEBAR SPLITTER
          // ------------------------------------------
          Rectangle {
            id: splitterBar
            Layout.fillHeight: true
            implicitWidth: 1
            color: splitterMouse.containsMouse || splitterMouse.pressed
                   ? settingsWin.accentColor
                   : settingsWin.separatorColor

            MouseArea {
              id: splitterMouse
              anchors.centerIn: parent
              width: 8
              height: parent.height
              hoverEnabled: true
              cursorShape: Qt.SizeHorCursor

              drag.target: null
              onPositionChanged: function(mouse) {
                if (pressed) {
                  var newW = settingsWin.sidebarWidth + mouse.x
                  if (newW >= 200 && newW <= 380) {
                    settingsWin.sidebarWidth = newW
                  }
                }
              }
            }
          }

          // ------------------------------------------
          // RIGHT CONTENT VIEW (Responsive Cards)
          // ------------------------------------------
          Flickable {
            id: rightScroller
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: contentCol.implicitHeight + 48
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
              anchors.top: parent.top
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              active: rightScroller.moving || rightScroller.flicking
              policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
              id: contentCol
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.leftMargin: 28
              anchors.rightMargin: 28
              anchors.top: parent.top
              anchors.topMargin: 20
              spacing: 18

              Item { implicitHeight: 4 }

              // Dynamic Category Title
              Text {
                text: {
                  switch(settingsWin.currentCategory) {
                    case 0: return "Appearance"
                    case 1: return "Desktop & Dock"
                    case 2: return "Wallpaper"
                    case 3: return "Wi-Fi"
                    case 4: return "Bluetooth"
                    case 5: return "Sound"
                    case 6: return "Undercover Disguise Transformation"
                    case 7: return "General & About This Mac"
                    default: return "System Settings"
                  }
                }
                font.family: "SF Pro Display, -apple-system, sans-serif"
                font.pixelSize: 22
                font.weight: Font.Bold
                color: settingsWin.textPrimary
              }

              // ==========================================
              // TAB 0: APPEARANCE
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 0
                Layout.fillWidth: true
                spacing: 16

                // Light / Dark Theme Selection
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 150
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.centerIn: parent
                    spacing: 36

                    // Light Card Option
                    ColumnLayout {
                      spacing: 8
                      Layout.alignment: Qt.AlignHCenter

                      Rectangle {
                        width: 128; height: 80; radius: 8
                        color: "#f5f5f7"
                        border.color: !settingsWin.isDark ? settingsWin.accentColor : Qt.rgba(0, 0, 0, 0.15)
                        border.width: !settingsWin.isDark ? 2.5 : 1
                        Rectangle { width: 108; height: 18; radius: 4; color: "#ffffff"; anchors.centerIn: parent }
                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: settingsWin.runCmd("omarchy-undercover -mac-light")
                        }
                      }
                      Text {
                        text: "Light"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        font.bold: !settingsWin.isDark
                        color: settingsWin.textPrimary
                        Layout.alignment: Qt.AlignHCenter
                      }
                    }

                    // Dark Card Option
                    ColumnLayout {
                      spacing: 8
                      Layout.alignment: Qt.AlignHCenter

                      Rectangle {
                        width: 128; height: 80; radius: 8
                        color: "#1e1e24"
                        border.color: settingsWin.isDark ? settingsWin.accentColor : Qt.rgba(255, 255, 255, 0.15)
                        border.width: settingsWin.isDark ? 2.5 : 1
                        Rectangle { width: 108; height: 18; radius: 4; color: "#2d2d34"; anchors.centerIn: parent }
                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: settingsWin.runCmd("omarchy-undercover -mac")
                        }
                      }
                      Text {
                        text: "Dark"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        font.bold: settingsWin.isDark
                        color: settingsWin.textPrimary
                        Layout.alignment: Qt.AlignHCenter
                      }
                    }
                  }
                }

                // Desktop Camouflage & Disguise Selection in Appearance
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: disguiseCol.implicitHeight + 28
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    id: disguiseCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Desktop Camouflage & Disguise"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Text {
                        text: "Select a disguise preset"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }

                    GridLayout {
                      Layout.fillWidth: true
                      columns: rightScroller.width > 620 ? 3 : 2
                      rowSpacing: 10
                      columnSpacing: 10

                      property var presets: [
                        { id: "mac-dark", name: "macOS Sequoia (Dark)", icon: "apple-logo.svg", isWin: false, cmd: "omarchy-undercover -mac" },
                        { id: "mac-light", name: "macOS Sequoia (Light)", icon: "apple-logo.svg", isWin: false, cmd: "omarchy-undercover -mac-light" },
                        { id: "win11-dark", name: "Windows 11 (Dark)", icon: "start.svg", isWin: true, cmd: "omarchy-undercover -w11" },
                        { id: "win11-light", name: "Windows 11 (Light)", icon: "start.svg", isWin: true, cmd: "omarchy-undercover -w11-light" },
                        { id: "omarchy", name: "Omarchy Default", icon: "disguise.svg", isWin: false, cmd: "omarchy-undercover --disable" }
                      ]

                      Repeater {
                        model: parent.presets
                        Rectangle {
                          Layout.fillWidth: true
                          implicitHeight: 52
                          radius: 8
                          color: (settingsWin.currentDisguise === modelData.id)
                                 ? Qt.rgba(settingsWin.accentColor.r, settingsWin.accentColor.g, settingsWin.accentColor.b, 0.15)
                                 : (disgMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0, 0, 0, 0.03)))
                          border.color: (settingsWin.currentDisguise === modelData.id) ? settingsWin.accentColor : settingsWin.cardBorder
                          border.width: (settingsWin.currentDisguise === modelData.id) ? 2 : 1

                          RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Image {
                              Layout.preferredWidth: 18
                              Layout.preferredHeight: 18
                              width: 18; height: 18
                              source: "file://" + settingsWin.homeDir + "/.local/share/icons/" + (modelData.isWin ? "win11/" : "") + (modelData.icon === "disguise.svg" ? "win11-settings/" : "") + modelData.icon
                              fillMode: Image.PreserveAspectFit
                            }

                            ColumnLayout {
                              Layout.fillWidth: true
                              spacing: 1
                              Text {
                                text: modelData.name
                                font.family: "SF Pro Text, -apple-system, sans-serif"
                                font.pixelSize: 11
                                font.weight: (settingsWin.currentDisguise === modelData.id) ? Font.Bold : Font.Normal
                                color: settingsWin.textPrimary
                                elide: Text.ElideRight
                              }
                              Text {
                                text: (settingsWin.currentDisguise === modelData.id) ? "Active Disguise" : "Click to switch"
                                font.family: "SF Pro Text, -apple-system, sans-serif"
                                font.pixelSize: 9
                                color: (settingsWin.currentDisguise === modelData.id) ? settingsWin.accentColor : settingsWin.textSecondary
                              }
                            }
                          }

                          MouseArea {
                            id: disgMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsWin.runCmd(modelData.cmd)
                          }
                        }
                      }
                    }
                  }
                }

                // Accent Color Inset Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 64
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    Text {
                      text: "Accent color"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 13
                      color: settingsWin.textPrimary
                    }
                    Item { Layout.fillWidth: true }

                    RowLayout {
                      spacing: 8
                      property var swatches: ["007aff", "5856d6", "af52de", "ff2d55", "ff9500", "ffcc00", "34c759", "8e8e93"]

                      Repeater {
                        model: parent.swatches
                        Rectangle {
                          width: 22; height: 22; radius: 11
                          color: "#" + modelData
                          border.color: settingsWin.activeAccent.toLowerCase() === modelData.toLowerCase() ? "#ffffff" : "transparent"
                          border.width: 2

                          MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              settingsWin.activeAccent = modelData
                              settingsWin.saveSetting("ACCENT", modelData)
                              settingsWin.runCmd("omarchy-undercover --reload")
                            }
                          }
                        }
                      }
                    }
                  }
                }

                // Transparency & Glass Inset Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 64
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    ColumnLayout {
                      spacing: 2
                      Text {
                        text: "Liquid Glass & Menu Bar Transparency"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: settingsWin.textPrimary
                      }
                      Text {
                        text: "Apply authentic frosted glass blur across top bar & surfaces"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }
                    Item { Layout.fillWidth: true }

                    // Pill Switch
                    Rectangle {
                      width: 38; height: 22; radius: 11
                      color: settingsWin.isTransparent ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")

                      Rectangle {
                        width: 18; height: 18; radius: 9
                        x: settingsWin.isTransparent ? 18 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#ffffff"
                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                      }

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          var next = !settingsWin.isTransparent
                          settingsWin.isTransparent = next
                          settingsWin.saveSetting("BAR_TRANSPARENT", next ? "true" : "false")
                          settingsWin.runCmd("omarchy-undercover --transparent " + (next ? "true" : "false"))
                        }
                      }
                    }
                  }
                }

                // Window Gaps & Rounding Group
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 120
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Window Gaps Row
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Desktop Window Gaps (" + settingsWin.windowGaps + "px)"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Slider {
                        from: 0; to: 24; stepSize: 1
                        value: settingsWin.windowGaps
                        onMoved: {
                          settingsWin.windowGaps = Math.round(value)
                          settingsWin.saveSetting("WINDOW_GAPS", settingsWin.windowGaps)
                          settingsWin.runCmd("hyprctl keyword general:gaps_in " + Math.round(settingsWin.windowGaps / 2) + " && hyprctl keyword general:gaps_out " + settingsWin.windowGaps)
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Window Corner Rounding Row
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Window Corner Radius (" + settingsWin.windowRounding + "px)"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Slider {
                        from: 0; to: 22; stepSize: 1
                        value: settingsWin.windowRounding
                        onMoved: {
                          settingsWin.windowRounding = Math.round(value)
                          settingsWin.saveSetting("WINDOW_ROUNDING", settingsWin.windowRounding)
                          settingsWin.runCmd("hyprctl keyword decoration:rounding " + settingsWin.windowRounding)
                        }
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 1: DESKTOP & DOCK
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 1
                Layout.fillWidth: true
                spacing: 16

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 220
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    // Dock Size Slider
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Dock Size (" + settingsWin.dockSize + "px)"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Slider {
                        from: 36; to: 72; stepSize: 2
                        value: settingsWin.dockSize
                        onMoved: {
                          settingsWin.dockSize = Math.round(value)
                          settingsWin.saveSetting("DOCK_SIZE", settingsWin.dockSize)
                          settingsWin.runCmd("omarchy-undercover --reload")
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Max Dock Items Slider
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Max Dock Items (" + settingsWin.maxDockItems + ")"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Slider {
                        from: 4; to: 56; stepSize: 1
                        value: settingsWin.maxDockItems
                        onMoved: {
                          settingsWin.maxDockItems = Math.round(value)
                          settingsWin.saveSetting("DOCK_MAX_ITEMS", settingsWin.maxDockItems)
                          settingsWin.runCmd("omarchy-undercover --reload")
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Dock Transparency Slider
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Dock Transparency (" + settingsWin.dockTransparency + "%)"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Slider {
                        from: 10; to: 100; stepSize: 1
                        value: settingsWin.dockTransparency
                        onMoved: {
                          settingsWin.dockTransparency = Math.round(value)
                          settingsWin.saveSetting("DOCK_TRANSPARENCY", settingsWin.dockTransparency)
                          settingsWin.runCmd("omarchy-undercover --reload")
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Auto-hide Dock Toggle
                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        spacing: 2
                        Text {
                          text: "Automatically hide and show the Dock"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Reveal smoothly when cursor hovers screen edge"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                      Item { Layout.fillWidth: true }

                      Rectangle {
                        width: 38; height: 22; radius: 11
                        color: settingsWin.autohideActive ? "#34c759" : (settingsWin.isDark ? "#39393d" : "#e5e5ea")
                        Rectangle {
                          width: 18; height: 18; radius: 9
                          x: settingsWin.autohideActive ? 18 : 2
                          anchors.verticalCenter: parent.verticalCenter
                          color: "#ffffff"
                          Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                        }
                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            var next = !settingsWin.autohideActive
                            settingsWin.autohideActive = next
                            settingsWin.saveSetting("AUTOHIDE", next ? "true" : "false")
                            settingsWin.runCmd("omarchy-undercover-autohide " + (next ? "--start" : "--stop"))
                          }
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Restart Dock Helper Button
                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Restart macOS Dynamic Dock"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Button {
                        text: "Restart Dock"
                        onClicked: settingsWin.runCmd("pkill -f 'quickshell.*mac-dock' && nohup quickshell -p ~/.config/omarchy-undercover/quickshell/mac-dock >/dev/null 2>&1 &")
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    // Keyboard Shortcuts
                    RowLayout {
                      Layout.fillWidth: true
                      ColumnLayout {
                        spacing: 2
                        Text {
                          text: "macOS Sequoia Keyboard Shortcuts"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 12
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                        }
                        Text {
                          text: "Configure Spotlight (Cmd+Space), Mission Control, and tiling keys"
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 11
                          color: settingsWin.textSecondary
                        }
                      }
                      Item { Layout.fillWidth: true }
                      Button {
                        text: "Customize Shortcuts"
                        onClicked: settingsWin.runCmd("omarchy-undercover-settings")
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 2: WALLPAPER
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 2
                Layout.fillWidth: true
                spacing: 14

                Text {
                  text: "Authentic 6K Apple & Windows Bloom Wallpapers"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 13
                  color: settingsWin.textSecondary
                }

                GridLayout {
                  Layout.fillWidth: true
                  columns: rightScroller.width > 650 ? 4 : (rightScroller.width > 480 ? 3 : 2)
                  rowSpacing: 14
                  columnSpacing: 14

                  property var walls: [
                    { name: "macOS Sequoia Dark", file: "macOS-Sequoia-Dark.jpg" },
                    { name: "macOS Sequoia Light", file: "macOS-Sequoia-Light.jpg" },
                    { name: "macOS Sonoma Dark", file: "Sonoma-dark.jpg" },
                    { name: "macOS Ventura Dark", file: "Ventura-dark.jpg" },
                    { name: "Windows 11 Bloom Dark", file: "win11_bloom_dark.jpg" },
                    { name: "Windows 11 Bloom Light", file: "win11_bloom_light.jpg" },
                    { name: "iOS 18 Beams Dark", file: "ios18_dark.jpg" },
                    { name: "iOS 18 Beams Light", file: "ios18_light.jpg" }
                  ]

                  Repeater {
                    model: parent.walls
                    Rectangle {
                      Layout.fillWidth: true
                      implicitHeight: 104
                      radius: 8
                      color: settingsWin.cardBg
                      border.color: wallMouse.containsMouse ? settingsWin.accentColor : settingsWin.cardBorder
                      border.width: wallMouse.containsMouse ? 2 : 1
                      clip: true

                      ColumnLayout {
                        anchors.fill: parent
                        spacing: 4

                        Rectangle {
                          Layout.fillWidth: true
                          Layout.fillHeight: true
                          color: Qt.rgba(settingsWin.accentColor.r, settingsWin.accentColor.g, settingsWin.accentColor.b, 0.15)
                          Image {
                            anchors.centerIn: parent
                            width: 24; height: 24
                            source: "file://" + settingsWin.homeDir + "/.local/share/icons/mac-settings/wallpaper.svg"
                            fillMode: Image.PreserveAspectFit
                            opacity: 0.75
                          }
                        }

                        Text {
                          Layout.fillWidth: true
                          Layout.margins: 6
                          text: modelData.name
                          font.family: "SF Pro Text, -apple-system, sans-serif"
                          font.pixelSize: 10
                          font.weight: Font.DemiBold
                          color: settingsWin.textPrimary
                          elide: Text.ElideRight
                        }
                      }

                      MouseArea {
                        id: wallMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWin.runCmd("omarchy-undercover-wallpaper -s '" + modelData.file + "'")
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 3: WI-FI
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 3
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 74
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Image {
                      Layout.preferredWidth: 24
                      Layout.preferredHeight: 24
                      width: 24; height: 24
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/mac-settings/wifi.svg"
                      fillMode: Image.PreserveAspectFit
                    }

                    ColumnLayout {
                      spacing: 2
                      Text {
                        text: "Wi-Fi"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 14
                        font.bold: true
                        color: settingsWin.textPrimary
                      }
                      Text {
                        text: settingsWin.wifiEnabled ? "Connected to: " + settingsWin.wifiSsid : "Wi-Fi is Off"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                      text: "Network Manager..."
                      onClicked: settingsWin.runCmd("omarchy-mac-wifi || nm-connection-editor")
                    }
                  }
                }
              }

              // ==========================================
              // TAB 4: BLUETOOTH
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 4
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 74
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Image {
                      Layout.preferredWidth: 24
                      Layout.preferredHeight: 24
                      width: 24; height: 24
                      source: "file://" + settingsWin.homeDir + "/.local/share/icons/mac-settings/bluetooth.svg"
                      fillMode: Image.PreserveAspectFit
                    }

                    ColumnLayout {
                      spacing: 2
                      Text {
                        text: "Bluetooth"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 14
                        font.bold: true
                        color: settingsWin.textPrimary
                      }
                      Text {
                        text: settingsWin.btEnabled ? "On and discovering devices" : "Bluetooth is Off"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 11
                        color: settingsWin.textSecondary
                      }
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                      text: "Bluetooth Devices..."
                      onClicked: settingsWin.runCmd("omarchy-mac-bluetooth || blueman-manager")
                    }
                  }
                }
              }

              // ==========================================
              // TAB 5: SOUND
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 5
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 124
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        width: 20; height: 20
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/mac-settings/sound.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      Text {
                        text: "Output Volume (" + settingsWin.volumeLevel + "%)"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Slider {
                        from: 0; to: 100; stepSize: 1
                        value: settingsWin.volumeLevel
                        onMoved: {
                          settingsWin.volumeLevel = Math.round(value)
                          settingsWin.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (settingsWin.volumeLevel / 100).toFixed(2))
                        }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    RowLayout {
                      Layout.fillWidth: true
                      Text {
                        text: "Play system alert sound"
                        font.family: "SF Pro Text, -apple-system, sans-serif"
                        font.pixelSize: 12
                        color: settingsWin.textPrimary
                      }
                      Item { Layout.fillWidth: true }
                      Button {
                        text: "Play macOS Ping"
                        onClicked: settingsWin.runCmd("omarchy-play-sound mac-switch")
                      }
                    }
                  }
                }
              }

              // ==========================================
              // TAB 6: UNDERCOVER DISGUISE TRANSFORMATION
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 6
                Layout.fillWidth: true
                spacing: 14

                Text {
                  text: "Active Desktop Camouflage"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 14
                  font.bold: true
                  color: settingsWin.textPrimary
                }

                GridLayout {
                  Layout.fillWidth: true
                  columns: rightScroller.width > 600 ? 2 : 1
                  rowSpacing: 12
                  columnSpacing: 12

                  // macOS Dark
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: (settingsWin.currentDisguise === "mac-dark") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "mac-dark") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        width: 24; height: 24
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/apple-logo.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "macOS Sequoia (Dark)" + (settingsWin.currentDisguise === "mac-dark" ? " — Active" : ""); font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Dark menu bar, dynamic dock & SF Pro fonts"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -mac")
                    }
                  }

                  // macOS Light
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: (settingsWin.currentDisguise === "mac-light") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "mac-light") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        width: 24; height: 24
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/apple-logo.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "macOS Sequoia (Light)" + (settingsWin.currentDisguise === "mac-light" ? " — Active" : ""); font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Solar light glass menu bar & high vibrancy dock"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -mac-light")
                    }
                  }

                  // Windows 11 Dark
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: (settingsWin.currentDisguise === "win11-dark") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "win11-dark") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 22; Layout.preferredHeight: 22
                        width: 22; height: 22
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11/start.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Windows 11 Fluent (Dark)" + (settingsWin.currentDisguise === "win11-dark" ? " — Active" : ""); font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Centered Mica taskbar, Start Menu & Segoe UI"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -w11")
                    }
                  }

                  // Windows 11 Light
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: (settingsWin.currentDisguise === "win11-light") ? settingsWin.accentColor : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "win11-light") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 22; Layout.preferredHeight: 22
                        width: 22; height: 22
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11/start.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Windows 11 Fluent (Light)" + (settingsWin.currentDisguise === "win11-light" ? " — Active" : ""); font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Solar Light taskbar, Fluent Start & Segoe UI"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -w11-light")
                    }
                  }

                  // Restore Default Omarchy Desktop
                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 8
                    color: settingsWin.cardBg
                    border.color: (settingsWin.currentDisguise === "omarchy") ? "#34c759" : settingsWin.cardBorder
                    border.width: (settingsWin.currentDisguise === "omarchy") ? 2 : 1

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 14
                      spacing: 12
                      Image {
                        Layout.preferredWidth: 22; Layout.preferredHeight: 22
                        width: 22; height: 22
                        source: "file://" + settingsWin.homeDir + "/.local/share/icons/win11-settings/disguise.svg"
                        fillMode: Image.PreserveAspectFit
                      }
                      ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Restore Default Omarchy Desktop" + (settingsWin.currentDisguise === "omarchy" ? " — Active" : ""); font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Revert camouflage, top bar branding, GTK & baseline"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 10; color: settingsWin.textSecondary }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover --disable")
                    }
                  }
                }
              }

              // ==========================================
              // TAB 7: GENERAL & ABOUT THIS MAC
              // ==========================================
              ColumnLayout {
                visible: settingsWin.currentCategory === 7
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 230
                  radius: 10
                  color: settingsWin.cardBg
                  border.color: settingsWin.cardBorder
                  border.width: 1

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    RowLayout {
                      spacing: 16
                      Rectangle {
                        width: 50; height: 50; radius: 12
                        color: settingsWin.accentColor
                        Image {
                          anchors.centerIn: parent
                          width: 28; height: 28
                          source: "file://" + settingsWin.homeDir + "/.local/share/icons/apple-logo.svg"
                          fillMode: Image.PreserveAspectFit
                        }
                      }
                      ColumnLayout {
                        spacing: 2
                        Text { text: "macOS Sequoia"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 16; font.bold: true; color: settingsWin.textPrimary }
                        Text { text: "Version 15.1 (Omarchy Undercover Camouflage)"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 11; color: settingsWin.textSecondary }
                      }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: settingsWin.separatorColor }

                    RowLayout {
                      Layout.fillWidth: true
                      Text { text: "Host Machine"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; color: settingsWin.textSecondary }
                      Item { Layout.fillWidth: true }
                      Text { text: "Omarchy Linux (Hyprland / Quickshell)"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; font.bold: true; color: settingsWin.textPrimary }
                    }

                    RowLayout {
                      Layout.fillWidth: true
                      Text { text: "System Diagnostics"; font.family: "SF Pro Text, -apple-system, sans-serif"; font.pixelSize: 12; color: settingsWin.textSecondary }
                      Item { Layout.fillWidth: true }
                      Button {
                        text: "Run Integrity Check"
                        onClicked: settingsWin.runCmd("omarchy-undercover --verify")
                      }
                    }
                  }
                }
              }

              Item { implicitHeight: 24 }
            }
          }
        }
      }

      // ==========================================
      // BOTTOM-RIGHT WINDOW RESIZE GRIP
      // ==========================================
      Rectangle {
        id: resizeCorner
        width: 18; height: 18
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "transparent"

        Canvas {
          anchors.fill: parent
          onPaint: {
            var ctx = getContext("2d")
            ctx.strokeStyle = settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(0, 0, 0, 0.3)
            ctx.lineWidth = 1.2
            ctx.beginPath()
            ctx.moveTo(14, 6); ctx.lineTo(6, 14)
            ctx.moveTo(14, 10); ctx.lineTo(10, 14)
            ctx.stroke()
          }
        }

        MouseArea {
          id: resizeMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.SizeFDiagCursor

          property real startX: 0
          property real startY: 0
          property real startW: 0
          property real startH: 0

          onPressed: function(mouse) {
            startX = mouse.x
            startY = mouse.y
            startW = settingsWin.width
            startH = settingsWin.height
            if (typeof settingsWin.startSystemResize === "function") {
              settingsWin.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
            }
          }

          onPositionChanged: function(mouse) {
            if (pressed) {
              var newW = startW + (mouse.x - startX)
              var newH = startH + (mouse.y - startY)
              if (newW >= 860) settingsWin.implicitWidth = newW
              if (newH >= 560) settingsWin.implicitHeight = newH
            }
          }
        }
      }
    }
  }
}
