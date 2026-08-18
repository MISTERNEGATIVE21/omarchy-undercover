# Maintainer: John Varghese <john@omarchy.org>
pkgname=omarchy-undercover
pkgver=3.0.0
pkgrel=1
pkgdesc="Windows 11 desktop transformation tool for Omarchy Hyprland"
arch=('any')
url="https://github.com/omarchy/omarchy-undercover"
license=('GPL-3.0-or-later')
depends=('hyprland' 'waybar' 'rofi' 'jq' 'python' 'python-gobject' 'python-nautilus' 'gtk4' 'libadwaita' 'xdg-utils' 'gettext')
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
    install -m 755 "$srcdir/uninstall.sh" "$pkgdir/usr/bin/omarchy-undercover-uninstall"

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
    # Nautilus override: launch the file manager with the stock GNOME (Adwaita)
    # look instead of the Windows skin, but with the Windows app skin
    # (Fluent) icons, opening on the My Computer view
    install -m 644 "$srcdir/assets/org.gnome.Nautilus.desktop" "$pkgdir/usr/share/applications/"

    # My Computer for Nautilus extension (system-wide)
    install -d "$pkgdir/usr/share/nautilus-python/extensions"
    install -d "$pkgdir/usr/share/glib-2.0/schemas"
    install -m 644 "$srcdir/assets/nautilus-my-computer/nautilus-my-computer.py" "$pkgdir/usr/share/nautilus-python/extensions/nautilus-my-computer.py"
    cp -r "$srcdir/assets/nautilus-my-computer/nautilus_my_computer" "$pkgdir/usr/share/nautilus-python/extensions/"
    install -m 644 "$srcdir/assets/nautilus-my-computer/io.github.yannmasoch.nautilus-my-computer.gschema.xml" "$pkgdir/usr/share/glib-2.0/schemas/"
    glib-compile-schemas --targetdir="$pkgdir/usr/share/glib-2.0/schemas" "$srcdir/assets/nautilus-my-computer"
    # Translations
    for po_file in "$srcdir"/assets/nautilus-my-computer/po/*.po; do
        [ -f "$po_file" ] || continue
        lang=$(basename "$po_file" .po)
        install -d "$pkgdir/usr/share/locale/$lang/LC_MESSAGES"
        msgfmt "$po_file" -o "$pkgdir/usr/share/locale/$lang/LC_MESSAGES/nautilus-my-computer.mo"
    done
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
