#!/usr/bin/env bash
# =============================================================================
# Test: macOS Menu Bar Wi-Fi & Bluetooth Flyouts Protocol Integration
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAC_WIFI="$REPO_DIR/configs/quickshell/mac-wifi/shell.qml"
MAC_BT="$REPO_DIR/configs/quickshell/mac-bluetooth/shell.qml"

if ! grep -q "omarchy-network-status" "$MAC_WIFI"; then
  echo "FAIL: mac-wifi missing omarchy-network-status integration" >&2
  exit 1
fi

if ! grep -q "omarchy-network-band" "$MAC_WIFI"; then
  echo "FAIL: mac-wifi missing omarchy-network-band integration" >&2
  exit 1
fi

if ! grep -q "omarchy-network-password" "$MAC_WIFI"; then
  echo "FAIL: mac-wifi missing omarchy-network-password integration" >&2
  exit 1
fi

if ! grep -q "omarchy-network-qr" "$MAC_WIFI"; then
  echo "FAIL: mac-wifi missing omarchy-network-qr integration" >&2
  exit 1
fi

if ! grep -q "omarchy-bluetooth-power" "$MAC_BT"; then
  echo "FAIL: mac-bluetooth missing omarchy-bluetooth-power integration" >&2
  exit 1
fi

if ! grep -q "omarchy-bluetooth-device" "$MAC_BT"; then
  echo "FAIL: mac-bluetooth missing omarchy-bluetooth-device integration" >&2
  exit 1
fi

# Quickshell Syntax Checks
QS_WIFI=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/mac-wifi" 2>&1 || true)
if echo "$QS_WIFI" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load mac-wifi:" >&2
  echo "$QS_WIFI" >&2
  exit 1
fi

QS_BT=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/mac-bluetooth" 2>&1 || true)
if echo "$QS_BT" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load mac-bluetooth:" >&2
  echo "$QS_BT" >&2
  exit 1
fi

echo "PASS: macOS menu bar flyouts protocol integration verified."
exit 0
