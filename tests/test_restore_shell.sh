#!/usr/bin/env bash
# =============================================================================
# Test: Shell State and Top Bar Restoration
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SANDBOX_HOME=$(mktemp -d)
trap 'rm -rf "$SANDBOX_HOME"' EXIT

export HOME="$SANDBOX_HOME"
export STATE_DIR="$HOME/.local/state/omarchy-undercover"
export CONFIG_DIR="$HOME/.config/omarchy/plugins/omarchy-undercover"
export BASELINE_FILE="$STATE_DIR/baseline"

mkdir -p "$HOME/.config/omarchy" "$STATE_DIR" "$CONFIG_DIR"

# 1. Simulate a tainted macOS shell.json left behind after macOS mode
cat << 'EOF' > "$HOME/.config/omarchy/shell.json"
{
  "version": 1,
  "bar": {
    "position": "top",
    "transparent": true,
    "centerAnchor": "",
    "layout": {
      "left": [
        { "id": "mac-apple" },
        { "id": "mac-appmenu" }
      ],
      "center": [
        { "id": "omarchy.media" }
      ],
      "right": [
        { "id": "omarchy-undercover" },
        { "id": "mac-battery" },
        { "id": "mac-clock" }
      ]
    }
  },
  "plugins": [
    "omarchy-undercover"
  ]
}
EOF

# Ensure no baseline file exists initially
rm -f "$BASELINE_FILE"

# 2. Extract and run restore_shell_from_baseline directly using a helper runner
# Source undercover functions
bash -c "
  export HOME='$SANDBOX_HOME'
  export SCRIPT_DIR='$REPO_DIR/scripts'
  export STATE_DIR='$STATE_DIR'
  export CONFIG_DIR='$CONFIG_DIR'
  export BASELINE_FILE='$BASELINE_FILE'

  source '$REPO_DIR/scripts/common.sh'
  source <(sed -n '/^restore_shell_from_baseline()/,/^}/p' '$REPO_DIR/scripts/omarchy-undercover')

  restore_shell_from_baseline ''
"

RESTORED_JSON="$HOME/.config/omarchy/shell.json"

if [[ ! -f "$RESTORED_JSON" ]]; then
  echo "FAIL: shell.json does not exist after restore" >&2
  exit 1
fi

# 3. Assertions
echo "Verifying restored shell.json..."

# Check 1: No mac-* widgets must be present
if grep -q "mac-apple" "$RESTORED_JSON" || grep -q "mac-clock" "$RESTORED_JSON"; then
  echo "FAIL: mac-* widgets still present in restored shell.json:" >&2
  cat "$RESTORED_JSON" >&2
  exit 1
fi

# Check 2: Default omarchy layout widgets must be restored
if ! grep -q "omarchy.menu" "$RESTORED_JSON" && ! grep -q "omarchy.clock" "$RESTORED_JSON"; then
  echo "FAIL: Default omarchy widgets missing from restored shell.json:" >&2
  cat "$RESTORED_JSON" >&2
  exit 1
fi

# Check 3: bar.transparent must not be true
TRANS=$(jq -r '.bar.transparent' "$RESTORED_JSON")
if [[ "$TRANS" == "true" ]]; then
  echo "FAIL: bar.transparent is still true after restore!" >&2
  exit 1
fi

echo "PASS: Shell restoration properly cleaned macos widgets and restored default layout."
exit 0
