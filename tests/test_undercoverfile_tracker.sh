#!/usr/bin/env bash
# =============================================================================
# Test: .undercoverfile Paging System & Safe XDG State Tracking (No Reload Storm)
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRACKER="$REPO_DIR/scripts/omarchy-undercover-tracker"
REPO_UNDERCOVER_FILE="$REPO_DIR/.undercoverfile"
INSTALLED_UNDERCOVER_FILE="$HOME/.config/omarchy/plugins/omarchy-undercover/.undercoverfile"
RUNTIME_FILE="${XDG_RUNTIME_DIR:-/tmp}/omarchy-undercover/.undercoverfile"
HOME_FILE="$HOME/.undercoverfile"

echo "=== 1. Checking tracker script existence and permissions ==="
if [[ ! -x "$TRACKER" ]]; then
  echo "FAIL: Tracker script not found or not executable at $TRACKER" >&2
  exit 1
fi
echo "  ✔ $TRACKER is executable"

# Ensure clean slate before test
rm -f "$REPO_UNDERCOVER_FILE" "$INSTALLED_UNDERCOVER_FILE" "$HOME_FILE" "$RUNTIME_FILE"

echo "=== 2. Running tracker --status and validating JSON ==="
STATUS_OUTPUT="$("$TRACKER" --status)"
if ! echo "$STATUS_OUTPUT" | jq . >/dev/null 2>&1; then
  echo "FAIL: Tracker --status output is not valid JSON" >&2
  exit 1
fi
echo "  ✔ Tracker output is valid JSON"

echo "=== 3. Validating target file locations (Safe XDG, no plugin reload storm) ==="
if [[ -f "$REPO_UNDERCOVER_FILE" ]]; then
  echo "FAIL: $REPO_UNDERCOVER_FILE was created in repo directory! Writing here triggers inotify reloads." >&2
  exit 1
fi
echo "  ✔ Repo directory is clean (no writes triggering bar reload)"

if [[ -f "$INSTALLED_UNDERCOVER_FILE" ]]; then
  echo "FAIL: $INSTALLED_UNDERCOVER_FILE was created in installed plugin directory! Writing here triggers infinite bar reloads." >&2
  exit 1
fi
echo "  ✔ Installed plugin directory is clean (no writes triggering bar reload)"

if [[ ! -f "$RUNTIME_FILE" ]]; then
  echo "FAIL: $RUNTIME_FILE was not created in runtime directory" >&2
  exit 1
fi
echo "  ✔ $RUNTIME_FILE exists in runtime directory"

if [[ -f "$HOME_FILE" && ! -L "$HOME_FILE" ]]; then
  echo "FAIL: Loose $HOME_FILE still exists in \$HOME root, should be cleaned up" >&2
  exit 1
fi
echo "  ✔ \$HOME is clean (no loose .undercoverfile polluting user home directory)"

echo "=== 4. Verifying required JSON schema fields & paging system in runtime .undercoverfile ==="
python3 -c "
import json, os, sys

path = '$RUNTIME_FILE'
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

print('  ✔ Schema validation passed: runtime paging system, VM, and window fields verified')
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

echo "=== 8. Testing daemon removal & clean no-op behavior ==="
DAEMON_OUT="$("$TRACKER" --daemon 2>&1)"
if [[ $? -ne 0 ]]; then
  echo "FAIL: --daemon should cleanly exit 0" >&2
  exit 1
fi
STOP_OUT="$("$TRACKER" --stop 2>&1)"
if [[ $? -ne 0 ]]; then
  echo "FAIL: --stop should cleanly exit 0" >&2
  exit 1
fi
echo "  ✔ --daemon and --stop exit cleanly without background process retention"

echo "=== 9. Verifying no tracker daemon in Service.qml (prevents CPU drain) ==="
if grep -q "trackerDaemonProc" "$REPO_DIR/Service.qml"; then
  echo "FAIL: Service.qml still contains trackerDaemonProc (causes high CPU / socket2 loop)" >&2
  exit 1
fi
echo "  ✔ Service.qml does NOT launch background tracker daemon"

grep -q "focusWindow" "$REPO_DIR/Service.qml" || {
  echo "FAIL: Service.qml does not expose focusWindow IPC" >&2
  exit 1
}
echo "  ✔ Service.qml exposes focusWindow IPC"

grep -q "focusWorkspace" "$REPO_DIR/Service.qml" || {
  echo "FAIL: Service.qml does not expose focusWorkspace IPC" >&2
  exit 1
}
echo "  ✔ Service.qml exposes focusWorkspace IPC"

echo "🎉 PASS: .undercoverfile safe tracking & daemon-free performance verified successfully!"
exit 0
