#!/usr/bin/env bash
# GNOME integration for Hyprland on Ubuntu: GNOME file chooser, Nautilus and Ubuntu's default apps.
# Run after `./setup install`. Safe to run again.
set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
SYSTEM_UNIT=/usr/lib/systemd/user/xdg-desktop-portal-gnome.service
GNOME_MIMEAPPS=/usr/share/applications/gnome-mimeapps.list

# xdg-desktop-portal-gnome refuses to start without graphical-session.target, which only a GNOME
# session activates. Override the unit with a copy that drops that requirement.
if [[ -f "$SYSTEM_UNIT" ]]; then
  mkdir -p "$CONFIG/systemd/user"
  {
    echo "# Copy of $SYSTEM_UNIT without the graphical-session.target requirement (for Hyprland)"
    grep -vE '^(Requisite|PartOf)=' "$SYSTEM_UNIT"
  } > "$CONFIG/systemd/user/xdg-desktop-portal-gnome.service"
  echo "Installed $CONFIG/systemd/user/xdg-desktop-portal-gnome.service"
else
  echo "Warning: $SYSTEM_UNIT not found, install xdg-desktop-portal-gnome" >&2
fi

# Ubuntu's default apps are only read when XDG_CURRENT_DESKTOP=GNOME; reuse them for Hyprland
if [[ -f "$GNOME_MIMEAPPS" ]]; then
  ln -sf "$GNOME_MIMEAPPS" "$CONFIG/hyprland-mimeapps.list"
  echo "Linked $CONFIG/hyprland-mimeapps.list -> $GNOME_MIMEAPPS"
fi

if [[ -f /usr/share/applications/org.gnome.Nautilus.desktop ]]; then
  xdg-mime default org.gnome.Nautilus.desktop inode/directory
  echo "Nautilus set as the default file manager"
fi

if systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user restart xdg-desktop-portal 2>/dev/null || true
fi

echo "Done. Log out and back in to Hyprland to apply the Qt theme and environment changes."
