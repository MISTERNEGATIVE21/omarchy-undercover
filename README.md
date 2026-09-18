# Omarchy Undercover

[![Release](https://img.shields.io/github/v/release/MISTERNEGATIVE21/omarchy-undercover?style=flat-square)](https://github.com/MISTERNEGATIVE21/omarchy-undercover/releases)
[![Compositor](https://img.shields.io/badge/compositor-Hyprland-00f2fe?style=flat-square)](https://hyprland.org)
[![Engine](https://img.shields.io/badge/engine-Quickshell%20%7C%20Waybar-ff2d55?style=flat-square)](https://github.com/MISTERNEGATIVE21/omarchy-undercover)
[![License](https://img.shields.io/badge/license-GPL--3.0--or--later-green?style=flat-square)](LICENSE)

Omarchy Undercover is a desktop transformation plugin for Omarchy Hyprland. It allows users to switch between a native macOS Sequoia interface, a Windows 11 Fluent environment, and the baseline Omarchy desktop on demand.

The suite configures status bars, docks, application launchers, window rules, compositor animations, and typography to deliver an authentic look and feel across both Quickshell (Omarchy 4.0+) and Waybar environments.

---

## Features

### Apple macOS Sequoia Mode
* Frosted glass top menu bar with Apple menu, global application menu, and Control Center.
* Auto-sizing macOS dock with responsive scaling, magnification, and running app indicators.
* Spotlight application and file search (<kbd>Super</kbd> + <kbd>Space</kbd>).
* Mission Control window switcher (<kbd>Super</kbd> + <kbd>Tab</kbd>).
* macOS-style window tiling and snap hotkeys.
* SF Pro typography, authentic traffic-light window controls, and spring physics animations.

### Windows 11 Fluent Mode
* Centered taskbar with Start menu, search, live weather flyout, and system tray.
* Windows 11 Start menu with pinned application grid and search integration.
* Quick Settings and Action Center flyouts with volume, brightness, Wi-Fi, and Bluetooth controls.
* Task View window switcher (<kbd>Super</kbd> + <kbd>Tab</kbd>) and Snap Assist layouts.
* Segoe UI typography, flat window styling, and cubic bezier animation curves.

### Plugin Integration & Tray Switcher
* Self-contained plugin architecture adhering to the Omarchy Plugin Manifest Schema (v1).
* Modular status bar widget with a multi-state tray icon for cycling or toggling modes.
* Non-destructive configuration management with automated baseline backup and restore.
* Seamless fallback to Waybar for legacy installations.

---

## Installation

Omarchy Undercover is packaged as an official Omarchy shell plugin.

### Install via Omarchy CLI

```bash
omarchy plugin add https://github.com/MISTERNEGATIVE21/omarchy-undercover.git --enable --yes
```

This clones the repository into `~/.config/omarchy/plugins/omarchy-undercover`, validates the manifest, links modular widgets into the shell plugin directory, and registers the global toggle keybindings.

### Enable the Bar / Tray Widget

To place the mode switcher icon in your status bar:

```bash
omarchy plugin enable omarchy-undercover --section right
```

---

## Usage

### Switching Modes via CLI

```bash
# macOS Sequoia (Dark)
omarchy-undercover -mac

# macOS Sequoia (Light)
omarchy-undercover -mac-light

# Windows 11 Fluent (Dark)
omarchy-undercover -w11

# Windows 11 Fluent (Light)
omarchy-undercover -w11-light

# Toggle between Undercover mode and baseline Omarchy desktop
omarchy-undercover --toggle

# Restore baseline Omarchy desktop configuration
omarchy-undercover --restore
```

### Mode Switcher Widget

When placed on the bar, the Undercover widget displays the active mode emblem and provides instant control:
* **Left-Click**: Opens the Undercover Control Center flyout.
* **Right-Click**: Fast-cycles between macOS, Windows 11, and baseline Omarchy.
* **Middle-Click**: Toggles between the current disguise and baseline Omarchy.
* **Scroll Wheel**: Cycles forward or backward through available modes.

---

## Keyboard Shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>U</kbd> | Toggle Undercover Mode | Cycles between active disguise and default Omarchy desktop |
| <kbd>Super</kbd> + <kbd>Space</kbd> | Spotlight / Start Menu | Opens macOS Spotlight or Windows 11 Start menu |
| <kbd>Super</kbd> + <kbd>Tab</kbd> | Mission Control / Task View | Opens interactive window switcher |
| <kbd>Super</kbd> + <kbd>E</kbd> | File Manager | Launches Flea file manager configured with active mode layout |
| <kbd>Super</kbd> + <kbd>B</kbd> | Toggle Taskbar / Bar | Toggles status bar or dock visibility |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>B</kbd> | Toggle Auto-Hide | Enables or disables edge-sensing auto-hide daemon |
| <kbd>Super</kbd> + <kbd>D</kbd> | Show Desktop | Minimizes or restores all visible windows |
| <kbd>Super</kbd> + <kbd>N</kbd> | Notifications / Widgets | Opens Notification Center or Action Center |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + Arrows | macOS Tiling | Tiles active window to left/right halves or corners (Mac mode) |
| <kbd>Super</kbd> + Arrows | Windows Snap | Snaps active window to left/right halves or maximizes (Windows mode) |
| <kbd>Alt</kbd> + <kbd>F4</kbd> | Close Window | Closes active application window |

---

## Configuration

Configuration is stored in `~/.config/omarchy/plugins/omarchy-undercover/settings.conf`:

```ini
# Active Mode: windows | mac | omarchy
MODE=mac

# Theme variant: dark | light
THEME_VARIANT=dark

# Status bar backend: auto | quickshell | waybar
SHELL_BACKEND=auto

# macOS Dock settings
DOCK_SIZE=56
DOCK_MAX_ITEMS=24
DOCK_TRANSPARENCY=76
ENABLE_MAC_DOCK=true

# Windows 11 Taskbar settings
TASKBAR_ALIGNMENT=center
TASKBAR_TRANSPARENT=false

# Intelligent edge auto-hide
AUTOHIDE=false
```

Custom dock and taskbar pinned applications can be configured in `defaults.json` within the plugin directory.

---

## Architecture

1. **Quickshell Host Integration (Omarchy 4.0+)**:
   Status bar components are loaded natively as Quickshell `BarWidget` and `Panel` items. The main service (`Service.qml`) synchronizes Hyprland state files and dynamic layer rules on startup and upon configuration changes.
2. **Hyprland Dynamic Toggles**:
   Keybindings and window rules are deployed to `~/.local/state/omarchy/toggles/hypr/` (`undercover.lua` and `undercover.conf`). This enables hot-reloading via `hyprctl reload` without modifying the user's primary compositor configuration.
3. **IPC Interface**:
   External scripts and keyboard handlers communicate with the running shell instance over Quickshell IPC via the `omarchy-undercover` and `omarchy-undercover-service` targets.
4. **Waybar & Standalone Fallback**:
   On systems without Quickshell, the suite falls back to Waybar configurations (`configs/waybar/config-win.jsonc` and `config-mac.jsonc`), ensuring full compatibility.

---

## Requirements

* **Omarchy Linux** (v3.0+ or v4.0+ Quattro)
* **Hyprland** (Wayland compositor)
* **Quickshell** (`omarchy-shell`, standard on Omarchy 4.0+) or **Waybar**
* **Flea** (`flea`, Omarchy native file manager)
* **Rofi-Wayland** (launcher and window switcher)
* **PipeWire / WirePlumber** (`wpctl`)
* **NetworkManager** (`nmcli`) and **BlueZ** (`bluetoothctl`)

---

## Uninstallation

To remove the plugin and restore default settings:

```bash
# Disable and remove the plugin
omarchy plugin disable omarchy-undercover
omarchy plugin remove omarchy-undercover

# Restore baseline configuration
omarchy-undercover --restore
```

---

## License

GNU General Public License v3.0 or later (GPL-3.0-or-later). See [LICENSE](LICENSE) for details.
