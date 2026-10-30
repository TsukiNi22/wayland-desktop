#!/bin/bash
# Usage: ./install.sh [--no-packages] [all | <style> | remove]   (no argument: asks)
#   all            every style + the switcher (wd-style, module of the top bar, Super+Shift+W)
#   <style>        one style alone: system, dev, ado, tty, miku, photographer
#   remove         remove the configs and put back the files saved at the install (the packages stay)
#   --no-packages  the configs only
# Install the packages of the chosen config for the distribution (fedora-like: dnf + copr sdegler/hyprland, debian-like:
# apt, arch-like: pacman; a package missing in the repositories is skipped), then the wayland-desktop configs (Hyprland,
# waybar, wofi, kitty, hyprlock, mako, the quickshell overview and the live wallpapers) for the user
# As a user: sudo for the packages only; as root through sudo (ex: the Wayland setup of dump): the configs go to $SUDO_USER
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="$CONFIG_DIR/wayland-desktop"
BIN_DIR="$HOME/.local/bin"
SHELL_DIR="$CONFIG_DIR/quickshell/wayland-desktop"
ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
BACKUP=".wd-backup"
MARK="wayland-desktop"

HYPRLAND_COPR="sdegler/hyprland" # fedora-like: hyprland, hyprlock (not in the Fedora repositories)
# Packages of every config (fedora names, translated for the family by pkg_name); a style adds the PACKAGES of its
# style.env (its fonts, the radio of ado and miku)
PACKAGES=(hyprland hyprlock waybar wofi kitty swaybg mako grim slurp wl-clipboard brightnessctl playerctl wireplumber
    libnotify nautilus btop adwaita-cursor-theme jetbrains-mono-fonts-all fontawesome-6-free-fonts
    google-noto-sans-cjk-vf-fonts google-noto-sans-symbols-2-fonts google-noto-color-emoji-fonts
    quickshell cava python3-gobject python3-cairo webkit2gtk4.1 gtk-layer-shell gtk-session-lock python3-pam python3-pillow)

# Files managed by the install (relative to ~/.config): copies of config/common, links of the active style
COPIES=(hypr/hyprland.lua kitty/kitty.conf wofi/config)
LINKS=(hypr/style.lua hypr/hyprlock.conf waybar/config.jsonc waybar/style.css wofi/style.css kitty/theme.conf mako/config)

# =========================
# Helpers
# =========================
info() {
    echo "[wayland-desktop] $*"
}

styles() {
    find "$REPO_DIR/config/styles" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

# Save a file of the user once (a link or a file of the install is not saved)
save() {
    local file="$CONFIG_DIR/$1"

    if [[ -L "$file" && "$(readlink "$file")" == "$DATA_DIR"* ]]; then
        return 0
    fi
    if [[ -e "$file" && ! -e "$file$BACKUP" ]] && ! grep -q "$MARK" "$file" 2> /dev/null; then
        mv "$file" "$file$BACKUP"
        info "saved ~/.config/$1 -> ~/.config/$1$BACKUP"
    fi
}

# Keyboard of the session (GNOME setting, else localectl) -> ~/.config/hypr/user.lua, written once
write_user() {
    local file="$CONFIG_DIR/hypr/user.lua"
    local source=""
    local layout="us"
    local variant=""

    if [[ -e "$file" ]]; then
        return 0
    fi
    source=$(gsettings get org.gnome.desktop.input-sources sources 2> /dev/null | grep -o "'xkb', '[^']*'" | head -n 1 | cut -d"'" -f4 || true)
    if [[ -n "$source" ]]; then
        layout="${source%%+*}"
        [[ "$source" == *+* ]] && variant="${source#*+}"
    elif command -v localectl > /dev/null; then
        layout=$(localectl status | sed -n 's/.*X11 Layout: *//p' | cut -d, -f1)
        variant=$(localectl status | sed -n 's/.*X11 Variant: *//p' | cut -d, -f1)
    fi
    cat > "$file" << EOF
-- Your own Hyprland overrides, never replaced by the wayland-desktop installer (keyboard detected at the install)

hl.config({
    input = {
        kb_layout  = "${layout:-us}",
        kb_variant = "$variant",
    },
})
EOF
    info "keyboard ${layout:-us}${variant:+ ($variant)} -> ~/.config/hypr/user.lua"
}

# =========================
# Packages
# =========================
os_family() {
    local ids

    ids=$(source /etc/os-release 2> /dev/null && echo "${ID:-} ${ID_LIKE:-}")
    case " $ids " in
        *" fedora "* | *" rhel "* | *" centos "*) echo rpm ;;
        *" debian "* | *" ubuntu "*) echo deb ;;
        *" arch "*) echo arch ;;
        *) echo unknown ;;
    esac
}

# Name of a package (fedora name) for the family: pkg_name <family> <package>
pkg_name() {
    case "$1:$2" in
        rpm:ffmpeg) echo "ffmpeg-free" ;;
        rpm:*) echo "$2" ;;
        deb:libnotify) echo "libnotify-bin" ;;
        deb:mako) echo "mako-notifier" ;;
        deb:adwaita-cursor-theme) echo "adwaita-icon-theme" ;;
        deb:adwaita-sans-fonts) echo "fonts-adwaita" ;;
        deb:jetbrains-mono-fonts-all) echo "fonts-jetbrains-mono" ;;
        deb:fontawesome-6-free-fonts) echo "fonts-font-awesome" ;;
        deb:google-noto-sans-cjk-vf-fonts) echo "fonts-noto-cjk" ;;
        deb:google-noto-sans-symbols-2-fonts | deb:google-noto-serif-vf-fonts) echo "fonts-noto-core" ;;
        deb:google-noto-color-emoji-fonts) echo "fonts-noto-color-emoji" ;;
        deb:python3-gobject) echo "python3-gi" ;;
        deb:python3-cairo) echo "python3-gi-cairo" ;;
        deb:webkit2gtk4.1) echo "gir1.2-webkit2-4.1" ;;
        deb:gtk-layer-shell) echo "gir1.2-gtklayershell-0.1" ;;
        deb:gtk-session-lock) echo "gir1.2-gtksessionlock-0.1" ;;
        deb:python3-pillow) echo "python3-pil" ;;
        arch:adwaita-cursor-theme) echo "adwaita-cursors" ;;
        arch:adwaita-sans-fonts) echo "adwaita-fonts" ;;
        arch:jetbrains-mono-fonts-all) echo "ttf-jetbrains-mono" ;;
        arch:fontawesome-6-free-fonts) echo "ttf-font-awesome" ;;
        arch:google-noto-sans-cjk-vf-fonts) echo "noto-fonts-cjk" ;;
        arch:google-noto-sans-symbols-2-fonts | arch:google-noto-serif-vf-fonts) echo "noto-fonts" ;;
        arch:google-noto-color-emoji-fonts) echo "noto-fonts-emoji" ;;
        arch:python3-gobject) echo "python-gobject" ;;
        arch:python3-cairo) echo "python-cairo" ;;
        arch:webkit2gtk4.1) echo "webkit2gtk-4.1" ;;
        arch:python3-pillow) echo "python-pillow" ;;
        arch:python3-pam) echo "python-pam" ;;
        *) echo "$2" ;;
    esac
}

pkg_installed() {
    case "$1" in
        # ffmpeg of RPM Fusion counts too (the free build would conflict with it)
        rpm) rpm -q "$2" > /dev/null 2>&1 || { [[ "$2" == ffmpeg-free ]] && command -v ffmpeg > /dev/null; } ;;
        deb) dpkg-query -W -f='${Status}' "$2" 2> /dev/null | grep -q "install ok installed" ;;
        arch) pacman -Q "$2" > /dev/null 2>&1 ;;
    esac
}

pkg_available() {
    case "$1" in
        rpm) dnf -q list --available "$2" > /dev/null 2>&1 ;;
        deb) apt-cache policy "$2" 2> /dev/null | grep -q "Candidate: [^(]" ;;
        arch) pacman -Si "$2" > /dev/null 2>&1 ;;
    esac
}

# A command as root: directly, else through sudo (the graphical prompt when SUDO_ASKPASS is set)
as_root() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    elif [[ -n "${SUDO_ASKPASS:-}" ]]; then
        sudo -A "$@"
    else
        sudo "$@"
    fi
}

# Packages of a mode (fedora names): the common ones and those of its styles
packages_of() {
    local style

    printf '%s\n' "${PACKAGES[@]}"
    for style in $([[ "$1" == "all" ]] && styles || echo "$1"); do
        sed -n 's/^PACKAGES="\(.*\)"$/\1/p' "$REPO_DIR/config/styles/$style/style.env" | tr ' ' '\n'
    done
}

install_packages() {
    local family
    local name
    local -a missing=()
    local -a wanted=()
    local -a skipped=()

    family=$(os_family)
    if [[ "$family" == "unknown" ]]; then
        info "unknown distribution: install the packages yourself (README), configs only"
        return 0
    fi
    mapfile -t missing < <(packages_of "$1" | grep . | while read -r name; do pkg_name "$family" "$name"; done \
        | awk '!seen[$0]++' | while read -r name; do pkg_installed "$family" "$name" || echo "$name"; done)
    if [[ ${#missing[@]} -eq 0 ]]; then
        info "packages: everything is installed"
        return 0
    fi
    info "packages to install ($family): ${missing[*]}"
    if [[ "$family" == "rpm" && " ${missing[*]} " == *" hyprland "* ]] && ! pkg_available rpm hyprland; then
        as_root dnf install -y dnf-plugins-core && as_root dnf copr enable -y "$HYPRLAND_COPR"
    elif [[ "$family" == "deb" ]]; then
        as_root apt-get update -qq
    fi
    # a package missing in the repositories of the family is skipped
    for name in "${missing[@]}"; do
        if pkg_available "$family" "$name"; then
            wanted+=("$name")
        else
            skipped+=("$name")
        fi
    done
    if [[ ${#wanted[@]} -gt 0 ]]; then
        case "$family" in
            rpm) as_root dnf install -y "${wanted[@]}" ;;
            deb) as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${wanted[@]}" ;;
            arch) as_root pacman -S --needed --noconfirm "${wanted[@]}" ;;
        esac
    fi
    if [[ ${#skipped[@]} -gt 0 ]]; then
        info "not in the $family repositories, skipped: ${skipped[*]}"
    fi
}

# =========================
# Install / remove
# =========================
install_configs() {
    local mode="$1"
    local style
    local -a chosen

    if [[ "$mode" == "all" ]]; then
        mapfile -t chosen < <(styles)
    else
        chosen=("$mode")
    fi
    mkdir -p "$CONFIG_DIR"/{hypr,waybar,wofi,kitty,mako} "$BIN_DIR"
    for file in "${COPIES[@]}" "${LINKS[@]}"; do
        save "$file"
    done

    rm -rf "$DATA_DIR/styles"
    mkdir -p "$DATA_DIR/styles" "$DATA_DIR/bin"
    for style in "${chosen[@]}"; do
        cp -r "$REPO_DIR/config/styles/$style" "$DATA_DIR/styles/$style"
        sed -i "s|@DIR@|$DATA_DIR/styles/$style|g" "$DATA_DIR/styles/$style/hyprlock.conf"
        if [[ "$mode" != "all" ]]; then
            # one style alone: no switcher in the top bar
            sed -i '/wd-switcher-begin/,/wd-switcher-end/d; /wd-switcher$/d' "$DATA_DIR/styles/$style/waybar.jsonc"
        fi
    done

    # overview (quickshell) and the kit of the live wallpapers (the pages load ../../common/wallpaper/wd.js)
    rm -rf "$SHELL_DIR" "$DATA_DIR/common"
    mkdir -p "$SHELL_DIR" "$DATA_DIR/common"
    cp "$REPO_DIR"/config/common/quickshell/*.qml "$SHELL_DIR/"
    echo "$MARK" > "$SHELL_DIR/.$MARK"
    cp -r "$REPO_DIR/config/common/wallpaper" "$DATA_DIR/common/wallpaper"
    # the animated cursors of the styles (wd-<style>, off until wd-style cursor on)
    rm -rf "$ICONS_DIR"/wd-*
    python3 "$REPO_DIR/config/common/cursors/make-cursors.py" "$DATA_DIR/styles" "$ICONS_DIR" 2> /dev/null \
        || info "animated cursors skipped (python3 and Pillow needed)"

    cp "$REPO_DIR/config/common/hypr/hyprland.lua" "$CONFIG_DIR/hypr/hyprland.lua"
    cp "$REPO_DIR/config/common/kitty/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"
    { echo "# $MARK"; cat "$REPO_DIR/config/common/wofi/config"; } > "$CONFIG_DIR/wofi/config"
    install -m 0755 "$REPO_DIR/config/common/bin/wd-style" "$DATA_DIR/bin/wd-style"
    install -m 0755 "$REPO_DIR/config/common/bin/wd-wallpaper" "$DATA_DIR/bin/wd-wallpaper"
    ln -sfn "$DATA_DIR/bin/wd-style" "$BIN_DIR/wd-style"
    echo "$mode" > "$DATA_DIR/mode"
    write_user

    # every style: start on System, a reinstall keeps the style in use
    local style="$mode"

    if [[ "$mode" == "all" ]]; then
        style=$(cat "$DATA_DIR/current" 2> /dev/null || true)
        [[ -n "$style" && -d "$DATA_DIR/styles/$style" ]] || style=system
    fi
    "$BIN_DIR/wd-style" set "$style"
    # the offline tracks of the radios (a personal copy in ~/.local/share/wd-radio), downloaded in the background
    if command -v yt-dlp > /dev/null; then
        setsid -f "$DATA_DIR/bin/wd-wallpaper" --cache > /dev/null 2>&1 || true
    fi
    info "installed: $([[ "$mode" == "all" ]] && echo "every style + the switcher" || echo "$mode")"
    info "log out and choose Hyprland at the login screen (Super: overview, Super+Shift+W: style menu)"
}

remove_configs() {
    local file

    for file in "${LINKS[@]}" "${COPIES[@]}"; do
        if [[ -L "$CONFIG_DIR/$file" ]] || grep -q "$MARK" "$CONFIG_DIR/$file" 2> /dev/null; then
            rm -f "$CONFIG_DIR/$file"
        fi
        if [[ -e "$CONFIG_DIR/$file$BACKUP" ]]; then
            mv "$CONFIG_DIR/$file$BACKUP" "$CONFIG_DIR/$file"
            info "restored ~/.config/$file"
        fi
    done
    if [[ -e "$SHELL_DIR/.$MARK" ]]; then
        rm -rf "$SHELL_DIR"
    fi
    rm -rf "$DATA_DIR" "$ICONS_DIR"/wd-*
    rm -f "$BIN_DIR/wd-style"
    info "removed (~/.config/hypr/user.lua is kept)"
}

# =========================
# Program
# =========================
WITH_PACKAGES=1
if [[ "${1:-}" == "--no-packages" ]]; then
    WITH_PACKAGES=0
    shift
fi

CHOICE="${1:-}"
if [[ -z "$CHOICE" ]]; then
    PS3="wayland-desktop config: "
    select CHOICE in all $(styles) remove; do
        [[ -n "$CHOICE" ]] && break
    done
fi
if [[ "$CHOICE" != "all" && "$CHOICE" != "remove" && ! -d "$REPO_DIR/config/styles/$CHOICE" ]]; then
    echo "install.sh: unknown choice '$CHOICE' (all, remove, $(styles | tr '\n' ' '))" >&2
    exit 1
fi

if [[ "$CHOICE" != "remove" && "$WITH_PACKAGES" -eq 1 ]]; then
    install_packages "$CHOICE"
fi

# the configs belong to a user: as root (through sudo), they go to $SUDO_USER
if [[ $EUID -eq 0 ]]; then
    if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
        echo "install.sh: the configs go to a user: run it as your user, or through sudo" >&2
        exit 1
    fi
    exec sudo -u "$SUDO_USER" -H bash "$REPO_DIR/install.sh" --no-packages "$CHOICE"
fi

case "$CHOICE" in
    all) install_configs all ;;
    remove) remove_configs ;;
    *) install_configs "$CHOICE" ;;
esac
