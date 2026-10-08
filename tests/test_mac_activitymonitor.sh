#!/usr/bin/env bash
# =============================================================================
# Test: macOS Activity Monitor Component & Dispatcher
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. Dispatcher executable check
DISPATCHER="$REPO_DIR/scripts/omarchy-mac-activitymonitor"
if [[ ! -x "$DISPATCHER" ]]; then
  echo "FAIL: Dispatcher $DISPATCHER does not exist or is not executable" >&2
  exit 1
fi

# 2. Check --help output
HELP_OUT=$("$DISPATCHER" --help 2>&1 || true)
if ! echo "$HELP_OUT" | grep -q "Activity Monitor"; then
  echo "FAIL: $DISPATCHER --help did not output expected usage description" >&2
  exit 1
fi

# 3. Quickshell QML check
QML_FILE="$REPO_DIR/configs/quickshell/mac-activitymonitor/shell.qml"
if [[ ! -f "$QML_FILE" ]]; then
  echo "FAIL: QML dashboard $QML_FILE does not exist" >&2
  exit 1
fi

# Check key UI features in QML
if ! grep -q "mac-activitymonitor" "$QML_FILE"; then
  echo "FAIL: namespace mac-activitymonitor missing from $QML_FILE" >&2
  exit 1
fi

if ! grep -q "#ff5f57" "$QML_FILE" || ! grep -q "#febc2e" "$QML_FILE" || ! grep -q "#28c840" "$QML_FILE"; then
  echo "FAIL: macOS traffic lights colors missing from $QML_FILE" >&2
  exit 1
fi

if ! grep -q "Activity Monitor" "$QML_FILE"; then
  echo "FAIL: Activity Monitor title missing from $QML_FILE" >&2
  exit 1
fi

# Check syntax with quickshell
QS_OUT=$(timeout 1.5s quickshell -p "$REPO_DIR/configs/quickshell/mac-activitymonitor" 2>&1 || true)
if echo "$QS_OUT" | grep -iE "syntax error|fatal|cannot load"; then
  echo "FAIL: Quickshell failed to load Activity Monitor QML:" >&2
  echo "$QS_OUT" >&2
  exit 1
fi

echo "PASS: macOS Activity Monitor component and dispatcher verified."
exit 0
