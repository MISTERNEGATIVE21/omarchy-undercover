Name:           omarchy-undercover
Version:        1.0.0
Release:        1%{?dist}
Summary:        Windows 11 desktop transformation tool for Omarchy Hyprland

License:        GPL-3.0-or-later
URL:            https://github.com/omarchy/omarchy-undercover
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       hyprland, waybar, rofi, jq, python3, python3-gobject, gtk4, libadwaita

%description
omarchy-undercover is a fault-tolerant desktop layout transformation tool designed
specifically for Omarchy Hyprland. It transforms your Hyprland environment into a
seamless Windows 11 style desktop with bottom taskbar and GTK control center.

%prep
%setup -q

%build
# No compilation required

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/omarchy-undercover/scripts
mkdir -p %{buildroot}%{_datadir}/omarchy-undercover/configs
mkdir -p %{buildroot}%{_datadir}/omarchy-undercover/wallpapers
mkdir -p %{buildroot}%{_datadir}/omarchy-undercover/assets/themes
mkdir -p %{buildroot}%{_datadir}/omarchy-undercover/assets/icons
mkdir -p %{buildroot}%{_datadir}/applications
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/scalable/apps
mkdir -p %{buildroot}%{_licensedir}/%{name}

install -m 0755 scripts/omarchy-undercover %{buildroot}%{_bindir}/omarchy-undercover
install -m 0755 scripts/omarchy-undercover-setup %{buildroot}%{_bindir}/omarchy-undercover-setup
install -m 0755 scripts/omarchy-undercover-settings %{buildroot}%{_bindir}/omarchy-undercover-settings
install -m 0755 scripts/omarchy-undercover-launcher %{buildroot}%{_bindir}/omarchy-undercover-launcher
install -m 0755 scripts/omarchy-undercover-wallpaper %{buildroot}%{_bindir}/omarchy-undercover-wallpaper
install -m 0755 scripts/omarchy-undercover-show-desktop %{buildroot}%{_bindir}/omarchy-undercover-show-desktop
install -m 0755 scripts/omarchy-undercover-minimize %{buildroot}%{_bindir}/omarchy-undercover-minimize
install -m 0755 scripts/omarchy-undercover-new-desktop %{buildroot}%{_bindir}/omarchy-undercover-new-desktop
install -m 0755 uninstall.sh %{buildroot}%{_bindir}/omarchy-undercover-uninstall

install -m 0644 scripts/common.sh %{buildroot}%{_datadir}/omarchy-undercover/scripts/common.sh
cp -pr configs/* %{buildroot}%{_datadir}/omarchy-undercover/configs/
cp -pr assets/wallpapers/* %{buildroot}%{_datadir}/omarchy-undercover/wallpapers/
cp -pr assets/themes/* %{buildroot}%{_datadir}/omarchy-undercover/assets/themes/
cp -pr assets/icons/* %{buildroot}%{_datadir}/omarchy-undercover/assets/icons/

install -m 0644 assets/omarchy-undercover.desktop %{buildroot}%{_datadir}/applications/
install -m 0644 assets/omarchy-undercover-settings.desktop %{buildroot}%{_datadir}/applications/
install -m 0644 assets/start-icon.svg %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/omarchy-undercover.svg
install -m 0644 assets/start-icon.svg %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/org.omarchy.undercover.settings.svg
install -m 0644 LICENSE %{buildroot}%{_licensedir}/%{name}/LICENSE

%files
%{_bindir}/omarchy-undercover
%{_bindir}/omarchy-undercover-setup
%{_bindir}/omarchy-undercover-settings
%{_bindir}/omarchy-undercover-launcher
%{_bindir}/omarchy-undercover-wallpaper
%{_bindir}/omarchy-undercover-show-desktop
%{_bindir}/omarchy-undercover-minimize
%{_bindir}/omarchy-undercover-new-desktop
%{_bindir}/omarchy-undercover-uninstall
%{_datadir}/omarchy-undercover/
%{_datadir}/applications/*.desktop
%{_licensedir}/%{name}/LICENSE

%changelog
* Thu Aug 13 2026 John Varghese <john@omarchy.org> - 1.0.0-1
- Initial release of Omarchy Undercover
