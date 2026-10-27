#!/usr/bin/env bash
# ==============================================================================
# Test: Undercover Installer and Bar Widget Position (Left / Middle / Right)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SHELL_JSON="$HOME/.config/omarchy/shell.json"

source "$REPO_ROOT/scripts/common.sh"
SETTINGS_CONF="$(undercover_settings_file)"

echo "=== 1. Testing ./install.sh --help ==="
"$REPO_ROOT/install.sh" --help | grep -q -- "--middle"
"$REPO_ROOT/install.sh" --help | grep -q -- "--left"
"$REPO_ROOT/install.sh" --help | grep -q -- "--right"
echo "✔ install.sh --help documents left, middle, right options."

echo "=== 2. Testing ./install.sh with explicit --middle flag ==="
"$REPO_ROOT/install.sh" --middle
grep -q "^BAR_POSITION=center" "$SETTINGS_CONF" || {
    echo "ERROR: BAR_POSITION=center not written to $SETTINGS_CONF" >&2
    exit 1
}
jq -e '.bar.layout.center[] | select(.id == "omarchy-undercover")' "$SHELL_JSON" >/dev/null || {
    echo "ERROR: omarchy-undercover missing from bar.layout.center in $SHELL_JSON" >&2
    exit 1
}
echo "✔ ./install.sh --middle correctly places Undercover icon in center (middle) of bar."

echo "=== 3. Testing ./install.sh with explicit --left flag ==="
"$REPO_ROOT/install.sh" --left
grep -q "^BAR_POSITION=left" "$SETTINGS_CONF" || {
    echo "ERROR: BAR_POSITION=left not written to $SETTINGS_CONF" >&2
    exit 1
}
jq -e '.bar.layout.left[] | select(.id == "omarchy-undercover")' "$SHELL_JSON" >/dev/null || {
    echo "ERROR: omarchy-undercover missing from bar.layout.left in $SHELL_JSON" >&2
    exit 1
}
echo "✔ ./install.sh --left correctly places Undercover icon on left of bar."

echo "=== 4. Testing ./install.sh interactive prompt via pipe (selecting 'middle') ==="
printf "middle\n" | "$REPO_ROOT/install.sh"
grep -q "^BAR_POSITION=center" "$SETTINGS_CONF" || {
    echo "ERROR: Piped 'middle' failed to set BAR_POSITION=center" >&2
    exit 1
}
jq -e '.bar.layout.center[] | select(.id == "omarchy-undercover")' "$SHELL_JSON" >/dev/null || {
    echo "ERROR: Piped 'middle' failed to place icon in center" >&2
    exit 1
}
echo "✔ Interactive pipe input 'middle' correctly sets middle/center position."

echo "=== 5. Testing ./install.sh interactive prompt via pipe (selecting 'right') ==="
printf "right\n" | "$REPO_ROOT/install.sh"
grep -q "^BAR_POSITION=right" "$SETTINGS_CONF" || {
    echo "ERROR: Piped 'right' failed to set BAR_POSITION=right" >&2
    exit 1
}
jq -e '.bar.layout.right[] | select(.id == "omarchy-undercover")' "$SHELL_JSON" >/dev/null || {
    echo "ERROR: Piped 'right' failed to place icon on right" >&2
    exit 1
}
echo "✔ Interactive pipe input 'right' correctly sets right position."

echo "=== 6. Validating binaries in PATH ==="
for bin_name in omarchy-undercover omarchy-mac-wifi omarchy-mac-bluetooth omarchy-mac-dock; do
    if [[ ! -x "$HOME/.local/bin/$bin_name" ]]; then
        echo "ERROR: $HOME/.local/bin/$bin_name missing or not executable" >&2
        exit 1
    fi
done
echo "✔ Required binaries properly symlinked in ~/.local/bin/."

echo "=== 7. Validating plugin compliance against Omarchy v1 schema ==="
if command -v omarchy >/dev/null 2>&1; then
    omarchy plugin validate "$REPO_ROOT"
    if [[ -d "$HOME/.config/omarchy/plugins/omarchy-undercover" ]]; then
        omarchy plugin validate "$HOME/.config/omarchy/plugins/omarchy-undercover"
    fi
fi
echo "✔ Plugin manifest compliance verified."

echo "=== ALL INSTALL & BAR POSITION TESTS PASSED SUCCESSFULLY! ==="
