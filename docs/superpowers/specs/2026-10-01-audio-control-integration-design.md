# Design Specification: Advanced Audio Control Integration & Windows 11 Sound Settings

- **Author**: misternegative21 & Antigravity
- **Date**: 2026-10-01
- **Status**: Approved
- **Target Repository**: `omarchy-undercover`

---

## 1. Overview & Objective

This specification details the integration of the **Advanced Audio Control** subsystem (from [`ssupt/omarchy-audio-control`](https://github.com/ssupt/omarchy-audio-control)) into **Omarchy Undercover**.

The integration equips both Windows 11 mode and macOS Sequoia mode with advanced audio capabilities (output and input device routing, per-application playback and recording mixer, speaker channel testing, live microphone testing, stereo balance tuning, persistent app routing, and one-click audio recovery) while preserving 100% of the authentic camouflage styling, typography, dark/light theme responsiveness, and UI/UX of Omarchy Undercover. Furthermore, it implements an authentic **System > Sound** view in the Windows 11 Settings QuickShell app.

---

## 2. Architecture & Components

### 2.1 Backend & Utilities Integration
1. **Core Audio Daemon (`bin/omarchy-audio-service`)**:
   - The compiled 64-bit ELF executable `omarchy-audio-service` from `ssupt/omarchy-audio-control` is placed in `omarchy-undercover/bin/omarchy-audio-service` alongside `backend-release.json`.
   - Supports execution via stdio JSON-RPC (`--plugin`) or CLI requests (`--request METHOD PARAMS_JSON`).
2. **Audio Utilities in `scripts/`**:
   - `omarchy-audio-speaker-test`: Uses `speaker-test` and Pulse/PipeWire to identify Left and Right channels.
   - `omarchy-audio-recovery`: Resets stuck audio streams via `omarchy-restart-audio` or `systemctl --user restart pipewire wireplumber`.
   - `omarchy-audio-rules`: Reads and updates `~/.config/omarchy/audio-rules.json` for per-app routing and device aliases.
   - `omarchy-audio-preferences`: Manages `~/.config/omarchy/audio-preferences.json` for default sinks/sources and Bluetooth profiles.
   - `omarchy-win11-sound`: Wrapper to launch or toggle the Windows 11 sound flyout.
   - `omarchy-mac-sound`: Wrapper to launch or toggle the macOS sound flyout.

### 2.2 Shared QuickShell QML Models (`configs/quickshell/common/`)
- `AudioService.qml`: Wraps `bin/omarchy-audio-service` using `Quickshell.Io.Process` and `AudioProtocol.js`, with automatic fallback to `wpctl`/`pactl` if the daemon binary is not present or reconnecting.
- `AudioProtocol.js`: JSON-RPC protocol encoder/decoder matching protocol version 1.
- `Model.js`: Node classification routines (extracting sinks, sources, playback streams, recording streams).

---

## 3. Windows 11 Mode Implementation

### 3.1 Windows 11 Sound Flyout (`configs/quickshell/win11-sound/shell.qml`)
- **Visual Design**: Mica dark/light container (`radius: 14`), Segoe UI typography, smooth entrance animation (`y` and `opacity` transitions).
- **Master Output Card**:
  - Speaker icon indicating volume state (`󰕾`, `󰖀`, `󰕿`, `󰝟`).
  - Fluent Slider (`from: 0.0, to: 1.0`) with percentage label.
  - Interactive mute button.
- **Output Device Selector**:
  - List of detected audio outputs (Speakers, Headphones, Bluetooth devices) with device icons (`🔊`, `🎧`).
  - Active device highlighted with accent border and checkmark `✓`.
  - One-click click to switch default sink.
- **Input (Microphone) Section**:
  - List of detected microphones with input volume slider and mute toggle.
- **Per-Application Volume Mixer (Expandable)**:
  - Collapsible/expandable section for active audio apps.
  - Each item displays app icon, name, volume slider, mute button, and target output device dropdown.
- **Footer Link**:
  - "More sound settings" link that opens the Windows 11 Settings app with direct focus on the Sound section.

### 3.2 Windows 11 Settings App (`configs/quickshell/win11-settings/shell.qml`)
- **System > Sound Section**:
  - Integrated into Category 0 (System) or directly accessible via `--page sound`.
  - **Output Card**:
    - Selectable list of output devices with radio indicators.
    - Master volume slider.
    - **Stereo Balance Slider**: Left ⟷ Right balance adjustment.
    - **Speaker Channel Test**: Button to run `omarchy-audio-speaker-test` to announce left and right channels.
  - **Input Card**:
    - Selectable microphone list.
    - Microphone volume slider.
    - **Microphone Test & VU Meter**: Real-time visual activity bar and 5-second test recording.
  - **Volume Mixer Card**:
    - Matrix of active applications with individual volume controls and persistent routing ("Always use" device vs "Follow default output").
  - **Troubleshoot & Recovery Card**:
    - One-click "Restart Audio Services" triggering `omarchy-audio-recovery`.

---

## 4. macOS Sequoia Mode Implementation

### 4.1 macOS Sound Flyout (`configs/quickshell/mac-sound/shell.qml`)
- **Visual Design**: Frosted glass container (`radius: 16`), SF Pro Text typography, Apple accent color (`#007aff` / `#0a84ff`), scale and opacity entrance transitions.
- **Apple Pill Slider**:
  - Smooth rounded pill slider with speaker icon and volume percentage.
- **Output Device Section**:
  - Clean list of outputs with Apple checkmark `✓` for active device.
- **Input (Microphone) Section**:
  - Microphone selector with gain slider and mute toggle.
- **App Mixer Section**:
  - Expandable list of playing applications with macOS styled volume sliders.
- **Footer Link**:
  - "Sound Settings..." button that launches macOS System Settings focused on the Sound tab.

### 4.2 macOS System Settings App (`configs/quickshell/mac-settings/shell.qml`)
- **Category 5: Sound**:
  - **Sound Effects**: System alert sound selector (Ping, etc.) and alert volume slider.
  - **Output**: Output device table with Name and Connection Type, Volume slider, Balance slider (Left ⟷ Right), and Speaker Test button.
  - **Input**: Input device table with Input Volume slider and live Input Level meter.
  - **App Mixer**: Per-app volume and routing controls.
  - **Sound Diagnostics & Recovery**: "Reset Sound System" card invoking `omarchy-audio-recovery`.

---

## 5. Error Handling & Safety

1. **Fallback Mechanism**:
   - If `bin/omarchy-audio-service` encounters any communication failure or timeout, UI controls fall back immediately to direct `wpctl set-volume`, `wpctl set-mute`, and `wpctl set-default` commands so audio interaction remains responsive.
2. **Process Lifecycle**:
   - Popups continue to write their PID to `$XDG_RUNTIME_DIR/omarchy-*.pid` and properly clean up processes on dismiss/Escape/click-away to prevent process leakage.
3. **Data Integrity**:
   - Audio rule persistence in `~/.config/omarchy/audio-rules.json` and preferences in `~/.config/omarchy/audio-preferences.json` are atomic to avoid corruption on unexpected reboots.

---

## 6. Verification & Test Plan

1. **Compilation & File Permissions**:
   - Ensure `bin/omarchy-audio-service` has executable permissions (`chmod +x`).
   - Ensure all scripts in `scripts/omarchy-audio-*` have executable permissions.
2. **Quickshell Configuration Sanity**:
   - Test `quickshell -p configs/quickshell/win11-sound` and `configs/quickshell/mac-sound`.
   - Test `quickshell -p configs/quickshell/win11-settings` and `configs/quickshell/mac-settings`.
   - Verify no QML syntax errors or broken imports.
3. **Functional Testing**:
   - Adjust volume in `win11-sound` and `mac-sound`: verify master volume updates smoothly.
   - Switch output sinks: verify default sink changes in PipeWire (`wpctl status`).
   - Run speaker test: verify audible channel identification chime.
   - Open Windows 11 Settings: verify System > Sound displays devices, mixer, and recovery options.
   - Open macOS Settings: verify Sound tab displays full sound controls.
