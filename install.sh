#!/usr/bin/env bash
# ==============================================================================
# Omarchy Undercover Installer
#
# Seamlessly installs Omarchy Undercover, links required binaries to PATH,
# sets up configurations and Hyprland toggle bindings, and configures the
# Undercover icon placement (left, middle, or right) on the Omarchy status bar.
#
# Usage:
#   ./install.sh                    # Interactive installation (prompts for icon position)
#   ./install.sh --left             # Place Undercover icon on the left of status bar
#   ./install.sh --middle           # Place Undercover icon in the middle (center)
#   ./install.sh --right            # Place Undercover icon on the right (default)
#   ./install.sh --bar-position <left|middle|right>
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POSITION=""

case "${1:-}" in
  --left|-l|left)
    POSITION="left"
    ;;
  --middle|-m|middle|--center|-c|center)
    POSITION="center"
    ;;
  --right|-r|right)
    POSITION="right"
    ;;
  --bar-position|--bar-placement|-b)
    POSITION="${2:-}"
    ;;
  -h|--help)
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --left, -l, left                 Place Undercover icon on the left of the bar"
    echo "  --middle, -m, middle, --center   Place Undercover icon in the middle of the bar"
    echo "  --right, -r, right               Place Undercover icon on the right of the bar"
    echo "  --bar-position <left|middle|right> Explicitly specify status bar placement"
    echo "  -h, --help                       Show this help message"
    exit 0
    ;;
  "")
    POSITION=""
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Usage: ./install.sh [--left|--middle|--right|--bar-position <pos>]" >&2
    exit 1
    ;;
esac

echo "=== Omarchy Undercover Installer ==="

# Lock guard: do not install while desktop session is locked
if command -v omarchy-shell >/dev/null 2>&1 &&
   [[ "$(omarchy-shell lock isLocked 2>/dev/null)" == "true" ]]; then
  echo "ERROR: Refusing to install while the session is locked." >&2
  echo "Please unlock first, then re-run." >&2
  exit 1
fi

"$SCRIPT_DIR/scripts/omarchy-undercover" --install "$POSITION"
