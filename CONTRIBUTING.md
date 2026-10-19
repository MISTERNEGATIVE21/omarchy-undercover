# Contributing to Omarchy Undercover

Thank you for your interest in contributing to **Omarchy Undercover**! We welcome contributions, bug fixes, enhancements, disguise themes, and documentation improvements from the community.

Please take a moment to review these guidelines before submitting an issue or pull request.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Submitting Pull Requests](#submitting-pull-requests)
- [Development Setup](#development-setup)
- [Coding Guidelines & Standards](#coding-guidelines--standards)
  - [QML & Quickshell Standards](#qml--quickshell-standards)
  - [Security Boundaries (External Labels & Clipboard)](#security-boundaries-external-labels--clipboard)
  - [Shell Script Standards](#shell-script-standards)
  - [Python Standards](#python-standards)
- [Running Tests](#running-tests)
- [Git Commit Guidelines](#git-commit-guidelines)
- [Pull Request Process](#pull-request-process)

---

## Code of Conduct

All contributors and participants are expected to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md). Please report unacceptable behavior through maintainer contact.

---

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report, please check existing [GitHub Issues](https://github.com/MISTERNEGATIVE21/omarchy-undercover/issues) to ensure the problem has not already been reported.

When filing a bug report, please use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:
- A clear, descriptive title.
- The disguise mode active when the bug occurred (e.g., macOS Tahoe, macOS Sequoia, Windows 11 Fluent).
- Environment details (`hyprctl version`, `omarchy-shell --version` or Quickshell version, Linux kernel).
- Exact steps to reproduce the issue.
- Expected vs. actual behavior.
- Relevant log output:
  ```bash
  journalctl --user -u quickshell -n 100 --no-pager
  ```

### Suggesting Enhancements

Feature requests and enhancement ideas are welcome! Please submit suggestions using the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md). Explain the context, motivation, target camouflage mode, and visual mockups where applicable.

### Submitting Pull Requests

1. Fork the repository and create a descriptive feature branch from `main`:
   ```bash
   git checkout -b feat/my-new-feature
   ```
2. Develop your changes locally following the [Coding Guidelines & Standards](#coding-guidelines--standards).
3. Ensure all tests in `./tests/` pass cleanly.
4. Commit your changes using [Conventional Commits](#git-commit-guidelines).
5. Push to your fork and submit a Pull Request targeting `main`.

---

## Development Setup

Omarchy Undercover is developed for Arch Linux with the [Omarchy](https://omarchy.org) Hyprland environment.

### Prerequisites

- Arch Linux or Omarchy
- Hyprland (`hyprctl`)
- Quickshell (`quickshell`) or Waybar
- Qt6 Declarative / QtQuick
- Python 3.10+
- NetworkManager (`nmcli`, D-Bus)
- BlueZ (`bluetoothctl`)
- PipeWire / WirePlumber (`wpctl`, `pactl`)

### Linking for Local Development

To test live changes directly in your Omarchy desktop environment:

```bash
# Clone the repository
git clone https://github.com/MISTERNEGATIVE21/omarchy-undercover.git ~/omarchy-undercover
cd ~/omarchy-undercover

# Link plugin into Omarchy user plugin path
mkdir -p ~/.config/omarchy/plugins
ln -sfn ~/omarchy-undercover ~/.config/omarchy/plugins/omarchy-undercover

# Launch undercover switcher
./scripts/omarchy-undercover
```

---

## Coding Guidelines & Standards

### QML & Quickshell Standards

- **Indentation**: Use 2 spaces for indentation.
- **Component Design**: Keep UI components modular and responsive to screen geometry.
- **Animations**: Use smooth, standard durations (120ms–240ms) with `Easing.OutCubic` or `Easing.OutQuad`.
- **Theme Awareness**: Respect dark and light theme tokens via `ThemeTokens.qml` or active state poller.

### Security Boundaries (External Labels & Clipboard)

1. **Mandatory `Text.PlainText` on Untrusted Data**:
   Qt Quick `Text` defaults to `textFormat: Text.AutoText`. If external network labels (SSIDs, Bluetooth devices, audio descriptions, window titles, process names) contain HTML tags, Qt will parse them as rich text and make remote image HTTP requests.
   **Rule**: Always specify `textFormat: Text.PlainText` on any `Text` component displaying external/untrusted input:
   ```qml
   Text {
     text: modelData.ssid
     textFormat: Text.PlainText
     elide: Text.ElideRight
   }
   ```
2. **Wayland Clipboard Isolation**:
   Do not use generic `TextInput` in floating overlay menus, which can cause Wayland clipboard handle exhaustion. Use custom key interceptors or native entry dialogs.
3. **Sensitive Arguments**:
   Never pass sensitive passwords or credentials as CLI parameters. Always use standard input (`--password-stdin` / process pipes).

### Shell Script Standards

- Use `#!/usr/bin/env bash`.
- Always begin scripts with `set -euo pipefail`.
- Quote all variable expansions: `"$variable"`.
- Avoid arbitrary `eval` and unvalidated subshells.

### Python Standards

- Adhere to PEP 8 standards.
- Use explicit argument parsing and type annotations where feasible.
- Handle D-Bus and subprocess exceptions gracefully with appropriate fallbacks.

---

## Running Tests

All pull requests must pass the complete automated test suite before merging. Run the test suite locally:

```bash
# Run security and plain-text boundary checks
./tests/test_edid_and_clipboard_security.sh

# Run system protocols and flyout integration checks
./tests/test_system_protocols.sh
./tests/test_mac_flyouts_protocols.sh
./tests/test_mac_controlcenter_protocols.sh
./tests/test_win11_protocols.sh

# Run credential security tests
./tests/test_wifi_password_security.sh

# Run component test suites
./tests/test_mac_activitymonitor.sh
./tests/test_win11_taskmanager.sh
./tests/test_settings_service_load.sh
```

---

## Git Commit Guidelines

We use [Conventional Commits](https://www.conventionalcommits.org/) for clean, readable history:

- `feat:` A new feature or disguise capability
- `fix:` A bug fix or boundary remediation
- `docs:` Documentation changes
- `style:` Formatting or code style adjustments without logic changes
- `refactor:` Code reorganization without behavioral changes
- `test:` Adding or updating test suites
- `chore:` Maintenance tasks, dependency updates, or PKGBUILD updates

**Examples:**
```
feat(wifi): add band switching toggle to mac flyout
fix(security): enforce Text.PlainText on active SSID telemetry
docs(contributing): add community standards and guidelines
```

---

## Pull Request Process

1. Ensure all modified files adhere to the project's formatting and security guidelines.
2. Verify that all test suites pass without warnings or regressions.
3. Update relevant documentation or tests to reflect your changes.
4. Fill out the [Pull Request Template](.github/pull_request_template.md) completely.
5. Maintainers will review your PR and may provide feedback or request revisions.
