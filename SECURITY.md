# Security Policy

The Omarchy Undercover maintainers take security and user privacy seriously. This document outlines supported versions, security principles, and the process for reporting vulnerabilities.

---

## Supported Versions

Security updates and bug fixes are actively provided for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 8.0.x   | :white_check_mark: |
| 7.5.x   | :white_check_mark: |
| < 7.5   | :x:                |

Users are encouraged to run the latest released version via the official Arch Linux package (`omarchy-undercover`) or Git tags.

---

## Reporting a Vulnerability

If you discover a security vulnerability or trust boundary violation in Omarchy Undercover, please **do not open a public issue**. Instead, follow responsible disclosure:

1. **GitHub Security Advisory**: Submit a private advisory report via [GitHub Security Advisories](https://github.com/MISTERNEGATIVE21/omarchy-undercover/security/advisories/new).
2. **Direct Maintainer Contact**: If GitHub advisories are unavailable, contact the repository maintainers through GitHub profile details.

### What to Include in Your Report

To help us triage and resolve the issue quickly, please include:
- A clear description of the vulnerability and its potential impact.
- Affected components (e.g., specific QML files, helper scripts, or IPC mechanisms).
- Step-by-step instructions or proof-of-concept to reproduce the behavior.
- Any proposed remediation or mitigation if known.

### Response Timeline

- **Initial Response**: Within 48 hours to acknowledge receipt of the report.
- **Triage & Assessment**: Within 7 business days to confirm validity and establish severity.
- **Fix & Disclosure**: Coordinated patch release and security announcement once validated.

---

## Architectural Security Invariants

Omarchy Undercover enforces strict architectural boundaries to protect user privacy and system security:

### 1. PlainText Rendering on External Data
Qt Quick `Text` items default to rich-text parsing (`Text.AutoText`). Untrusted inputs broadcast over the air or derived from external processes (Wi-Fi SSIDs, Bluetooth device names, audio sink/source descriptions, window titles, process names) must strictly enforce `textFormat: Text.PlainText`. This prevents remote image HTTP GET requests (SSRF / IP leaks) and HTML markup interpretation.

### 2. Wayland Clipboard Isolation
Floating overlay menus (Quick Settings, Wi-Fi menus, Bluetooth menus, System Settings) must not embed generic `TextInput` controls. Under Wayland / QtWayland, unconstrained `TextInput` elements in layer-shell overlays can cause clipboard handle exhaustion and freeze desktop inputs.

### 3. Credential Protection
Network credentials (Wi-Fi pre-shared keys, passwords) are never passed as command-line arguments to avoid exposure in process tables (`/proc/*/cmdline` or `ps aux`). Credential transmission is strictly conducted through secure standard input streams (`--password-stdin`, D-Bus parameters).

### 4. Non-Destructive Desktop Isolation
The plugin strictly sandboxes disguise configurations within `~/.config/omarchy/plugins/omarchy-undercover`. Baseline compositor rules, keybindings, and theme settings are backed up and restored cleanly, preventing dots pollution or loss of user configurations.

### 5. Wayland Application ID & Icon Decoder Isolation
Wayland client applications specify their application ID (`app_id` / window class) without compositor mediation. To prevent confined or sandboxed applications from abusing the shared shell's image decoders (e.g. host memory exhaustion via crafted PNG compressed metadata chunks in host-mapped caches), all client identifiers must be strictly validated against canonical XDG icon tokens (`/^[a-zA-Z0-9][a-zA-Z0-9._-]*$/`). Absolute paths, path traversal sequences (`..`), path separators (`/`, `\`), and URI schemes (`file://`, `image://`) from client attributes are unconditionally rejected. System-level icon paths from desktop entries are strictly canonicalized under `/usr/share/{icons,pixmaps}/` with traversal sequences disallowed, and icon existence checks (`check: true`) are enforced before passing tokens to theme providers.

### 6. Audio Device Identifier & IPC Isolation
PulseAudio and PipeWire permit untrusted clients (including audio-authorized Flatpak applications) to define virtual node and sink names (e.g. via `module-null-sink`). To prevent application sandbox escapes and command injection across the desktop environment, device names from external audio state collectors (`scripts/omarchy-audio-state`) are strictly validated against canonical identifier tokens (`/^[a-zA-Z0-9_.:@-]{1,160}$/`). Control commands and audio switches in `AudioService.qml` strictly pass direct argument vectors (`Quickshell.execDetached([...])`) to `pactl`, `wpctl`, and audio helpers without invoking shell interpreters (`bash -c`), preventing arbitrary command execution when switching audio sinks or adjusting volumes.

