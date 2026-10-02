# Omarchy Undercover (v6.1.1)

[![Omarchy Verified](https://img.shields.io/badge/omarchy-verified_plugin-00c853?style=flat-square&logo=archlinux)](https://github.com/MISTERNEGATIVE21/omarchy-undercover)
[![Version](https://img.shields.io/badge/version-v6.1.1?style=flat-square)](https://github.com/MISTERNEGATIVE21/omarchy-undercover/releases/tag/v6.1.1)
[![Release](https://img.shields.io/github/v/release/MISTERNEGATIVE21/omarchy-undercover?style=flat-square)](https://github.com/MISTERNEGATIVE21/omarchy-undercover/releases)
[![Compositor](https://img.shields.io/badge/compositor-Hyprland-00f2fe?style=flat-square)](https://hyprland.org)
[![Engine](https://img.shields.io/badge/engine-Quickshell%20%7C%20Waybar-ff2d55?style=flat-square)](https://github.com/MISTERNEGATIVE21/omarchy-undercover)
[![License](https://img.shields.io/badge/license-GPL--3.0--or--later-green?style=flat-square)](LICENSE)

![Omarchy Undercover Preview](preview.png)

An official **verified Omarchy plugin** that brings a complete desktop camouflage and transformation suite to [Omarchy](https://omarchy.org) Hyprland. Switch between an authentic Apple macOS Sequoia interface, a Windows 11 Fluent environment, and your baseline Omarchy desktop on demand with zero configuration conflicts.

Designed for presentations, shared screen privacy, or personal preference, Omarchy Undercover dynamically reconfigures status bars, docks, application launchers, window rules, compositor animations, and typography across both Quickshell (Omarchy 4.0+) and Waybar environments.

---

## What it does

- **Single bar icon & popup panel**: Multi-state status bar tray widget (`Widget.qml`) that displays the active disguise emblem and opens the native Quickshell Undercover Control Center (`Panel.qml`).
  - **Left-Click**: Opens the Undercover Control Center flyout.
  - **Right-Click**: Fast-cycles between macOS, Windows 11, and baseline Omarchy.
  - **Middle-Click**: Toggles between the active disguise and baseline Omarchy.
  - **Scroll Wheel**: Steps forward or backward through available presets.
- **One-touch camouflage toggle**: Switch between your chosen disguise and baseline Omarchy instantly via <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>U</kbd> or CLI.
- **Apple macOS Sequoia Mode**: Frosted glass top menu bar with Apple menu, global application menu, polygraph monitor, Control Center, auto-magnifying dock with active app running indicators, Spotlight search (<kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>Space</kbd> or Top Bar / Dock icon), Mission Control window switcher (<kbd>Super</kbd> + <kbd>Tab</kbd>), and authentic SF Pro typography.
- **Windows 11 Fluent Mode**: Centered taskbar with Start menu, search integration, live weather widget flyout, Quick Settings & Action Center (<kbd>Super</kbd> + <kbd>A</kbd>), Task View overview (<kbd>Super</kbd> + <kbd>Tab</kbd>), Snap Assist tiling (<kbd>Super</kbd> + <kbd>Z</kbd>), and authentic Segoe UI typography.
- **Transparent Taskbar Preset**: Zero-border acrylic glass taskbar mode seamlessly blending desktop wallpaper with floating centered icons.
- **Zero configuration conflicts**: Completely non-destructive configuration management. Backs up user baseline upon initial activation and restores cleanly without deleting custom dotfiles or polluting global paths.
- **Dual engine support**: Built natively for Quickshell (`omarchy-shell`, standard on Omarchy 4.0+) with automatic fallback to Waybar for legacy installations.

---

## What ships today

| Piece | What it is |
|---|---|
| `manifest.json` | Plugin definition adhering to the official Omarchy Plugin Schema (v1) |
| `Widget.qml` | Status bar presence and multi-state camouflage switcher icon |
| `Panel.qml` | Native Quickshell popup control center, mode cards, and quick settings |
| `Service.qml` | Background service synchronizing Hyprland state files and dynamic layer rules |
| `settings.conf` | User configuration file (`~/.config/omarchy/plugins/omarchy-undercover/settings.conf`) |
| `scripts/omarchy-undercover` | Primary CLI switcher, hotkey handler, and IPC controller |
| `scripts/backup-baseline` | Automated non-destructive backup of baseline compositor settings |
| `scripts/restore-baseline` | Clean restoration of user's original desktop environment |
| `scripts/generate_preview.py` | Automated high-resolution showcase preview generator |
| `configs/` | Hyprland window rules, rofi themes, and Waybar fallback configurations |
| `assets/` | Authentic SF Pro & Segoe UI fonts, wallpapers, and SVG icon sets |

---

## Screenshots

### Apple macOS Sequoia Mode

| macOS Sequoia Dark | macOS Sequoia Light |
| :---: | :---: |
| [![macOS Sequoia Dark](assets/screenshots/MacOS_Dark.png)](assets/screenshots/MacOS_Dark.png) | [![macOS Sequoia Light](assets/screenshots/MacOS_Light.png)](assets/screenshots/MacOS_Light.png) |
| *Night-mode frosted menu bar with polygraph monitor, Control Center, and dynamic floating dock* | *Daylight aesthetic with high-vibrancy frosted menu bar, authentic light-mode dock, and Sequoia day wallpaper* |

### Windows 11 Fluent Mode

| Windows 11 Dark | Windows 11 Light |
| :---: | :---: |
| [![Windows 11 Dark](assets/screenshots/Windows11_Dark.png)](assets/screenshots/Windows11_Dark.png) | [![Windows 11 Light](assets/screenshots/Windows11_Light.png)](assets/screenshots/Windows11_Light.png) |
| *Centered taskbar with Start button, live weather feed, dark Bloom wallpaper, and system tray* | *Daylight acrylic taskbar with centered launcher, light Bloom wallpaper, and clean Segoe UI styling* |

| Windows 11 Transparent Taskbar |
| :---: |
| [![Windows 11 Transparent Taskbar](assets/screenshots/Windows11_Transparent.png)](assets/screenshots/Windows11_Transparent.png) |
| *Zero-border glass taskbar mode seamlessly blending desktop wallpaper with floating centered icons* |

---

## Features

### Apple macOS Sequoia Mode
* Frosted glass top menu bar with Apple menu, global application menu, and Control Center.
* Hidden Bar menu bar collapse and hide/unhide items toggle button.
* Auto-sizing macOS dock with responsive scaling, magnification, and running app indicators.
* Spotlight application and file search magnifier widget.
* Mission Control window switcher.
* SF Pro typography, authentic traffic-light window controls, and spring physics animations.

### Windows 11 Fluent Mode
* Centered taskbar with Start menu, search, live weather flyout, and system tray.
* Windows 11 Start menu with pinned application grid and search integration.
* Quick Settings and Action Center flyouts with volume, brightness, Wi-Fi, and Bluetooth controls.
* Task View window switcher and Snap Assist layouts.
* Segoe UI typography, flat window styling, and cubic bezier animation curves.

### Plugin Integration & Tray Switcher
* Self-contained plugin architecture adhering to the Omarchy Plugin Manifest Schema (v1).
* Ultra-responsive 60fps animations, throttled low-latency hardware controls, and reduced memory footprint.
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

Undercover provides configurable, platform-authentic shortcuts for both Windows 11 and macOS Sequoia modes. All shortcuts can be customized or toggled on/off in **Settings → Shortcuts**.

> [!NOTE]
> Core Omarchy keybindings (such as <kbd>Super</kbd> + <kbd>W</kbd> for **Close Window**) are strictly protected from collisions. The Windows 11 Widgets Board uses <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>W</kbd> by default.

### Default Global Shortcuts
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>U</kbd> | Toggle Undercover Mode | Cycles between active disguise preset and default Omarchy desktop |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>B</kbd> | Toggle Auto-Hide | Enables or disables edge-sensing auto-hide daemon |

### Windows 11 Fluent Shortcuts
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| <kbd>Super</kbd> (tap) / <kbd>Super</kbd> + <kbd>Space</kbd> | Start Menu | Opens Windows 11 Start Menu |
| <kbd>Super</kbd> + <kbd>E</kbd> | File Explorer | Opens File Manager in Windows 11 layout |
| <kbd>Super</kbd> + <kbd>Tab</kbd> | Task View | Opens window switcher and desktop overview |
| <kbd>Super</kbd> + <kbd>A</kbd> | Action Center | Opens Quick Settings & Action Center flyout |
| <kbd>Super</kbd> + <kbd>N</kbd> | Notifications | Opens Notification Center and Calendar |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>W</kbd> | Widgets Board | Opens live weather, news, and hardware widgets |
| <kbd>Super</kbd> + <kbd>I</kbd> | Settings | Opens Undercover Settings / Control Center |
| <kbd>Super</kbd> + <kbd>D</kbd> | Show Desktop | Minimizes or restores all visible windows |
| <kbd>Super</kbd> + <kbd>Z</kbd> | Snap Assist | Opens Windows 11 Snap Layouts menu |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | Snipping Tool | Captures region screenshot to clipboard |
| <kbd>Super</kbd> + <kbd>V</kbd> | Clipboard History | Opens clipboard manager |
| <kbd>Alt</kbd> + <kbd>F4</kbd> | Close Window | Closes the active application window |
| <kbd>Super</kbd> + Arrows | Snap Assist Tiling | Snaps window to left/right halves or maximizes |

### Apple macOS Sequoia Shortcuts
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| <kbd>Super</kbd> + <kbd>Space</kbd> | Spotlight Search | Opens macOS Spotlight application/file search |
| <kbd>Super</kbd> + <kbd>Tab</kbd> | Mission Control | Opens window switcher |
| <kbd>Super</kbd> + <kbd>N</kbd> | Notifications & Widgets | Opens slide-out Notification Center & Widgets |
| <kbd>Super</kbd> + <kbd>,</kbd> | System Settings | Opens macOS System Settings |
| <kbd>Super</kbd> + <kbd>E</kbd> | Finder | Opens File Manager in macOS layout |
| <kbd>Super</kbd> + <kbd>M</kbd> | Minimize | Minimizes active application window |
| <kbd>Super</kbd> + <kbd>D</kbd> | Show Desktop | Pushes windows aside to reveal desktop |
| <kbd>Super</kbd> + <kbd>Q</kbd> | Quit Window | Closes active application window |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Q</kbd> | Lock Screen | Locks screen session |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + Arrows | macOS Window Tiling | Tiles window to left/right halves or zooms window |


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

To completely remove the plugin and restore your system to pristine normal settings:

```bash
# 1. Cleanly restore baseline desktop state and remove toggles/caches
omarchy-undercover --uninstall
# or with yui helper:
yui uninstall

# 2. Disable and remove the plugin directory (if installed via omarchy plugin)
omarchy plugin disable omarchy-undercover
omarchy plugin remove omarchy-undercover
```

---

## Credits & Acknowledgments

**Omarchy Undercover** is developed and maintained by **misternegative21** with inspiration, modules, and architecture incorporated from exceptional community plugins and contributors across the Omarchy Linux ecosystem.

### Creator & Lead Developer
* **misternegative21** ([@MISTERNEGATIVE21](https://github.com/MISTERNEGATIVE21))
  * Project creator, lead architecture, and maintenance.
  * Windows 11 Fluent and macOS Sequoia QuickShell desktop environments, widgets, popups, and transitions.
  * Dynamic multi-monitor management, display identification badges, and projection flyouts.
  * Camouflage switching engine, system layer rules, and packaging.

### Integrated Plugins & Upstream Contributors
* **crmne** ([@crmne](https://github.com/crmne)) — [crmne/omarchy-hyprmoncfg](https://github.com/crmne/omarchy-hyprmoncfg)
  * Display management foundations, multi-monitor configuration logic, layout profiles, VRR, and display orientation integration.
* **twiking** ([@twiking](https://github.com/twiking)) — [twiking/omasettings](https://github.com/twiking/omasettings)
  * Settings architecture, design patterns, and native system configuration controls for Windows and macOS settings panels.
* **ssupt** ([@ssupt](https://github.com/ssupt)) — [ssupt/omarchy-audio-control](https://github.com/ssupt/omarchy-audio-control)
  * High-performance PipeWire/WirePlumber audio daemon (`omarchy-audio-service`), speaker test suite, per-app audio stream mixer, and audio routing rules.
* **thisisgm** ([@thisisgm](https://github.com/thisisgm)) — [thisisgm/omarchy-flea-filemanager](https://github.com/thisisgm/omarchy-flea-filemanager)
  * Lightweight native Flea file manager integration and desktop shelf concepts.
* **Omarchy Core Team & Hyprland Communities**
  * Special thanks to the Omarchy maintainers, the Hyprland development community, and the QuickShell project for empowering rich Wayland desktop interfaces.

---

## License

Copyright (C) 2026 misternegative21 <supergogetavegito21@gmail.com>

Licensed under the GNU General Public License v3.0 or later (GPL-3.0-or-later). See [LICENSE](LICENSE) for details.
