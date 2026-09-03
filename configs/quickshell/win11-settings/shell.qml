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
    title: "Settings"

    implicitWidth: 980
    implicitHeight: 660
    minimumSize: Qt.size(820, 540)
    color: "transparent"

    property string homeDir: Quickshell.env("HOME")
    property string userName: Quickshell.env("USER") || "User"
    property bool isDark: true
    property bool isTransparent: true
    property string activeAccent: "0078d4"
    property int currentCategory: 0
    property string searchQuery: ""

    property int volumeLevel: 70
    property int brightnessLevel: 80
    property bool wifiEnabled: true
    property string wifiSsid: "Connected"
    property bool btEnabled: true
    property bool isAwakeActive: false
    property bool autohideActive: false
    property string taskbarAlign: "center"
    property int windowGaps: 8
    property int windowRounding: 10

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    function saveSetting(key, val) {
      runCmd("sed -i 's/^" + key + "=.*/" + key + "=" + val + "/' " + homeDir + "/.config/omarchy-undercover/settings.conf 2>/dev/null || true")
    }

    // Reactive Watcher on state
    FileView {
      id: stateWatcher
      path: settingsWin.homeDir + "/.config/omarchy-undercover/state"
      watchChanges: true
      onLoaded: {
        var s = text().trim()
        settingsWin.isDark = (s.indexOf("light") === -1)
      }
      onFileChanged: {
        reload()
        var s = text().trim()
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
        settingsWin.isTransparent = (s.indexOf("WIN11_TRANSPARENCY=false") === -1 && s.indexOf("BAR_TRANSPARENT=false") === -1)
        if (s.indexOf("ALIGN_LEFT=true") !== -1) settingsWin.taskbarAlign = "left"
        else settingsWin.taskbarAlign = "center"
        var m = s.match(/ACCENT=([0-9a-fA-F]+)/)
        if (m && m[1]) settingsWin.activeAccent = m[1]
      }
      onFileChanged: {
        reload()
        var s = text()
        settingsWin.autohideActive = (s.indexOf("AUTOHIDE=true") !== -1)
        settingsWin.isTransparent = (s.indexOf("WIN11_TRANSPARENCY=false") === -1 && s.indexOf("BAR_TRANSPARENT=false") === -1)
        if (s.indexOf("ALIGN_LEFT=true") !== -1) settingsWin.taskbarAlign = "left"
        else settingsWin.taskbarAlign = "center"
        var m = s.match(/ACCENT=([0-9a-fA-F]+)/)
        if (m && m[1]) settingsWin.activeAccent = m[1]
      }
    }

    // Live Hardware Poller
    Process {
      id: hwPoller
      command: [
        "bash", "-c",
        "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo '70'); " +
        "bri=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo '80'); " +
        "wifi=$(nmcli radio wifi 2>/dev/null || echo 'enabled'); " +
        "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 || echo 'Connected'); " +
        "bt=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo '1' || echo '0'); " +
        "echo \"$vol|$bri|$wifi|$ssid|$bt\""
      ]
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          var parts = line.trim().split("|")
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
      interval: 3000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!hwPoller.running) hwPoller.running = true
      }
    }

    // Windows 11 Acrylic Mica Background Container
    Rectangle {
      id: windowBody
      anchors.fill: parent
      radius: 12
      color: settingsWin.isDark
             ? (settingsWin.isTransparent ? Qt.rgba(0.12, 0.13, 0.17, 0.94) : "#1f2025")
             : (settingsWin.isTransparent ? Qt.rgba(0.96, 0.96, 0.98, 0.94) : "#f3f3f6")
      border.color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.10)
      border.width: 1
      clip: true

      ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 1. Top Windows 11 Titlebar
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 44
          color: "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 0
            spacing: 12

            // App Icon & Title
            RowLayout {
              spacing: 8
              Text { text: "⚙"; font.pixelSize: 15; color: "#" + settingsWin.activeAccent }
              Text {
                text: "Settings"
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.bold: true
                color: settingsWin.isDark ? "#ffffff" : "#1a1a1a"
              }
            }

            Item { Layout.fillWidth: true }

            // Titlebar Window Controls (— 🗖 ✕)
            RowLayout {
              spacing: 0

              Rectangle {
                implicitWidth: 46
                implicitHeight: 32
                color: minMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                Text { anchors.centerIn: parent; text: "—"; font.pixelSize: 10; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                MouseArea {
                  id: minMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: settingsWin.runCmd("omarchy-undercover-minimize")
                }
              }

              Rectangle {
                implicitWidth: 46
                implicitHeight: 32
                color: maxMouse.containsMouse ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
                Text { anchors.centerIn: parent; text: "🗖"; font.pixelSize: 11; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                MouseArea {
                  id: maxMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: settingsWin.runCmd("omarchy-undercover-snap up")
                }
              }

              Rectangle {
                implicitWidth: 46
                implicitHeight: 32
                color: closeMouse.containsMouse ? "#c42b1c" : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: "✕"
                  font.pixelSize: 10
                  font.bold: true
                  color: closeMouse.containsMouse ? "#ffffff" : (settingsWin.isDark ? "#ffffff" : "#1a1a1a")
                }
                MouseArea {
                  id: closeMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Qt.quit()
                }
              }
            }
          }
        }

        // 2. Main Body Split: Left Sidebar + Right Content View
        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 0

          // ==========================================
          // LEFT SIDEBAR (Windows 11 Navigation)
          // ==========================================
          Rectangle {
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            color: settingsWin.isDark ? Qt.rgba(0, 0, 0, 0.15) : Qt.rgba(0, 0, 0, 0.02)
            border.color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.05)
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 14
              spacing: 10

              // User Profile Capsule
              RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                  width: 44
                  height: 44
                  radius: 22
                  color: "#" + settingsWin.activeAccent
                  Text {
                    anchors.centerIn: parent
                    text: settingsWin.userName.charAt(0).toUpperCase()
                    font.family: "Segoe UI"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#ffffff"
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text {
                    text: settingsWin.userName
                    font.family: "Segoe UI"
                    font.pixelSize: 13
                    font.bold: true
                    color: settingsWin.isDark ? "#ffffff" : "#1a1a1a"
                  }
                  Text {
                    text: "Local Account / Administrator"
                    font.family: "Segoe UI"
                    font.pixelSize: 10
                    color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.5)
                  }
                }
              }

              // Search Box
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 6
                color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
                border.color: searchInput.activeFocus ? ("#" + settingsWin.activeAccent) : "transparent"
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  spacing: 6

                  Text { text: "🔍"; font.pixelSize: 11; opacity: 0.5 }
                  TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    color: settingsWin.isDark ? "#ffffff" : "#1a1a1a"
                    clip: true
                    Text {
                      visible: !searchInput.text
                      text: "Find a setting"
                      font.family: "Segoe UI"
                      font.pixelSize: 11
                      color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(0, 0, 0, 0.4)
                    }
                    onTextChanged: settingsWin.searchQuery = text
                  }
                }
              }

              // Navigation Categories List
              property var categories: [
                { id: 0, icon: "🖥️", name: "System" },
                { id: 1, icon: "🔷", name: "Bluetooth & devices" },
                { id: 2, icon: "📶", name: "Network & internet" },
                { id: 3, icon: "🎨", name: "Personalization" },
                { id: 4, icon: "🛠️", name: "PowerToys & Tools" },
                { id: 5, icon: "🕵️", name: "Undercover Disguise" },
                { id: 6, icon: "🔄", name: "Windows Update & Health" }
              ]

              ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: parent.categories

                delegate: Rectangle {
                  width: parent.width
                  implicitHeight: 38
                  radius: 6

                  readonly property bool isSelected: settingsWin.currentCategory === modelData.id
                  color: isSelected
                         ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                         : (catMouse.containsMouse
                            ? (settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04))
                            : "transparent")

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text { text: modelData.icon; font.pixelSize: 14 }
                    Text {
                      text: modelData.name
                      font.family: "Segoe UI"
                      font.pixelSize: 12
                      font.bold: isSelected
                      color: settingsWin.isDark ? "#ffffff" : "#1a1a1a"
                      Layout.fillWidth: true
                    }
                  }

                  // Left Accent Bar for Active Category
                  Rectangle {
                    visible: isSelected
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 18
                    radius: 1.5
                    color: "#" + settingsWin.activeAccent
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

          // ==========================================
          // RIGHT CONTENT VIEW
          // ==========================================
          ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
              width: parent.width - 32
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: 16

              Item { implicitHeight: 4 }

              // Header Title
              Text {
                text: {
                  switch(settingsWin.currentCategory) {
                    case 0: return "System"
                    case 1: return "Bluetooth & devices"
                    case 2: return "Network & internet"
                    case 3: return "Personalization"
                    case 4: return "PowerToys & Tools (Winux Utilities)"
                    case 5: return "Undercover Disguise Transformation"
                    case 6: return "Windows Update & System Health"
                    default: return "Settings"
                  }
                }
                font.family: "Segoe UI"
                font.pixelSize: 22
                font.bold: true
                color: settingsWin.isDark ? "#ffffff" : "#1a1a1a"
              }

              // ----------------------------------------------------
              // TAB 0: SYSTEM (Display, Sound, Gaps, Multitasking)
              // ----------------------------------------------------
              ColumnLayout {
                visible: settingsWin.currentCategory === 0
                Layout.fillWidth: true
                spacing: 12

                // Display Brightness Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 70
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  border.color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Text { text: "☀️"; font.pixelSize: 20 }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Display Brightness"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                      Text { text: settingsWin.brightnessLevel + "%"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                    }
                    Slider {
                      from: 5; to: 100
                      value: settingsWin.brightnessLevel
                      onMoved: {
                        settingsWin.brightnessLevel = Math.round(value)
                        settingsWin.runCmd("brightnessctl set " + Math.round(value) + "% >/dev/null 2>&1")
                      }
                    }
                  }
                }

                // Sound Volume Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 70
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  border.color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Text { text: "🔊"; font.pixelSize: 20 }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Master Volume"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                      Text { text: settingsWin.volumeLevel + "%"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                    }
                    Slider {
                      from: 0; to: 100
                      value: settingsWin.volumeLevel
                      onMoved: {
                        settingsWin.volumeLevel = Math.round(value)
                        settingsWin.runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (Math.round(value) / 100.0) + " >/dev/null 2>&1")
                      }
                    }
                  }
                }

                // Window Gaps Tuning Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 70
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  border.color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Text { text: "🗖"; font.pixelSize: 20 }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Desktop Window Gaps"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                      Text { text: settingsWin.windowGaps + "px outer gaps"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                    }
                    Slider {
                      from: 0; to: 24
                      value: settingsWin.windowGaps
                      onMoved: {
                        settingsWin.windowGaps = Math.round(value)
                        settingsWin.runCmd("hyprctl keyword general:gaps_out " + Math.round(value) + " >/dev/null 2>&1")
                      }
                    }
                  }
                }
              }

              // ----------------------------------------------------
              // TAB 1: BLUETOOTH & DEVICES
              // ----------------------------------------------------
              ColumnLayout {
                visible: settingsWin.currentCategory === 1
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 60
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Text { text: "🔷"; font.pixelSize: 18 }
                    Text { text: "Bluetooth Radio Power"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a"; Layout.fillWidth: true }
                    Switch {
                      checked: settingsWin.btEnabled
                      onToggled: {
                        settingsWin.btEnabled = checked
                        settingsWin.runCmd("bluetoothctl power " + (checked ? "on" : "off"))
                      }
                    }
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 44
                  radius: 6
                  color: "#" + settingsWin.activeAccent
                  Text { anchors.centerIn: parent; text: "Open Advanced Bluetooth Manager"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsWin.runCmd("omarchy-bluetooth-manager || blueman-manager")
                  }
                }
              }

              // ----------------------------------------------------
              // TAB 2: NETWORK & INTERNET
              // ----------------------------------------------------
              ColumnLayout {
                visible: settingsWin.currentCategory === 2
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 60
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Text { text: "📶"; font.pixelSize: 18 }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Wi-Fi Connection"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                      Text { text: settingsWin.wifiEnabled ? settingsWin.wifiSsid : "Wi-Fi is turned off"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                    }
                    Switch {
                      checked: settingsWin.wifiEnabled
                      onToggled: {
                        settingsWin.wifiEnabled = checked
                        settingsWin.runCmd("nmcli radio wifi " + (checked ? "on" : "off"))
                      }
                    }
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 44
                  radius: 6
                  color: "#" + settingsWin.activeAccent
                  Text { anchors.centerIn: parent; text: "Scan & Connect to Wi-Fi Networks"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsWin.runCmd("omarchy-wifi-manager || nm-connection-editor")
                  }
                }
              }

              // ----------------------------------------------------
              // TAB 3: PERSONALIZATION (Accent colors, Wallpapers, Taskbar)
              // ----------------------------------------------------
              ColumnLayout {
                visible: settingsWin.currentCategory === 3
                Layout.fillWidth: true
                spacing: 14

                // Dark / Light Theme Switch
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 60
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Text { text: "🌓"; font.pixelSize: 18 }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Color Mode"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                      Text { text: settingsWin.isDark ? "Dark Mode" : "Light Mode"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                    }
                    Switch {
                      checked: settingsWin.isDark
                      onToggled: {
                        settingsWin.isDark = checked
                        settingsWin.runCmd("omarchy-undercover " + (checked ? "-w11" : "-w11-light"))
                      }
                    }
                  }
                }

                // Accent Color Palette
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 6
                  Text { text: "Windows 11 Accent Color"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                  RowLayout {
                    spacing: 10
                    property var palette: ["0078d4", "60cdff", "00b7c3", "107c41", "8764b8", "c42b1c", "e81123", "486860"]
                    Repeater {
                      model: parent.palette
                      Rectangle {
                        width: 32; height: 32; radius: 16
                        color: "#" + modelData
                        border.color: settingsWin.activeAccent === modelData ? "#ffffff" : "transparent"
                        border.width: 2
                        Text {
                          visible: settingsWin.activeAccent === modelData
                          anchors.centerIn: parent
                          text: "✓"
                          color: "#ffffff"
                          font.bold: true
                          font.pixelSize: 14
                        }
                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            settingsWin.activeAccent = modelData
                            settingsWin.saveSetting("ACCENT", modelData)
                            settingsWin.runCmd("hyprctl reload >/dev/null 2>&1")
                          }
                        }
                      }
                    }
                  }
                }

                // Taskbar Alignment Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 60
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Text { text: "◫"; font.pixelSize: 18 }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Taskbar Alignment"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                      Text { text: settingsWin.taskbarAlign === "center" ? "Centered" : "Left Aligned"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                    }
                    Rectangle {
                      implicitWidth: 90
                      implicitHeight: 28
                      radius: 4
                      color: "#" + settingsWin.activeAccent
                      Text { anchors.centerIn: parent; text: "Switch Align"; font.family: "Segoe UI"; font.pixelSize: 10; font.bold: true; color: "#ffffff" }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          var next = (settingsWin.taskbarAlign === "center" ? "left" : "center")
                          settingsWin.taskbarAlign = next
                          settingsWin.runCmd("omarchy-undercover --align-" + next)
                        }
                      }
                    }
                  }
                }

                // Taskbar Auto-Hide Card
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 60
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Text { text: "⤓"; font.pixelSize: 18 }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "Automatically hide the taskbar"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                      Text { text: settingsWin.autohideActive ? "Taskbar hides when cursor is away" : "Taskbar is permanently pinned"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                    }
                    Switch {
                      checked: settingsWin.autohideActive
                      onToggled: {
                        settingsWin.autohideActive = checked
                        settingsWin.runCmd("omarchy-undercover-autohide --toggle")
                      }
                    }
                  }
                }
              }

              // ----------------------------------------------------
              // TAB 4: POWERTOYS & UTILITIES (Winux PowerTools)
              // ----------------------------------------------------
              ColumnLayout {
                visible: settingsWin.currentCategory === 4
                Layout.fillWidth: true
                spacing: 12

                // FancyZones / Snap Layouts Tool
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 80
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  border.color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Text { text: "◫"; font.pixelSize: 22; color: "#" + settingsWin.activeAccent }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "FancyZones / Snap Assist (Win + Z)"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                      Text { text: "Tile active window into 50/50, 66/33, or 4-grid quadrants with instant keybindings"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                    }
                    Rectangle {
                      implicitWidth: 90
                      implicitHeight: 28
                      radius: 4
                      color: "#" + settingsWin.activeAccent
                      Text { anchors.centerIn: parent; text: "Snap Menu"; font.family: "Segoe UI"; font.pixelSize: 10; font.bold: true; color: "#ffffff" }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWin.runCmd("omarchy-undercover-snap menu")
                      }
                    }
                  }
                }

                // PowerToys Awake
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 70
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Text { text: "☕"; font.pixelSize: 22 }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "PowerToys Awake"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                      Text { text: settingsWin.isAwakeActive ? "Awake active: system will not sleep" : "Standard sleep and screensaver timers apply"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                    }
                    Switch {
                      checked: settingsWin.isAwakeActive
                      onToggled: {
                        settingsWin.isAwakeActive = checked
                        settingsWin.runCmd("omarchy toggle idle 2>/dev/null || true")
                      }
                    }
                  }
                }

                // PowerToys ColorPicker
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 70
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Text { text: "💉"; font.pixelSize: 22 }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "PowerToys Color Picker (Win + Shift + C)"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                      Text { text: "Pick any color on screen and copy HEX code to clipboard"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                    }
                    Rectangle {
                      implicitWidth: 80
                      implicitHeight: 28
                      radius: 4
                      color: "#" + settingsWin.activeAccent
                      Text { anchors.centerIn: parent; text: "Pick Color"; font.family: "Segoe UI"; font.pixelSize: 10; font.bold: true; color: "#ffffff" }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWin.runCmd("hyprpicker -a || wl-color-picker")
                      }
                    }
                  }
                }

                // PowerToys Always on Top
                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 70
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Text { text: "📌"; font.pixelSize: 22 }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "PowerToys Always on Top (Win + Ctrl + T)"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                      Text { text: "Pin the active window so it stays on top of all other windows"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                    }
                    Rectangle {
                      implicitWidth: 80
                      implicitHeight: 28
                      radius: 4
                      color: "#" + settingsWin.activeAccent
                      Text { anchors.centerIn: parent; text: "Toggle Pin"; font.family: "Segoe UI"; font.pixelSize: 10; font.bold: true; color: "#ffffff" }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWin.runCmd("hyprctl dispatch pin active")
                      }
                    }
                  }
                }
              }

              // ----------------------------------------------------
              // TAB 5: UNDERCOVER DISGUISE TRANSFORMATION
              // ----------------------------------------------------
              ColumnLayout {
                visible: settingsWin.currentCategory === 5
                Layout.fillWidth: true
                spacing: 12

                Text { text: "1-Click Desktop Camouflage Presets"; font.family: "Segoe UI"; font.pixelSize: 13; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }

                GridLayout {
                  Layout.fillWidth: true
                  columns: 2
                  rowSpacing: 10
                  columnSpacing: 10

                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: 8
                    color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)
                    border.color: "#0078d4"
                    border.width: 1
                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 12
                      Text { text: "🪟"; font.pixelSize: 20 }
                      ColumnLayout {
                        Text { text: "Windows 11 Dark"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                        Text { text: "Mica Acrylic taskbar, Fluent icons & fonts"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -w11")
                    }
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: 8
                    color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)
                    border.color: "#60cdff"
                    border.width: 1
                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 12
                      Text { text: "🪟"; font.pixelSize: 20 }
                      ColumnLayout {
                        Text { text: "Windows 11 Light"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                        Text { text: "Clean light taskbar with Fluent styling"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -w11-light")
                    }
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: 8
                    color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)
                    border.color: "#ff2d55"
                    border.width: 1
                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 12
                      Text { text: "🍏"; font.pixelSize: 20 }
                      ColumnLayout {
                        Text { text: "macOS Sequoia Dark"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                        Text { text: "Frosted top bar, wave dock & SF Pro typography"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: settingsWin.runCmd("omarchy-undercover -mac")
                    }
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: 8
                    color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)
                    border.color: "#5856d6"
                    border.width: 1
                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 12
                      Text { text: "🐧"; font.pixelSize: 20 }
                      ColumnLayout {
                        Text { text: "Restore Default Omarchy"; font.family: "Segoe UI"; font.pixelSize: 12; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                        Text { text: "Deactivate camouflage and restore baseline"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
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

              // ----------------------------------------------------
              // TAB 6: WINDOWS UPDATE & SYSTEM HEALTH
              // ----------------------------------------------------
              ColumnLayout {
                visible: settingsWin.currentCategory === 6
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 80
                  radius: 8
                  color: settingsWin.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.03)
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Text { text: "🛡️"; font.pixelSize: 22 }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text { text: "You're up to date"; font.family: "Segoe UI"; font.pixelSize: 13; font.bold: true; color: settingsWin.isDark ? "#ffffff" : "#1a1a1a" }
                      Text { text: "Omarchy Undercover v3.2.0 • Omarchy Shell Plugin Protocol v1"; font.family: "Segoe UI"; font.pixelSize: 10; color: Qt.rgba(1,1,1,0.5) }
                    }
                    Rectangle {
                      implicitWidth: 120
                      implicitHeight: 32
                      radius: 4
                      color: "#" + settingsWin.activeAccent
                      Text { anchors.centerIn: parent; text: "Check for updates"; font.family: "Segoe UI"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsWin.runCmd("xdg-terminal-exec -e bash -c 'omarchy update; read -p \"Press Enter to close\"'")
                      }
                    }
                  }
                }
              }

              Item { implicitHeight: 20 }
            }
          }
        }
      }
    }
  }
}
