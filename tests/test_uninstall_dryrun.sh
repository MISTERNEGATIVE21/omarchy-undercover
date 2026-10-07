#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Testing uninstaller CLI options and documentation..."
"$ROOT_DIR/uninstall.sh" --help | grep -q -- "--purge"
"$ROOT_DIR/scripts/omarchy-undercover" --help | grep -q -- "--purge"
"$ROOT_DIR/scripts/omarchy-undercover" --help | grep -q -- "--uninstall"

echo "Validating plugin compliance against Omarchy v1 schema..."
omarchy plugin validate "$ROOT_DIR"
if [[ -d "$HOME/.config/omarchy/plugins/omarchy-undercover" ]]; then
    omarchy plugin validate "$HOME/.config/omarchy/plugins/omarchy-undercover"
fi

echo "Verifying undercover integrity..."
"$ROOT_DIR/scripts/omarchy-undercover" --verify

echo "All uninstall & compliance tests passed!"
