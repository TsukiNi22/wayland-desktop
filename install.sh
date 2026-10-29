#!/bin/bash
# Usage: ./install.sh [all | <style> | remove]   (no argument: asks)
#   all       every style + the switcher (wd-style, module of the top bar, Super+Shift+W)
#   <style>   one style alone: system, dev, ado, tty, miku, photographer
#   remove    remove the configs and put back the files saved at the install
# Install the wayland-desktop configs (Hyprland, waybar, wofi, kitty, hyprlock) for the current user, never as root
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="$CONFIG_DIR/wayland-desktop"
BIN_DIR="$HOME/.local/bin"
BACKUP=".wd-backup"
MARK="wayland-desktop"

# Files managed by the install (relative to ~/.config): copies of config/common, links of the active style
COPIES=(hypr/hyprland.lua kitty/kitty.conf wofi/config)
LINKS=(hypr/style.lua hypr/hyprlock.conf waybar/config.jsonc waybar/style.css wofi/style.css kitty/theme.conf)

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
    mkdir -p "$CONFIG_DIR"/{hypr,waybar,wofi,kitty} "$BIN_DIR"
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

    cp "$REPO_DIR/config/common/hypr/hyprland.lua" "$CONFIG_DIR/hypr/hyprland.lua"
    cp "$REPO_DIR/config/common/kitty/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"
    { echo "# $MARK"; cat "$REPO_DIR/config/common/wofi/config"; } > "$CONFIG_DIR/wofi/config"
    install -m 0755 "$REPO_DIR/config/common/bin/wd-style" "$DATA_DIR/bin/wd-style"
    ln -sfn "$DATA_DIR/bin/wd-style" "$BIN_DIR/wd-style"
    echo "$mode" > "$DATA_DIR/mode"
    write_user

    # every style: start on System
    "$BIN_DIR/wd-style" set "$([[ "$mode" == "all" ]] && echo system || echo "$mode")"
    info "installed: $([[ "$mode" == "all" ]] && echo "every style + the switcher" || echo "$mode")"
    info "log out and choose Hyprland at the login screen (Super+Shift+W: style menu)"
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
    rm -rf "$DATA_DIR"
    rm -f "$BIN_DIR/wd-style"
    info "removed (~/.config/hypr/user.lua is kept)"
}

# =========================
# Program
# =========================
if [[ $EUID -eq 0 ]]; then
    echo "install.sh: run it as your user, not as root" >&2
    exit 1
fi

CHOICE="${1:-}"
if [[ -z "$CHOICE" ]]; then
    PS3="wayland-desktop config: "
    select CHOICE in all $(styles) remove; do
        [[ -n "$CHOICE" ]] && break
    done
fi

case "$CHOICE" in
    all) install_configs all ;;
    remove) remove_configs ;;
    *)
        if [[ ! -d "$REPO_DIR/config/styles/$CHOICE" ]]; then
            echo "install.sh: unknown choice '$CHOICE' (all, remove, $(styles | tr '\n' ' '))" >&2
            exit 1
        fi
        install_configs "$CHOICE"
        ;;
esac
