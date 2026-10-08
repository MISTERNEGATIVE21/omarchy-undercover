#!/usr/bin/env bash
# =============================================================================
# Test: macOS Shortcuts and Apple Menu Activity Monitor Wiring
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. mac-mode.lua shortcut check
LUA_MAC="$REPO_DIR/configs/hypr/mac-mode.lua"
if ! grep -q "SUPER + ALT + ESCAPE" "$LUA_MAC" || ! grep -q "omarchy-mac-activitymonitor" "$LUA_MAC"; then
  echo "FAIL: Super+Alt+Escape Activity Monitor binding missing from mac-mode.lua" >&2
  exit 1
fi

# 2. mac-mode.conf shortcut check
CONF_MAC="$REPO_DIR/configs/hypr/mac-mode.conf"
if ! grep -q "SUPER ALT, Escape" "$CONF_MAC" || ! grep -q "omarchy-mac-activitymonitor" "$CONF_MAC"; then
  echo "FAIL: Super+Alt+Escape Activity Monitor binding missing from mac-mode.conf" >&2
  exit 1
fi

# 3. widgets/mac-apple.qml menu item check
APPLE_QML="$REPO_DIR/widgets/mac-apple.qml"
if ! grep -A 8 "Force Quit Applications" "$APPLE_QML" | grep -q "omarchy-mac-activitymonitor"; then
  echo "FAIL: Force Quit Applications in mac-apple.qml is not wired to omarchy-mac-activitymonitor" >&2
  exit 1
fi

if ! grep -q "Activity Monitor" "$APPLE_QML"; then
  echo "FAIL: Activity Monitor entry missing from Apple Menu in mac-apple.qml" >&2
  exit 1
fi

echo "PASS: macOS Activity Monitor shortcuts and Apple Menu wiring verified."
exit 0
