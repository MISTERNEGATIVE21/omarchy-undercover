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
      bottom: 48
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 620
    implicitHeight: 630

    property bool isDark: true
    property bool isTransparent: true
    property string searchFilter: ""
    property int currentView: 0 // 0: Pinned, 1: All Apps, 2: Search Results
    property bool showPowerPopup: false
    property string homeDir: Quickshell.env("HOME")

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

    // Pinned Applications (6x3 grid)
    property var pinnedApps: [
      { name: "Edge", icon: "🌐", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/microsoft-edge.svg", exec: "omarchy-browser" },
      { name: "Word", icon: "📝", iconUrl: "", exec: "libreoffice --writer || abiword || omarchy-browser https://office.com" },
      { name: "Excel", icon: "📊", iconUrl: "", exec: "libreoffice --calc || gnumeric || xdg-open https://office.com" },
      { name: "PowerPoint", icon: "📽️", iconUrl: "", exec: "libreoffice --impress || xdg-open https://office.com" },
      { name: "Store", icon: "🛍️", iconUrl: "", exec: "pamac-manager || gnome-software || discover" },
      { name: "Photos", icon: "🖼️", iconUrl: "", exec: "eog || gwenview || loupe" },
      { name: "Settings", icon: "⚙️", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/settings.svg", exec: "omarchy-undercover-settings" },
      { name: "Terminal", icon: "💻", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/terminal.svg", exec: "xdg-terminal-exec" },
      { name: "Explorer", icon: "📁", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/explorer.svg", exec: "nautilus computer:/// || thunar || dolphin" },
      { name: "Calculator", icon: "🔢", iconUrl: "", exec: "gnome-calculator || kcalc || galculator" },
      { name: "Spotify", icon: "🎵", iconUrl: "", exec: "spotify || omarchy-win11-widgets" },
      { name: "Antigravity", icon: "🚀", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/antigravity-ide.svg", exec: "antigravity-ide || code || vscodium" },
      { name: "VS Code", icon: "🧑‍💻", iconUrl: "", exec: "code || vscodium || cursor" },
      { name: "Chat", icon: "💬", iconUrl: "", exec: "discord || telegram-desktop || slack" },
      { name: "Notepad", icon: "🗒️", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/notepad.svg", exec: "gedit || kate || mousepad || gnome-text-editor" },
      { name: "Mail", icon: "✉️", iconUrl: "", exec: "thunderbird || evolution || geary" },
      { name: "Paint", icon: "🎨", iconUrl: "", exec: "drawing || gimp || inkscape || pinta" },
      { name: "Weather", icon: "🌤️", iconUrl: "", exec: "omarchy-win11-widgets" }
    ]

    // Complete All-Apps Catalog (Alphabetical A-Z Drawer)
    property var allAppsList: [
      { name: "Antigravity IDE", icon: "🚀", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/antigravity-ide.svg", category: "A", exec: "antigravity-ide || code || vscodium" },
      { name: "Alacritty Terminal", icon: "💻", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/terminal.svg", category: "A", exec: "alacritty || xdg-terminal-exec" },
      { name: "App Store / Software", icon: "🛍️", iconUrl: "", category: "A", exec: "pamac-manager || gnome-software || discover" },
      { name: "Bluetooth Manager", icon: "🔷", iconUrl: "", category: "B", exec: "omarchy-win11-bluetooth || blueman-manager" },
      { name: "Browser (Edge)", icon: "🌐", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/microsoft-edge.svg", category: "B", exec: "omarchy-browser" },
      { name: "Calculator", icon: "🔢", iconUrl: "", category: "C", exec: "gnome-calculator || kcalc" },
      { name: "Calendar", icon: "📅", iconUrl: "", category: "C", exec: "gnome-calendar || korganizer" },
      { name: "Camera", icon: "📷", iconUrl: "", category: "C", exec: "cheese || kamoso" },
      { name: "Clock & Alarms", icon: "⏰", iconUrl: "", category: "C", exec: "gnome-clocks || kclock" },
      { name: "Discord", icon: "💬", iconUrl: "", category: "D", exec: "discord || vesktop" },
      { name: "Document Viewer", icon: "📑", iconUrl: "", category: "D", exec: "evince || okular" },
      { name: "File Explorer", icon: "📁", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/explorer.svg", category: "F", exec: "nautilus computer:/// || thunar" },
      { name: "Firefox Browser", icon: "🦊", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/firefox.svg", category: "F", exec: "firefox" },
      { name: "GIMP Image Editor", icon: "🎨", iconUrl: "", category: "G", exec: "gimp" },
      { name: "Google Chrome", icon: "🌐", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/google-chrome.svg", category: "G", exec: "google-chrome-stable || chromium" },
      { name: "LibreOffice Calc", icon: "📊", iconUrl: "", category: "L", exec: "libreoffice --calc" },
      { name: "LibreOffice Writer", icon: "📝", iconUrl: "", category: "L", exec: "libreoffice --writer" },
      { name: "LibreOffice Impress", icon: "📽️", iconUrl: "", category: "L", exec: "libreoffice --impress" },
      { name: "Mail / Thunderbird", icon: "✉️", iconUrl: "", category: "M", exec: "thunderbird || evolution" },
      { name: "Microsoft Edge", icon: "🌐", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/microsoft-edge.svg", category: "M", exec: "omarchy-browser" },
      { name: "Music / Media Player", icon: "🎵", iconUrl: "", category: "M", exec: "spotify || vlc || celluloid" },
      { name: "Notepad Text Editor", icon: "🗒️", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/notepad.svg", category: "N", exec: "gedit || kate || mousepad" },
      { name: "Omarchy Settings", icon: "🕵️", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/settings.svg", category: "O", exec: "omarchy-undercover-settings" },
      { name: "Paint / Drawing", icon: "🎨", iconUrl: "", category: "P", exec: "drawing || pinta" },
      { name: "Photos / Image Viewer", icon: "🖼️", iconUrl: "", category: "P", exec: "eog || gwenview || loupe" },
      { name: "Screen Recorder", icon: "🎥", iconUrl: "", category: "S", exec: "obs || wf-recorder" },
      { name: "Settings", icon: "⚙️", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/settings.svg", category: "S", exec: "omarchy-undercover-settings" },
      { name: "Sound Mixer", icon: "🔊", iconUrl: "", category: "S", exec: "omarchy-win11-sound || pavucontrol" },
      { name: "Spotify", icon: "🎵", iconUrl: "", category: "S", exec: "spotify" },
      { name: "System Monitor", icon: "📈", iconUrl: "", category: "S", exec: "gnome-system-monitor || btop" },
      { name: "Task View / Switcher", icon: "⧉", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/taskview.svg", category: "T", exec: "rofi -show window" },
      { name: "Terminal Console", icon: "💻", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/terminal.svg", category: "T", exec: "xdg-terminal-exec" },
      { name: "VS Code", icon: "🧑‍💻", iconUrl: "", category: "V", exec: "code || vscodium" },
      { name: "VLC Media Player", icon: "🎬", iconUrl: "", category: "V", exec: "vlc" },
      { name: "Weather & Widgets", icon: "🌤️", iconUrl: "", category: "W", exec: "omarchy-win11-widgets" },
      { name: "Wi-Fi Manager", icon: "📶", iconUrl: "", category: "W", exec: "omarchy-win11-wifi || nm-connection-editor" }
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
      radius: 14
      color: startWindow.isDark 
             ? (startWindow.isTransparent ? Qt.rgba(0.12, 0.12, 0.16, 0.88) : "#202024")
             : (startWindow.isTransparent ? Qt.rgba(0.97, 0.97, 0.98, 0.90) : "#f5f5f8")
      border.color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        // 1. Top Search Bar with Live Real-Time TextInput
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 20
            color: searchInput.activeFocus
                   ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                   : (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))
            border.color: searchInput.activeFocus ? (startWindow.isDark ? "#60cdff" : "#0067c0") : (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10))
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 12
              spacing: 10

              Item {
                implicitWidth: 16
                implicitHeight: 16
                Layout.alignment: Qt.AlignVCenter
                Image {
                  anchors.centerIn: parent
                  width: 16
                  height: 16
                  source: "file://" + startWindow.homeDir + "/.local/share/icons/win11/search.svg"
                  fillMode: Image.PreserveAspectFit
                  opacity: 0.7
                }
              }

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

        // 2. Main StackLayout for seamless View Switching
        StackLayout {
          id: viewsStack
          currentIndex: startWindow.currentView
          Layout.fillWidth: true
          Layout.fillHeight: true

          // ================= VIEW 0: PINNED APPS & RECOMMENDED =================
          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Pinned Header
            RowLayout {
              Layout.fillWidth: true
              Text {
                text: "Pinned"
                color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                font.family: "Segoe UI"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.fillWidth: true
              }
              Rectangle {
                implicitWidth: 80
                implicitHeight: 24
                radius: 5
                color: allAppsMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: "All apps >"
                  color: startWindow.isDark ? "#60cdff" : "#0067c0"
                  font.family: "Segoe UI"
                  font.pixelSize: 11
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

            // 6x3 Grid of Pinned Apps
            GridLayout {
              columns: 6
              rowSpacing: 8
              columnSpacing: 6
              Layout.fillWidth: true

              Repeater {
                model: startWindow.pinnedApps

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 68
                  radius: 8
                  color: tileMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"

                  ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Item {
                      Layout.alignment: Qt.AlignHCenter
                      implicitWidth: 32
                      implicitHeight: 32

                      Image {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        source: (modelData.iconUrl && modelData.iconUrl.length > 0) ? modelData.iconUrl : ""
                        visible: modelData.iconUrl && modelData.iconUrl.length > 0
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                      }

                      Rectangle {
                        anchors.centerIn: parent
                        width: 30
                        height: 30
                        radius: 7
                        visible: !modelData.iconUrl || modelData.iconUrl.length === 0
                        color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
                        Text {
                          anchors.centerIn: parent
                          text: modelData.icon
                          font.pixelSize: 18
                        }
                      }
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
              Layout.topMargin: 2
              Text {
                text: "Recommended"
                color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                font.family: "Segoe UI"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.fillWidth: true
              }
              Rectangle {
                implicitWidth: 60
                implicitHeight: 24
                radius: 5
                color: moreMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: "More >"
                  color: startWindow.isDark ? "#60cdff" : "#0067c0"
                  font.family: "Segoe UI"
                  font.pixelSize: 11
                }
                MouseArea {
                  id: moreMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: startWindow.runCmd("xdg-open ~/Documents")
                }
              }
            }

            // 2-Column Recommended Items Grid
            GridLayout {
              columns: 2
              columnSpacing: 8
              rowSpacing: 4
              Layout.fillWidth: true

              Repeater {
                model: startWindow.recommendedItems

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 40
                  radius: 7
                  color: recMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text { text: modelData.icon; font.pixelSize: 16 }
                    ColumnLayout {
                      spacing: 1
                      Layout.fillWidth: true
                      Text {
                        text: modelData.name
                        color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }
                      Text {
                        text: modelData.time
                        color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.5)
                        font.family: "Segoe UI"
                        font.pixelSize: 9
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

            Item { Layout.fillHeight: true }
          }

          // ================= VIEW 1: ALL APPS A-Z DRAWER =================
          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Back Button Header
            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Rectangle {
                implicitWidth: 68
                implicitHeight: 26
                radius: 6
                color: backM.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
                RowLayout {
                  anchors.centerIn: parent
                  spacing: 4
                  Text { text: "‹"; font.pixelSize: 13; color: startWindow.isDark ? "#60cdff" : "#0067c0"; font.weight: Font.Bold }
                  Text { text: "Back"; color: startWindow.isDark ? "#60cdff" : "#0067c0"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold }
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
                font.pixelSize: 13
                font.weight: Font.Bold
              }
            }

            // Scrollable All-Apps List with zero clipping
            ScrollView {
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

              ListView {
                id: allAppsView
                width: parent.width
                model: startWindow.allAppsList
                spacing: 3
                boundsBehavior: Flickable.StopAtBounds
                bottomMargin: 10

                delegate: Rectangle {
                  width: allAppsView.width
                  implicitHeight: 38
                  radius: 6
                  color: appRowM.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Item {
                      implicitWidth: 26
                      implicitHeight: 26
                      Layout.alignment: Qt.AlignVCenter

                      Image {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: (modelData.iconUrl && modelData.iconUrl.length > 0) ? modelData.iconUrl : ""
                        visible: modelData.iconUrl && modelData.iconUrl.length > 0
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                      }

                      Rectangle {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        radius: 6
                        visible: !modelData.iconUrl || modelData.iconUrl.length === 0
                        color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
                        Text {
                          anchors.centerIn: parent
                          text: modelData.icon
                          font.pixelSize: 14
                        }
                      }
                    }

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
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

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
              ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

              ListView {
                id: searchResultsView
                width: parent.width
                model: startWindow.getFilteredApps()
                spacing: 3
                boundsBehavior: Flickable.StopAtBounds
                bottomMargin: 10

                delegate: Rectangle {
                  width: searchResultsView.width
                  implicitHeight: 42
                  radius: 7
                  color: searchRowM.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03))
                  border.color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Item {
                      implicitWidth: 26
                      implicitHeight: 26
                      Layout.alignment: Qt.AlignVCenter

                      Image {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: (modelData.iconUrl && modelData.iconUrl.length > 0) ? modelData.iconUrl : ""
                        visible: modelData.iconUrl && modelData.iconUrl.length > 0
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                      }

                      Rectangle {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        radius: 6
                        visible: !modelData.iconUrl || modelData.iconUrl.length === 0
                        color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
                        Text {
                          anchors.centerIn: parent
                          text: modelData.icon
                          font.pixelSize: 14
                        }
                      }
                    }

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
                        font.pixelSize: 9
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
              implicitHeight: 40
              radius: 7
              color: webSearchM.containsMouse ? (startWindow.isDark ? Qt.rgba(0, 120, 212, 0.3) : Qt.rgba(0, 120, 212, 0.15)) : (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
              border.color: startWindow.isDark ? Qt.rgba(0, 120, 212, 0.5) : Qt.rgba(0, 120, 212, 0.3)

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text { text: "🌐"; font.pixelSize: 15 }
                Text {
                  text: "Search the web for \"" + startWindow.searchFilter + "\""
                  color: startWindow.isDark ? "#60cdff" : "#0067c0"
                  font.family: "Segoe UI"
                  font.pixelSize: 11
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
        }

        // 3. User Profile & Power Footer (Permanently pinned at bottom)
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 48
          radius: 9
          color: startWindow.isDark ? Qt.rgba(0.08, 0.08, 0.11, 0.85) : Qt.rgba(0.92, 0.92, 0.94, 0.90)
          border.color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            // User Profile
            RowLayout {
              spacing: 10
              Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: startWindow.isDark ? "#0078d4" : "#0067c0"
                Text {
                  anchors.centerIn: parent
                  text: (Quickshell.env("USER") ? Quickshell.env("USER").substring(0, 1).toUpperCase() : "U")
                  color: "#ffffff"
                  font.family: "Segoe UI"
                  font.pixelSize: 12
                  font.weight: Font.Bold
                }
              }
              ColumnLayout {
                spacing: 1
                Text {
                  text: Quickshell.env("USER") ? (Quickshell.env("USER").charAt(0).toUpperCase() + Quickshell.env("USER").slice(1)) : "Personal Account"
                  color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                  font.family: "Segoe UI"
                  font.pixelSize: 11
                  font.weight: Font.DemiBold
                }
                Text {
                  text: "Personal Account"
                  color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(0, 0, 0, 0.45)
                  font.family: "Segoe UI"
                  font.pixelSize: 9
                }
              }
            }

            Item { Layout.fillWidth: true }

            // Settings Shortcut
            Rectangle {
              implicitWidth: 32
              implicitHeight: 32
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
              implicitWidth: 32
              implicitHeight: 32
              radius: 6
              color: powerMouse.containsMouse || startWindow.showPowerPopup ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)) : "transparent"
              Text { anchors.centerIn: parent; text: "⏻"; color: startWindow.isDark ? "#ffffff" : "#1a1a1a"; font.pixelSize: 15 }
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

      // ================= POWER FLYOUT POPUP CARD =================
      Rectangle {
        id: powerFlyout
        visible: startWindow.showPowerPopup
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 18
        anchors.bottomMargin: 72
        width: 220
        height: 220
        radius: 12
        color: startWindow.isDark ? Qt.rgba(0.14, 0.14, 0.18, 0.98) : Qt.rgba(0.98, 0.98, 1.0, 0.98)
        border.color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)
        border.width: 1

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
