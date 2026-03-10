#!/bin/bash
# Dotfiles restore script for aarjithk
# Run this on a fresh Arch + Hyprland install to restore everything

GITHUB_USER="genfire209"
REPO_NAME="dotfiles"
REPO_DIR="$HOME/.dotfiles"
REMOTE="git@github.com:$GITHUB_USER/$REPO_NAME.git"

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

ok()   { echo -e "${GREEN}[OK]${RESET} $1"; }
info() { echo -e "${YELLOW}[INFO]${RESET} $1"; }
err()  { echo -e "${RED}[ERROR]${RESET} $1"; }

# ── Clone repo ─────────────────────────────────────────────────────────────────
if [ ! -d "$REPO_DIR/.git" ]; then
    info "Cloning dotfiles from GitHub..."
    git clone "$REMOTE" "$REPO_DIR"
    if [ $? -ne 0 ]; then
        err "Failed to clone repo. Make sure SSH keys are set up."
        exit 1
    fi
fi

cd "$REPO_DIR"
ok "Dotfiles repo ready at $REPO_DIR"

# ── Reinstall packages ─────────────────────────────────────────────────────────
if [ -f "$REPO_DIR/pkglist.txt" ]; then
    info "Reinstalling packages from pkglist.txt..."
    # Install packages, skip ones that fail (e.g. AUR packages not yet available)
    sudo pacman -S --needed --noconfirm - < "$REPO_DIR/pkglist.txt" 2>/dev/null
    ok "Packages restored (AUR packages may need manual install with yay)"
else
    info "No pkglist.txt found, skipping package install"
fi

# ── Restore configs ────────────────────────────────────────────────────────────
info "Restoring ~/.config directories..."
mkdir -p "$HOME/.config"
if [ -d "$REPO_DIR/config" ]; then
    cp -r "$REPO_DIR/config/." "$HOME/.config/"
    ok "Configs restored to ~/.config"
fi

# ── Restore local bin scripts ──────────────────────────────────────────────────
info "Restoring ~/.local/bin scripts..."
mkdir -p "$HOME/.local/bin"
if [ -d "$REPO_DIR/local/bin" ]; then
    cp -r "$REPO_DIR/local/bin/." "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/"* 2>/dev/null
    ok "Scripts restored to ~/.local/bin"
fi

# ── Restore fonts ──────────────────────────────────────────────────────────────
info "Restoring fonts..."
mkdir -p "$HOME/.local/share/fonts"
if [ -d "$REPO_DIR/fonts" ] && [ "$(ls -A $REPO_DIR/fonts)" ]; then
    cp -r "$REPO_DIR/fonts/." "$HOME/.local/share/fonts/"
    fc-cache -f
    ok "Fonts restored"
fi

# ── Restore SDDM theme ─────────────────────────────────────────────────────────
info "Restoring SDDM theme..."
if [ -d "$REPO_DIR/sddm/themes/simple_sddm_2" ]; then
    sudo cp -r "$REPO_DIR/sddm/themes/simple_sddm_2" /usr/share/sddm/themes/
    ok "SDDM theme restored"
fi

# ── Restore SDDM config ────────────────────────────────────────────────────────
if [ -f "$REPO_DIR/sddm/sddm.conf" ]; then
    sudo cp "$REPO_DIR/sddm/sddm.conf" /etc/sddm.conf
    ok "SDDM config restored"
fi

# ── Restore sudoers rule ───────────────────────────────────────────────────────
info "Restoring sudoers rule..."
if [ -f "$REPO_DIR/sudoers/sddm-sync" ]; then
    # Update username in sudoers rule in case it changed
    sudo cp "$REPO_DIR/sudoers/sddm-sync" /etc/sudoers.d/sddm-sync
    sudo chmod 440 /etc/sudoers.d/sddm-sync
    ok "Sudoers rule restored"
fi

# ── Restore shell configs ──────────────────────────────────────────────────────
info "Restoring shell configs..."
for f in .zshrc .bashrc .zprofile .profile .zshenv; do
    if [ -f "$REPO_DIR/$f" ]; then
        cp "$REPO_DIR/$f" "$HOME/$f"
        ok "Restored ~/$f"
    fi
done

# ── Fix permissions on SDDM background ────────────────────────────────────────
sudo chmod 666 /usr/share/sddm/themes/simple_sddm_2/Backgrounds/default 2>/dev/null
ok "SDDM background permissions set"

echo ""
ok "Restore complete! You may want to reboot."
info "AUR packages from pkglist.txt may need manual install:"
info "  yay -S \$(cat ~/.dotfiles/pkglist.txt)"
