import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property int masterVolume: 70
  property bool masterMuted: false
  property int micVolume: 70
  property bool micMuted: false
  property string defaultSink: ""
  property string defaultSource: ""
  property var sinks: []
  property var sources: []
  property var streams: []
  property bool ready: false

  function runCmd(cmd) {
    Quickshell.execDetached(["bash", "-c", cmd])
  }

  function refresh() {
    if (!statePoller.running) statePoller.running = true
  }

  function setMasterVolume(pct) {
    var v = Math.max(0, Math.min(100, Math.round(pct)))
    root.masterVolume = v
    runCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (v / 100.0).toFixed(2))
  }

  function toggleMasterMute() {
    root.masterMuted = !root.masterMuted
    runCmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
  }

  function setMicVolume(pct) {
    var v = Math.max(0, Math.min(100, Math.round(pct)))
    root.micVolume = v
    runCmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 && wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + (v / 100.0).toFixed(2))
  }

  function toggleMicMute() {
    root.micMuted = !root.micMuted
    runCmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
  }

  function setDefaultSink(name) {
    root.defaultSink = name
    runCmd("pactl set-default-sink " + name)
    refreshTimer.restart()
  }

  function setDefaultSource(name) {
    root.defaultSource = name
    runCmd("pactl set-default-source " + name)
    refreshTimer.restart()
  }

  function setStreamVolume(streamIndex, pct) {
    var v = Math.max(0, Math.min(150, Math.round(pct)))
    for (var i = 0; i < root.streams.length; i++) {
      if (root.streams[i].index === streamIndex) {
        root.streams[i].volume = v
        break
      }
    }
    runCmd("pactl set-sink-input-volume " + streamIndex + " " + v + "%")
  }

  function toggleStreamMute(streamIndex) {
    for (var i = 0; i < root.streams.length; i++) {
      if (root.streams[i].index === streamIndex) {
        root.streams[i].muted = !root.streams[i].muted
        break
      }
    }
    runCmd("pactl set-sink-input-mute " + streamIndex + " toggle")
  }

  function moveStream(streamIndex, sinkName) {
    runCmd("pactl move-sink-input " + streamIndex + " " + sinkName)
    refreshTimer.restart()
  }

  function runSpeakerTest(sinkName) {
    var target = sinkName || root.defaultSink
    if (target) {
      runCmd("omarchy-audio-speaker-test " + target + " 2>/dev/null || speaker-test -c 2 -t wav -l 1 >/dev/null 2>&1 &")
    }
  }

  function runRecovery() {
    runCmd("omarchy-audio-recovery 2>/dev/null || omarchy-restart-audio 2>/dev/null || (systemctl --user restart pipewire wireplumber &)")
  }

  property string pluginDir: {
    var p = Quickshell.env("OMARCHY_PLUGIN_DIR")
    if (p) return p
    var dev = Quickshell.env("HOME") + "/omarchy-undercover"
    return dev
  }

  Process {
    id: statePoller
    running: true
    command: [
      "bash", "-c",
      "export PATH=\"" + root.pluginDir + "/scripts:$PATH\"; " +
      "omarchy-audio-state 2>/dev/null || python3 " + root.pluginDir + "/scripts/omarchy-audio-state 2>/dev/null"
    ]
    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function(line) {
        var str = String(line).trim()
        if (!str || str.charAt(0) !== "{") return
        try {
          var data = JSON.parse(str)
          if (data) {
            root.masterVolume = data.masterVolume !== undefined ? data.masterVolume : root.masterVolume
            root.masterMuted = data.masterMuted !== undefined ? data.masterMuted : root.masterMuted
            root.micVolume = data.micVolume !== undefined ? data.micVolume : root.micVolume
            root.micMuted = data.micMuted !== undefined ? data.micMuted : root.micMuted
            root.defaultSink = data.defaultSink || root.defaultSink
            root.defaultSource = data.defaultSource || root.defaultSource
            root.sinks = data.sinks || []
            root.sources = data.sources || []
            root.streams = data.streams || []
            root.ready = true
          }
        } catch (e) {}
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 200
    repeat: false
    onTriggered: {
      if (!statePoller.running) statePoller.running = true
    }
  }

  Timer {
    interval: 2500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!statePoller.running) statePoller.running = true
    }
  }
}
