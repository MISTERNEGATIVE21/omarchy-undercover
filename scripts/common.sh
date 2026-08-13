#!/usr/bin/env bash
#
# Omarchy Undercover - Core Utilities & Rollback Engine
# SPDX-License-Identifier: GPL-3.0-or-later
#
# omarchy:summary=Core transactional engine and utility functions for Omarchy Undercover
# omarchy:args=[internal-library]

# Standard output helpers
msg() {
    echo -e "\e[32m✔\e[0m  $1"
    notify_omarchy "Omarchy Undercover" "$1" "󰖔" "normal"
}

warn() {
    echo -e "\e[33m⚠\e[0m  $1" >&2
    notify_omarchy "Omarchy Undercover Warning" "$1" "󰀦" "normal"
}

error() {
    echo -e "\e[31m✖\e[0m  $1" >&2
    notify_omarchy "Omarchy Undercover Error" "$1" "󰅙" "critical"
    exit 1
}

command_exists() { command -v "$1" &>/dev/null; }

# Omarchy Native Notification Helper
notify_omarchy() {
    local headline="$1"
    local body="${2:-}"
    local glyph="${3:-󰖔}"
    local urgency="${4:-normal}"

    if command_exists omarchy-notification-send; then
        omarchy-notification-send "$headline" "$body" -g "$glyph" -u "$urgency" 2>/dev/null || true
    elif command_exists notify-send; then
        notify-send -u "$urgency" "$headline" "$body" 2>/dev/null || true
    fi
}

# ---------------------------------------------------------------------------
# Omarchy Version & Shell Backend Auto-Detection
# ---------------------------------------------------------------------------

detect_omarchy_version() {
    local ver=""
    if command_exists omarchy; then
        ver=$(omarchy version 2>/dev/null | head -n 1 || true)
    fi
    if [[ -z "$ver" && -f "/usr/share/omarchy/version" ]]; then
        ver=$(cat "/usr/share/omarchy/version" 2>/dev/null | head -n 1 || true)
    fi
    if [[ -z "$ver" && -n "${OMARCHY_PATH:-}" && -f "${OMARCHY_PATH}/version" ]]; then
        ver=$(cat "${OMARCHY_PATH}/version" 2>/dev/null | head -n 1 || true)
    fi

    if [[ -n "$ver" ]]; then
        echo "$ver"
    else
        echo "legacy"
    fi
}

get_omarchy_major_version() {
    local full_ver
    full_ver=$(detect_omarchy_version)
    if [[ "$full_ver" =~ ^([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "0"
    fi
}

is_quickshell_supported() {
    local major
    major=$(get_omarchy_major_version)
    if (( major >= 4 )); then
        return 0
    fi
    if command_exists omarchy-shell || command_exists quickshell; then
        if [[ -d "/usr/share/omarchy/shell" || -f "$HOME/.config/omarchy/shell.json" ]]; then
            return 0
        fi
    fi
    return 1
}

detect_shell_backend() {
    local pref
    pref=$(read_setting "SHELL_BACKEND" "auto")

    case "$pref" in
        quickshell|qs|omarchy-shell)
            echo "quickshell"
            return 0
            ;;
        waybar|legacy)
            echo "waybar"
            return 0
            ;;
        auto|*)
            if is_quickshell_supported; then
                echo "quickshell"
            elif command_exists waybar; then
                echo "waybar"
            elif is_quickshell_supported; then
                echo "quickshell"
            else
                echo "waybar"
            fi
            return 0
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Omarchy System Reload & Bar Helpers
# ---------------------------------------------------------------------------

omarchy_reload_waybar() {
    # 1. Kill any existing waybar processes
    pkill -9 -x waybar 2>/dev/null || true
    local retry=0
    while pgrep -x waybar >/dev/null && [[ $retry -lt 8 ]]; do
        sleep 0.05
        ((retry++))
    done
    pkill -9 -x waybar 2>/dev/null || true
    sleep 0.15

    # 2. Launch single instance
    nohup waybar >/tmp/waybar.log 2>&1 &
    disown 2>/dev/null || true

    # 3. Strict Self-Check: Enforce singleton
    sleep 0.35
    local pids=($(pgrep -x waybar))
    if [[ ${#pids[@]} -gt 1 ]]; then
        for ((i=1; i<${#pids[@]}; i++)); do
            kill -9 "${pids[$i]}" 2>/dev/null || true
        done
    elif [[ ${#pids[@]} -eq 0 ]]; then
        nohup waybar >/tmp/waybar.log 2>&1 &
        disown 2>/dev/null || true
    fi
}

omarchy_reload_quickshell() {
    # Kill any leftover waybar processes so they do not overlap with quickshell
    pkill -9 -x waybar 2>/dev/null || true

    if command_exists omarchy; then
        omarchy restart shell 2>/dev/null || true
    elif command_exists omarchy-restart-shell; then
        omarchy-restart-shell 2>/dev/null || true
    fi
}

omarchy_reload_bar() {
    local backend
    backend=$(detect_shell_backend)
    if [[ "$backend" == "quickshell" ]]; then
        omarchy_reload_quickshell
    else
        omarchy_reload_waybar
    fi
}

omarchy_toggle_bar() {
    local backend
    backend=$(detect_shell_backend)
    if [[ "$backend" == "quickshell" ]]; then
        if command_exists omarchy; then
            omarchy toggle bar 2>/dev/null || true
        elif command_exists omarchy-toggle-bar; then
            omarchy-toggle-bar 2>/dev/null || true
        elif command_exists omarchy-toggle; then
            omarchy-toggle bar-off toggle 2>/dev/null || true
        else
            pkill -SIGUSR1 -x waybar 2>/dev/null || true
        fi
    else
        pkill -SIGUSR1 -x waybar 2>/dev/null || true
    fi
}

omarchy_reload_hyprland() {
    if command_exists omarchy-restart-hyprctl; then
        omarchy-restart-hyprctl 2>/dev/null || true
    elif command_exists hyprctl; then
        hyprctl reload 2>/dev/null || true
    fi
}

omarchy_reload_mako() {
    if command_exists omarchy-restart-mako; then
        omarchy-restart-mako 2>/dev/null || true
    elif command_exists makoctl; then
        makoctl reload 2>/dev/null || true
    fi
}

# Set the GNOME/GTK interface theme, falling back to direct gsettings when the
# Omarchy theme helper is unavailable or silently fails.
omarchy_set_gnome_theme() {
    local theme="$1"
    local icon_theme="$2"
    local cursor_theme="$3"
    local cursor_size="${4:-24}"

    if command_exists omarchy-theme-set-gnome; then
        omarchy-theme-set-gnome "$theme" 2>/dev/null || true
    fi

    if command_exists gsettings; then
        [[ -n "$theme" ]] && gsettings set org.gnome.desktop.interface gtk-theme "$theme" 2>/dev/null || true
        [[ -n "$icon_theme" ]] && gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
        [[ -n "$cursor_theme" ]] && gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme" 2>/dev/null || true
        [[ -n "$cursor_size" ]] && gsettings set org.gnome.desktop.interface cursor-size "$cursor_size" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
    fi

    if command_exists hyprctl; then
        hyprctl setcursor "$cursor_theme" "$cursor_size" 2>/dev/null || true
    fi
}

# Backup/Restore Helpers
backup_config_dir() {
    local dir_name="$1"
    local backup_target_dir="$2"
    local source_dir="$HOME/.config/$dir_name"

    mkdir -p "$backup_target_dir"
    if [[ -d "$source_dir" ]]; then
        cp -a "$source_dir" "$backup_target_dir/$dir_name"
    else
        touch "$backup_target_dir/.absent_$dir_name"
    fi
}

restore_config_dir() {
    local dir_name="$1"
    local backup_target_dir="$2"
    local source_dir="$HOME/.config/$dir_name"

    if [[ -f "$backup_target_dir/.absent_$dir_name" ]]; then
        rm -rf "$source_dir"
    elif [[ -d "$backup_target_dir/$dir_name" ]]; then
        rm -rf "$source_dir"
        cp -a "$backup_target_dir/$dir_name" "$source_dir"
    fi
}

# Manifest Generator
create_manifest() {
    local backup_dir="$1"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local gtk_theme=""
    local icon_theme=""
    local cursor_theme=""

    if command_exists gsettings; then
        gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | sed -e "s/^'//" -e "s/'$//")
        icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | sed -e "s/^'//" -e "s/'$//")
        cursor_theme=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | sed -e "s/^'//" -e "s/'$//")
    fi

    cat <<EOF > "$backup_dir/manifest.json"
{
  "timestamp": "$timestamp",
  "omarchy_version": "$(detect_omarchy_version)",
  "shell_backend": "$(detect_shell_backend)",
  "gtk_theme": "$gtk_theme",
  "icon_theme": "$icon_theme",
  "cursor_theme": "$cursor_theme"
}
EOF
}

# Transactional Rollback Engine
rollback_transaction() {
    warn "Rolling back transaction..."
    if [[ -n "${BACKUP_DIR:-}" && -d "${BACKUP_DIR:-}" ]]; then
        for backup_item in "$BACKUP_DIR"/*; do
            if [[ -e "$backup_item" ]]; then
                item_name=$(basename "$backup_item")
                if [[ -d "$backup_item" ]]; then
                    restore_config_dir "$item_name" "$BACKUP_DIR"
                fi
            fi
        done
    fi
}

# ---------------------------------------------------------------------------
# Settings persistence (~/.config/omarchy-undercover/settings.conf)
# ---------------------------------------------------------------------------
undercover_settings_file() {
    echo "$HOME/.config/omarchy-undercover/settings.conf"
}

read_setting() {
    local key="$1" default="${2:-}"
    local file
    file=$(undercover_settings_file)
    local value="$default"
    if [[ -f "$file" ]]; then
        local found
        found=$(grep -E "^${key}=" "$file" 2>/dev/null | tail -1 | cut -d= -f2-)
        [[ -n "$found" ]] && value="$found"
    fi
    printf '%s' "$value"
}

write_setting() {
    local key="$1" value="$2"
    local file
    file=$(undercover_settings_file)
    mkdir -p "$(dirname "$file")"
    if [[ -f "$file" ]] && grep -qE "^${key}=" "$file"; then
        sed -i -E "s|^${key}=.*|${key}=${value}|" "$file"
    else
        printf '%s=%s\n' "$key" "$value" >> "$file"
    fi
}

# ---------------------------------------------------------------------------
# Hyprland Lua integration (Windows mode module)
# ---------------------------------------------------------------------------
WINDOWS_MARKER_START="-- >>> Omarchy Undercover Windows Mode <<<"
WINDOWS_MARKER_END="-- <<< Omarchy Undercover Windows Mode >>>"

enable_windows_hyprland() {
    local hypr_lua="$HOME/.config/hypr/hyprland.lua"
    local windows_lua="$HOME/.config/hypr/windows-mode.lua"
    local src_lua="${CONFIG_DIR:-$HOME/.config/omarchy-undercover}/hypr/windows-mode.lua"

    mkdir -p "$HOME/.config/hypr"
    if [[ ! -f "$src_lua" ]]; then
        src_lua="${SCRIPT_DIR:-.}/../configs/hypr/windows-mode.lua"
    fi
    if [[ -f "$src_lua" ]]; then
        cp "$src_lua" "$windows_lua"
        chmod 644 "$windows_lua"
    fi

    touch "$hypr_lua"
    if ! grep -qF -- "$WINDOWS_MARKER_START" "$hypr_lua"; then
        printf '\n-- %s\nrequire("hypr.windows-mode")\n-- %s\n' \
            "$WINDOWS_MARKER_START" "$WINDOWS_MARKER_END" >> "$hypr_lua"
        msg "Registered windows-mode.lua in Hyprland (Lua config)."
    fi
}

disable_windows_hyprland() {
    local hypr_lua="$HOME/.config/hypr/hyprland.lua"

    if [[ -f "$hypr_lua" ]]; then
        sed -i "/^-- ${WINDOWS_MARKER_START}$/,/^-- ${WINDOWS_MARKER_END}$/d" "$hypr_lua"
        sed -i '/^$/N;/^\n$/D' "$hypr_lua" 2>/dev/null || true
    fi
    rm -f "$HOME/.config/hypr/windows-mode.lua"
}
