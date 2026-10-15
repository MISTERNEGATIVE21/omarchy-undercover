#!/usr/bin/env bash
# =============================================================================
# Test: .undercoverfile Paging System and Window/VM Tracker Inside Plugin Folders
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACKER="$REPO_DIR/scripts/omarchy-undercover-tracker"
REPO_UNDERCOVER_FILE="$REPO_DIR/.undercoverfile"
INSTALLED_UNDERCOVER_FILE="$HOME/.config/omarchy/plugins/omarchy-undercover/.undercoverfile"
RUNTIME_FILE="${XDG_RUNTIME_DIR:-/tmp}/.undercoverfile"
HOME_FILE="$HOME/.undercoverfile"

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

echo "=== 3. Validating target files creation inside plugin folders ==="
if [[ ! -f "$REPO_UNDERCOVER_FILE" ]]; then
  echo "FAIL: $REPO_UNDERCOVER_FILE was not created in repo/plugin directory" >&2
  exit 1
fi
echo "  ✔ $REPO_UNDERCOVER_FILE exists inside repository/plugin folder"

if [[ ! -f "$INSTALLED_UNDERCOVER_FILE" ]]; then
  echo "FAIL: $INSTALLED_UNDERCOVER_FILE was not created in installed plugin directory" >&2
  exit 1
fi
echo "  ✔ $INSTALLED_UNDERCOVER_FILE exists inside installed plugin folder"

if [[ ! -f "$RUNTIME_FILE" ]]; then
  echo "FAIL: $RUNTIME_FILE was not created" >&2
  exit 1
fi
echo "  ✔ $RUNTIME_FILE exists"

if [[ -f "$HOME_FILE" && ! -L "$HOME_FILE" ]]; then
  echo "FAIL: Loose $HOME_FILE still exists in \$HOME root, should be cleaned up" >&2
  exit 1
fi
echo "  ✔ \$HOME is clean (no loose .undercoverfile polluting user home directory)"

echo "=== 4. Verifying required JSON schema fields & paging system in .undercoverfile ==="
python3 -c "
import json, os, sys

path = '$REPO_UNDERCOVER_FILE'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

required_keys = [
    'timestamp', 'iso_time',
    'paging',
    'current_workspace', 'current_vm',
    'workspaces_count', 'vms_count',
    'workspaces', 'vms',
    'current_window',
    'windows_count', 'total_clients',
    'windows', 'workspace_windows',
    'stage_manager_groups', 'monitors',
    'plugin_dir', 'file_path'
]

for k in required_keys:
    assert k in data, f'Missing key: {k}'

# Verify paging system details
paging = data['paging']
for pk in ['current_page', 'current_page_name', 'total_pages', 'pages', 'windows_per_page', 'active_page_windows', 'plugin_file']:
    assert pk in paging, f'Missing paging key: {pk}'

assert paging['current_page'] == data['current_workspace']['id'], 'current_page mismatch'
assert paging['total_pages'] == data['workspaces_count'], 'total_pages mismatch'
assert isinstance(paging['pages'], list), 'paging pages not list'
assert isinstance(paging['windows_per_page'], dict), 'windows_per_page not dict'

# Check counts
assert isinstance(data['workspaces_count'], int), 'workspaces_count not int'
assert isinstance(data['vms_count'], int), 'vms_count not int'
assert data['workspaces_count'] == data['vms_count'], 'workspaces_count and vms_count mismatch'
assert isinstance(data['windows_count'], int), 'windows_count not int'
assert isinstance(data['windows'], list), 'windows not list'
assert isinstance(data['stage_manager_groups'], list), 'stage_manager_groups not list'

print('  ✔ Schema validation passed: paging system, VM, and window fields verified')
"

echo "=== 5. Testing --paging CLI option ==="
PAGING_OUTPUT="$("$TRACKER" --paging)"
if ! echo "$PAGING_OUTPUT" | grep -q "Current Page"; then
  echo "FAIL: --paging missing Current Page" >&2
  exit 1
fi
if ! echo "$PAGING_OUTPUT" | grep -q "Total Pages"; then
  echo "FAIL: --paging missing Total Pages" >&2
  exit 1
fi
if ! echo "$PAGING_OUTPUT" | grep -q "Plugin State File"; then
  echo "FAIL: --paging missing Plugin State File" >&2
  exit 1
fi
echo "  ✔ --paging output verified"

echo "=== 6. Testing --summary human-readable output ==="
SUMMARY_OUTPUT="$("$TRACKER" --summary)"
if ! echo "$SUMMARY_OUTPUT" | grep -q "Plugin State File"; then
  echo "FAIL: --summary missing Plugin State File" >&2
  exit 1
fi
if ! echo "$SUMMARY_OUTPUT" | grep -q "Current VM / Workspace"; then
  echo "FAIL: --summary missing Current VM / Workspace" >&2
  exit 1
fi
if ! echo "$SUMMARY_OUTPUT" | grep -q "Total VMs / Workspaces"; then
  echo "FAIL: --summary missing Total VMs / Workspaces" >&2
  exit 1
fi
echo "  ✔ --summary output verified"

echo "=== 7. Testing --focus query parsing and error handling ==="
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

echo "=== 8. Verifying integration in layout switchers and Service.qml ==="
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

grep -q "trackerFile" "$REPO_DIR/Service.qml" || {
  echo "FAIL: Service.qml does not expose trackerFile IPC" >&2
  exit 1
}
echo "  ✔ Service.qml exposes trackerFile IPC"

grep -q "focusWindow" "$REPO_DIR/Service.qml" || {
  echo "FAIL: Service.qml does not expose focusWindow IPC" >&2
  exit 1
}
echo "  ✔ Service.qml exposes focusWindow IPC"

echo "🎉 PASS: .undercoverfile paging system inside plugin folders verified successfully!"
exit 0
