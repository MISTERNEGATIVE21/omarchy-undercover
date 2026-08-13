# 🕵️ Omarchy Undercover (v2.5.0)

```
╭────────────────────────────────────────────────────────────────────────╮
│                                                                        │
│   🕵️  O M A R C H Y   U N D E R C O V E R   ( v 2 . 5 . 0 )            │
│   The Ultimate macOS Sequoia & Windows 11 Desktop Suite for Hyprland   │
│   Developed by misternegative21                                        │
│                                                                        │
╰────────────────────────────────────────────────────────────────────────╯
```

[![Release](https://img.shields.io/badge/Release-v2.5.0-blue.svg?style=for-the-badge)](https://github.com/MISTERNEGATIVE21/omarchy-undercover/releases)
[![Compositor](https://img.shields.io/badge/Compositor-Hyprland-00f2fe.svg?style=for-the-badge)](https://hyprland.org)
[![Theme Engine](https://img.shields.io/badge/Theme-Omarchy-ff2d55.svg?style=for-the-badge)](https://github.com/MISTERNEGATIVE21/omarchy-undercover)
[![License](https://img.shields.io/badge/License-GPL--3.0-green.svg?style=for-the-badge)](LICENSE)

> **The Ultimate Camouflage & Transformation Suite for Linux / Hyprland**  
> Effortlessly morph your Linux desktop into pixel-perfect **Apple macOS Sequoia** or **Windows 11 Fluent**, complete with authentic typography, native blur/mica glassmorphism, dynamic auto-sizing dock, live weather, functional radio toggles, and universal GTK/Qt theming.

---

## ⚡ 1-Line Quick Install

```bash
bash <(curl -sL https://raw.githubusercontent.com/MISTERNEGATIVE21/omarchy-undercover/master/install.sh)
```

Or clone and run the interactive TUI installer:

```bash
git clone https://github.com/MISTERNEGATIVE21/omarchy-undercover.git
cd omarchy-undercover
./install.sh
```

---

## 🌟 Transformation Presets (4-Mode Cycle)

Press **`Super + Alt + U`** to instantly cycle through the 4 environments:

$$\Large \text{🍏 macOS Dark} \longrightarrow \text{☀️ macOS Light} \longrightarrow \text{🪟 Win11 Dark} \longrightarrow \text{🌅 Win11 Light}$$

```
┌───────────────────────────────┬────────────────────────────────┐
│  🍏 Apple macOS Sequoia       │  🪟 Windows 11 Fluent          │
├───────────────────────────────┼────────────────────────────────┤
│  • Frosted Top Menu Bar       │  • Centered Mica Taskbar       │
│  • Dynamic Auto-Sizing Dock   │  • Task View & Start Button    │
│  • Full Vector Apple SVGs     │  • Live Geolocation Weather    │
│  • Window Traffic Lights      │  • Windows 11 Start Menu       │
│  • SF Pro Text & Display      │  • Segoe UI & Cascadia Code    │
│  • Liga SFMono Nerd Font      │  • Action Center Quick Toggles │
│  • Spotlight (Super + Space)  │  • Real Wi-Fi / Bluetooth Sync │
└───────────────────────────────┴────────────────────────────────┘
```

---

## ⌨️ Global Keyboard Shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>U</kbd> | **Toggle Undercover Mode** | Cycles across `mac-dark` ➔ `mac-light` ➔ `win11-dark` ➔ `win11-light` |
| <kbd>Super</kbd> + <kbd>B</kbd> / <kbd>Win</kbd> + <kbd>B</kbd> | **Toggle Taskbar / Dock** | Instantly hides or shows the Waybar dock/taskbar |
| <kbd>Super</kbd> + <kbd>Space</kbd> / <kbd>Win</kbd> | **Spotlight / Start Menu** | Opens macOS Spotlight or Windows 11 Start menu |
| <kbd>Super</kbd> + <kbd>Tab</kbd> | **Mission Control / Task View** | Opens interactive window switcher |
| <kbd>Super</kbd> + <kbd>N</kbd> | **Notification Center** | Opens macOS Widget Center or Windows 11 Action Center |
| <kbd>Super</kbd> + <kbd>D</kbd> / <kbd>Win</kbd> + <kbd>D</kbd> | **Show Desktop** | Minimizes/toggles all active windows |
| <kbd>Alt</kbd> + <kbd>F4</kbd> | **Close Window** | Closes active window (Windows mode) |

---

## 🛠️ CLI Command Reference

### Mode Switching
```bash
# 🍏 Switch to Apple macOS Sequoia (Dark mode)
omarchy-undercover -mac

# ☀️ Switch to Apple macOS Sequoia (Light mode)
omarchy-undercover -mac-light

# 🪟 Switch to Windows 11 Fluent (Dark mode)
omarchy-undercover -w11

# 🌅 Switch to Windows 11 Fluent (Light mode)
omarchy-undercover -w11-light

# 🔄 Cycle to next mode in 4-mode sequence
omarchy-undercover --toggle
```

### Auto-Hide Daemon Control
```bash
# Enable smart mouse edge auto-hide (HiDPI calibrated)
omarchy-undercover --autohide on

# Disable auto-hide (keep dock permanently visible)
omarchy-undercover --autohide off
```

### GUI Control Center & System Settings
```bash
# Launch GTK4 / Libadwaita Undercover Settings App
omarchy-undercover-settings
```

---

## 🖼️ Included 6K & 4K Wallpapers Library
Stored in `~/.config/omarchy-undercover/wallpapers/`:
* `macOS-Sequoia-Dark.jpg` & `macOS-Sequoia-Light.jpg` (Official 6K Solar Noon/Midnight)
* `Sonoma-dark.jpg` & `Sonoma-light.jpg` (Official 4K Sonoma Ribbons)
* `Ventura-dark.jpg` & `Ventura-light.jpg` (Official 4K Ventura Flower)
* `Monterey-dark.jpg` & `Monterey-light.jpg` (Official 5K Monterey Waves)
* `win11_bloom_dark.jpg` & `win11_bloom_light.jpg` (Official 4K Windows 11 Bloom)
* `win11_flow_dark.jpg` (Official 4K Flow Dark)
* `ios18_dark.jpg` & `ios18_light.jpg` (Official 4K iOS 18 Beams)

---

## 📜 License
GPL-3.0-or-later © **[misternegative21](https://github.com/MISTERNEGATIVE21)**
