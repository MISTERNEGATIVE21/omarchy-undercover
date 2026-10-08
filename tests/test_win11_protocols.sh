#!/usr/bin/env bash
# =============================================================================
# Test: Windows 11 Action Center & Flyouts Protocol Integration
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIN_AC="$REPO_DIR/configs/quickshell/win11-actioncenter/shell.qml"
WIN_WIFI="$REPO_DIR/configs/quickshell/win11-wifi/shell.qml"
WIN_BT="$REPO_DIR/configs/quickshell/win11-bluetooth/shell.qml"

echo "Checking win11-wifi protocol bindings..."
if ! grep -q "omarchy-network-status" "$WIN_WIFI" || ! grep -q "omarchy-network-band" "$WIN_WIFI"; then
  echo "FAIL: win11-wifi missing omarchy-network-status or omarchy-network-band" >&2
  exit 1
fi

if ! grep -q "omarchy-network-password" "$WIN_WIFI" || ! grep -q "omarchy-network-qr" "$WIN_WIFI"; then
  echo "FAIL: win11-wifi missing omarchy-network-password or omarchy-network-qr" >&2
  exit 1
fi

echo "Checking win11-bluetooth protocol bindings..."
if ! grep -q "omarchy-bluetooth-power" "$WIN_BT" || ! grep -q "omarchy-bluetooth-device" "$WIN_BT"; then
  echo "FAIL: win11-bluetooth missing omarchy-bluetooth-power or omarchy-bluetooth-device" >&2
  exit 1
fi

echo "Checking win11-actioncenter protocol bindings..."
if ! grep -q "omarchy-network-password" "$WIN_AC" || ! grep -q "omarchy-network-qr" "$WIN_AC"; then
  echo "FAIL: win11-actioncenter missing omarchy-network-password or omarchy-network-qr" >&2
  exit 1
fi

if ! grep -q "omarchy-bluetooth-power" "$WIN_AC" || ! grep -q "omarchy-bluetooth-device" "$WIN_AC"; then
  echo "FAIL: win11-actioncenter missing omarchy-bluetooth-power or omarchy-bluetooth-device" >&2
  exit 1
fi

# Quickshell Syntax Checks
echo "Validating Quickshell QML syntax..."
QS_WIFI=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/win11-wifi" 2>&1 || true)
if echo "$QS_WIFI" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load win11-wifi:" >&2
  echo "$QS_WIFI" >&2
  exit 1
fi

QS_BT=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/win11-bluetooth" 2>&1 || true)
if echo "$QS_BT" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load win11-bluetooth:" >&2
  echo "$QS_BT" >&2
  exit 1
fi

QS_AC=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/win11-actioncenter" 2>&1 || true)
if echo "$QS_AC" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load win11-actioncenter:" >&2
  echo "$QS_AC" >&2
  exit 1
fi

echo "PASS: Windows 11 Action Center & Flyouts protocol integration verified."
exit 0
