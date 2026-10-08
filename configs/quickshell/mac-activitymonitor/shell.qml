import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
  id: shellRoot

  PanelWindow {
    id: activityWindow
    screen: Quickshell.screens[0]

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "mac-activitymonitor"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
    color: "transparent"

    property string homeDir: Quickshell.env("HOME")
    property string pluginDir: Quickshell.env("OMARCHY_PLUGIN_DIR") || (activityWindow.homeDir + "/.config/omarchy/plugins/omarchy-undercover")
    property bool isDark: true
    property bool isMaximized: false

    // Tabs & Filters
    property string activeTab: "cpu" // "cpu" | "memory" | "disk" | "network"
    property string searchQuery: ""
    property var selectedProcess: null

    // System Statistics State
    property real overallCpu: 0.0
    property real cpuFreq: 2.40
    property string cpuModel: "Processor"
    property int physicalCores: 4
    property int logicalThreads: 8
    property int uptimeSeconds: 0
    property int totalProcesses: 0
    property real memUsedGb: 0.0
    property real memTotalGb: 16.0
    property real memAvailGb: 8.0
    property real memPct: 0.0
    property var appList: []
    property var bgProcList: []

    // Historical data for live charts
    property var cpuHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    function closeManager() {
      activityWindow.visible = false
      var pidFile = (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omarchy-mac-activitymonitor.pid"
      Quickshell.execDetached(["rm", "-f", pidFile])
      Quickshell.execDetached(["kill", String(Quickshell.processId)])
    }

    function toggleMaximize() {
      activityWindow.isMaximized = !activityWindow.isMaximized
    }

    function minimizeWindow() {
      Quickshell.execDetached(["omarchy-undercover-minimize"])
      activityWindow.closeManager()
    }

    function endTask(proc, force) {
      if (!proc) return
      var sig = force ? "-9" : "-15"
      if (proc.pid) {
        Quickshell.execDetached(["kill", sig, String(proc.pid)])
      }
      if (proc.address) {
        Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "address:" + proc.address])
      }
      activityWindow.selectedProcess = null
    }

    function resolveAppIcon(item) {
      if (!item) return ""
      var cls = (item.class || item.name || "").toLowerCase().trim()
      var candidates = [cls, cls.replace(/[\s_-]+/g, ""), cls.split(/[\s_-]+/)[0]]
      for (var i = 0; i < candidates.length; i++) {
        var p = Quickshell.iconPath(candidates[i], true)
        if (p && p.length > 0) return p
      }
      return Quickshell.iconPath("application-x-executable", true) || ""
    }

    // Process statistics backend
    Process {
      id: statsProc
      command: [
        "bash", "-c",
        "for p in \"" + activityWindow.pluginDir + "/scripts/omarchy-win11-taskmanager-backend\" \"" + activityWindow.homeDir + "/omarchy-undercover/scripts/omarchy-win11-taskmanager-backend\" \"$(which omarchy-win11-taskmanager-backend 2>/dev/null)\"; do if [ -x \"$p\" ]; then exec \"$p\" 1.5; fi; done"
      ]
      running: true
      stdout: SplitParser {
        onRead: function(line) {
          if (!line) return
          try {
            var data = JSON.parse(line.trim())
            if (data.error) return

            activityWindow.overallCpu = data.cpu_pct || 0.0
            activityWindow.cpuFreq = data.cpu_freq || 2.5
            activityWindow.cpuModel = data.cpu_model || "Apple Silicon / Processor"
            activityWindow.physicalCores = data.cores || 8
            activityWindow.logicalThreads = data.threads || 8
            activityWindow.uptimeSeconds = data.uptime_sec || 0
            activityWindow.totalProcesses = data.proc_count || 0

            activityWindow.memUsedGb = data.mem_used_gb || 0.0
            activityWindow.memTotalGb = data.mem_total_gb || 16.0
            activityWindow.memAvailGb = data.mem_avail_gb || 8.0
            activityWindow.memPct = data.mem_pct || 0.0

            activityWindow.appList = data.apps || []
            activityWindow.bgProcList = data.bg_procs || []

            var newCpuHist = activityWindow.cpuHistory.slice()
            newCpuHist.push(activityWindow.overallCpu)
            if (newCpuHist.length > 30) newCpuHist.shift()
            activityWindow.cpuHistory = newCpuHist
          } catch(e) {}
        }
      }
    }

    Shortcut {
      sequence: "Escape"
      onActivated: activityWindow.closeManager()
    }

    // Main Tahoe/Sequoia Window Frame
    Rectangle {
      id: mainFrame
      anchors.centerIn: parent
      width: activityWindow.isMaximized ? ((activityWindow.screen ? activityWindow.screen.width : 1280) - 20) : Math.min(1040, (activityWindow.screen ? activityWindow.screen.width : 1280) - 40)
      height: activityWindow.isMaximized ? ((activityWindow.screen ? activityWindow.screen.height : 800) - 50) : Math.min(680, (activityWindow.screen ? activityWindow.screen.height : 720) - 50)
      radius: 14
      color: Qt.rgba(0.14, 0.15, 0.18, 0.96)
      border.color: Qt.rgba(1, 1, 1, 0.15)
      border.width: 1
      clip: true

      Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
      Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

      ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 1. macOS Unified Titlebar & Toolbar
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 52
          color: Qt.rgba(0.11, 0.12, 0.14, 0.98)
          border.color: Qt.rgba(1, 1, 1, 0.08)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 14

            // Traffic Light Buttons
            RowLayout {
              spacing: 8

              // Close (Red)
              Rectangle {
                width: 13; height: 13; radius: 6.5
                color: btnCloseM.containsMouse ? "#ff5f57" : "#ff5f56"
                border.color: Qt.rgba(0, 0, 0, 0.25)
                border.width: 0.5
                Text {
                  anchors.centerIn: parent
                  text: "✕"
                  font.pixelSize: 8
                  font.bold: true
                  visible: btnCloseM.containsMouse
                  color: "#4a0002"
                }
                MouseArea {
                  id: btnCloseM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: activityWindow.closeManager()
                }
              }

              // Minimize (Yellow)
              Rectangle {
                width: 13; height: 13; radius: 6.5
                color: btnMinM.containsMouse ? "#febc2e" : "#ffbd2e"
                border.color: Qt.rgba(0, 0, 0, 0.25)
                border.width: 0.5
                Text {
                  anchors.centerIn: parent
                  text: "—"
                  font.pixelSize: 8
                  font.bold: true
                  visible: btnMinM.containsMouse
                  color: "#593b00"
                }
                MouseArea {
                  id: btnMinM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: activityWindow.minimizeWindow()
                }
              }

              // Zoom / Maximize (Green)
              Rectangle {
                width: 13; height: 13; radius: 6.5
                color: btnZoomM.containsMouse ? "#28c840" : "#27c93f"
                border.color: Qt.rgba(0, 0, 0, 0.25)
                border.width: 0.5
                Text {
                  anchors.centerIn: parent
                  text: "+"
                  font.pixelSize: 9
                  font.bold: true
                  visible: btnZoomM.containsMouse
                  color: "#004008"
                }
                MouseArea {
                  id: btnZoomM
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: activityWindow.toggleMaximize()
                }
              }
            }

            Item { Layout.preferredWidth: 8 }

            // Action: Stop / Force Quit button
            Rectangle {
              Layout.preferredWidth: 32
              Layout.preferredHeight: 30
              radius: 6
              property bool hasTarget: activityWindow.selectedProcess !== null
              color: hasTarget ? (btnStopM.containsMouse ? "#c42b1c" : Qt.rgba(1, 1, 1, 0.10)) : Qt.rgba(1, 1, 1, 0.04)
              border.color: hasTarget ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.06)
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 12
                font.bold: true
                color: parent.hasTarget ? "#ffffff" : Qt.rgba(1, 1, 1, 0.3)
              }

              MouseArea {
                id: btnStopM
                anchors.fill: parent
                enabled: parent.hasTarget
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: activityWindow.endTask(activityWindow.selectedProcess, true)
              }
            }

            // Window Title
            Text {
              text: "Activity Monitor"
              font.family: "SF Pro Text, -apple-system, sans-serif"
              font.pixelSize: 13
              font.bold: true
              color: "#ffffff"
            }

            Item { Layout.fillWidth: true }

            // Segmented Tab Control: CPU | Memory | Disk | Network
            Rectangle {
              Layout.preferredWidth: 260
              Layout.preferredHeight: 28
              radius: 7
              color: Qt.rgba(0, 0, 0, 0.35)
              border.color: Qt.rgba(1, 1, 1, 0.10)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 2
                spacing: 2

                Repeater {
                  model: [
                    { id: "cpu", name: "CPU" },
                    { id: "memory", name: "Memory" },
                    { id: "disk", name: "Disk" },
                    { id: "network", name: "Network" }
                  ]

                  Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 5
                    color: activityWindow.activeTab === modelData.id ? Qt.rgba(1, 1, 1, 0.20) : "transparent"

                    Text {
                      anchors.centerIn: parent
                      text: modelData.name
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 11
                      font.bold: activityWindow.activeTab === modelData.id
                      color: activityWindow.activeTab === modelData.id ? "#ffffff" : Qt.rgba(1, 1, 1, 0.65)
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: activityWindow.activeTab = modelData.id
                    }
                  }
                }
              }
            }

            Item { Layout.preferredWidth: 8 }

            // Search Filter Input Field
            Rectangle {
              Layout.preferredWidth: 200
              Layout.preferredHeight: 28
              radius: 6
              color: macSearchIn.activeFocus ? Qt.rgba(0.20, 0.22, 0.26, 0.95) : Qt.rgba(0, 0, 0, 0.28)
              border.color: macSearchIn.activeFocus ? "#007aff" : Qt.rgba(1, 1, 1, 0.12)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text { text: "🔍"; font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.5) }

                TextInput {
                  id: macSearchIn
                  Layout.fillWidth: true
                  color: "#ffffff"
                  font.family: "SF Pro Text, -apple-system, sans-serif"
                  font.pixelSize: 11
                  selectByMouse: true
                  clip: true
                  onTextChanged: activityWindow.searchQuery = text

                  Text {
                    anchors.fill: parent
                    visible: !macSearchIn.text && !macSearchIn.activeFocus
                    text: "Search"
                    color: Qt.rgba(1, 1, 1, 0.4)
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 11
                  }
                }
              }
            }
          }
        }

        // 2. Table Header
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 28
          color: Qt.rgba(0.10, 0.11, 0.13, 0.98)
          border.color: Qt.rgba(1, 1, 1, 0.06)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 8

            Text { Layout.preferredWidth: 320; text: "Process Name"; font.family: "SF Pro Text"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1, 1, 1, 0.8) }
            Text { Layout.preferredWidth: 100; text: "% CPU"; font.family: "SF Pro Text"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1, 1, 1, 0.8) }
            Text { Layout.preferredWidth: 120; text: "Memory (MB)"; font.family: "SF Pro Text"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1, 1, 1, 0.8) }
            Text { Layout.preferredWidth: 100; text: "PID"; font.family: "SF Pro Text"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1, 1, 1, 0.8) }
            Text { Layout.preferredWidth: 100; text: "Status"; font.family: "SF Pro Text"; font.pixelSize: 11; font.bold: true; color: Qt.rgba(1, 1, 1, 0.8) }
            Item { Layout.fillWidth: true }
          }
        }

        // 3. Process Table Rows
        ScrollView {
          id: tableScroll
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ColumnLayout {
            width: tableScroll.width
            spacing: 1

            // Apps Section
            Repeater {
              model: {
                var q = activityWindow.searchQuery.toLowerCase().trim()
                var list = activityWindow.appList.concat(activityWindow.bgProcList)
                if (!q) return list
                return list.filter(function(p) {
                  return (p.name || "").toLowerCase().indexOf(q) !== -1 ||
                         (p.class || "").toLowerCase().indexOf(q) !== -1 ||
                         String(p.pid).indexOf(q) !== -1
                })
              }

              Rectangle {
                id: procRow
                property var procItem: modelData
                property bool isSelected: activityWindow.selectedProcess && activityWindow.selectedProcess.pid === procItem.pid
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                color: isSelected ? "#007aff" : (rowM.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 16
                  anchors.rightMargin: 16
                  spacing: 8

                  RowLayout {
                    Layout.preferredWidth: 320
                    spacing: 8

                    Image {
                      Layout.preferredWidth: 16; Layout.preferredHeight: 16
                      sourceSize: Qt.size(16, 16)
                      source: activityWindow.resolveAppIcon(procItem)
                      fillMode: Image.PreserveAspectFit
                    }

                    Text {
                      Layout.fillWidth: true
                      text: procItem.name || procItem.class || "Process"
                      font.family: "SF Pro Text, -apple-system, sans-serif"
                      font.pixelSize: 11
                      color: "#ffffff"
                      elide: Text.ElideRight
                    }
                  }

                  Text {
                    Layout.preferredWidth: 100
                    text: procItem.cpu + "%"
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 11
                    font.bold: procItem.cpu > 10
                    color: procItem.cpu > 25 ? "#fce100" : "#ffffff"
                  }

                  Text {
                    Layout.preferredWidth: 120
                    text: procItem.mem_mb + " MB"
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 11
                    color: "#ffffff"
                  }

                  Text {
                    Layout.preferredWidth: 100
                    text: String(procItem.pid)
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.7)
                  }

                  Text {
                    Layout.preferredWidth: 100
                    text: procItem.status || "Running"
                    font.family: "SF Pro Text, -apple-system, sans-serif"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.7)
                  }

                  Item { Layout.fillWidth: true }
                }

                MouseArea {
                  id: rowM
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: activityWindow.selectedProcess = procItem
                }
              }
            }
          }
        }

        // 4. Bottom macOS Summary & Gauge Panel
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 76
          color: Qt.rgba(0.10, 0.11, 0.14, 0.98)
          border.color: Qt.rgba(1, 1, 1, 0.08)
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 24

            // CPU Gauge
            ColumnLayout {
              spacing: 4
              Text { text: "% CPU Usage"; font.family: "SF Pro Text"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
              Text { text: "System: " + Math.round(activityWindow.overallCpu) + "%"; font.family: "SF Pro Text"; font.pixelSize: 11; color: "#007aff" }
              Text { text: "Idle: " + Math.max(0, 100 - Math.round(activityWindow.overallCpu)) + "%"; font.family: "SF Pro Text"; font.pixelSize: 11; color: Qt.rgba(1, 1, 1, 0.5) }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.margins: 12; color: Qt.rgba(1, 1, 1, 0.08) }

            // Memory Pressure
            ColumnLayout {
              spacing: 4
              Text { text: "Physical Memory"; font.family: "SF Pro Text"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
              Text { text: "Memory Used: " + activityWindow.memUsedGb + " GB / " + activityWindow.memTotalGb + " GB"; font.family: "SF Pro Text"; font.pixelSize: 11; color: "#34c759" }
              Text { text: "Cached Files: " + activityWindow.memAvailGb + " GB"; font.family: "SF Pro Text"; font.pixelSize: 11; color: Qt.rgba(1, 1, 1, 0.5) }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.margins: 12; color: Qt.rgba(1, 1, 1, 0.08) }

            // Process counts
            ColumnLayout {
              spacing: 4
              Text { text: "Processes"; font.family: "SF Pro Text"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
              Text { text: "Total Processes: " + activityWindow.totalProcesses; font.family: "SF Pro Text"; font.pixelSize: 11; color: "#ffffff" }
              Text { text: "Threads: " + activityWindow.logicalThreads; font.family: "SF Pro Text"; font.pixelSize: 11; color: Qt.rgba(1, 1, 1, 0.5) }
            }

            Item { Layout.fillWidth: true }
          }
        }
      }
    }
  }
}
