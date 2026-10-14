#!/usr/bin/env bash
# ==============================================================================
# Test macOS Stage Manager CLI interface
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/scripts/omarchy-mac-stagemanager"

if [[ ! -x "$CLI" ]]; then
    echo "ERROR: CLI executable not found at $CLI" >&2
    exit 1
fi

output=$("$CLI" --status)
echo "Status output: $output"
echo "$output" | jq . >/dev/null

has_opened=$(echo "$output" | jq -r 'has("opened")')
if [[ "$has_opened" != "true" ]]; then
    echo "ERROR: Missing 'opened' key in --status output" >&2
    exit 1
fi

has_groups=$(echo "$output" | jq -r 'has("groups")')
has_windows=$(echo "$output" | jq -r 'has("windows")')
if [[ "$has_groups" != "true" || "$has_windows" != "true" ]]; then
    echo "ERROR: Missing 'groups' or 'windows' key in --status output" >&2
    exit 1
fi

echo "Stage Manager CLI test passed!"
