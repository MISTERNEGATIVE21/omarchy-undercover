import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  PanelWindow {
    id: startWindow
    screen: Quickshell.screens[0]

    anchors {
      bottom: true
    }
    margins {
      bottom: 54
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: 620
    implicitHeight: 700

    property bool isDark: true
    property bool isTransparent: true
    property string searchFilter: ""
    property int currentView: 0 // 0: Pinned, 1: All Apps, 2: Search Results
    property bool showPowerPopup: false

    Shortcut {
      sequence: "Escape"
      onActivated: Qt.quit()
    }

    function runCmd(cmd) {
      Qt.quit()
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    // Dynamic theme state poller
    Process {
      id: statePoller
      running: true
      command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'win11-dark'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          startWindow.isDark = (s.indexOf("light") === -1)
        }
      }
    }

    Process {
      id: transparencyPoller
      running: true
      command: ["bash", "-c", "grep -E '^(WIN11_TRANSPARENCY|BAR_TRANSPARENT)=' $HOME/.config/omarchy-undercover/settings.conf 2>/dev/null || echo 'WIN11_TRANSPARENCY=true'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          if (s.indexOf("false") !== -1) {
            startWindow.isTransparent = false
          } else if (s.indexOf("true") !== -1) {
            startWindow.isTransparent = true
          }
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
        if (!transparencyPoller.running) transparencyPoller.running = true
      }
    }

    // Pinned Applications
    property var pinnedApps: [
      { name: "Browser", icon: "🌐", exec: "omarchy-browser" },
      { name: "Word", icon: "📝", exec: "libreoffice --writer || abiword || omarchy-browser https://office.com" },
      { name: "Excel", icon: "📊", exec: "libreoffice --calc || gnumeric || xdg-open https://office.com" },
      { name: "PowerPoint", icon: "📽️", exec: "libreoffice --impress || xdg-open https://office.com" },
      { name: "Store", icon: "🛍️", exec: "pamac-manager || gnome-software || discover" },
      { name: "Photos", icon: "🖼️", exec: "eog || gwenview || loupe" },
      { name: "Settings", icon: "⚙️", exec: "omarchy-undercover-settings" },
      { name: "Terminal", icon: "💻", exec: "xdg-terminal-exec" },
      { name: "Explorer", icon: "📁", exec: "nautilus computer:/// || thunar || dolphin" },
      { name: "Calculator", icon: "🔢", exec: "gnome-calculator || kcalc || galculator" },
      { name: "Spotify", icon: "🎵", exec: "spotify || omarchy-win11-widgets" },
      { name: "Antigravity", icon: "🚀", exec: "antigravity-ide || code || vscodium" },
      { name: "VS Code", icon: "🧑‍💻", exec: "code || vscodium || cursor" },
      { name: "Chat", icon: "💬", exec: "discord || telegram-desktop || slack" },
      { name: "Notepad", icon: "🗒️", exec: "gedit || kate || mousepad || gnome-text-editor" },
      { name: "Mail", icon: "✉️", exec: "thunderbird || evolution || geary" },
      { name: "Paint", icon: "🎨", exec: "drawing || gimp || inkscape || pinta" },
      { name: "Clock", icon: "⏰", exec: "gnome-clocks || kclock" },
      { name: "Weather", icon: "🌤️", exec: "omarchy-win11-widgets" }
    ]

    // Complete All-Apps Catalog (Alphabetical A-Z Drawer)
    property var allAppsList: [
      { name: "Antigravity IDE", icon: "🚀", category: "A", exec: "antigravity-ide || code || vscodium" },
      { name: "Alacritty Terminal", icon: "💻", category: "A", exec: "alacritty || xdg-terminal-exec" },
      { name: "App Store / Packages", icon: "🛍️", category: "A", exec: "pamac-manager || gnome-software" },
      { name: "Bluetooth Manager", icon: "󰂯", category: "B", exec: "omarchy-win11-bluetooth || blueman-manager" },
      { name: "Calculator", icon: "🔢", category: "C", exec: "gnome-calculator || kcalc" },
      { name: "Calendar", icon: "📅", category: "C", exec: "gnome-calendar || korganizer" },
      { name: "Camera", icon: "📷", category: "C", exec: "cheese || kamoso" },
      { name: "Clock & Alarms", icon: "⏰", category: "C", exec: "gnome-clocks || kclock" },
      { name: "Discord", icon: "💬", category: "D", exec: "discord || vesktop" },
      { name: "Document Viewer", icon: "📑", category: "D", exec: "evince || okular" },
      { name: "File Explorer", icon: "📁", category: "F", exec: "nautilus computer:/// || thunar" },
      { name: "Firefox Browser", icon: "🦊", category: "F", exec: "firefox" },
      { name: "GIMP Image Editor", icon: "🎨", category: "G", exec: "gimp" },
      { name: "Google Chrome", icon: "🌐", category: "G", exec: "google-chrome-stable || chromium" },
      { name: "LibreOffice Calc", icon: "📊", category: "L", exec: "libreoffice --calc" },
      { name: "LibreOffice Writer", icon: "📝", category: "L", exec: "libreoffice --writer" },
      { name: "LibreOffice Impress", icon: "📽️", category: "L", exec: "libreoffice --impress" },
      { name: "Mail / Thunderbird", icon: "✉️", category: "M", exec: "thunderbird || evolution" },
      { name: "Microsoft Edge", icon: "🌐", category: "M", exec: "xdg-open https://microsoft.com || firefox" },
      { name: "Music / Media Player", icon: "🎵", category: "M", exec: "spotify || vlc || celluloid" },
      { name: "Notepad / Text Editor", icon: "🗒️", category: "N", exec: "gedit || kate || mousepad" },
      { name: "Omarchy Settings", icon: "🕵️", category: "O", exec: "omarchy-undercover-settings" },
      { name: "Paint / Drawing", icon: "🎨", category: "P", exec: "drawing || pinta" },
      { name: "Photos / Image Viewer", icon: "🖼️", category: "P", exec: "eog || gwenview || loupe" },
      { name: "Screen Recorder", icon: "🎥", category: "S", exec: "obs || wf-recorder" },
      { name: "Settings", icon: "⚙️", category: "S", exec: "omarchy-undercover-settings" },
      { name: "Sound Mixer", icon: "🔊", category: "S", exec: "omarchy-win11-sound || pavucontrol" },
      { name: "Spotify", icon: "🎵", category: "S", exec: "spotify" },
      { name: "System Monitor", icon: "📈", category: "S", exec: "gnome-system-monitor || btop" },
      { name: "Task View / Switcher", icon: "⧉", category: "T", exec: "rofi -show window" },
      { name: "Terminal Console", icon: "💻", category: "T", exec: "xdg-terminal-exec" },
      { name: "VS Code", icon: "🧑‍💻", category: "V", exec: "code || vscodium" },
      { name: "VLC Media Player", icon: "🎬", category: "V", exec: "vlc" },
      { name: "Weather & Widgets", icon: "🌤️", category: "W", exec: "omarchy-win11-widgets" },
      { name: "Wi-Fi Manager", icon: "󰤨", category: "W", exec: "omarchy-win11-wifi || nm-connection-editor" }
    ]

    property var recommendedItems: [
      { name: "omarchy-undercover.sh", time: "Just now", icon: "📄", exec: "xdg-open ~/.config/omarchy-undercover" },
      { name: "Windows-11-Fluent-Design.pdf", time: "2h ago", icon: "📑", exec: "xdg-open ~/Documents" },
      { name: "Project-Roadmap-2026.docx", time: "Yesterday at 4:15 PM", icon: "📘", exec: "xdg-open ~/Documents" },
      { name: "hyprland-config.lua", time: "Yesterday at 11:30 AM", icon: "⚙️", exec: "xdg-open ~/.config/hypr" },
      { name: "system-diagnostics.log", time: "5 days ago", icon: "📝", exec: "omarchy-undercover --status" }
    ]

    // Filtered search results
    function getFilteredApps() {
      if (!startWindow.searchFilter || startWindow.searchFilter.trim() === "") return []
      var q = startWindow.searchFilter.toLowerCase().trim()
      return startWindow.allAppsList.filter(function(app) {
        return app.name.toLowerCase().indexOf(q) !== -1 || app.exec.toLowerCase().indexOf(q) !== -1
      })
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: 16
      color: startWindow.isDark 
             ? (startWindow.isTransparent ? Qt.rgba(0.12, 0.12, 0.16, 0.85) : "#202024")
             : (startWindow.isTransparent ? Qt.rgba(0.97, 0.97, 0.98, 0.88) : "#f5f5f8")
      border.color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // 1. Top Search Bar with Live Real-Time TextInput
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            radius: 21
            color: searchInput.activeFocus
                   ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                   : (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))
            border.color: searchInput.activeFocus ? (startWindow.isDark ? "#60cdff" : "#0067c0") : (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10))
            border.width: 1.5

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 14
              spacing: 10

              Text { text: "🔍"; font.pixelSize: 13; color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.7) : Qt.rgba(0, 0, 0, 0.6) }

              TextInput {
                id: searchInput
                Layout.fillWidth: true
                font.family: "Segoe UI"
                font.pixelSize: 12
                color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                clip: true
                selectByMouse: true
                selectionColor: startWindow.isDark ? "#0078d4" : "#0067c0"

                Text {
                  visible: !searchInput.text && !searchInput.inputMethodComposing
                  text: "Type here to search apps, settings, and documents..."
                  color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.45)
                  font.family: "Segoe UI"
                  font.pixelSize: 12
                  anchors.verticalCenter: parent.verticalCenter
                }

                onTextChanged: {
                  startWindow.searchFilter = text
                  if (text.trim().length > 0) {
                    startWindow.currentView = 2
                  } else {
                    startWindow.currentView = 0
                  }
                }

                onAccepted: {
                  var res = startWindow.getFilteredApps()
                  if (res.length > 0) {
                    startWindow.runCmd(res[0].exec)
                  } else if (text.trim().length > 0) {
                    startWindow.runCmd("omarchy-browser 'https://www.bing.com/search?q=" + encodeURIComponent(text.trim()) + "'")
                  }
                }
              }

              // Clear button
              Rectangle {
                visible: searchInput.text.length > 0
                implicitWidth: 20
                implicitHeight: 20
                radius: 10
                color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.10)
                Text { anchors.centerIn: parent; text: "✕"; color: startWindow.isDark ? "#ffffff" : "#1a1a1a"; font.pixelSize: 10 }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    searchInput.text = ""
                    startWindow.searchFilter = ""
                    startWindow.currentView = 0
                  }
                }
              }
            }
          }

          // Close button
          Rectangle {
            implicitWidth: 32
            implicitHeight: 32
            radius: 6
            color: startCloseM.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "✕"
              color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
              font.pixelSize: 13
            }
            MouseArea {
              id: startCloseM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Qt.quit()
            }
          }
        }

        // ================= VIEW 0: PINNED APPS & RECOMMENDED =================
        ColumnLayout {
          visible: startWindow.currentView === 0
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 12

          // Pinned Header
          RowLayout {
            Layout.fillWidth: true
            Text {
              text: "Pinned"
              color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
              font.family: "Segoe UI"
              font.pixelSize: 14
              font.weight: Font.DemiBold
              Layout.fillWidth: true
            }
            Rectangle {
              implicitWidth: 84
              implicitHeight: 26
              radius: 6
              color: allAppsMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"
              Text {
                anchors.centerIn: parent
                text: "All apps >"
                color: startWindow.isDark ? "#60cdff" : "#0067c0"
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.weight: Font.DemiBold
              }
              MouseArea {
                id: allAppsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  startWindow.currentView = 1
                }
              }
            }
          }

          // Pinned Grid (6 cols x 3 rows)
          GridLayout {
            Layout.fillWidth: true
            columns: 6
            rowSpacing: 10
            columnSpacing: 6

            Repeater {
              model: startWindow.pinnedApps

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 74
                radius: 8
                color: tileMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                border.color: tileMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.10)) : "transparent"
                border.width: 1

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 4

                  Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.icon
                    font.pixelSize: 26
                  }
                  Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.name
                    color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: tileMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: startWindow.runCmd(modelData.exec)
                }
              }
            }
          }

          // Recommended Header
          RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Text {
              text: "Recommended"
              color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
              font.family: "Segoe UI"
              font.pixelSize: 14
              font.weight: Font.DemiBold
              Layout.fillWidth: true
            }
            Rectangle {
              implicitWidth: 64
              implicitHeight: 26
              radius: 6
              color: moreMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"
              Text {
                anchors.centerIn: parent
                text: "More >"
                color: startWindow.isDark ? "#60cdff" : "#0067c0"
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.weight: Font.DemiBold
              }
              MouseArea {
                id: moreMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: startWindow.runCmd("nautilus recent:/// || thunar")
              }
            }
          }

          // Recommended Files Grid
          GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 6
            columnSpacing: 10

            Repeater {
              model: startWindow.recommendedItems

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: 8
                color: recMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 10

                  Text { text: modelData.icon; font.pixelSize: 18 }
                  ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                      text: modelData.name
                      color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                      font.family: "Segoe UI"
                      font.pixelSize: 12
                      font.weight: Font.DemiBold
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                    Text {
                      text: modelData.time
                      color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.5)
                      font.family: "Segoe UI"
                      font.pixelSize: 10
                    }
                  }
                }

                MouseArea {
                  id: recMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: startWindow.runCmd(modelData.exec)
                }
              }
            }
          }
        }

        // ================= VIEW 1: ALL APPS A-Z DRAWER =================
        ColumnLayout {
          visible: startWindow.currentView === 1
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 10

          // Back Button Header
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
              implicitWidth: 72
              implicitHeight: 28
              radius: 6
              color: backM.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
              RowLayout {
                anchors.centerIn: parent
                spacing: 4
                Text { text: "‹"; font.pixelSize: 14; color: startWindow.isDark ? "#60cdff" : "#0067c0"; font.weight: Font.Bold }
                Text { text: "Back"; color: startWindow.isDark ? "#60cdff" : "#0067c0"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold }
              }
              MouseArea {
                id: backM
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: startWindow.currentView = 0
              }
            }

            Text {
              text: "All Apps"
              color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
              font.family: "Segoe UI"
              font.pixelSize: 14
              font.weight: Font.Bold
            }
          }

          // Scrollable All-Apps List
          ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
              id: allAppsView
              width: parent.width
              model: startWindow.allAppsList
              spacing: 3

              delegate: Rectangle {
                width: allAppsView.width
                implicitHeight: 40
                radius: 6
                color: appRowM.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  anchors.rightMargin: 12
                  spacing: 12

                  Text { text: modelData.icon; font.pixelSize: 18 }
                  Text {
                    text: modelData.name
                    color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                  }
                  Text {
                    text: modelData.category
                    color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(0, 0, 0, 0.4)
                    font.family: "Segoe UI"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                  }
                }

                MouseArea {
                  id: appRowM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: startWindow.runCmd(modelData.exec)
                }
              }
            }
          }
        }

        // ================= VIEW 2: LIVE SEARCH RESULTS =================
        ColumnLayout {
          visible: startWindow.currentView === 2
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 10

          Text {
            text: "Search Results for \"" + startWindow.searchFilter + "\""
            color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.7) : Qt.rgba(0, 0, 0, 0.6)
            font.family: "Segoe UI"
            font.pixelSize: 12
            font.weight: Font.DemiBold
          }

          ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
              id: searchResultsView
              width: parent.width
              model: startWindow.getFilteredApps()
              spacing: 4

              delegate: Rectangle {
                width: searchResultsView.width
                implicitHeight: 44
                radius: 8
                color: searchRowM.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03))
                border.color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  anchors.rightMargin: 12
                  spacing: 12

                  Text { text: modelData.icon; font.pixelSize: 20 }
                  ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                      text: modelData.name
                      color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                      font.family: "Segoe UI"
                      font.pixelSize: 12
                      font.weight: Font.DemiBold
                    }
                    Text {
                      text: "App • " + modelData.exec
                      color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.45)
                      font.family: "Segoe UI"
                      font.pixelSize: 10
                      elide: Text.ElideRight
                    }
                  }
                  Text {
                    text: "Open ➔"
                    color: startWindow.isDark ? "#60cdff" : "#0067c0"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                  }
                }

                MouseArea {
                  id: searchRowM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: startWindow.runCmd(modelData.exec)
                }
              }
            }
          }

          // Web Search Fallback Action Card
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            radius: 8
            color: webSearchM.containsMouse ? (startWindow.isDark ? Qt.rgba(0, 120, 212, 0.3) : Qt.rgba(0, 120, 212, 0.15)) : (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
            border.color: startWindow.isDark ? Qt.rgba(0, 120, 212, 0.5) : Qt.rgba(0, 120, 212, 0.3)

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              spacing: 10

              Text { text: "🌐"; font.pixelSize: 16 }
              Text {
                text: "Search the web for \"" + startWindow.searchFilter + "\""
                color: startWindow.isDark ? "#60cdff" : "#0067c0"
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                Layout.fillWidth: true
              }
            }

            MouseArea {
              id: webSearchM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: startWindow.runCmd("omarchy-browser 'https://www.bing.com/search?q=" + encodeURIComponent(startWindow.searchFilter) + "'")
            }
          }
        }

        Item { Layout.fillHeight: true }

        // 6. User Profile & Power Footer
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 52
          radius: 10
          color: startWindow.isDark ? Qt.rgba(0.08, 0.08, 0.11, 0.85) : Qt.rgba(0.92, 0.92, 0.94, 0.90)
          border.color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14

            // User Profile
            RowLayout {
              spacing: 10
              Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: startWindow.isDark ? "#0078d4" : "#0067c0"
                Text {
                  anchors.centerIn: parent
                  text: (Quickshell.env("USER") ? Quickshell.env("USER").substring(0, 1).toUpperCase() : "U")
                  color: "#ffffff"
                  font.family: "Segoe UI"
                  font.pixelSize: 13
                  font.weight: Font.Bold
                }
              }
              ColumnLayout {
                spacing: 1
                Text {
                  text: Quickshell.env("USER") ? (Quickshell.env("USER").charAt(0).toUpperCase() + Quickshell.env("USER").slice(1)) : "Personal Account"
                  color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                  font.family: "Segoe UI"
                  font.pixelSize: 12
                  font.weight: Font.DemiBold
                }
                Text {
                  text: "Personal Account"
                  color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.45)
                  font.family: "Segoe UI"
                  font.pixelSize: 10
                }
              }
            }

            Item { Layout.fillWidth: true }

            // Settings Shortcut
            Rectangle {
              implicitWidth: 36
              implicitHeight: 36
              radius: 6
              color: setMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
              Text { anchors.centerIn: parent; text: "⚙️"; font.pixelSize: 14 }
              MouseArea {
                id: setMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Qt.quit()
                  startWindow.runCmd("omarchy-undercover-settings")
                }
              }
            }

            // Power Button
            Rectangle {
              implicitWidth: 36
              implicitHeight: 36
              radius: 6
              color: powerMouse.containsMouse || startWindow.showPowerPopup ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)) : "transparent"
              Text { anchors.centerIn: parent; text: "⏻"; color: startWindow.isDark ? "#ffffff" : "#1a1a1a"; font.pixelSize: 16 }
              MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  startWindow.showPowerPopup = !startWindow.showPowerPopup
                }
              }
            }
          }
        }
      }

      // Redesigned Fluent Power Popup Card
      Rectangle {
        visible: startWindow.showPowerPopup
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 62
        anchors.right: parent.right
        anchors.rightMargin: 16
        implicitWidth: 210
        implicitHeight: 200
        radius: 12
        color: startWindow.isDark ? Qt.rgba(0.14, 0.15, 0.20, 0.98) : Qt.rgba(0.98, 0.98, 0.99, 0.98)
        border.color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.14)
        border.width: 1
        z: 200

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 6
          spacing: 2

          // Sleep
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 6
            color: sleepM.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10
              Text { text: "🌙"; font.pixelSize: 13 }
              ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text { text: "Sleep"; color: startWindow.isDark ? "#ffffff" : "#1a1a1a"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold }
                Text { text: "Low-power standby"; color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.45); font.family: "Segoe UI"; font.pixelSize: 10 }
              }
            }
            MouseArea {
              id: sleepM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Qt.quit()
                startWindow.runCmd("systemctl suspend")
              }
            }
          }

          // Restart
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 6
            color: restartM.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10
              Text { text: "🔄"; font.pixelSize: 13 }
              ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text { text: "Restart"; color: startWindow.isDark ? "#ffffff" : "#1a1a1a"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold }
                Text { text: "Closes apps and restarts PC"; color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.45); font.family: "Segoe UI"; font.pixelSize: 10 }
              }
            }
            MouseArea {
              id: restartM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Qt.quit()
                startWindow.runCmd("systemctl reboot")
              }
            }
          }

          // Shut Down
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 6
            color: shutM.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10
              Text { text: "⏻"; color: "#ff5f56"; font.pixelSize: 13 }
              ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text { text: "Shut down"; color: startWindow.isDark ? "#ffffff" : "#1a1a1a"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold }
                Text { text: "Powers off your PC"; color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.45); font.family: "Segoe UI"; font.pixelSize: 10 }
              }
            }
            MouseArea {
              id: shutM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Qt.quit()
                startWindow.runCmd("systemctl poweroff")
              }
            }
          }

          // Lock
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 6
            color: lockM.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10
              Text { text: "🔒"; font.pixelSize: 13 }
              ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text { text: "Lock Screen"; color: startWindow.isDark ? "#ffffff" : "#1a1a1a"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold }
                Text { text: "Secures current session"; color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.45); font.family: "Segoe UI"; font.pixelSize: 10 }
              }
            }
            MouseArea {
              id: lockM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Qt.quit()
                startWindow.runCmd("loginctl lock-session || hyprlock || swaylock")
              }
            }
          }

          // Sign Out
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 6
            color: signoutM.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 10
              spacing: 10
              Text { text: "🚪"; font.pixelSize: 13 }
              ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text { text: "Sign Out"; color: startWindow.isDark ? "#ffffff" : "#1a1a1a"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold }
                Text { text: "Exits user environment"; color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.45); font.family: "Segoe UI"; font.pixelSize: 10 }
              }
            }
            MouseArea {
              id: signoutM
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Qt.quit()
                startWindow.runCmd("hyprctl dispatch exit")
              }
            }
          }
        }
      }
    }
  }
}
