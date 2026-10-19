## Description
A concise summary of the changes proposed in this pull request and the problem they solve.

## Type of Change
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 🔒 Security fix (hardening, plain text enforcement, clipboard isolation)
- [ ] 💅 UI/UX refinement (visual styling, animations, typography)
- [ ] 📝 Documentation update (README, guides, comments)
- [ ] 🔧 Refactoring / Maintenance (code improvements, PKGBUILD)

## Related Issue(s)
Fixes # (or relates to #)

## Testing & Verification
Describe how the changes were verified:
- [ ] Ran `./tests/test_edid_and_clipboard_security.sh` successfully
- [ ] Ran `./tests/test_system_protocols.sh` and flyout protocol tests
- [ ] Validated Quickshell QML compilation with zero syntax errors or warnings
- [ ] Manually tested live desktop mode switching (<kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>U</kbd>)
- [ ] Tested dark and light theme appearance

## Security Checklist
- [ ] All external network labels, SSIDs, and device names strictly enforce `textFormat: Text.PlainText`.
- [ ] No generic `TextInput` components added to layer-shell overlays (preserving Wayland clipboard stability).
- [ ] Passwords/credentials are delivered via stdin and never exposed in CLI command arguments.
- [ ] Configuration changes are isolated within plugin boundaries without modifying baseline dotfiles.

## Additional Notes
Add any other context, performance observations, or screenshots below.
