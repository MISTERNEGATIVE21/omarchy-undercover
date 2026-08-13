#!/bin/bash
# =============================================================================
# 🕵️ Omarchy Undercover — Interactive TUI Installer & Setup
# Basecamp / Charm Gum animated TUI installer for Hyprland desktop transformation.
# Copyright (C) 2026 misternegative21
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/omarchy-undercover"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_SHARE="$HOME/.local/share"
APPS_DIR="$LOCAL_SHARE/applications"
ICONS_DIR="$LOCAL_SHARE/icons"
FONTS_DIR="$LOCAL_SHARE/fonts"

# Color constants
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Check if gum is installed, fallback to ANSI helpers if not
HAS_GUM=0
if command -v gum >/dev/null 2>&1; then
    HAS_GUM=1
fi

print_banner() {
    clear
    if [[ $HAS_GUM -eq 1 ]]; then
        gum style \
            --border double \
            --margin "1 2" \
            --padding "1 4" \
            --border-foreground 39 \
            --foreground 212 \
            --bold \
            "🕵️  O M A R C H Y   U N D E R C O V E R   (v2.5.0)" \
            "  The Ultimate macOS Sequoia & Windows 11 Desktop Suite  " \
            "  Developed by misternegative21                          "
    else
        echo -e "${CYAN}${BOLD}====================================================================${NC}"
        echo -e "${MAGENTA}${BOLD}     🕵️  OMARCHY UNDERCOVER — DESKTOP TRANSFORMATION SUITE (v2.5.0)${NC}"
        echo -e "${BLUE}          Developed by misternegative21 for Hyprland / Omarchy${NC}"
        echo -e "${CYAN}${BOLD}====================================================================${NC}"
        echo ""
    fi
}

run_step() {
    local title="$1"
    local cmd="$2"
    if [[ $HAS_GUM -eq 1 ]]; then
        gum spin --spinner dot --title "$title" -- bash -c "$cmd"
        gum style --foreground 48 "  ✔ $title"
    else
        echo -e "${YELLOW}❯ ${title}...${NC}"
        eval "$cmd"
        echo -e "${GREEN}✔ Done: ${title}${NC}"
    fi
}

main() {
    print_banner

    # 1. Environment & Target Directories
    run_step "Creating destination directories in ~/.config and ~/.local..." '
        mkdir -p "$CONFIG_DIR/wallpapers" "$CONFIG_DIR/waybar" "$CONFIG_DIR/rofi" "$CONFIG_DIR/gtk" "$CONFIG_DIR/assets"
        mkdir -p "$LOCAL_BIN" "$APPS_DIR" "$ICONS_DIR/hicolor/scalable/apps" "$ICONS_DIR/mac-dock" "$FONTS_DIR"
    '

    # 2. Typography Installation
    run_step "Installing authentic Apple SF Pro, SF Mono, Segoe UI, and Cascadia Code fonts..." '
        if [[ -d "$SCRIPT_DIR/assets/fonts" ]]; then
            cp -rf "$SCRIPT_DIR/assets/fonts/"* "$FONTS_DIR/" 2>/dev/null || true
        fi
        fc-cache -f "$FONTS_DIR" >/dev/null 2>&1 || true
    '

    # 3. Vector Icons & Assets
    run_step "Deploying vector icons, dock launchers, and theme assets..." '
        if [[ -d "$SCRIPT_DIR/assets/mac-dock" ]]; then
            cp -rf "$SCRIPT_DIR/assets/mac-dock/"* "$ICONS_DIR/mac-dock/" 2>/dev/null || true
        fi
        if [[ -d "$SCRIPT_DIR/assets/icons" ]]; then
            cp -rf "$SCRIPT_DIR/assets/icons/"* "$ICONS_DIR/hicolor/scalable/apps/" 2>/dev/null || true
        fi
        gtk-update-icon-cache -f -t "$ICONS_DIR/hicolor" >/dev/null 2>&1 || true
    '

    # 4. 6K & 4K Wallpapers
    run_step "Installing authentic 6K & 4K macOS and Windows 11 wallpaper library..." '
        if [[ -d "$SCRIPT_DIR/assets/wallpapers" ]]; then
            cp -rf "$SCRIPT_DIR/assets/wallpapers/"* "$CONFIG_DIR/wallpapers/" 2>/dev/null || true
        fi
    '

    # 5. Configurations & Waybar Engine
    run_step "Deploying Waybar dynamic auto-sizing dock, Mica taskbars, and Rofi menus..." '
        if [[ -d "$SCRIPT_DIR/configs/waybar" ]]; then
            cp -rf "$SCRIPT_DIR/configs/waybar/"* "$CONFIG_DIR/waybar/" 2>/dev/null || true
        fi
        if [[ -d "$SCRIPT_DIR/configs/rofi" ]]; then
            cp -rf "$SCRIPT_DIR/configs/rofi/"* "$CONFIG_DIR/rofi/" 2>/dev/null || true
        fi
        if [[ -d "$SCRIPT_DIR/configs/gtk" ]]; then
            cp -rf "$SCRIPT_DIR/configs/gtk/"* "$CONFIG_DIR/gtk/" 2>/dev/null || true
        fi
    '

    # 6. Executables & Binaries
    run_step "Installing CLI state machine, GUI control center, and daemons into ~/.local/bin..." '
        if [[ -d "$SCRIPT_DIR/scripts" ]]; then
            for s in "$SCRIPT_DIR/scripts/"*; do
                if [[ -f "$s" ]]; then
                    cp -f "$s" "$LOCAL_BIN/"
                    chmod +x "$LOCAL_BIN/$(basename "$s")"
                fi
            done
        fi
    '

    # 7. Desktop Applications & Database
    run_step "Registering desktop applications and system control center..." '
        if [[ -f "$SCRIPT_DIR/assets/omarchy-undercover.desktop" ]]; then
            cp -f "$SCRIPT_DIR/assets/omarchy-undercover.desktop" "$APPS_DIR/"
        fi
        if [[ -f "$SCRIPT_DIR/assets/omarchy-settings.desktop" ]]; then
            cp -f "$SCRIPT_DIR/assets/omarchy-settings.desktop" "$APPS_DIR/"
        fi
        update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
    '

    # 8. Hyprland Keybindings & Modules
    run_step "Integrating Hyprland dynamic modules and global SUPER+ALT+U keybinding..." '
        mkdir -p "$HOME/.config/hypr"
        if [[ -f "$SCRIPT_DIR/configs/hypr/mac-mode.lua" ]]; then
            cp -f "$SCRIPT_DIR/configs/hypr/mac-mode.lua" "$HOME/.config/hypr/mac-mode.lua"
        fi
        if [[ -f "$SCRIPT_DIR/configs/hypr/windows-mode.lua" ]]; then
            cp -f "$SCRIPT_DIR/configs/hypr/windows-mode.lua" "$HOME/.config/hypr/windows-mode.lua"
        fi
        hyprctl reload >/dev/null 2>&1 || true
    '

    echo ""
    if [[ $HAS_GUM -eq 1 ]]; then
        gum style --foreground 39 --bold "✨ Select your starting desktop transformation preset:"
        CHOSEN=$(gum choose \
            "🍏 Apple macOS Sequoia (Dark)" \
            "☀️ Apple macOS Sequoia (Light)" \
            "🪟 Windows 11 Fluent (Dark)" \
            "🌅 Windows 11 Fluent (Light)")
    else
        echo -e "${CYAN}${BOLD}Select your starting desktop transformation preset:${NC}"
        echo "1) Apple macOS Sequoia (Dark)"
        echo "2) Apple macOS Sequoia (Light)"
        echo "3) Windows 11 Fluent (Dark)"
        echo "4) Windows 11 Fluent (Light)"
        read -p "Enter choice [1-4]: " opt
        case "$opt" in
            1) CHOSEN="🍏 Apple macOS Sequoia (Dark)" ;;
            2) CHOSEN="☀️ Apple macOS Sequoia (Light)" ;;
            3) CHOSEN="🪟 Windows 11 Fluent (Dark)" ;;
            4) CHOSEN="🌅 Windows 11 Fluent (Light)" ;;
            *) CHOSEN="🍏 Apple macOS Sequoia (Dark)" ;;
        esac
    fi

    case "$CHOSEN" in
        *"macOS Sequoia (Dark)"*)
            "$LOCAL_BIN/omarchy-undercover" -mac
            ;;
        *"macOS Sequoia (Light)"*)
            "$LOCAL_BIN/omarchy-undercover" -mac-light
            ;;
        *"Windows 11 Fluent (Dark)"*)
            "$LOCAL_BIN/omarchy-undercover" -w11
            ;;
        *"Windows 11 Fluent (Light)"*)
            "$LOCAL_BIN/omarchy-undercover" -w11-light
            ;;
    esac

    echo ""
    if [[ $HAS_GUM -eq 1 ]]; then
        gum style \
            --border rounded \
            --margin "1 2" \
            --padding "1 3" \
            --border-foreground 48 \
            --foreground 48 \
            --bold \
            "🎉 Omarchy Undercover Successfully Installed & Activated!" \
            "" \
            "  • Press Super + Alt + U anywhere to cycle modes" \
            "  • Press Super + B to toggle dock/taskbar autohide" \
            "  • Run 'omarchy-undercover-settings' to open the Control Center"
    else
        echo -e "${GREEN}${BOLD}🎉 Omarchy Undercover Successfully Installed & Activated!${NC}"
        echo -e "  • Press ${YELLOW}Super + Alt + U${NC} anywhere to cycle modes"
        echo -e "  • Press ${YELLOW}Super + B${NC} to toggle dock/taskbar autohide"
        echo -e "  • Run ${CYAN}omarchy-undercover-settings${NC} to open the Control Center"
    fi
}

main "$@"
