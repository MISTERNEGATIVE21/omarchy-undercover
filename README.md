# 🕵️ Omarchy Undercover (v2.5.0)

> **The Ultimate Camouflage & Transformation Suite for Hyprland / Omarchy**  
> Effortlessly morph your Linux desktop into pixel-perfect **Apple macOS Sequoia** or **Windows 11 Fluent**, complete with authentic typography, native blur/mica glassmorphism, dynamic auto-sizing dock, live weather, and universal GTK/Qt theming.

Developed by **[misternegative21](https://github.com/MISTERNEGATIVE21)**.

---

## 🌟 Key Features

### 🍏 Apple macOS Sequoia Environment
* **Frosted Glass Top Menu Bar**: 30px translucent top bar with functional Apple Menu, Finder title, application menus (`File`, `Edit`, `View`, `Go`, `Window`, `Help`), live calendar clock, Siri launcher, and Control Center.
* **Dynamic Auto-Sizing Dock**: Floating bottom dock that shrink-wraps and dynamically resizes to tightly hug only active apps, complete with vector Apple icons (Finder, Launchpad, Safari, Messages, Music, Photos, App Store, Terminal, Settings) and active running app indicator dots (`•`).
* **Universal Window Traffic Lights**: True macOS circular window controls (🔴 `#FF5F56`, 🟡 `#FFBD2E`, 🟢 `#27C93F`) across GTK3, GTK4, and Libadwaita applications.
* **Spotlight & Mission Control**: Rofi Spotlight search (`Super + Space`) and Mission Control window switcher (`Super + Tab`).
* **Apple Typography Stack**: `SF Pro Text`, `SF Pro Display`, and `Liga SFMono Nerd Font`.

### 🪟 Windows 11 Fluent Environment
* **Centered Mica Acrylic Taskbar**: Centered taskbar pill housing the ⊞ Start button, Search capsule, **Task View** (`󱂬`), and running applications.
* **Live Geolocation Weather Widget**: Bottom-left real-time temperature and weather conditions (`🌦️ +27°C`) powered by `omarchy-weather` with intelligent caching.
* **Windows 11 Start Menu**: Bottom-anchored Start menu with Pinned grid, search bar, user profile, and power options.
* **Windows 11 Notification Center & Quick Settings**: Native Libadwaita panel (`Super + N`) with volume sliders, network toggles, and interactive calendar.
* **Microsoft Typography Stack**: `Segoe UI`, `Segoe UI Semibold`, and `Cascadia Code`.

### ⚡ Intelligent Performance & Integration
* **Smart Edge Auto-Hide Daemon**: Monitors cursor position with HiDPI scale factor calibration (`2560x1440` @ `1.6x`), revealing dock on bottom hover and smoothly hiding when mouse moves away.
* **5-Mode Cycle Switcher**: `mac-dark` ➔ `mac-light` ➔ `win11-dark` ➔ `win11-light` ➔ `omarchy baseline`.
* **Universal System Theming Dispatcher**: Instant broadcast of GTK themes, icon packs, typography, and cursor sizes across GSettings, GTK 3/4 `settings.ini`, GTK 2 `~/.gtkrc-2.0`, and XWayland `xsettingsd`.
* **GUI Control Center**: Modern GTK4 / Libadwaita settings application (`omarchy-undercover-settings`) with wallpaper gallery, blur sliders, and component reloaders.

---

## ⌨️ Global Keyboard Shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>U</kbd> | **Toggle Undercover Mode** | Cycles across `mac-dark` ➔ `mac-light` ➔ `win11-dark` ➔ `win11-light` ➔ `omarchy` |
| <kbd>Super</kbd> + <kbd>B</kbd> / <kbd>Win</kbd> + <kbd>B</kbd> | **Toggle Taskbar / Dock** | Instantly hides or shows the Waybar dock/taskbar |
| <kbd>Super</kbd> + <kbd>Space</kbd> / <kbd>Win</kbd> | **Spotlight / Start Menu** | Opens macOS Spotlight or Windows 11 Start menu |
| <kbd>Super</kbd> + <kbd>Tab</kbd> | **Mission Control / Task View** | Opens interactive window switcher |
| <kbd>Super</kbd> + <kbd>N</kbd> | **Notification Center** | Opens macOS Widget Center or Windows 11 Quick Settings |
| <kbd>Super</kbd> + <kbd>D</kbd> / <kbd>Win</kbd> + <kbd>D</kbd> | **Show Desktop** | Minimizes/toggles all active windows |
| <kbd>Alt</kbd> + <kbd>F4</kbd> | **Close Window** | Closes active window (Windows mode) |

---

## 🛠️ Command Reference

### Mode Switching
```bash
# Switch to Apple macOS Sequoia (Dark mode)
omarchy-undercover -mac

# Switch to Apple macOS Sequoia (Light mode)
omarchy-undercover -mac-light

# Switch to Windows 11 Fluent (Dark mode)
omarchy-undercover -w11

# Switch to Windows 11 Fluent (Light mode)
omarchy-undercover -w11-light

# Cycle to next mode in 5-mode sequence
omarchy-undercover --toggle

# Restore original Omarchy baseline configuration
omarchy-undercover --disable
```

### Auto-Hide Daemon Control
```bash
# Enable smart mouse edge auto-hide
omarchy-undercover --autohide on

# Disable auto-hide (keep dock permanently visible)
omarchy-undercover --autohide off
```

### GUI Control Center
```bash
# Launch GTK4 / Libadwaita Undercover Settings App
omarchy-undercover-settings
```

### Diagnostics & Integrity
```bash
# Display current active mode and configuration state
omarchy-undercover --status

# Perform deep verification of configs, themes, fonts, and assets
omarchy-undercover --verify
```

---

## 🖼️ Included Wallpapers Library (6K & 4K)
Stored in `~/.config/omarchy-undercover/wallpapers/`:
* `macOS-Sequoia-Dark.jpg` & `macOS-Sequoia-Light.jpg` (Official 6K Solar Noon/Midnight)
* `Sonoma-dark.jpg` & `Sonoma-light.jpg` (Official 4K Sonoma Ribbons)
* `Ventura-dark.jpg` & `Ventura-light.jpg` (Official 4K Ventura Flower)
* `Monterey-dark.jpg` & `Monterey-light.jpg` (Official 5K Monterey Waves)
* `win11_bloom_dark.jpg` & `win11_bloom_light.jpg` (Official 4K Windows 11 Bloom)
* `win11_flow_dark.jpg` (Official 4K Flow Dark)
* `ios18_dark.jpg` & `ios18_light.jpg` (Official 4K iOS 18 Beams)

---

## 📦 Installation & Setup

```bash
git clone https://github.com/MISTERNEGATIVE21/omarchy-undercover.git
cd omarchy-undercover
./scripts/omarchy-undercover-setup
```

---

## 📜 License
GPL-3.0-or-later © **misternegative21**
