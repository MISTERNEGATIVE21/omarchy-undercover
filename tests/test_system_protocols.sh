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

echo "Checking omarchy-wifi-dbus forget subcommand..."
WIFI_USAGE=$(python3 scripts/omarchy-wifi-dbus forget 2>&1 || true)
if [[ "$WIFI_USAGE" != *"Usage"* && "$WIFI_USAGE" != *"ssid"* ]]; then
  echo "FAIL: omarchy-wifi-dbus forget without arguments did not output usage: $WIFI_USAGE"
  exit 1
fi

WIFI_FORGET_TEST=$(python3 scripts/omarchy-wifi-dbus forget "NONEXISTENT_TEST_SSID_12345" 2>&1 || true)
if [[ "$WIFI_FORGET_TEST" == *"Traceback"* ]]; then
  echo "FAIL: omarchy-wifi-dbus forget crashed with Traceback: $WIFI_FORGET_TEST"
  exit 1
fi

echo "Checking omarchy-bluetooth-dbus forget subcommand..."
BT_USAGE=$(python3 scripts/omarchy-bluetooth-dbus forget 2>&1 || true)
if [[ "$BT_USAGE" != *"Usage"* && "$BT_USAGE" != *"mac"* ]]; then
  echo "FAIL: omarchy-bluetooth-dbus forget without arguments did not output usage: $BT_USAGE"
  exit 1
fi

BT_FORGET_TEST=$(python3 scripts/omarchy-bluetooth-dbus forget "00:11:22:33:44:55" 2>&1 || true)
if [[ "$BT_FORGET_TEST" == *"Traceback"* ]]; then
  echo "FAIL: omarchy-bluetooth-dbus forget crashed with Traceback: $BT_FORGET_TEST"
  exit 1
fi

echo "PASS: All Omarchy system protocol tools and fallbacks verified."
exit 0
