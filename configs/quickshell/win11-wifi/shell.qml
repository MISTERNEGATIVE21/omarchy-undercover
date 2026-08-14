import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  PanelWindow {
    id: wifiWindow
    screen: Quickshell.screens[0]

    anchors {
      bottom: true
      right: true
    }
    margins {
      bottom: 54
      right: 12
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-menu"
    color: "transparent"

    implicitWidth: 360
    implicitHeight: 480

    property bool isDark: true
    property bool wifiEnabled: true
    property string activeSsid: ""
    property var networks: []
    property string connectingSsid: ""
    property string passwordInput: ""
    property bool isScanning: false

    function runCmd(cmd) {
      Quickshell.execDetached(["bash", "-c", cmd])
    }

    // Theme state poller
    Process {
      id: statePoller
      running: true
      command: ["bash", "-c", "cat $HOME/.config/omarchy-undercover/state 2>/dev/null || echo 'win11-dark'"]
      stdout: SplitParser {
        onRead: function(line) {
          var s = String(line).trim()
          wifiWindow.isDark = (s.indexOf("light") === -1)
        }
      }
    }

    // Wi-Fi Radio status poller
    Process {
      id: radioPoller
      running: true
      command: ["bash", "-c", "nmcli radio wifi"]
      stdout: SplitParser {
        onRead: function(line) {
          wifiWindow.wifiEnabled = (String(line).trim().toLowerCase() === "enabled")
        }
      }
    }

    // Wi-Fi Scan Process
    Process {
      id: scanPoller
      command: ["bash", "-c", "nmcli -t -f in-use,ssid,signal,security dev wifi list 2>/dev/null"]
      stdout: SplitParser {
        onRead: function(line) {
          var l = String(line).trim()
          if (!l) return
          var parts = l.split(":")
          if (parts.length >= 4) {
            var inUse = (parts[0] === "*")
            var ssid = parts[1]
            var signal = parseInt(parts[2]) || 0
            var security = parts[3]
            if (ssid && ssid.length > 0) {
              if (inUse) wifiWindow.activeSsid = ssid
              var exists = false
              var currentList = wifiWindow.networks
              for (var i = 0; i < currentList.length; i++) {
                if (currentList[i].ssid === ssid) {
                  currentList[i].signal = signal
                  currentList[i].inUse = inUse
                  exists = true
                  break
                }
              }
              if (!exists) {
                currentList.push({
                  ssid: ssid,
                  signal: signal,
                  security: security,
                  inUse: inUse,
                  isSecured: (security.length > 0 && security !== "--")
                })
              }
              wifiWindow.networks = currentList
            }
          }
        }
      }
      onExited: function() {
        wifiWindow.isScanning = false
      }
    }

    function triggerScan() {
      wifiWindow.isScanning = true
      wifiWindow.networks = []
      scanPoller.running = true
    }

    Timer {
      interval: 8000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        if (!scanPoller.running) scanPoller.running = true
        if (!radioPoller.running) radioPoller.running = true
      }
    }

    function getSignalIcon(sig) {
      if (sig >= 75) return "󰤨"
      if (sig >= 50) return "󰤥"
      if (sig >= 25) return "󰤢"
      return "󰤟"
    }

    Rectangle {
      id: card
      anchors.fill: parent
      radius: 14
      color: wifiWindow.isDark ? Qt.rgba(0.12, 0.12, 0.16, 0.96) : Qt.rgba(0.97, 0.97, 0.98, 0.98)
      border.color: wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header Row
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Text {
            text: "󰤨"
            font.pixelSize: 18
            color: wifiWindow.isDark ? "#60cdff" : "#0067c0"
          }

          Text {
            text: "Wi-Fi Networks"
            font.family: "Segoe UI"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: wifiWindow.isDark ? "#ffffff" : "#1a1a1a"
            Layout.fillWidth: true
          }

          // Scan button
          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: scanMouse.containsMouse ? (wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "🔄"
              font.pixelSize: 12
            }
            MouseArea {
              id: scanMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: wifiWindow.triggerScan()
            }
          }

          // Close button
          Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: 6
            color: closeMouse.containsMouse ? (wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"
            Text {
              anchors.centerIn: parent
              text: "✕"
              font.pixelSize: 12
              color: wifiWindow.isDark ? "#ffffff" : "#1a1a1a"
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

        // Wi-Fi Power Switch Card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 46
          radius: 8
          color: wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
          border.color: wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Text {
              text: "Wi-Fi"
              font.family: "Segoe UI"
              font.pixelSize: 12.5
              font.weight: Font.DemiBold
              color: wifiWindow.isDark ? "#ffffff" : "#1a1a1a"
              Layout.fillWidth: true
            }

            Rectangle {
              implicitWidth: 44
              implicitHeight: 22
              radius: 11
              color: wifiWindow.wifiEnabled ? (wifiWindow.isDark ? "#60cdff" : "#0067c0") : Qt.rgba(0.5, 0.5, 0.5, 0.4)

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: wifiWindow.wifiEnabled ? parent.width - width - 3 : 3
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: "#ffffff"
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var target = !wifiWindow.wifiEnabled
                  wifiWindow.wifiEnabled = target
                  wifiWindow.runCmd("nmcli radio wifi " + (target ? "on" : "off"))
                  wifiWindow.triggerScan()
                }
              }
            }
          }
        }

        // Active Connected Banner
        Rectangle {
          visible: wifiWindow.activeSsid.length > 0 && wifiWindow.wifiEnabled
          Layout.fillWidth: true
          implicitHeight: 52
          radius: 8
          color: wifiWindow.isDark ? Qt.rgba(0, 120, 212, 0.25) : Qt.rgba(0, 120, 212, 0.12)
          border.color: wifiWindow.isDark ? "#60cdff" : "#0067c0"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text { text: "󰤨"; font.pixelSize: 18; color: wifiWindow.isDark ? "#60cdff" : "#0067c0" }

            ColumnLayout {
              spacing: 1
              Layout.fillWidth: true
              Text {
                text: wifiWindow.activeSsid
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: wifiWindow.isDark ? "#ffffff" : "#1a1a1a"
                elide: Text.ElideRight
              }
              Text {
                text: "Connected, secured"
                font.family: "Segoe UI"
                font.pixelSize: 9.5
                color: wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.55)
              }
            }

            Rectangle {
              implicitWidth: 80
              implicitHeight: 26
              radius: 6
              color: disMouse.containsMouse ? Qt.rgba(1, 0.2, 0.2, 0.3) : Qt.rgba(1, 0.2, 0.2, 0.15)
              Text {
                anchors.centerIn: parent
                text: "Disconnect"
                font.family: "Segoe UI"
                font.pixelSize: 10.5
                color: "#ff5f56"
              }
              MouseArea {
                id: disMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  wifiWindow.runCmd("nmcli con down id '" + wifiWindow.activeSsid + "' || nmcli dev disconnect wlan0")
                  wifiWindow.activeSsid = ""
                  wifiWindow.triggerScan()
                }
              }
            }
          }
        }

        // Available Networks Section Title
        Text {
          visible: wifiWindow.wifiEnabled
          text: "Available Networks"
          font.family: "Segoe UI"
          font.pixelSize: 11
          font.weight: Font.DemiBold
          color: wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.5)
        }

        // Networks ScrollView
        ScrollView {
          visible: wifiWindow.wifiEnabled
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ListView {
            id: netListView
            width: parent.width
            model: wifiWindow.networks
            spacing: 4

            delegate: ColumnLayout {
              width: netListView.width
              spacing: 4

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: 6
                color: netRowMouse.containsMouse ? (wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  spacing: 10

                  Text {
                    text: wifiWindow.getSignalIcon(modelData.signal)
                    font.pixelSize: 15
                    color: wifiWindow.isDark ? "#ffffff" : "#1a1a1a"
                  }

                  Text {
                    text: modelData.ssid
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.weight: modelData.inUse ? Font.DemiBold : Font.Normal
                    color: wifiWindow.isDark ? "#ffffff" : "#1a1a1a"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }

                  Text {
                    visible: modelData.isSecured
                    text: "🔒"
                    font.pixelSize: 11
                  }
                }

                MouseArea {
                  id: netRowMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (modelData.inUse) return
                    if (modelData.isSecured) {
                      wifiWindow.connectingSsid = (wifiWindow.connectingSsid === modelData.ssid ? "" : modelData.ssid)
                      wifiWindow.passwordInput = ""
                    } else {
                      wifiWindow.runCmd("nmcli dev wifi connect '" + modelData.ssid + "'")
                      wifiWindow.triggerScan()
                    }
                  }
                }
              }

              // Inline Password Input Panel
              Rectangle {
                visible: wifiWindow.connectingSsid === modelData.ssid
                Layout.fillWidth: true
                implicitHeight: 68
                radius: 6
                color: wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05)
                border.color: wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10)

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 8
                  spacing: 6

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                      Layout.fillWidth: true
                      implicitHeight: 28
                      radius: 4
                      color: wifiWindow.isDark ? Qt.rgba(0, 0, 0, 0.3) : "#ffffff"
                      border.color: wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.14)

                      TextInput {
                        id: pwInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        echoMode: TextInput.Password
                        font.pixelSize: 11
                        color: wifiWindow.isDark ? "#ffffff" : "#1a1a1a"
                        selectByMouse: true
                        onTextChanged: wifiWindow.passwordInput = text
                        onAccepted: {
                          wifiWindow.runCmd("nmcli dev wifi connect '" + modelData.ssid + "' password '" + pwInput.text + "'")
                          wifiWindow.connectingSsid = ""
                          wifiWindow.triggerScan()
                        }
                      }
                    }

                    Rectangle {
                      implicitWidth: 60
                      implicitHeight: 28
                      radius: 4
                      color: wifiWindow.isDark ? "#0078d4" : "#0067c0"
                      Text { anchors.centerIn: parent; text: "Connect"; color: "#ffffff"; font.pixelSize: 10.5; font.weight: Font.DemiBold }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          wifiWindow.runCmd("nmcli dev wifi connect '" + modelData.ssid + "' password '" + pwInput.text + "'")
                          wifiWindow.connectingSsid = ""
                          wifiWindow.triggerScan()
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // Wi-Fi Settings Link Footer
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 34
          radius: 6
          color: setLinkM.containsMouse ? (wifiWindow.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"
          RowLayout {
            anchors.centerIn: parent
            spacing: 6
            Text { text: "⚙️"; font.pixelSize: 12 }
            Text {
              text: "More Wi-Fi settings"
              font.family: "Segoe UI"
              font.pixelSize: 11
              font.weight: Font.DemiBold
              color: wifiWindow.isDark ? "#60cdff" : "#0067c0"
            }
          }
          MouseArea {
            id: setLinkM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Qt.quit()
              wifiWindow.runCmd("nm-connection-editor || omarchy-undercover-settings")
            }
          }
        }
      }
    }
  }
}
