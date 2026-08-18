#!/usr/bin/env bash
# =============================================================================
# 🕵️ OMARCHY UNDERCOVER — BASECAMP / CHARM TUI INSTALLER (v3.0.0)
# Interactive Terminal Installer with Smooth Multi-Stage Animations & Styling
#
# Copyright (C) 2026 misternegative21
# License: GPL-3.0-or-later
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/omarchy-undercover"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_SHARE="$HOME/.local/share"
APPS_DIR="$LOCAL_SHARE/applications"
ICONS_DIR="$LOCAL_SHARE/icons"
FONTS_DIR="$LOCAL_SHARE/fonts"

# ANSI Terminal Color Tokens
CYAN='\033[38;2;0;242;254m'
BLUE='\033[38;2;0;120;212m'
PURPLE='\033[38;2;175;82;222m'
PINK='\033[38;2;255;45;85m'
GREEN='\033[38;2;52;199;89m'
YELLOW='\033[38;2;255;204;0m'
WHITE='\033[38;2;255;255;255m'
GRAY='\033[38;2;140;140;160m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

HAS_GUM=0
if [[ -t 0 && -t 1 ]] && command -v gum >/dev/null 2>&1; then
    HAS_GUM=1
fi

print_logo() {
    if [[ -t 1 ]]; then
        clear 2>/dev/null || true
    fi
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
  ██████╗ ███╗   ███╗ █████╗ ██████╗  ██████╗██╗  ██╗██╗   ██╗
 ██╔═══██╗████╗ ████║██╔══██╗██╔══██╗██╔════╝██║  ██║╚██╗ ██╔╝
 ██║   ██║██╔████╔██║███████║██████╔╝██║     ███████║ ╚████╔╝ 
 ██║   ██║██║╚██╔╝██║██╔══██║██╔══██╗██║     ██╔══██║  ╚██╔╝  
 ╚██████╔╝██║ ╚═╝ ██║██║  ██║██║  ██║╚██████╗██║  ██║   ██║   
  ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   
EOF
    echo -e "${PINK}${BOLD}"
    cat << "EOF"
 ██╗   ██╗███╗   ██╗██████╗ ███████╗██████╗  ██████╗ ██████╗ ██╗   ██╗███████╗██████╗ 
 ██║   ██║████╗  ██║██╔══██╗██╔════╝██╔══██╗██╔════╝██╔═══██╗██║   ██║██╔════╝██╔══██╗
 ██║   ██║██╔██╗ ██║██║  ██║█████╗  ██████╔╝██║     ██║   ██║██║   ██║█████╗  ██████╔╝
 ██║   ██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗██║     ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗
 ╚██████╔╝██║ ╚████║██████╔╝███████╗██║  ██║╚██████╗╚██████╔╝ ╚████╔╝ ███████╗██║  ██║
  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝
EOF
    echo -e "${NC}"
}

print_header_box() {
    if [[ $HAS_GUM -eq 1 ]]; then
        gum style \
            --border double \
            --margin "0 1 1 1" \
            --padding "1 3" \
            --border-foreground 39 \
            --foreground 255 \
            --bold \
            "🕵️  OMARCHY UNDERCOVER  •  THE ULTIMATE DESKTOP TRANSFORMATION SUITE" \
            "   macOS Sequoia Frosted Glass  ╳  Windows 11 Fluent Acrylic        " \
            "   Release v3.0.0  •  Engineered by misternegative21                "
    else
        echo -e "${BLUE}${BOLD}┌────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BLUE}${BOLD}│${WHITE}  🕵️  OMARCHY UNDERCOVER  •  THE ULTIMATE DESKTOP TRANSFORMATION SUITE   ${BLUE}│${NC}"
        echo -e "${BLUE}${BOLD}│${CYAN}   macOS Sequoia Frosted Glass  ╳  Windows 11 Fluent Acrylic         ${BLUE}│${NC}"
        echo -e "${BLUE}${BOLD}│${GRAY}   Release v3.0.0  •  Engineered by misternegative21                 ${BLUE}│${NC}"
        echo -e "${BLUE}${BOLD}└────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
    fi
}

run_animated_step() {
    local step_num="$1"
    local total_steps="$2"
    local spinner_type="$3"
    local title="$4"
    local cmd="$5"

    local prefix="[${step_num}/${total_steps}]"

    if [[ $HAS_GUM -eq 1 ]]; then
        gum spin --spinner "$spinner_type" --title "$prefix $title" -- bash -c "$cmd" 2>/dev/null || eval "$cmd"
        gum style --foreground 48 "  ✔ $prefix $title"
    else
        echo -ne "${CYAN}${BOLD}${prefix} ${YELLOW}⏳ ${title}...${NC}\r"
        eval "$cmd"
        echo -e "${GREEN}${BOLD}  ✔ ${prefix} ${WHITE}${title}${NC}                      "
    fi
    sleep 0.05
}

main() {
    print_logo
    print_header_box

    echo -e "${WHITE}${BOLD}⚡ Initializing Deployment Pipeline:${NC}\n"

    # Step 1: Destination Directories
    run_animated_step "1" "8" "dot" "Configuring directory architecture in ~/.config & ~/.local" '
        mkdir -p "$CONFIG_DIR/wallpapers" "$CONFIG_DIR/waybar" "$CONFIG_DIR/shell" "$CONFIG_DIR/plugins" "$CONFIG_DIR/themes" "$CONFIG_DIR/rofi" "$CONFIG_DIR/gtk" "$CONFIG_DIR/assets"
        mkdir -p "$HOME/.config/omarchy/themes" "$HOME/.config/omarchy/plugins"
        mkdir -p "$LOCAL_BIN" "$APPS_DIR" "$ICONS_DIR/hicolor/scalable/apps" "$ICONS_DIR/mac-dock" "$FONTS_DIR"
    '

    # Step 2: Authentic Typography Stack
    run_animated_step "2" "8" "monkey" "Installing Apple SF Pro, SF Mono, Segoe UI & Cascadia Code" '
        if [[ -d "$SCRIPT_DIR/assets/fonts" ]]; then
            cp -rf "$SCRIPT_DIR/assets/fonts/"* "$FONTS_DIR/" 2>/dev/null || true
        fi
        fc-cache -f "$FONTS_DIR" >/dev/null 2>&1 || true
    '

    # Step 3: Vector Icon Engines & SVGs
    run_animated_step "3" "8" "line" "Deploying vector app icons, dock suite, and custom emblems" '
        mkdir -p "$ICONS_DIR/win11" "$ICONS_DIR/mac-dock"
        if [[ -d "$SCRIPT_DIR/assets/mac-dock" ]]; then
            cp -rf "$SCRIPT_DIR/assets/mac-dock/"* "$ICONS_DIR/mac-dock/" 2>/dev/null || true
        fi
        if [[ -d "$SCRIPT_DIR/assets/icons/win11" ]]; then
            cp -rf "$SCRIPT_DIR/assets/icons/win11/"* "$ICONS_DIR/win11/" 2>/dev/null || true
        fi
        if [[ -d "$SCRIPT_DIR/assets/icons" ]]; then
            cp -rf "$SCRIPT_DIR/assets/icons/"* "$ICONS_DIR/hicolor/scalable/apps/" 2>/dev/null || true
        fi
        gtk-update-icon-cache -f -t "$ICONS_DIR/hicolor" >/dev/null 2>&1 || true
    '

    # Step 4: 6K & 4K Authentic Wallpapers
    run_animated_step "4" "8" "pulse" "Deploying 6K & 4K macOS Sequoia & Windows 11 Bloom wallpapers" '
        if [[ -d "$SCRIPT_DIR/assets/wallpapers" ]]; then
            cp -rf "$SCRIPT_DIR/assets/wallpapers/"* "$CONFIG_DIR/wallpapers/" 2>/dev/null || true
        fi
    '

    # Step 5: Quickshell (Omarchy 4.0+) Themes, Widgets & Layouts
    run_animated_step "5" "8" "points" "Compiling Quickshell 4.0 QML widgets, themes & Waybar layouts" '
        if [[ -d "$SCRIPT_DIR/configs/shell" ]]; then
            cp -rf "$SCRIPT_DIR/configs/shell/"* "$CONFIG_DIR/shell/" 2>/dev/null || true
        fi
        if [[ -d "$SCRIPT_DIR/configs/quickshell" ]]; then
            mkdir -p "$CONFIG_DIR/quickshell"
            cp -rf "$SCRIPT_DIR/configs/quickshell/"* "$CONFIG_DIR/quickshell/" 2>/dev/null || true
        fi
        if [[ -d "$SCRIPT_DIR/configs/plugins" ]]; then
            cp -rf "$SCRIPT_DIR/configs/plugins/"* "$CONFIG_DIR/plugins/" 2>/dev/null || true
            cp -rf "$SCRIPT_DIR/configs/plugins/"* "$HOME/.config/omarchy/plugins/" 2>/dev/null || true
        fi
        if [[ -d "$SCRIPT_DIR/configs/omarchy-theme" ]]; then
            cp -rf "$SCRIPT_DIR/configs/omarchy-theme/"* "$CONFIG_DIR/themes/" 2>/dev/null || true
            cp -rf "$SCRIPT_DIR/configs/omarchy-theme/"* "$HOME/.config/omarchy/themes/" 2>/dev/null || true
        fi
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

    # Step 6: CLI State Machine, Start Menu & Network Managers
    run_animated_step "6" "8" "globe" "Installing executables, start menu & wireless managers into ~/.local/bin" '
        if [[ -d "$SCRIPT_DIR/scripts" ]]; then
            for s in "$SCRIPT_DIR/scripts/"*; do
                if [[ -f "$s" ]]; then
                    cp -f "$s" "$LOCAL_BIN/"
                    chmod +x "$LOCAL_BIN/$(basename "$s")"
                fi
            done
        fi
    '

    # Step 7: Desktop Integration & Splash Screen Launchers
    run_animated_step "7" "8" "minidot" "Registering desktop applications and evaporating splash screen" '
        if [[ -f "$SCRIPT_DIR/assets/omarchy-undercover.desktop" ]]; then
            cp -f "$SCRIPT_DIR/assets/omarchy-undercover.desktop" "$APPS_DIR/"
        fi
        if [[ -f "$SCRIPT_DIR/assets/omarchy-settings.desktop" ]]; then
            cp -f "$SCRIPT_DIR/assets/omarchy-settings.desktop" "$APPS_DIR/"
        fi
        update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
    '

    # Step 8: Hyprland Dynamic Modules & Keybindings
    run_animated_step "8" "8" "dot" "Synchronizing Hyprland physics, spring curves & Super+Alt+U" '
        mkdir -p "$HOME/.config/hypr"
        if [[ -f "$SCRIPT_DIR/configs/hypr/mac-mode.lua" ]]; then
            cp -f "$SCRIPT_DIR/configs/hypr/mac-mode.lua" "$HOME/.config/hypr/mac-mode.lua"
        fi
        if [[ -f "$SCRIPT_DIR/configs/hypr/windows-mode.lua" ]]; then
            cp -f "$SCRIPT_DIR/configs/hypr/windows-mode.lua" "$HOME/.config/hypr/windows-mode.lua"
        fi
        if [[ -f "$HOME/.config/hypr/bindings.lua" ]]; then
            if ! grep -q "omarchy-undercover --toggle" "$HOME/.config/hypr/bindings.lua"; then
                echo -e "\n-- Global Omarchy Undercover Mode Toggle (Super + Alt + U)\no.bind(\"SUPER + ALT + U\", \"Toggle Undercover Mode\", \"omarchy-undercover --toggle\")" >> "$HOME/.config/hypr/bindings.lua"
            fi
        fi
        hyprctl reload >/dev/null 2>&1 || true
    '

    echo ""
    local opt_arg="${1:-}"
    case "$opt_arg" in
        1|--mac|--mac-dark|mac) CHOSEN="🍏 Apple macOS Sequoia (Dark)" ;;
        2|--mac-light|mac-light) CHOSEN="☀️ Apple macOS Sequoia (Light)" ;;
        3|--w11|--win11|--windows|win11-dark) CHOSEN="🪟 Windows 11 Fluent (Dark)" ;;
        4|--w11-light|--win11-light|win11-light) CHOSEN="🌅 Windows 11 Fluent (Light)" ;;
        *)
            if [[ $HAS_GUM -eq 1 && -t 0 ]]; then
                gum style --foreground 39 --bold "✨ Select your initial desktop transformation preset:"
                CHOSEN=$(gum choose \
                    "🍏 Apple macOS Sequoia (Dark)" \
                    "☀️ Apple macOS Sequoia (Light)" \
                    "🪟 Windows 11 Fluent (Dark)" \
                    "🌅 Windows 11 Fluent (Light)")
            elif [[ -t 0 ]]; then
                echo -e "${CYAN}${BOLD}✨ Select your initial desktop transformation preset:${NC}"
                echo -e "  ${PURPLE}1)${NC} 🍏 Apple macOS Sequoia (Dark)"
                echo -e "  ${YELLOW}2)${NC} ☀️ Apple macOS Sequoia (Light)"
                echo -e "  ${BLUE}3)${NC} 🪟 Windows 11 Fluent (Dark)"
                echo -e "  ${PINK}4)${NC} 🌅 Windows 11 Fluent (Light)"
                read -p "  Enter choice [1-4]: " opt
                case "$opt" in
                    1) CHOSEN="🍏 Apple macOS Sequoia (Dark)" ;;
                    2) CHOSEN="☀️ Apple macOS Sequoia (Light)" ;;
                    3) CHOSEN="🪟 Windows 11 Fluent (Dark)" ;;
                    4) CHOSEN="🌅 Windows 11 Fluent (Light)" ;;
                    *) CHOSEN="🍏 Apple macOS Sequoia (Dark)" ;;
                esac
            else
                CHOSEN="🍏 Apple macOS Sequoia (Dark)"
            fi
            ;;
    esac

    echo ""
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
            --margin "1 1" \
            --padding "1 3" \
            --border-foreground 48 \
            --foreground 255 \
            --bold \
            "🎉 OMARCHY UNDERCOVER SUCCESSFULLY INSTALLED & ACTIVATED!" \
            "" \
            "  ⚡ Super + Alt + U    ➔  Cycle 4-Mode Presets (Mac ➔ Win11)" \
            "  ⚡ Super + B          ➔  Toggle Taskbar / Dock Autohide" \
            "  ⚡ Super + Space / Win➔  Spotlight Search / Start Menu" \
            "  ⚡ Super + Tab        ➔  Mission Control / Task View" \
            "  ⚡ Super + N          ➔  Widget Center / Action Center" \
            "  ⚡ Settings App       ➔  omarchy-undercover-settings"
    else
        echo -e "${GREEN}${BOLD}┌────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${GREEN}${BOLD}│  🎉 OMARCHY UNDERCOVER SUCCESSFULLY INSTALLED & ACTIVATED!            │${NC}"
        echo -e "${GREEN}${BOLD}├────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${WHITE}  • ${YELLOW}Super + Alt + U${WHITE}    ➔  Cycle 4-Mode Presets (Mac ➔ Win11)            │${NC}"
        echo -e "${WHITE}  • ${YELLOW}Super + B${WHITE}          ➔  Toggle Taskbar / Dock Autohide                │${NC}"
        echo -e "${WHITE}  • ${YELLOW}Super + Space / Win${WHITE}➔  Spotlight Search / Start Menu                 │${NC}"
        echo -e "${WHITE}  • ${YELLOW}Super + Tab${WHITE}        ➔  Mission Control / Task View                   │${NC}"
        echo -e "${WHITE}  • ${YELLOW}Super + N${WHITE}          ➔  Widget Center / Action Center                 │${NC}"
        echo -e "${WHITE}  • ${CYAN}Settings App${WHITE}       ➔  ${CYAN}omarchy-undercover-settings${WHITE}                   │${NC}"
        echo -e "${GREEN}${BOLD}└────────────────────────────────────────────────────────────────────────┘${NC}"
    fi
}

main "$@"
