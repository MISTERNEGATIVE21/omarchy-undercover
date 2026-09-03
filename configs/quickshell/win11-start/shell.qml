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
      bottom: 52
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 620
    implicitHeight: 640

    property bool isDark: true
    property bool isTransparent: true
    property string searchFilter: ""
    property int currentView: 0 // 0: Pinned + Recommended, 1: All Apps, 2: Search Results
    property bool showPowerPopup: false
    property string homeDir: Quickshell.env("HOME")
    property string userName: Quickshell.env("USER") || "User"

    Shortcut {
      sequence: "Escape"
      onActivated: {
        if (startWindow.showPowerPopup) {
          startWindow.showPowerPopup = false
        } else if (startWindow.currentView !== 0) {
          startWindow.currentView = 0
          searchInput.text = ""
        } else {
          Qt.quit()
        }
      }
    }

    function runCmd(cmd) {
      Qt.quit()
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    // Reactive Theme State Poller via FileView
    FileView {
      id: stateWatcher
      path: startWindow.homeDir + "/.config/omarchy-undercover/state"
      watchChanges: true
      onLoaded: {
        var s = text().trim()
        startWindow.isDark = (s.indexOf("light") === -1)
      }
      onFileChanged: {
        reload()
        var s = text().trim()
        startWindow.isDark = (s.indexOf("light") === -1)
      }
    }

    FileView {
      id: settingsWatcher
      path: startWindow.homeDir + "/.config/omarchy-undercover/settings.conf"
      watchChanges: true
      onLoaded: {
        var s = text()
        startWindow.isTransparent = (s.indexOf("BAR_TRANSPARENT=false") === -1 && s.indexOf("WIN11_TRANSPARENCY=false") === -1)
      }
      onFileChanged: {
        reload()
        var s = text()
        startWindow.isTransparent = (s.indexOf("BAR_TRANSPARENT=false") === -1 && s.indexOf("WIN11_TRANSPARENCY=false") === -1)
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
      { name: "Discord", icon: "💬", iconUrl: "", exec: "discord || vesktop || telegram-desktop" },
      { name: "Notepad", icon: "🗒️", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/notepad.svg", exec: "gedit || kate || mousepad || gnome-text-editor" },
      { name: "Mail", icon: "✉️", iconUrl: "", exec: "thunderbird || evolution || geary" },
      { name: "Paint", icon: "🎨", iconUrl: "", exec: "drawing || gimp || inkscape || pinta" },
      { name: "Weather", icon: "🌤️", iconUrl: "", exec: "omarchy-win11-widgets" }
    ]

    // Complete All-Apps Catalog (Alphabetical A-Z Drawer)
    property var allAppsList: [
      { name: "Alacritty Terminal", icon: "💻", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/terminal.svg", category: "A", exec: "alacritty || xdg-terminal-exec" },
      { name: "Antigravity IDE", icon: "🚀", iconUrl: "file://" + startWindow.homeDir + "/.local/share/icons/win11/antigravity-ide.svg", category: "A", exec: "antigravity-ide || code || vscodium" },
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
      { name: "omarchy-undercover", time: "Just now", icon: "📄", exec: "xdg-open ~/.config/omarchy-undercover" },
      { name: "Windows-11-Fluent.pdf", time: "2h ago", icon: "📑", exec: "xdg-open ~/Documents" },
      { name: "Project-Roadmap-2026.docx", time: "Yesterday at 4:15 PM", icon: "📘", exec: "xdg-open ~/Documents" },
      { name: "hyprland-config.lua", time: "Yesterday at 11:30 AM", icon: "⚙️", exec: "xdg-open ~/.config/hypr" },
      { name: "system-diagnostics.log", time: "5 days ago", icon: "📝", exec: "omarchy-undercover --status" }
    ]

    function getFilteredApps() {
      if (!startWindow.searchFilter || startWindow.searchFilter.trim() === "") return []
      var q = startWindow.searchFilter.toLowerCase().trim()
      return startWindow.allAppsList.filter(function(app) {
        return app.name.toLowerCase().indexOf(q) !== -1 || app.exec.toLowerCase().indexOf(q) !== -1
      })
    }

    // Windows 11 Fluent Acrylic / Mica Glass Container
    Rectangle {
      id: bg
      anchors.fill: parent
      radius: 12
      color: startWindow.isDark 
             ? (startWindow.isTransparent ? Qt.rgba(0.12, 0.13, 0.17, 0.88) : "#202024")
             : (startWindow.isTransparent ? Qt.rgba(0.97, 0.97, 0.98, 0.90) : "#f5f5f8")
      border.color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // 1. Top Search Bar with Fluent Focus Accent Glow
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 38
          radius: 19
          color: searchInput.activeFocus
                 ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                 : (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))
          border.color: searchInput.activeFocus ? (startWindow.isDark ? "#60cdff" : "#0067c0") : (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10))
          border.width: searchInput.activeFocus ? 2 : 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10

            Text {
              text: "󰍉"
              font.pixelSize: 14
              color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.6)
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
                if (text.trim().length > 0) startWindow.currentView = 2
                else startWindow.currentView = 0
              }

              onAccepted: {
                var res = startWindow.getFilteredApps()
                if (res.length > 0) startWindow.runCmd(res[0].exec)
                else if (text.trim().length > 0) startWindow.runCmd("omarchy-browser 'https://www.bing.com/search?q=" + encodeURIComponent(text.trim()) + "'")
              }
            }

            Text {
              visible: searchInput.text.length > 0
              text: "✕"
              font.pixelSize: 11
              color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.5)
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  searchInput.text = ""
                  startWindow.currentView = 0
                }
              }
            }
          }
        }

        // 2. Main Body (Swappable between Pinned+Recommended, All Apps, and Search Results)
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          // VIEW 0: Pinned + Recommended View
          ColumnLayout {
            anchors.fill: parent
            visible: startWindow.currentView === 0
            spacing: 12

            // Pinned Header
            RowLayout {
              Layout.fillWidth: true
              Text {
                text: "Pinned"
                font.family: "Segoe UI"
                font.pixelSize: 13
                font.bold: true
                color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
              }
              Item { Layout.fillWidth: true }
              Rectangle {
                implicitWidth: allAppsBtnText.implicitWidth + 16
                implicitHeight: 24
                radius: 4
                color: allAppsMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"

                RowLayout {
                  anchors.centerIn: parent
                  spacing: 4
                  Text {
                    id: allAppsBtnText
                    text: "All apps"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(0, 0, 0, 0.8)
                  }
                  Text {
                    text: "›"
                    font.pixelSize: 13
                    color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.6)
                  }
                }

                MouseArea {
                  id: allAppsMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: startWindow.currentView = 1
                }
              }
            }

            // 6-Column Pinned Apps Grid
            GridLayout {
              Layout.fillWidth: true
              columns: 6
              rowSpacing: 8
              columnSpacing: 4

              Repeater {
                model: startWindow.pinnedApps

                Rectangle {
                  implicitWidth: 92
                  implicitHeight: 74
                  radius: 6
                  color: tileMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"
                  border.color: tileMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                  scale: tileMouse.containsMouse ? 1.02 : 1.0

                  Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                  ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Item {
                      Layout.alignment: Qt.AlignHCenter
                      implicitWidth: 34
                      implicitHeight: 34

                      Image {
                        visible: modelData.iconUrl !== ""
                        anchors.fill: parent
                        source: modelData.iconUrl
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                      }

                      Text {
                        visible: modelData.iconUrl === ""
                        anchors.centerIn: parent
                        text: modelData.icon
                        font.pixelSize: 24
                      }
                    }

                    Text {
                      Layout.alignment: Qt.AlignHCenter
                      text: modelData.name
                      font.family: "Segoe UI"
                      font.pixelSize: 11
                      color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
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
              Text {
                text: "Recommended"
                font.family: "Segoe UI"
                font.pixelSize: 13
                font.bold: true
                color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
              }
              Item { Layout.fillWidth: true }
              Text {
                text: "More ›"
                font.family: "Segoe UI"
                font.pixelSize: 11
                color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.6)
              }
            }

            // Recommended Items (2 Columns)
            GridLayout {
              Layout.fillWidth: true
              columns: 2
              rowSpacing: 4
              columnSpacing: 12

              Repeater {
                model: startWindow.recommendedItems

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 38
                  radius: 5
                  color: recMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.04)) : "transparent"

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Text { text: modelData.icon; font.pixelSize: 18 }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 0
                      Text {
                        text: modelData.name
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        font.bold: true
                        color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }
                      Text {
                        text: modelData.time
                        font.family: "Segoe UI"
                        font.pixelSize: 10
                        color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.5)
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

          // VIEW 1: All Apps A-Z Drawer
          ColumnLayout {
            anchors.fill: parent
            visible: startWindow.currentView === 1
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              Rectangle {
                implicitWidth: backBtnText.implicitWidth + 16
                implicitHeight: 24
                radius: 4
                color: backMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"
                RowLayout {
                  anchors.centerIn: parent
                  spacing: 4
                  Text { text: "‹"; font.pixelSize: 13; color: startWindow.isDark ? "#ffffff" : "#1a1a1a" }
                  Text { id: backBtnText; text: "Back to Pinned"; font.family: "Segoe UI"; font.pixelSize: 11; color: startWindow.isDark ? "#ffffff" : "#1a1a1a" }
                }
                MouseArea {
                  id: backMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: startWindow.currentView = 0
                }
              }
              Item { Layout.fillWidth: true }
              Text { text: "All applications"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.6) }
            }

            ListView {
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              model: startWindow.allAppsList
              spacing: 2
              boundsBehavior: Flickable.StopAtBounds

              delegate: Rectangle {
                width: parent.width
                implicitHeight: 34
                radius: 4
                color: allAppItemMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  spacing: 10

                  Item {
                    implicitWidth: 20
                    implicitHeight: 20
                    Image {
                      visible: modelData.iconUrl !== ""
                      anchors.fill: parent
                      source: modelData.iconUrl
                      fillMode: Image.PreserveAspectFit
                      smooth: true
                    }
                    Text {
                      visible: modelData.iconUrl === ""
                      anchors.centerIn: parent
                      text: modelData.icon
                      font.pixelSize: 16
                    }
                  }

                  Text {
                    text: modelData.name
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                    Layout.fillWidth: true
                  }
                }

                MouseArea {
                  id: allAppItemMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: startWindow.runCmd(modelData.exec)
                }
              }
            }
          }

          // VIEW 2: Search Results
          ColumnLayout {
            anchors.fill: parent
            visible: startWindow.currentView === 2
            spacing: 6

            Text {
              text: "Search Results (" + startWindow.getFilteredApps().length + ")"
              font.family: "Segoe UI"
              font.pixelSize: 12
              font.bold: true
              color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.6)
            }

            ListView {
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              model: startWindow.getFilteredApps()
              spacing: 2

              delegate: Rectangle {
                width: parent.width
                implicitHeight: 36
                radius: 4
                color: searchResMouse.containsMouse ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)) : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  spacing: 10

                  Item {
                    implicitWidth: 22
                    implicitHeight: 22
                    Image {
                      visible: modelData.iconUrl !== ""
                      anchors.fill: parent
                      source: modelData.iconUrl
                      fillMode: Image.PreserveAspectFit
                    }
                    Text {
                      visible: modelData.iconUrl === ""
                      anchors.centerIn: parent
                      text: modelData.icon
                      font.pixelSize: 16
                    }
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                      text: modelData.name
                      font.family: "Segoe UI"
                      font.pixelSize: 11
                      font.bold: true
                      color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
                    }
                    Text {
                      text: modelData.exec
                      font.family: "Segoe UI"
                      font.pixelSize: 9
                      color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(0, 0, 0, 0.4)
                    }
                  }
                }

                MouseArea {
                  id: searchResMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: startWindow.runCmd(modelData.exec)
                }
              }
            }
          }
        }

        // 3. User Profile & Power Hub Footer Bar
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 48
          radius: 8
          color: startWindow.isDark ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(0, 0, 0, 0.04)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            // User Info
            RowLayout {
              spacing: 8

              Rectangle {
                width: 28
                height: 28
                radius: 14
                color: "#0078d4"
                Text {
                  anchors.centerIn: parent
                  text: startWindow.userName.charAt(0).toUpperCase()
                  font.family: "Segoe UI"
                  font.pixelSize: 12
                  font.bold: true
                  color: "#ffffff"
                }
              }

              Text {
                text: startWindow.userName
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.bold: true
                color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
              }
            }

            Item { Layout.fillWidth: true }

            // Power Button
            Rectangle {
              implicitWidth: 32
              implicitHeight: 32
              radius: 6
              color: powerMouse.containsMouse || startWindow.showPowerPopup ? (startWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"

              Text {
                anchors.centerIn: parent
                text: "⏻"
                font.pixelSize: 16
                color: startWindow.isDark ? "#ffffff" : "#1a1a1a"
              }

              MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: startWindow.showPowerPopup = !startWindow.showPowerPopup
              }
            }
          }
        }
      }

      // Windows 11 Power Flyout Popup
      Rectangle {
        id: powerFlyout
        visible: startWindow.showPowerPopup
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        anchors.right: parent.right
        anchors.rightMargin: 18
        implicitWidth: 140
        implicitHeight: powerCol.implicitHeight + 16
        radius: 8
        color: startWindow.isDark ? Qt.rgba(0.16, 0.17, 0.22, 0.96) : Qt.rgba(0.98, 0.98, 1.0, 0.96)
        border.color: startWindow.isDark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)
        border.width: 1
        z: 99

        ColumnLayout {
          id: powerCol
          anchors.fill: parent
          anchors.margins: 6
          spacing: 2

          Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 4
            color: p1.containsMouse ? (startWindow.isDark ? "#0078d4" : "#60cdff") : "transparent"
            Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "󰤄  Sleep"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#ffffff" }
            MouseArea { id: p1; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: startWindow.runCmd("systemctl suspend") }
          }
          Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 4
            color: p2.containsMouse ? (startWindow.isDark ? "#0078d4" : "#60cdff") : "transparent"
            Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "󰑐  Restart"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#ffffff" }
            MouseArea { id: p2; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: startWindow.runCmd("systemctl reboot") }
          }
          Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 4
            color: p3.containsMouse ? (startWindow.isDark ? "#0078d4" : "#60cdff") : "transparent"
            Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "󰐥  Shut down"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#ffffff" }
            MouseArea { id: p3; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: startWindow.runCmd("systemctl poweroff") }
          }
          Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 4
            color: p4.containsMouse ? (startWindow.isDark ? "#0078d4" : "#60cdff") : "transparent"
            Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "󰍃  Sign out"; font.family: "Segoe UI"; font.pixelSize: 11; color: "#ffffff" }
            MouseArea { id: p4; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: startWindow.runCmd("hyprctl dispatch exit") }
          }
        }
      }
    }
  }
}
