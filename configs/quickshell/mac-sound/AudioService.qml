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

  property string pluginDir: {
    var p = Quickshell.env("OMARCHY_PLUGIN_DIR")
    if (p) return p
    var dev = Quickshell.env("HOME") + "/omarchy-undercover"
    return dev
  }

  function isValidAudioDevice(name) {
    return typeof name === "string" && /^[a-zA-Z0-9_.:@-]{1,160}$/.test(name)
  }

  function refresh() {
    if (!statePoller.running) statePoller.running = true
  }

  function setMasterVolume(pct) {
    var v = Math.max(0, Math.min(100, Math.round(pct)))
    root.masterVolume = v
    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (v / 100.0).toFixed(2)])
  }

  function toggleMasterMute() {
    root.masterMuted = !root.masterMuted
    Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
  }

  function setMicVolume(pct) {
    var v = Math.max(0, Math.min(100, Math.round(pct)))
    root.micVolume = v
    Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "0"])
    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (v / 100.0).toFixed(2)])
  }

  function toggleMicMute() {
    root.micMuted = !root.micMuted
    Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
  }

  function setDefaultSink(name) {
    if (!isValidAudioDevice(name)) return
    root.defaultSink = name
    Quickshell.execDetached(["pactl", "set-default-sink", name])
    refreshTimer.restart()
  }

  function setDefaultSource(name) {
    if (!isValidAudioDevice(name)) return
    root.defaultSource = name
    Quickshell.execDetached(["pactl", "set-default-source", name])
    refreshTimer.restart()
  }

  function setStreamVolume(streamIndex, pct) {
    if (typeof streamIndex !== "number" || isNaN(streamIndex) || streamIndex < 0) return
    var v = Math.max(0, Math.min(150, Math.round(pct)))
    for (var i = 0; i < root.streams.length; i++) {
      if (root.streams[i].index === streamIndex) {
        root.streams[i].volume = v
        break
      }
    }
    Quickshell.execDetached(["pactl", "set-sink-input-volume", String(streamIndex), v + "%"])
  }

  function toggleStreamMute(streamIndex) {
    if (typeof streamIndex !== "number" || isNaN(streamIndex) || streamIndex < 0) return
    for (var i = 0; i < root.streams.length; i++) {
      if (root.streams[i].index === streamIndex) {
        root.streams[i].muted = !root.streams[i].muted
        break
      }
    }
    Quickshell.execDetached(["pactl", "set-sink-input-mute", String(streamIndex), "toggle"])
  }

  function moveStream(streamIndex, sinkName) {
    if (typeof streamIndex !== "number" || isNaN(streamIndex) || streamIndex < 0 || !isValidAudioDevice(sinkName)) return
    Quickshell.execDetached(["pactl", "move-sink-input", String(streamIndex), sinkName])
    refreshTimer.restart()
  }

  function runSpeakerTest(sinkOrChannel) {
    var sink = root.defaultSink
    var channel = ""
    if (sinkOrChannel === "left" || sinkOrChannel === "right" || sinkOrChannel === "both") {
      channel = sinkOrChannel
    } else if (sinkOrChannel && isValidAudioDevice(sinkOrChannel)) {
      sink = sinkOrChannel
    }
    if (sink && isValidAudioDevice(sink)) {
      var args = [root.pluginDir + "/scripts/omarchy-audio-speaker-test", sink]
      if (channel) args.push(channel)
      Quickshell.execDetached(args)
    }
  }

  function runRecovery() {
    Quickshell.execDetached([root.pluginDir + "/scripts/omarchy-audio-recovery"])
  }

  Process {
    id: statePoller
    running: true
    command: [root.pluginDir + "/scripts/omarchy-audio-state"]
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
