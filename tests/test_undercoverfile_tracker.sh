#!/usr/bin/env bash
# =============================================================================
# Test: .undercoverfile State File and Window/VM Tracker
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACKER="$REPO_DIR/scripts/omarchy-undercover-tracker"
UNDERCOVER_FILE="$HOME/.undercoverfile"
RUNTIME_FILE="${XDG_RUNTIME_DIR:-/tmp}/.undercoverfile"

echo "=== 1. Checking tracker script existence and permissions ==="
if [[ ! -x "$TRACKER" ]]; then
  echo "FAIL: Tracker script not found or not executable at $TRACKER" >&2
  exit 1
fi
echo "  ✔ $TRACKER is executable"

echo "=== 2. Running tracker --status and validating JSON ==="
STATUS_OUTPUT="$("$TRACKER" --status)"
if ! echo "$STATUS_OUTPUT" | jq . >/dev/null 2>&1; then
  echo "FAIL: Tracker --status output is not valid JSON" >&2
  exit 1
fi
echo "  ✔ Tracker output is valid JSON"

echo "=== 3. Validating target files creation ==="
if [[ ! -f "$UNDERCOVER_FILE" ]]; then
  echo "FAIL: ~/.undercoverfile was not created" >&2
  exit 1
fi
echo "  ✔ $UNDERCOVER_FILE exists"

if [[ ! -f "$RUNTIME_FILE" ]]; then
  echo "FAIL: $RUNTIME_FILE was not created" >&2
  exit 1
fi
echo "  ✔ $RUNTIME_FILE exists"

echo "=== 4. Verifying required JSON schema fields in .undercoverfile ==="
python3 -c '
import json, os, sys

path = os.path.expanduser("~/.undercoverfile")
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

required_keys = [
    "timestamp", "iso_time",
    "current_workspace", "current_vm",
    "workspaces_count", "vms_count",
    "workspaces", "vms",
    "current_window",
    "windows_count", "total_clients",
    "windows", "workspace_windows",
    "stage_manager_groups", "monitors"
]

for k in required_keys:
    assert k in data, f"Missing key: {k}"

# Check current_workspace and current_vm
assert "id" in data["current_workspace"], "current_workspace missing id"
assert "id" in data["current_vm"], "current_vm missing id"
assert data["current_workspace"]["id"] == data["current_vm"]["id"], "current_workspace and current_vm mismatch"
assert "windows_count" in data["current_workspace"], "current_workspace missing windows_count"

# Check counts
assert isinstance(data["workspaces_count"], int), "workspaces_count not int"
assert isinstance(data["vms_count"], int), "vms_count not int"
assert data["workspaces_count"] == data["vms_count"], "workspaces_count and vms_count mismatch"
assert isinstance(data["windows_count"], int), "windows_count not int"
assert isinstance(data["windows"], list), "windows not list"
assert isinstance(data["stage_manager_groups"], list), "stage_manager_groups not list"

print("  ✔ Schema validation passed: all VM, workspace, and window fields verified")
'

echo "=== 5. Testing --summary human-readable output ==="
SUMMARY_OUTPUT="$("$TRACKER" --summary)"
if ! echo "$SUMMARY_OUTPUT" | grep -q "Current VM / Workspace"; then
  echo "FAIL: --summary missing Current VM / Workspace" >&2
  exit 1
fi
if ! echo "$SUMMARY_OUTPUT" | grep -q "Total VMs / Workspaces"; then
  echo "FAIL: --summary missing Total VMs / Workspaces" >&2
  exit 1
fi
if ! echo "$SUMMARY_OUTPUT" | grep -q "Total Open Windows"; then
  echo "FAIL: --summary missing Total Open Windows" >&2
  exit 1
fi
echo "  ✔ --summary output verified"

echo "=== 6. Testing --focus query parsing and error handling ==="
# Test looking for a non-existent window returns exit code 1 and clean error JSON
set +e
ERR_OUT="$("$TRACKER" --focus "nonexistent-app-xyz-999" 2>&1)"
RET=$?
set -e
if [[ $RET -eq 0 ]]; then
  echo "FAIL: Expected non-zero exit code for non-existent window, got 0" >&2
  exit 1
fi
if ! echo "$ERR_OUT" | grep -q "not found"; then
  echo "FAIL: Expected 'not found' error message, got: $ERR_OUT" >&2
  exit 1
fi
echo "  ✔ --focus non-existent target handled cleanly"

echo "=== 7. Verifying integration in layout switchers and Service.qml ==="
grep -q "omarchy-undercover-tracker" "$REPO_DIR/widgets/win11-taskbar.qml" || {
  echo "FAIL: win11-taskbar.qml does not integrate omarchy-undercover-tracker" >&2
  exit 1
}
echo "  ✔ win11-taskbar.qml integrates tracker"

grep -q "omarchy-undercover-tracker" "$REPO_DIR/configs/quickshell/mac-dock/shell.qml" || {
  echo "FAIL: mac-dock shell.qml does not integrate omarchy-undercover-tracker" >&2
  exit 1
}
echo "  ✔ mac-dock shell.qml integrates tracker"

grep -q "omarchy-undercover-tracker" "$REPO_DIR/configs/quickshell/mac-stagemanager/StageManager.qml" || {
  echo "FAIL: mac-stagemanager StageManager.qml does not integrate omarchy-undercover-tracker" >&2
  exit 1
}
echo "  ✔ mac-stagemanager StageManager.qml integrates tracker"

grep -q "omarchy-undercover-tracker" "$REPO_DIR/configs/quickshell/win11-taskview/shell.qml" || {
  echo "FAIL: win11-taskview shell.qml does not integrate omarchy-undercover-tracker" >&2
  exit 1
}
echo "  ✔ win11-taskview shell.qml integrates tracker"

grep -q "omarchy-undercover-tracker" "$REPO_DIR/scripts/omarchy-undercover-activate" || {
  echo "FAIL: omarchy-undercover-activate does not integrate omarchy-undercover-tracker" >&2
  exit 1
}
echo "  ✔ omarchy-undercover-activate integrates tracker"

grep -q "trackerDaemonProc" "$REPO_DIR/Service.qml" || {
  echo "FAIL: Service.qml does not launch tracker daemon" >&2
  exit 1
}
echo "  ✔ Service.qml launches tracker daemon"

grep -q "focusWindow" "$REPO_DIR/Service.qml" || {
  echo "FAIL: Service.qml does not expose focusWindow IPC" >&2
  exit 1
}
echo "  ✔ Service.qml exposes focusWindow IPC"

echo "🎉 PASS: .undercoverfile tracker and window/VM navigation verified successfully!"
exit 0
