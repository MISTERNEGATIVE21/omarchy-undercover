#!/usr/bin/env bash
# =============================================================================
# Test: Third-Party Plugin & Custom Layout Preservation Across Mode Switches
# Also verifies Widget.qml defaults to Omarchy mode when state file is missing
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SANDBOX_HOME=$(mktemp -d)
trap 'rm -rf "$SANDBOX_HOME"' EXIT

export HOME="$SANDBOX_HOME"
export STATE_DIR="$HOME/.local/state/omarchy/undercover"
export CONFIG_DIR="$HOME/.config/omarchy/plugins/omarchy-undercover"
export BACKUP_DIR="$STATE_DIR/backups"
export BASELINE_FILE="$STATE_DIR/baseline"

mkdir -p "$HOME/.config/omarchy" "$STATE_DIR" "$CONFIG_DIR" "$BACKUP_DIR"

echo "=== 1. Setting up customized user shell.json with 3rd-party plugins ==="
cat << 'EOF' > "$HOME/.config/omarchy/shell.json"
{
  "version": 1,
  "bar": {
    "position": "top",
    "transparent": false,
    "centerAnchor": "omarchy.clock",
    "layout": {
      "left": [
        { "id": "custom-launcher" },
        { "id": "omarchy.workspaces" }
      ],
      "center": [
        { "id": "omarchy.clock" },
        { "id": "custom-pomodoro-timer" }
      ],
      "right": [
        { "id": "omarchy.tray" },
        { "id": "custom-weather-card" },
        { "id": "omarchy-undercover" }
      ]
    }
  },
  "plugins": [
    "custom-launcher",
    "custom-pomodoro-timer",
    "custom-weather-card",
    "omarchy-undercover"
  ]
}
EOF

echo "=== 2. Testing backup_original_configs() with undercover already on bar ==="
bash -c "
  export HOME='$SANDBOX_HOME'
  export SCRIPT_DIR='$REPO_DIR/scripts'
  export STATE_DIR='$STATE_DIR'
  export CONFIG_DIR='$CONFIG_DIR'
  export BACKUP_DIR='$BACKUP_DIR'
  export BASELINE_FILE='$BASELINE_FILE'

  source '$REPO_DIR/scripts/common.sh'
  source <(sed -n '/^backup_original_configs()/,/^}/p' '$REPO_DIR/scripts/omarchy-undercover')

  backup_original_configs
"

BASELINE_PATH=$(cat "$BASELINE_FILE" 2>/dev/null || echo "")
if [[ -z "$BASELINE_PATH" || ! -f "$BASELINE_PATH/omarchy/shell.json" ]]; then
  echo "FAIL: Baseline shell.json was not created!" >&2
  exit 1
fi

echo "Verifying backed-up baseline shell.json..."
BACKED_UP_JSON="$BASELINE_PATH/omarchy/shell.json"

if ! grep -q "custom-pomodoro-timer" "$BACKED_UP_JSON"; then
  echo "FAIL: Baseline backup wiped user third-party plugins! Content:" >&2
  cat "$BACKED_UP_JSON" >&2
  exit 1
fi

if ! grep -q "custom-launcher" "$BACKED_UP_JSON"; then
  echo "FAIL: Baseline backup missing custom-launcher! Content:" >&2
  cat "$BACKED_UP_JSON" >&2
  exit 1
fi
echo "✔ Baseline successfully preserved user's custom shell.json despite omarchy-undercover presence."

echo "=== 3. Simulating switch to macOS mode (shell.json overwritten by camouflage) ==="
cat << 'EOF' > "$HOME/.config/omarchy/shell.json"
{
  "version": 1,
  "bar": {
    "position": "top",
    "transparent": true,
    "centerAnchor": "",
    "layout": {
      "left": [ { "id": "mac-apple" }, { "id": "mac-appmenu" } ],
      "center": [ { "id": "omarchy.media" } ],
      "right": [ { "id": "mac-battery" }, { "id": "mac-clock" } ]
    }
  },
  "plugins": [ "omarchy-undercover" ]
}
EOF

echo "=== 4. Simulating switch back to Omarchy mode (restoring from baseline) ==="
bash -c "
  export HOME='$SANDBOX_HOME'
  export SCRIPT_DIR='$REPO_DIR/scripts'
  export STATE_DIR='$STATE_DIR'
  export CONFIG_DIR='$CONFIG_DIR'
  export BACKUP_DIR='$BACKUP_DIR'
  export BASELINE_FILE='$BASELINE_FILE'

  source '$REPO_DIR/scripts/common.sh'
  source <(sed -n '/^restore_shell_from_baseline()/,/^}/p' '$REPO_DIR/scripts/omarchy-undercover')

  restore_shell_from_baseline '$BASELINE_PATH'
"

RESTORED_JSON="$HOME/.config/omarchy/shell.json"
echo "Verifying restored shell.json..."

# Assert 3rd-party plugins are present
for p in "custom-launcher" "custom-pomodoro-timer" "custom-weather-card" "omarchy-undercover"; do
  if ! jq -e --arg p "$p" '.plugins // [] | index($p)' "$RESTORED_JSON" >/dev/null 2>&1; then
    echo "FAIL: Missing plugin '$p' in restored shell.json plugins array:" >&2
    cat "$RESTORED_JSON" >&2
    exit 1
  fi
done
echo "✔ All third-party plugins preserved in .plugins array."

# Assert custom widgets are present in layout
if ! grep -q "custom-launcher" "$RESTORED_JSON" || ! grep -q "custom-pomodoro-timer" "$RESTORED_JSON"; then
  echo "FAIL: Custom widgets missing from restored bar layout:" >&2
  cat "$RESTORED_JSON" >&2
  exit 1
fi
echo "✔ Custom widgets preserved in .bar.layout."

# Assert no mac-* widgets remain
if grep -q "mac-apple" "$RESTORED_JSON" || grep -q "mac-battery" "$RESTORED_JSON"; then
  echo "FAIL: Tainted mac-* widgets still in restored shell.json:" >&2
  cat "$RESTORED_JSON" >&2
  exit 1
fi
echo "✔ Camouflage widgets cleanly removed."

echo "=== 5. Testing Widget.qml defaults when state file is missing or empty ==="
# Verify Widget.qml static properties and fallback logic
if ! grep -q 'property string activeState: "omarchy"' "$REPO_DIR/Widget.qml"; then
  echo "FAIL: Widget.qml activeState does not default to 'omarchy'!" >&2
  exit 1
fi

if ! grep -q 'property string currentMode: "omarchy"' "$REPO_DIR/Widget.qml"; then
  echo "FAIL: Widget.qml currentMode does not default to 'omarchy'!" >&2
  exit 1
fi

if ! grep -q 'if (!raw) raw = "omarchy"' "$REPO_DIR/Widget.qml"; then
  echo "FAIL: Widget.qml updateFromState() does not default raw to 'omarchy'!" >&2
  exit 1
fi

echo "✔ Widget.qml defaults to omarchy mode and is visible when state file is absent."

echo "🎉 PASS: All custom plugin preservation and widget visibility checks passed successfully!"
exit 0

