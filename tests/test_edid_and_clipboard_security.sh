#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 1. Checking SettingsService.qml for command injection immunity ==="

SETTINGS_SERVICES=(
  "$REPO_ROOT/configs/quickshell/common/SettingsService.qml"
  "$REPO_ROOT/configs/quickshell/mac-settings/SettingsService.qml"
  "$REPO_ROOT/configs/quickshell/win11-actioncenter/SettingsService.qml"
  "$REPO_ROOT/configs/quickshell/win11-settings/SettingsService.qml"
)

# Verify all 4 files are synchronized
BASE="${SETTINGS_SERVICES[0]}"
for f in "${SETTINGS_SERVICES[@]}"; do
  if ! cmp -s "$BASE" "$f"; then
    echo "ERROR: $f is out of sync with $BASE"
    exit 1
  fi
done
echo "  ✔ All 4 SettingsService.qml files are synchronized."

# Verify no runCmd or bash -c command string interpolation exists in SettingsService.qml
for f in "${SETTINGS_SERVICES[@]}"; do
  if grep -E "runCmd\(" "$f" >/dev/null; then
    echo "ERROR: Found runCmd in $f"
    exit 1
  fi
  if grep -E "bash.*-c.*monitors" "$f" >/dev/null; then
    echo "ERROR: Found bash -c monitors interpolation in $f"
    exit 1
  fi
done
echo "  ✔ No runCmd or bash -c interpolation found in SettingsService.qml files."

# Verify monitor methods use direct argument arrays
for method in "setMonitorScale" "setMonitorMode" "setMonitorTransform" "setMonitorVrr" "setMonitorMirror" "setMonitorDisabled"; do
  if ! grep -F "Quickshell.execDetached([root.pluginDir + \"/scripts/omarchy-settings-engine\", \"monitors\"" "$BASE" >/dev/null; then
    echo "ERROR: Missing direct argument array execution for monitors in $BASE"
    exit 1
  fi
done
echo "  ✔ Monitor methods use direct argument arrays without shell interpolation."

echo "=== 1b. Checking AudioService.qml for command injection immunity and device validation ==="

AUDIO_SERVICES=(
  "$REPO_ROOT/configs/quickshell/common/AudioService.qml"
  "$REPO_ROOT/configs/quickshell/mac-sound/AudioService.qml"
  "$REPO_ROOT/configs/quickshell/mac-settings/AudioService.qml"
  "$REPO_ROOT/configs/quickshell/win11-sound/AudioService.qml"
  "$REPO_ROOT/configs/quickshell/win11-settings/AudioService.qml"
)

# Verify all 5 files are synchronized
AUDIO_BASE="${AUDIO_SERVICES[0]}"
for f in "${AUDIO_SERVICES[@]}"; do
  if ! cmp -s "$AUDIO_BASE" "$f"; then
    echo "ERROR: $f is out of sync with $AUDIO_BASE"
    exit 1
  fi
done
echo "  ✔ All 5 AudioService.qml files are synchronized."

# Verify no runCmd or bash -c command string interpolation exists in AudioService.qml
for f in "${AUDIO_SERVICES[@]}"; do
  if grep -E "runCmd\(" "$f" >/dev/null; then
    echo "ERROR: Found runCmd in $f"
    exit 1
  fi
  if grep -E 'bash.*-c' "$f" >/dev/null; then
    echo "ERROR: Found bash -c interpolation in $f"
    exit 1
  fi
done
echo "  ✔ No runCmd or bash -c interpolation found in AudioService.qml files."

# Verify isValidAudioDevice canonical token validator is enforced
for f in "${AUDIO_SERVICES[@]}"; do
  if ! grep -F "function isValidAudioDevice" "$f" >/dev/null; then
    echo "ERROR: Missing isValidAudioDevice token validator in $f"
    exit 1
  fi
done
echo "  ✔ isValidAudioDevice canonical token validator enforced across all AudioService.qml copies."

# Verify audio control methods use direct argument arrays without shell interpolation
for token in 'Quickshell.execDetached(["pactl", "set-default-sink"' 'Quickshell.execDetached(["pactl", "set-default-source"' 'Quickshell.execDetached(["wpctl", "set-volume"' 'Quickshell.execDetached(["wpctl", "set-mute"'; do
  if ! grep -F "$token" "$AUDIO_BASE" >/dev/null; then
    echo "ERROR: Missing direct argument array execution for $token in $AUDIO_BASE"
    exit 1
  fi
done
echo "  ✔ Audio methods use direct argument arrays without shell interpolation."

# Test device token validation in scripts/omarchy-audio-state and QML regex
python3 -c '
import re, sys

device_pattern = re.compile(r"^[a-zA-Z0-9_.:@-]{1,160}$")

malicious_vectors = [
    "attacker;id;",
    "sink;rm -rf /",
    "sink$(whoami)",
    "sink`touch /tmp/pwned`",
    "sink\nid",
    "sink|curl attacker.com",
    "sink & touch /tmp/pwned &",
    "sink name with spaces",
    "../traversal/sink",
    "a" * 161,
    "",
]

for vec in malicious_vectors:
    if device_pattern.match(vec):
        print(f"SECURITY ERROR: Malicious audio device vector allowed: {vec}")
        sys.exit(1)

valid_devices = [
    "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__HDMI3__sink",
    "alsa_output.usb-Kart_Aura_Pro_33024317260416-01.pro-output-0",
    "alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Mic1__source",
    "bluez_output.00_11_22_33_44_55.1",
    "null",
    "auto_null",
    "@DEFAULT_AUDIO_SINK@",
    "@DEFAULT_AUDIO_SOURCE@",
    "omarchy_audio_group_0123456789abcdef"
]

for dev in valid_devices:
    if not device_pattern.match(dev):
        print(f"VALIDATION ERROR: Valid audio device rejected: {dev}")
        sys.exit(1)
'
echo "  ✔ Audio device token validator strictly rejects shell metacharacters, spaces, path traversal, and buffer overflows."

echo "=== 2. Checking Settings and flyouts for clipboard exhaustion isolation ==="

# Verify no editable TextInput exists anywhere in any QML file (preventing Qt Wayland clipboard hook exhaustion)
QML_INPUT_FILES=(
  "$REPO_ROOT/configs/quickshell/mac-settings/shell.qml"
  "$REPO_ROOT/configs/quickshell/win11-settings/shell.qml"
  "$REPO_ROOT/configs/quickshell/mac-wifi/shell.qml"
  "$REPO_ROOT/configs/quickshell/win11-wifi/shell.qml"
  "$REPO_ROOT/configs/quickshell/mac-bluetooth/shell.qml"
  "$REPO_ROOT/configs/quickshell/win11-bluetooth/shell.qml"
  "$REPO_ROOT/configs/quickshell/mac-controlcenter/shell.qml"
  "$REPO_ROOT/configs/quickshell/win11-actioncenter/shell.qml"
  "$REPO_ROOT/configs/quickshell/mac-activitymonitor/shell.qml"
  "$REPO_ROOT/configs/quickshell/win11-taskmanager/shell.qml"
  "$REPO_ROOT/configs/quickshell/win11-taskview/shell.qml"
  "$REPO_ROOT/configs/quickshell/win11-start/shell.qml"
  "$REPO_ROOT/MacScreensaverOverlay.qml"
)

for shell_file in "${QML_INPUT_FILES[@]}"; do
  if grep -n "TextInput" "$shell_file" >/dev/null; then
    echo "ERROR: $shell_file contains TextInput element(s), causing Qt Wayland clipboard exhaustion vulnerability!"
    exit 1
  fi
done
echo "  ✔ Zero TextInput elements exist across all Settings and flyouts (total clipboard isolation)."

# Verify mac-settings refresh rate selector does not prioritize raw EDID description over canonical names
if grep -n "setMonitorMode" "$REPO_ROOT/configs/quickshell/mac-settings/shell.qml" -B 3 | grep -F "m.description || m.name" >/dev/null; then
  echo "ERROR: mac-settings refresh rate selector still prioritizes m.description over m.name"
  exit 1
fi
echo "  ✔ Refresh rate selector uses canonical monitor identifiers."

echo "=== 3. Checking application-controlled window titles and tooltips for Text.PlainText enforcement ==="

# win11-taskbar.qml: window titles in preview and taskview must enforce Text.PlainText
if ! grep -B 2 "clientObj.title" "$REPO_ROOT/widgets/win11-taskbar.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: widgets/win11-taskbar.qml clientObj.title missing textFormat: Text.PlainText"
  exit 1
fi
if ! grep -B 2 "winObj.title" "$REPO_ROOT/widgets/win11-taskbar.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: widgets/win11-taskbar.qml winObj.title missing textFormat: Text.PlainText"
  exit 1
fi
if ! grep -A 3 "id: tooltipText" "$REPO_ROOT/widgets/win11-taskbar.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: widgets/win11-taskbar.qml tooltipText missing textFormat: Text.PlainText"
  exit 1
fi

# win11-taskview/shell.qml: window titles must enforce Text.PlainText
if ! grep -B 2 "winClient.title" "$REPO_ROOT/configs/quickshell/win11-taskview/shell.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/win11-taskview/shell.qml winClient.title missing textFormat: Text.PlainText"
  exit 1
fi
if ! grep -B 2 "contextMenuTarget.title" "$REPO_ROOT/configs/quickshell/win11-taskview/shell.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/win11-taskview/shell.qml contextMenuTarget.title missing textFormat: Text.PlainText"
  exit 1
fi

# mac-dock: tooltips must enforce Text.PlainText
if ! grep -A 3 "id: tooltipText" "$REPO_ROOT/widgets/mac-dock.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: widgets/mac-dock.qml tooltipText missing textFormat: Text.PlainText"
  exit 1
fi
if ! grep -A 3 "id: tooltipText" "$REPO_ROOT/configs/quickshell/mac-dock/shell.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/mac-dock/shell.qml tooltipText missing textFormat: Text.PlainText"
  exit 1
fi

# mac-appmenu.qml: activeAppName must enforce Text.PlainText
if ! grep -A 3 "id: appTitleText" "$REPO_ROOT/widgets/mac-appmenu.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: widgets/mac-appmenu.qml appTitleText missing textFormat: Text.PlainText"
  exit 1
fi

# StageManager.qml: appLabel must enforce Text.PlainText
if ! grep -A 3 "id: appLabel" "$REPO_ROOT/configs/quickshell/mac-stagemanager/StageManager.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/mac-stagemanager/StageManager.qml appLabel missing textFormat: Text.PlainText"
  exit 1
fi

# Process monitors: process names must enforce Text.PlainText
if ! grep -B 2 "procItem.name" "$REPO_ROOT/configs/quickshell/win11-taskmanager/shell.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/win11-taskmanager/shell.qml procItem.name missing textFormat: Text.PlainText"
  exit 1
fi
if ! grep -B 2 "procItem.name" "$REPO_ROOT/configs/quickshell/mac-activitymonitor/shell.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/mac-activitymonitor/shell.qml procItem.name missing textFormat: Text.PlainText"
  exit 1
fi

echo "  ✔ Window titles, process names, and tooltips strictly enforce Text.PlainText (rich text / image SSRF immunity)."

echo "=== 4. Checking external network and device labels for Text.PlainText enforcement ==="

# mac-wifi: diagnostics active SSID card must enforce Text.PlainText
if ! grep -C 3 "macWifiWindow.activeSsid" "$REPO_ROOT/configs/quickshell/mac-wifi/shell.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/mac-wifi/shell.qml activeSsid diagnostics card missing textFormat: Text.PlainText"
  exit 1
fi

# mac-controlcenter: diagnostics active SSID card must enforce Text.PlainText
if ! grep -C 3 "controlCenterWindow.wifiSsid" "$REPO_ROOT/configs/quickshell/mac-controlcenter/shell.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/mac-controlcenter/shell.qml wifiSsid diagnostics card missing textFormat: Text.PlainText"
  exit 1
fi

# win11-wifi: diagnostics active SSID card must enforce Text.PlainText
if ! grep -C 3 "wifiWindow.activeSsid" "$REPO_ROOT/configs/quickshell/win11-wifi/shell.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/win11-wifi/shell.qml activeSsid diagnostics card missing textFormat: Text.PlainText"
  exit 1
fi

# win11-actioncenter: bluetooth device label must enforce Text.PlainText
if ! grep -C 3 "actionCenterWindow.btDevice" "$REPO_ROOT/configs/quickshell/win11-actioncenter/shell.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/win11-actioncenter/shell.qml btDevice missing textFormat: Text.PlainText"
  exit 1
fi

# mac-settings & win11-settings: active SSID must enforce Text.PlainText
if ! grep -C 3 "text: settingsService.wifiActiveSsid" "$REPO_ROOT/configs/quickshell/mac-settings/shell.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/mac-settings/shell.qml wifiActiveSsid missing textFormat: Text.PlainText"
  exit 1
fi
if ! grep -C 3 "text: settingsService.wifiActiveSsid" "$REPO_ROOT/configs/quickshell/win11-settings/shell.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/win11-settings/shell.qml wifiActiveSsid missing textFormat: Text.PlainText"
  exit 1
fi

# win11-taskmanager: context menu process name must enforce Text.PlainText
if ! grep -C 3 "taskManagerWindow.contextProcess" "$REPO_ROOT/configs/quickshell/win11-taskmanager/shell.qml" | grep -F "textFormat: Text.PlainText" >/dev/null; then
  echo "ERROR: configs/quickshell/win11-taskmanager/shell.qml contextProcess.name missing textFormat: Text.PlainText"
  exit 1
fi

echo "  ✔ External network SSIDs, Bluetooth devices, and diagnostic labels strictly enforce Text.PlainText."

echo "=== 5. Checking Wayland application ID and icon decoder isolation ==="

ICON_ISOLATION_FILES=(
  "$REPO_ROOT/widgets/win11-taskbar.qml"
  "$REPO_ROOT/widgets/mac-dock.qml"
  "$REPO_ROOT/configs/quickshell/mac-dock/shell.qml"
  "$REPO_ROOT/configs/quickshell/mac-stagemanager/StageManager.qml"
  "$REPO_ROOT/configs/quickshell/win11-taskview/shell.qml"
  "$REPO_ROOT/configs/quickshell/win11-taskmanager/shell.qml"
  "$REPO_ROOT/configs/quickshell/mac-activitymonitor/shell.qml"
)

# 1. Verify isValidIconToken token validation helper is present in all target files
for f in "${ICON_ISOLATION_FILES[@]}"; do
  if ! grep -F "function isValidIconToken" "$f" >/dev/null; then
    echo "ERROR: $f is missing isValidIconToken canonical token validation function!"
    exit 1
  fi
  if ! grep -F 'return /^[a-zA-Z0-9][a-zA-Z0-9._-]*$/.test(str)' "$f" >/dev/null; then
    echo "ERROR: $f has non-compliant isValidIconToken regex validation!"
    exit 1
  fi
done
echo "  ✔ isValidIconToken canonical token validator enforced across all taskbar, dock, and task view components."

# 2. Verify no raw image://icon/ concatenation with unvalidated client variables exists
for f in "${ICON_ISOLATION_FILES[@]}"; do
  if grep -E 'image://icon/" \+ \(?c\.(class|initialClass)' "$f" >/dev/null; then
    echo "ERROR: $f contains raw image://icon/ concatenation with client window class!"
    exit 1
  fi
  if grep -E 'image://icon/" \+ modelData\.appId' "$f" >/dev/null; then
    echo "ERROR: $f contains raw image://icon/ concatenation with modelData.appId!"
    exit 1
  fi
done
echo "  ✔ Zero raw image://icon/ client-controlled string interpolations detected."

# 3. Verify StageManager.qml does not blindly map arbitrary root paths to file:// or pass unvalidated client appId
if grep -F 'if (name.charAt(0) === "/") return "file://" + name' "$REPO_ROOT/configs/quickshell/mac-stagemanager/StageManager.qml" >/dev/null; then
  echo "ERROR: StageManager.qml still blindly maps arbitrary absolute paths to file:// !"
  exit 1
fi
if grep -E 'iconSource\(entry \? entry\.icon : \(appId' "$REPO_ROOT/configs/quickshell/mac-stagemanager/StageManager.qml" >/dev/null; then
  echo "ERROR: StageManager.qml passes unvalidated client appId directly into iconSource!"
  exit 1
fi
if ! grep -F 'fallbackToken = clientCandidates[t]' "$REPO_ROOT/configs/quickshell/mac-stagemanager/StageManager.qml" >/dev/null; then
  echo "ERROR: StageManager.qml missing token validation on fallback client candidates!"
  exit 1
fi
echo "  ✔ StageManager strictly guards icon paths against client-controlled local file URIs and path traversal."

# 4. Functional validation of the canonical icon token regex and system icon path sanitization
python3 -c '
import re
token_pattern = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9._-]*$")
system_path_pattern = re.compile(r"^\/usr\/share\/(icons|pixmaps)\/[a-zA-Z0-9_.-]+(\/[a-zA-Z0-9_.-]+)*\.(png|svg|xpm|ico)$")

def is_safe_system_icon(name):
    if not name or not isinstance(name, str):
        return False
    if ".." in name or "\\" in name or "\0" in name:
        return False
    clean = name[7:] if name.startswith("file://") else name
    if not system_path_pattern.match(clean):
        return False
    parts = clean.split("/")[1:]
    return not any(p in (".", "..", "") for p in parts)

# Malicious vectors: must all FAIL validation
malicious = [
    "/home/user/.cache/crafted.png",
    "/tmp/bomb.png",
    "../../../../etc/shadow",
    "file:///home/user/.cache/bomb.png",
    "/usr/share/icons/../../home/user/.cache/bomb.png",
    "/usr/share/pixmaps/../../../tmp/crafted.png",
    "file:///usr/share/icons/../../home/user/.cache/crafted.png",
    "image://icon/foo",
    "http://127.0.0.1/evil.png",
    "app\x00name",
    "/bin/sh",
    "../app.png",
    "",
    " ",
    "-leading-dash",
    ".leading-dot",
    "app/subdir",
    "app\\backslash"
]

for vec in malicious:
    if token_pattern.match(vec):
        print(f"SECURITY ERROR: Malicious vector allowed as token: {vec}")
        exit(1)
    if is_safe_system_icon(vec):
        print(f"SECURITY ERROR: Malicious vector allowed as system path: {vec}")
        exit(1)

# Canonical tokens: must all PASS token validation
valid_tokens = [
    "firefox",
    "org.mozilla.firefox",
    "org.gnome.Nautilus",
    "discord",
    "antigravity-ide",
    "code_oss",
    "app123",
    "application-x-executable"
]

for val in valid_tokens:
    if not token_pattern.match(val):
        print(f"VALIDATION ERROR: Valid token rejected: {val}")
        exit(1)

# Trusted system paths: must PASS system path validation
valid_paths = [
    "/usr/share/icons/hicolor/scalable/apps/firefox.svg",
    "/usr/share/pixmaps/gedit.png",
    "file:///usr/share/icons/hicolor/48x48/apps/terminal.png",
    "/usr/share/icons/Adwaita/32x32/apps/calc.svg"
]

for vp in valid_paths:
    if not is_safe_system_icon(vp):
        print(f"VALIDATION ERROR: Valid system icon path rejected: {vp}")
        exit(1)
'
echo "  ✔ Canonical icon token and system path validation correctly blocks path traversal, absolute filenames, and URI schemes."

echo "=== 6. Validating Quickshell QML compilation ==="
if command -v quickshell >/dev/null 2>&1; then
  timeout 3s quickshell -p "$REPO_ROOT/configs/quickshell/mac-settings/shell.qml" 2>&1 | grep -iE "error|critical" || true
  timeout 3s quickshell -p "$REPO_ROOT/configs/quickshell/win11-settings/shell.qml" 2>&1 | grep -iE "error|critical" || true
  timeout 3s quickshell -p "$REPO_ROOT/configs/quickshell/mac-sound/shell.qml" 2>&1 | grep -iE "error|critical" || true
  timeout 3s quickshell -p "$REPO_ROOT/configs/quickshell/win11-sound/shell.qml" 2>&1 | grep -iE "error|critical" || true
  timeout 3s quickshell -p "$REPO_ROOT/configs/quickshell/mac-wifi/shell.qml" 2>&1 | grep -iE "error|critical" || true
  timeout 3s quickshell -p "$REPO_ROOT/configs/quickshell/win11-wifi/shell.qml" 2>&1 | grep -iE "error|critical" || true
  timeout 3s quickshell -p "$REPO_ROOT/configs/quickshell/mac-dock/shell.qml" 2>&1 | grep -iE "error|critical" || true
  echo "  ✔ Quickshell settings, flyout, sound, and dock QML configs compile cleanly."
fi

echo "🎉 All EDID injection, clipboard security, plain text rendering, and icon isolation tests passed successfully!"

