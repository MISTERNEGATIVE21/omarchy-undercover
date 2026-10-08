#!/usr/bin/env bash
#
# Omarchy Undercover - Core Utilities & Rollback Engine
# SPDX-License-Identifier: GPL-3.0-or-later
#
# omarchy:summary=Core transactional engine and utility functions for Omarchy Undercover
# omarchy:args=[internal-library]

# ponytail: simple include guard prevents re-sourcing 500+ lines
[[ -n "${_UNDERCOVER_COMMON_SH_LOADED:-}" ]] && return 0
_UNDERCOVER_COMMON_SH_LOADED=1

if [[ -z "${SCRIPT_DIR:-}" || ! -f "${SCRIPT_DIR}/common.sh" ]]; then
    _C_SRC="${BASH_SOURCE[0]}"
    while [ -h "$_C_SRC" ]; do
        _C_DIR="$(cd -P "$(dirname "$_C_SRC")" && pwd)"
        _C_SRC="$(readlink "$_C_SRC")"
        [[ $_C_SRC != /* ]] && _C_SRC="$_C_DIR/$_C_SRC"
    done
    SCRIPT_DIR="$(cd -P "$(dirname "$_C_SRC")" && pwd)"
    unset _C_SRC _C_DIR
fi

if [[ -n "${SCRIPT_DIR:-}" && -d "${SCRIPT_DIR}" ]]; then
    if [[ ":$PATH:" != *":${SCRIPT_DIR}:"* ]]; then
        PATH="${SCRIPT_DIR}:${PATH}"
    fi
fi

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
    local log_dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/omarchy-undercover"
    mkdir -p -m 0700 "$log_dir" 2>/dev/null || true
    nohup waybar >"$log_dir/waybar.log" 2>&1 &
    disown 2>/dev/null || true

    # 3. Strict Self-Check: Enforce singleton
    sleep 0.35
    local pids=($(pgrep -x waybar))
    if [[ ${#pids[@]} -gt 1 ]]; then
        for ((i=1; i<${#pids[@]}; i++)); do
            kill -9 "${pids[$i]}" 2>/dev/null || true
        done
    elif [[ ${#pids[@]} -eq 0 ]]; then
        nohup waybar >"$log_dir/waybar.log" 2>&1 &
        disown 2>/dev/null || true
    fi
}

omarchy_reload_quickshell() {
    # Kill any leftover waybar processes so they do not overlap with quickshell
    pkill -9 -x waybar 2>/dev/null || true

    # Terminate any duplicate omarchy-launch-shell supervisors to prevent double bars
    local supervisors=()
    supervisors=($(pgrep -f "omarchy-launch-shell" 2>/dev/null || true))
    if (( ${#supervisors[@]} > 1 )); then
        pkill -TERM -f "omarchy-launch-shell" 2>/dev/null || true
        sleep 0.3
        pkill -9 -f "omarchy-launch-shell" 2>/dev/null || true
        while timeout 2 quickshell kill -p "/usr/share/omarchy/shell" --any-display >/dev/null 2>&1; do :; done
        pkill -9 -f "quickshell.*omarchy/shell" 2>/dev/null || true
        if command_exists omarchy; then
            omarchy restart shell 2>/dev/null || true
        elif command_exists omarchy-restart-shell; then
            omarchy-restart-shell 2>/dev/null || true
        fi
        return 0
    fi

    if command_exists omarchy-shell && omarchy-shell shell ping >/dev/null 2>&1; then
        omarchy-shell shell reloadConfig >/dev/null 2>&1 || true
    else
        # When restarting, terminate old supervisor first so dispatch does not leak duplicates
        pkill -TERM -f "omarchy-launch-shell" 2>/dev/null || true
        sleep 0.2
        if command_exists omarchy; then
            omarchy restart shell 2>/dev/null || true
        elif command_exists omarchy-restart-shell; then
            omarchy-restart-shell 2>/dev/null || true
        fi
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
        if [[ "$backup_target_dir" == "$source_dir"* ]]; then
            mkdir -p "$backup_target_dir/$dir_name"
            for item in "$source_dir"/*; do
                local base
                base="$(basename "$item")"
                if [[ "$base" != "plugins" && "$base" != "backups" ]]; then
                    cp -a "$item" "$backup_target_dir/$dir_name/" 2>/dev/null || true
                fi
            done
        else
            cp -a "$source_dir" "$backup_target_dir/$dir_name"
        fi
    else
        touch "$backup_target_dir/.absent_$dir_name"
    fi
}

restore_config_dir() {
    local dir_name="$1"
    local backup_target_dir="$2"

    # Directory traversal defense: ensure dir_name is a clean relative basename
    if [[ -z "$dir_name" || "$dir_name" == *".."* || "$dir_name" == *"/"* || "$dir_name" == *"\\"* ]]; then
        return 1
    fi

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
# Settings persistence (resolved inside official Omarchy plugin directory)
# ---------------------------------------------------------------------------
undercover_plugin_dir() {
    local base_dir="${SCRIPT_DIR:-.}"
    if [[ -f "$base_dir/manifest.json" ]]; then
        (cd "$base_dir" && pwd)
    elif [[ -f "$base_dir/../manifest.json" ]]; then
        (cd "$base_dir/.." && pwd)
    elif [[ -d "$HOME/.config/omarchy/plugins/omarchy-undercover" ]]; then
        echo "$HOME/.config/omarchy/plugins/omarchy-undercover"
    elif [[ -d "$HOME/.config/omarchy/plugins/undercover" ]]; then
        echo "$HOME/.config/omarchy/plugins/undercover"
    else
        echo "$HOME/.config/omarchy/plugins/omarchy-undercover"
    fi
}

undercover_config_dir() {
    undercover_plugin_dir
}

undercover_user_dir() {
    local udir="$HOME/.config/omarchy/plugins/omarchy-undercover"
    if [[ ! -d "$udir" && -d "$HOME/.config/omarchy/plugins/undercover" ]]; then
        udir="$HOME/.config/omarchy/plugins/undercover"
    fi
    mkdir -p "$udir" 2>/dev/null || true
    echo "$udir"
}

undercover_state_dir() {
    local sdir="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/undercover"
    mkdir -p "$sdir" 2>/dev/null || true
    echo "$sdir"
}

undercover_state_file() {
    echo "$(undercover_state_dir)/state"
}

undercover_settings_file() {
    local pdir
    pdir=$(undercover_plugin_dir)
    local cfg="$pdir/settings.conf"
    if [[ -w "$pdir" || ( -f "$cfg" && -w "$cfg" ) ]]; then
        if [[ ! -f "$cfg" ]]; then
            touch "$cfg" 2>/dev/null || true
        fi
        echo "$cfg"
    else
        local udir
        udir=$(undercover_user_dir)
        local ucfg="$udir/settings.conf"
        if [[ ! -f "$ucfg" ]]; then
            if [[ -f "$cfg" ]]; then
                cp -f "$cfg" "$ucfg" 2>/dev/null || true
            else
                touch "$ucfg" 2>/dev/null || true
            fi
        fi
        echo "$ucfg"
    fi
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
# Hyprland integration (Omarchy toggle and Lua modules)
# ---------------------------------------------------------------------------

enable_undercover_hyprland() {
    local mode="${1:-windows}"
    local toggles_dir="$HOME/.local/state/omarchy/toggles/hypr"
    local plugin_root=""

    if [[ -f "${SCRIPT_DIR}/../manifest.json" ]]; then
        plugin_root="$(cd "${SCRIPT_DIR}/.." && pwd)"
    elif [[ -d "$HOME/.config/omarchy/plugins/omarchy-undercover" ]]; then
        plugin_root="$HOME/.config/omarchy/plugins/omarchy-undercover"
    elif [[ -d "$HOME/.config/omarchy/plugins/undercover" ]]; then
        plugin_root="$HOME/.config/omarchy/plugins/undercover"
    fi

    mkdir -p "$toggles_dir"

    # Deploy undercover.lua to Omarchy dynamic toggles
    local src_toggle=""
    if [[ -f "$plugin_root/configs/hypr/undercover.lua" ]]; then
        src_toggle="$plugin_root/configs/hypr/undercover.lua"
    elif [[ -f "${SCRIPT_DIR}/../configs/hypr/undercover.lua" ]]; then
        src_toggle="${SCRIPT_DIR}/../configs/hypr/undercover.lua"
    fi
    if [[ -n "$src_toggle" ]]; then
        cp -f "$src_toggle" "$toggles_dir/undercover.lua"
        chmod 644 "$toggles_dir/undercover.lua"
    fi

    # In Omarchy 4.0+, .lua is strictly favored. If hyprland.lua is present, clean up legacy .conf.
    local undercover_conf="$toggles_dir/undercover.conf"
    if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
        rm -f "$undercover_conf"
    else
        # Legacy fallback only for pre-Omarchy 4.0 conf-based setups
        local conf_src=""
        if [[ "$mode" == "windows" || "$mode" == "win11" ]]; then
            conf_src="${plugin_root}/configs/hypr/windows-mode.conf"
        elif [[ "$mode" == "mac" || "$mode" == "ios" ]]; then
            conf_src="${plugin_root}/configs/hypr/mac-mode.conf"
        fi
        {
            echo "# Omarchy Undercover Dynamic Hyprland Toggle (legacy fallback)"
            echo "bind = SUPER ALT, u, exec, omarchy-undercover --toggle"
            if [[ -n "$conf_src" && -f "$conf_src" ]]; then
                echo "source = $conf_src"
            fi
        } > "$undercover_conf"
        chmod 644 "$undercover_conf"
    fi


    # Reload hyprland cleanly so dynamic toggles take effect
    if command_exists hyprctl; then
        hyprctl reload >/dev/null 2>&1 || true
    fi
}

disable_undercover_hyprland() {
    enable_undercover_hyprland "omarchy"
}

uninstall_undercover_hyprland() {
    rm -f "$HOME/.local/state/omarchy/toggles/hypr/undercover.lua" \
          "$HOME/.local/state/omarchy/toggles/hypr/undercover.conf" 2>/dev/null || true
    if command_exists hyprctl; then
        hyprctl reload >/dev/null 2>&1 || true
    fi
}

enable_windows_hyprland() {
    enable_undercover_hyprland "windows"
}

disable_windows_hyprland() {
    disable_undercover_hyprland
}

