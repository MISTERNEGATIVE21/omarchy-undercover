# Maintainer: MISTERNEGATIVE21 <MISTERNEGATIVE21@gmail.com>
pkgname=omarchy-undercover
pkgver=5.3.1
pkgrel=1
pkgdesc="Windows 11 desktop transformation tool for Omarchy Hyprland"
arch=('any')
url="https://github.com/omarchy/omarchy-undercover"
license=('GPL-3.0-or-later')
depends=('hyprland' 'waybar' 'rofi' 'jq' 'python' 'python-gobject' 'gtk4' 'libadwaita' 'xdg-utils' 'flea')
optdepends=('wofi: Alternative application launcher')
source=()
sha256sums=()

package() {
    cd "$srcdir"
    
    # Create system directories
    install -d "$pkgdir/usr/bin"
    install -d "$pkgdir/usr/share/omarchy-undercover/scripts"
    install -d "$pkgdir/usr/share/omarchy-undercover/configs"
    install -d "$pkgdir/usr/share/omarchy-undercover/wallpapers"
    install -d "$pkgdir/usr/share/applications"
    install -d "$pkgdir/usr/share/icons/hicolor/scalable/apps"
    install -d "$pkgdir/usr/share/licenses/$pkgname"

    # Install scripts
    for script_file in "$srcdir/scripts/"*; do
        if [ -f "$script_file" ] && [ -x "$script_file" ]; then
            install -m 755 "$script_file" "$pkgdir/usr/bin/$(basename "$script_file")"
        fi
    done
    install -m 644 "$srcdir/scripts/common.sh" "$pkgdir/usr/share/omarchy-undercover/scripts/common.sh"
    install -m 755 "$srcdir/scripts/common.sh" "$pkgdir/usr/bin/omarchy-undercover-common.sh"

    # Install configuration files
    cp -r "$srcdir/configs/"* "$pkgdir/usr/share/omarchy-undercover/configs/"

    # Install wallpapers
    if [ -d "$srcdir/assets/wallpapers" ]; then
        cp -r "$srcdir/assets/wallpapers/"* "$pkgdir/usr/share/omarchy-undercover/wallpapers/"
    fi

    # Install Windows 11 themes, icons and cursors
    install -d "$pkgdir/usr/share/omarchy-undercover/assets/themes"
    install -d "$pkgdir/usr/share/omarchy-undercover/assets/icons"
    if [ -d "$srcdir/assets/themes" ]; then
        cp -r "$srcdir/assets/themes/"* "$pkgdir/usr/share/omarchy-undercover/assets/themes/"
    fi
    if [ -d "$srcdir/assets/icons" ]; then
        cp -r "$srcdir/assets/icons/"* "$pkgdir/usr/share/omarchy-undercover/assets/icons/"
    fi
    if [ -d "$srcdir/assets/mac-dock" ]; then
        install -d "$pkgdir/usr/share/omarchy-undercover/assets/mac-dock"
        cp -r "$srcdir/assets/mac-dock/"* "$pkgdir/usr/share/omarchy-undercover/assets/mac-dock/"
    fi

    # Install desktop files & assets
    install -m 644 "$srcdir/assets/omarchy-undercover.desktop" "$pkgdir/usr/share/applications/"
    install -m 644 "$srcdir/assets/omarchy-undercover-settings.desktop" "$pkgdir/usr/share/applications/"

    # The Omarchy Undercover logo powers the app/desktop icons; the start-icon
    # SVG stays in assets and is used directly by the Start menu button.
    if [ -f "$srcdir/assets/omarchy-undercover-logo.svg" ]; then
        install -m 644 "$srcdir/assets/omarchy-undercover-logo.svg" "$pkgdir/usr/share/icons/hicolor/scalable/apps/omarchy-undercover.svg"
        install -m 644 "$srcdir/assets/omarchy-undercover-logo.svg" "$pkgdir/usr/share/icons/hicolor/scalable/apps/org.omarchy.undercover.settings.svg"
    fi
    if [ -f "$srcdir/assets/start-icon.svg" ]; then
        install -m 644 "$srcdir/assets/start-icon.svg" "$pkgdir/usr/share/omarchy-undercover/assets/start-icon.svg"
        install -m 644 "$srcdir/assets/start-icon.svg" "$pkgdir/usr/share/icons/hicolor/scalable/apps/windows-start.svg"
    fi

    # Install license
    install -m 644 "$srcdir/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
