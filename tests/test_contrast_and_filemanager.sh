#!/usr/bin/env bash
# =============================================================================
# Test: File Managers & Color Contrast / Readability Overhaul
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FM_SCRIPT="$REPO_DIR/scripts/omarchy-undercover-filemanager"
STYLE_MAC="$REPO_DIR/configs/waybar/style-mac.css"
STYLE_WIN="$REPO_DIR/configs/waybar/style-win.css"
MAC_CLOCK="$REPO_DIR/widgets/mac-clock.qml"
MAC_APPMENU="$REPO_DIR/widgets/mac-appmenu.qml"

# 1. Flea UI configuration presets
if ! grep -q '"view":"columns"' "$FM_SCRIPT"; then
  echo "FAIL: omarchy-undercover-filemanager missing macOS Miller columns view preset" >&2
  exit 1
fi

if ! grep -q '"view":"list"' "$FM_SCRIPT"; then
  echo "FAIL: omarchy-undercover-filemanager missing Windows 11 Details list view preset" >&2
  exit 1
fi

if ! grep -q '"addressBar":"breadcrumb"' "$FM_SCRIPT" || ! grep -q '"addressBar":"path"' "$FM_SCRIPT"; then
  echo "FAIL: omarchy-undercover-filemanager missing addressBar configuration" >&2
  exit 1
fi

# 2. Waybar CSS Contrast and Drop Shadows
if ! grep -A 10 "window#waybar.mac-topbar" "$STYLE_MAC" | grep -q "text-shadow"; then
  echo "FAIL: style-mac.css mac-topbar missing text-shadow for light wallpaper contrast" >&2
  exit 1
fi

if ! grep -A 10 "window#waybar.win11-taskbar" "$STYLE_WIN" | grep -q "rgba(32, 32, 32, 0.96)"; then
  echo "FAIL: style-win.css win11-taskbar missing solid 96% dark acrylic background" >&2
  exit 1
fi

# 3. Quickshell Mac Topbar Widget High-Contrast Text Outlining
if ! grep -q "style: Text.Outline" "$MAC_CLOCK"; then
  echo "FAIL: widgets/mac-clock.qml missing Text.Outline styling for contrast" >&2
  exit 1
fi

if ! grep -q "style: Text.Outline" "$MAC_APPMENU"; then
  echo "FAIL: widgets/mac-appmenu.qml missing Text.Outline styling for contrast" >&2
  exit 1
fi

echo "PASS: File manager presets and UI contrast enhancements verified."
exit 0
