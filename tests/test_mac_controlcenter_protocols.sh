#!/usr/bin/env bash
# =============================================================================
# Test: macOS Control Center Protocol Integration
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCC_QML="$REPO_DIR/configs/quickshell/mac-controlcenter/shell.qml"

if ! grep -q "omarchy-network-status" "$MCC_QML"; then
  echo "FAIL: mac-controlcenter missing omarchy-network-status integration" >&2
  exit 1
fi

if ! grep -q "omarchy-network-band" "$MCC_QML"; then
  echo "FAIL: mac-controlcenter missing omarchy-network-band integration" >&2
  exit 1
fi

if ! grep -q "omarchy-network-password" "$MCC_QML"; then
  echo "FAIL: mac-controlcenter missing omarchy-network-password integration" >&2
  exit 1
fi

if ! grep -q "omarchy-network-qr" "$MCC_QML"; then
  echo "FAIL: mac-controlcenter missing omarchy-network-qr integration" >&2
  exit 1
fi

if ! grep -q "omarchy-bluetooth-power" "$MCC_QML"; then
  echo "FAIL: mac-controlcenter missing omarchy-bluetooth-power integration" >&2
  exit 1
fi

if ! grep -q "omarchy-bluetooth-device" "$MCC_QML"; then
  echo "FAIL: mac-controlcenter missing omarchy-bluetooth-device integration" >&2
  exit 1
fi

# Quickshell Syntax Check
QS_OUT=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/mac-controlcenter" 2>&1 || true)
if echo "$QS_OUT" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load mac-controlcenter:" >&2
  echo "$QS_OUT" >&2
  exit 1
fi

echo "PASS: macOS Control Center protocol integration verified."
exit 0
