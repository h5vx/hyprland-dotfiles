# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

# Ubuntu (26.04+) dependencies installer.
# Everything comes from apt (Ubuntu archive + PPAs) or prebuilt upstream release
# files (.deb, fonts, themes). Nix is not used.

UBUNTU_PPAS=(
  cppiber/hyprland        # hyprland >= 0.55 (Lua config), hypridle, hyprlock, hyprpicker, hyprsunset, xdph
  avengemedia/danklinux   # quickshell (0.3.2 = pinned commit), matugen, cliphist
  marin-m/songrec         # songrec
)

# Pinned upstream sources for things not packaged for Ubuntu
DARKLY_VERSION="0.5.41"
ADW_GTK3_VERSION="6.5"
BREEZE_PLUS_VERSION="6.28.0"
NERD_FONTS_VERSION="3.5.1"
HYPRSHOT_VERSION="1.3.0"
RUBIK_COMMIT="e337a5f69a9bea30e58d05bd40184d79cc099628"
READEX_PRO_COMMIT="1a5aaa4c15edb043c37113a8cddf020235917050"

UBUNTU_FONTS_DIR=/usr/local/share/fonts/illogical-impulse
UBUNTU_CACHE_DIR="${REPO_ROOT}/cache/dist-ubuntu"

# Package groups mirror sdata/dist-arch/illogical-impulse-*/PKGBUILD
ubuntu_pkgs_audio=(cava pavucontrol-qt wireplumber pipewire-pulse libdbusmenu-gtk3-4 playerctl)
ubuntu_pkgs_backlight=(geoclue-2.0 brightnessctl ddcutil)
ubuntu_pkgs_basic=(bc coreutils cliphist cmake curl wget ripgrep jq xdg-user-dirs rsync git unzip xz-utils libsecret-tools)
ubuntu_pkgs_fonts_themes=(
  breeze breeze-icon-theme bibata-cursor-theme eza fish fontconfig kitty matugen starship
  fonts-space-grotesk fonts-noto-color-emoji
)
ubuntu_pkgs_hyprland=(hyprland hyprsunset wl-clipboard)
ubuntu_pkgs_portal=(xdg-desktop-portal xdg-desktop-portal-kde xdg-desktop-portal-gtk xdg-desktop-portal-hyprland)
ubuntu_pkgs_python=(
  clang build-essential pkg-config
  libgtk-4-dev libadwaita-1-dev libsoup-3.0-dev libportal-gtk4-dev
  gobject-introspection libgirepository-2.0-dev libgirepository1.0-dev
  # Headers for python packages built from source in the venv
  libdbus-1-dev libcairo2-dev libwayland-dev libffi-dev
)
ubuntu_pkgs_quickshell=(
  quickshell
  qml6-module-qtquick qml6-module-qtquick-layouts qml6-module-qtquick-controls
  qml6-module-qtquick-effects qml6-module-qtquick-shapes qml6-module-qtquick-window
  qml6-module-qtqml qml6-module-qtqml-models qml6-module-qtcore
  qml6-module-qt-labs-synchronizer qml6-module-qt-labs-folderlistmodel
  qml6-module-qt5compat-graphicaleffects
  qml6-module-qtmultimedia qml6-module-qtpositioning qml6-module-qtquick-timeline
  qml6-module-qtsensors qml6-module-qtquick-virtualkeyboard qt6-virtualkeyboard-plugin
  qt6-svg-plugins qt6-image-formats-plugins kimageformat6-plugins
  qt6-wayland qt6-translations-l10n
  qml6-module-org-kde-kirigami qml6-module-org-kde-syntaxhighlighting kdialog
)
ubuntu_pkgs_screencapture=(grim slurp swappy tesseract-ocr tesseract-ocr-eng wf-recorder)
ubuntu_pkgs_toolkit=(upower wtype ydotool)
ubuntu_pkgs_widgets=(
  fuzzel libglib2.0-bin imagemagick hypridle hyprlock hyprpicker
  songrec translate-shell wlogout qalc
)
ubuntu_pkgs_misc=(libkf6config-bin)
# Installed with --no-install-recommends to avoid pulling in the whole Plasma desktop
ubuntu_pkgs_kde=(
  bluedevil gnome-keyring network-manager plasma-nm polkit-kde-agent-1
  dolphin systemsettings kde-cli-tools
  plasma-integration  # Qt platform theme "kde" (QT_QPA_PLATFORMTHEME=kde), needed for icons
)
ubuntu_pkgs_microtex=(libtinyxml2-dev libgtkmm-3.0-dev libgtksourceviewmm-3.0-dev libcairomm-1.0-dev)

#####################################################################################

ubuntu_add_ppas(){
  local ppa
  for ppa in "${UBUNTU_PPAS[@]}"; do
    local owner="${ppa%%/*}" name="${ppa##*/}"
    if grep -rqsE "ppa\.launchpad(content)?\.net/${owner}/${name}/" /etc/apt/sources.list /etc/apt/sources.list.d/; then
      echo -e "${STY_BLUE}PPA ${ppa} is already enabled.${STY_RST}"
    else
      x sudo add-apt-repository -y -n "ppa:${ppa}"
    fi
  done
}

ubuntu_fetch(){
  # Usage: ubuntu_fetch <url> <output-file>
  x curl -fL --retry 3 --progress-bar -o "$2" "$1"
}

install_ubuntu_darkly(){
  if dpkg-query -W -f='${Version}' darkly 2>/dev/null | grep -q "^${DARKLY_VERSION}"; then return; fi
  local file="darkly-${DARKLY_VERSION}_kubuntu-26.04_amd64.deb"
  x mkdir -p "$UBUNTU_CACHE_DIR"
  ubuntu_fetch "https://github.com/Bali10050/Darkly/releases/download/v${DARKLY_VERSION}/${file}" "$UBUNTU_CACHE_DIR/${file}"
  x sudo apt-get install -y "$UBUNTU_CACHE_DIR/${file}"
}

install_ubuntu_adw_gtk3(){
  if [[ -d /usr/local/share/themes/adw-gtk3-dark ]]; then return; fi
  local file="adw-gtk3v${ADW_GTK3_VERSION}.tar.xz"
  x mkdir -p "$UBUNTU_CACHE_DIR"
  ubuntu_fetch "https://github.com/lassekongo83/adw-gtk3/releases/download/v${ADW_GTK3_VERSION}/${file}" "$UBUNTU_CACHE_DIR/${file}"
  x sudo mkdir -p /usr/local/share/themes
  x sudo tar -xf "$UBUNTU_CACHE_DIR/${file}" -C /usr/local/share/themes
}

install_ubuntu_breeze_plus(){
  if [[ -d /usr/local/share/icons/breeze-plus ]]; then return; fi
  local file="breeze-plus-${BREEZE_PLUS_VERSION}.tar.gz"
  x mkdir -p "$UBUNTU_CACHE_DIR"
  ubuntu_fetch "https://github.com/mjkim0727/breeze-plus/archive/refs/tags/${BREEZE_PLUS_VERSION}.tar.gz" "$UBUNTU_CACHE_DIR/${file}"
  x tar -xf "$UBUNTU_CACHE_DIR/${file}" -C "$UBUNTU_CACHE_DIR"
  x sudo mkdir -p /usr/local/share/icons
  x sudo cp -r "$UBUNTU_CACHE_DIR/breeze-plus-${BREEZE_PLUS_VERSION}"/src/breeze-plus* /usr/local/share/icons/
}

install_ubuntu_hyprshot(){
  if [[ -x /usr/local/bin/hyprshot ]]; then return; fi
  x mkdir -p "$UBUNTU_CACHE_DIR"
  ubuntu_fetch "https://raw.githubusercontent.com/Gustash/Hyprshot/${HYPRSHOT_VERSION}/hyprshot" "$UBUNTU_CACHE_DIR/hyprshot"
  x sudo install -Dm755 "$UBUNTU_CACHE_DIR/hyprshot" /usr/local/bin/hyprshot
}

install_ubuntu_fonts(){
  local tmp="$UBUNTU_CACHE_DIR/fonts"
  x mkdir -p "$tmp"
  x sudo mkdir -p "$UBUNTU_FONTS_DIR"

  # Material Symbols (variable)
  local style
  for style in Outlined Rounded Sharp; do
    local f="MaterialSymbols${style}[FILL,GRAD,opsz,wght].ttf"
    if [[ ! -f "$UBUNTU_FONTS_DIR/$f" ]]; then
      ubuntu_fetch "https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/MaterialSymbols${style}%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf" "$tmp/$f"
      x sudo install -m644 "$tmp/$f" "$UBUNTU_FONTS_DIR/$f"
    fi
  done

  # Rubik (variable)
  local f
  for f in "Rubik[wght].ttf" "Rubik-Italic[wght].ttf"; do
    if [[ ! -f "$UBUNTU_FONTS_DIR/$f" ]]; then
      local enc="${f//[/%5B}"; enc="${enc//]/%5D}"
      ubuntu_fetch "https://raw.githubusercontent.com/googlefonts/rubik/${RUBIK_COMMIT}/fonts/variable/${enc}" "$tmp/$f"
      x sudo install -m644 "$tmp/$f" "$UBUNTU_FONTS_DIR/$f"
    fi
  done

  # Readex Pro
  for f in ReadexPro-ExtraLight ReadexPro-Light ReadexPro-Regular ReadexPro-Medium ReadexPro-SemiBold ReadexPro-bold; do
    if [[ ! -f "$UBUNTU_FONTS_DIR/$f.ttf" ]]; then
      ubuntu_fetch "https://raw.githubusercontent.com/ThomasJockin/readexpro/${READEX_PRO_COMMIT}/fonts/ttf/$f.ttf" "$tmp/$f.ttf"
      x sudo install -m644 "$tmp/$f.ttf" "$UBUNTU_FONTS_DIR/$f.ttf"
    fi
  done

  # JetBrains Mono Nerd Font
  if [[ ! -d "$UBUNTU_FONTS_DIR/JetBrainsMonoNerd" ]]; then
    ubuntu_fetch "https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONTS_VERSION}/JetBrainsMono.tar.xz" "$tmp/JetBrainsMono.tar.xz"
    x mkdir -p "$tmp/JetBrainsMonoNerd"
    x tar -xf "$tmp/JetBrainsMono.tar.xz" -C "$tmp/JetBrainsMonoNerd"
    x sudo mkdir -p "$UBUNTU_FONTS_DIR/JetBrainsMonoNerd"
    x sudo cp "$tmp"/JetBrainsMonoNerd/*.ttf "$UBUNTU_FONTS_DIR/JetBrainsMonoNerd/"
  fi

  x sudo fc-cache -f
}

install_ubuntu_microtex(){
  if [[ -x /opt/MicroTeX/LaTeX ]]; then return; fi
  install-MicroTeX
}

#####################################################################################

if ! command -v apt-get >/dev/null 2>&1; then
  printf "${STY_RED}[$0]: apt-get not found, it seems that the system is not Ubuntu. Aborting...${STY_RST}\n"
  exit 1
fi

if ! command -v add-apt-repository >/dev/null 2>&1; then
  v sudo apt-get install -y software-properties-common
fi

showfun ubuntu_add_ppas
v ubuntu_add_ppas
v sudo apt-get update

case $SKIP_SYSUPDATE in
  true) true ;;
  *) v sudo apt-get full-upgrade -y ;;
esac

for group in audio backlight basic fonts_themes hyprland portal python quickshell screencapture toolkit widgets misc microtex; do
  declare -n _pkgs="ubuntu_pkgs_${group}"
  echo -e "${STY_CYAN}Installing package group: ${group}${STY_RST}"
  v sudo apt-get install -y "${_pkgs[@]}"
  unset -n _pkgs
done
echo -e "${STY_CYAN}Installing package group: kde${STY_RST}"
v sudo apt-get install -y --no-install-recommends "${ubuntu_pkgs_kde[@]}"

showfun install_ubuntu_darkly
v install_ubuntu_darkly
showfun install_ubuntu_adw_gtk3
v install_ubuntu_adw_gtk3
showfun install_ubuntu_breeze_plus
v install_ubuntu_breeze_plus
showfun install_ubuntu_hyprshot
v install_ubuntu_hyprshot
showfun install_ubuntu_fonts
v install_ubuntu_fonts
showfun install_ubuntu_microtex
v install_ubuntu_microtex

# uv is not packaged for Ubuntu; the official standalone installer puts it into ~/.local/bin
if ! command -v uv >/dev/null 2>&1; then
  showfun install-uv
  UV_NO_MODIFY_PATH=1 v install-uv
  export PATH="$HOME/.local/bin:$PATH"
fi
