# Windows 11 Start Menu, Taskbar Auto-Hide, Transparency Toggle & Fluid Animations Design Specification

## Overview
This specification details the enhancements to the Omarchy Undercover transformation suite for Windows 11 and macOS desktop modes. It provides an authentic Windows 11 Start Menu (in both Quickshell and GTK4/Python backends), a robust auto-hide taskbar daemon with active-menu locking, a dedicated Windows 11 transparency effects toggle in the Undercover Settings app, and fluid animations for window creation, minimizing, closing, and workspace transitions across both Windows 11 and macOS modes.

---

## 1. Windows 11 Start Menu (Dual Engine)

### 1.1 Visual Layout & Components
* **Positioning**: Bottom-anchored, elevated 12px above the taskbar, centered on screen (or left-aligned if classic alignment is selected).
* **Styling**: Rounded corners (16px), subtle specular border (`rgba(255,255,255,0.12)` in dark mode, `rgba(0,0,0,0.10)` in light mode), compositor drop shadow, and Mica/acrylic frosted glass when transparency is enabled.
* **Top Header & Search**:
  * Windows 11 search input with magnifying glass glyph, live character filtering of installed applications, clear button (`✕`), and Enter-to-launch (or browser search fallback).
* **Pinned Applications Section**:
  * 6×3 Grid of pinned applications with Fluent icons, labels, and hover glow.
  * Apps include Browser, Explorer, Settings, Terminal, VS Code, Store, Media Player, Calculator, Notepad, Spotify, etc.
* **"All apps >" Drawer**:
  * Seamless view transition from Pinned Grid to an alphabetical A–Z scrollable list of all installed applications with category headers.
* **Recommended Section**:
  * Recent documents and quick links with timestamps and icons.
* **User Profile & Power Bar**:
  * Bottom strip with user avatar, username (`$USER`), and quick account menu (Lock, Sign Out).
  * Windows 11 Power button (`⏻`) with interactive popover (*Lock, Sign Out, Sleep, Hibernate, Restart, Shut Down*).

### 1.2 Unified Invocation & Layer Handling
* `omarchy-win11-start`, `omarchy-win11-startmenu`, `omarchy-undercover-launcher`, Waybar click, and `SUPER` key all toggle the menu reliably without spawn conflicts.
* Auto-dismiss on focus loss, clicking outside the window, pressing Escape, or launching an application.

---

## 2. Taskbar Auto-Hide Engine

### 2.1 Triggering & Proximity
* **Bottom Edge Reveal**: Moving cursor to within 6px of the bottom edge reveals the taskbar immediately.
* **Hit-Box Retention**: When cursor is inside the taskbar bounding area, it stays permanently visible.
* **Debounced Exit**: 250ms smooth dwell buffer before sliding hidden to avoid jitter.

### 2.2 Active Flyout & Menu Lock
* The auto-hide daemon detects if the Start Menu, Action Center, Calendar flyout, or Widgets board is open. While open, auto-hide is locked in the visible state so the taskbar does not hide while interacting with menus.

### 2.3 Cross-Backend Synchronization
* Fully compatible with Quickshell (`omarchy-shell` / toggle state flags) and Waybar (`SIGUSR1` / `mode: "hide"`).
* Controlled via `omarchy-undercover-settings`, keybinding `SUPER + ALT + B`, CLI `omarchy-undercover-autohide [--toggle | --start | --stop]`, and persisted in `settings.conf` (`AUTOHIDE=true|false`).

---

## 3. Transparency Toggle & Real-Time Live Effects

### 3.1 Settings Suite Integration
* Dedicated **"Windows 11 Transparency Effects"** switch in `omarchy-undercover-settings` (Effects & Transparency and Dock & Taskbar pages).
* Persisted in `settings.conf` (`WIN11_TRANSPARENCY=true|false` and `BAR_TRANSPARENT=true|false`).

### 3.2 Visual State Effects
* **Transparency ON**:
  * Taskbar: Translucent background (`rgba(32, 32, 32, 0.80)` dark / `rgba(243, 243, 243, 0.85)` light) with Hyprland layer blur.
  * Start Menu & Flyouts: Frosted Mica glass with blur passes.
  * Windows: Active opacity 0.96, inactive opacity 0.88 with Hyprland background blur enabled.
* **Transparency OFF**:
  * Taskbar: Solid clean `#1f1f1f` dark / `#f3f3f3` light.
  * Start Menu & Flyouts: Solid opaque `#202020` / `#f3f3f3` background.
  * Windows: 1.00 solid opacity across all windows.
* Live real-time update using `hyprctl`, GTK CSS providers, and QML property updates.

---

## 4. Window Controls & Fluid Animations

### 4.1 Window Controls (Minimize & Close)
* Titlebar header layout set to `:minimize,maximize,close` in GTK 3/4 and GSettings for Windows mode (and `close,minimize,maximize:` for macOS mode).
* `omarchy-undercover-minimize` sends active window to `special:minimized` scratchpad with animated transition and toggles back on click or `Win + M`.
* Close button and `Alt + F4` trigger clean window termination.

### 4.2 Fluid Animation Curves
* **Windows 11 Mode**:
  * Fluent cubic-bezier `(0.1, 0.9, 0.2, 1.0)` curves with `popin 90%` for window opening/closing and smooth `specialWorkspace` slide for minimize/restore.
* **macOS Mode**:
  * Apple fluid spring curves (`macFluid`, `macGenie`, `macSpring`) with fluid scale-down for window minimize (`specialWorkspace`), smooth genie-style restore, and fluid workspace sliding.
