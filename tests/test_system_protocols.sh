#!/usr/bin/env bash
# =============================================================================
# Test: Omarchy System Protocols Tooling Verification
# =============================================================================
set -euo pipefail

echo "Checking Omarchy official network tools..."
command -v omarchy-network-status >/dev/null || { echo "FAIL: omarchy-network-status missing"; exit 1; }
command -v omarchy-network-band >/dev/null || { echo "FAIL: omarchy-network-band missing"; exit 1; }
command -v omarchy-network-password >/dev/null || { echo "FAIL: omarchy-network-password missing"; exit 1; }
command -v omarchy-network-qr >/dev/null || { echo "FAIL: omarchy-network-qr missing"; exit 1; }

echo "Checking Omarchy official bluetooth tools..."
command -v omarchy-bluetooth-power >/dev/null || { echo "FAIL: omarchy-bluetooth-power missing"; exit 1; }
command -v omarchy-bluetooth-device >/dev/null || { echo "FAIL: omarchy-bluetooth-device missing"; exit 1; }

echo "Checking Omarchy network status output format..."
STATUS_OUT=$(omarchy-network-status --verbose 2>&1 || true)
if [[ -z "$STATUS_OUT" ]]; then
  echo "FAIL: omarchy-network-status returned empty output"
  exit 1
fi

echo "Checking fallback tools..."
command -v nmcli >/dev/null || { echo "FAIL: nmcli missing"; exit 1; }
command -v bluetoothctl >/dev/null || { echo "FAIL: bluetoothctl missing"; exit 1; }
command -v wpctl >/dev/null || { echo "FAIL: wpctl missing"; exit 1; }

echo "PASS: All Omarchy system protocol tools and fallbacks verified."
exit 0
