#!/usr/bin/env bash
# ==============================================================================
# Omarchy Undercover Uninstaller
#
# Cleanly restores the user's original desktop environment, theme, wallpaper,
# and stock screensaver toggles without modifying any non-undercover configurations.
#
# Usage:
#   ./uninstall.sh            # Restores original desktop and removes runtime/cache
#   ./uninstall.sh --purge    # Also deletes downloaded screensavers and unlinks plugin
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PURGE=0

case "${1:-}" in
  --purge|-p) PURGE=1 ;;
  ""|-h|--help)
    if [[ "${1:-}" =~ -h|--help ]]; then
      echo "Usage: ./uninstall.sh [--purge]"
      echo "  --purge    Completely remove cached media assets and delete plugin installation"
      exit 0
    fi
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Usage: ./uninstall.sh [--purge]" >&2
    exit 1
    ;;
esac

echo "=== Omarchy Undercover Uninstaller ==="

# Lock guard: do not disrupt active lock session
if command -v omarchy-shell >/dev/null 2>&1 &&
   [[ "$(omarchy-shell lock isLocked 2>/dev/null)" == "true" ]]; then
  echo "ERROR: Refusing to uninstall while the session is locked." >&2
  echo "Please unlock first, then re-run." >&2
  exit 1
fi

if [[ "$PURGE" -eq 1 ]]; then
  "$SCRIPT_DIR/scripts/omarchy-undercover" --purge
else
  "$SCRIPT_DIR/scripts/omarchy-undercover" --uninstall
fi

echo "=== Uninstallation complete ==="
