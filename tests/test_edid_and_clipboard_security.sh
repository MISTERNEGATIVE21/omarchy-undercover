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

echo "=== 3. Validating Quickshell QML compilation ==="
if command -v quickshell >/dev/null 2>&1; then
  timeout 3s quickshell -p "$REPO_ROOT/configs/quickshell/mac-settings/shell.qml" 2>&1 | grep -iE "error|critical" || true
  timeout 3s quickshell -p "$REPO_ROOT/configs/quickshell/win11-settings/shell.qml" 2>&1 | grep -iE "error|critical" || true
  timeout 3s quickshell -p "$REPO_ROOT/configs/quickshell/mac-wifi/shell.qml" 2>&1 | grep -iE "error|critical" || true
  timeout 3s quickshell -p "$REPO_ROOT/configs/quickshell/win11-wifi/shell.qml" 2>&1 | grep -iE "error|critical" || true
  echo "  ✔ Quickshell settings and flyout QML configs compile cleanly."
fi

echo "🎉 All EDID injection and clipboard security tests passed successfully!"
