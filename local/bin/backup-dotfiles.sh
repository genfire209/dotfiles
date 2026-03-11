#!/bin/bash
# Dotfiles backup script for aarjithk
# Backs up configs, packages, SDDM theme, scripts, fonts to GitHub

GITHUB_USER="genfire209"
REPO_NAME="dotfiles"
REPO_DIR="$HOME/.dotfiles"
REMOTE="https://github.com/$GITHUB_USER/$REPO_NAME.git"

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

ok()   { echo -e "${GREEN}[OK]${RESET} $1"; }
info() { echo -e "${YELLOW}[INFO]${RESET} $1"; }
err()  { echo -e "${RED}[ERROR]${RESET} $1"; }

# ── Init repo if needed ────────────────────────────────────────────────────────
if [ ! -d "$REPO_DIR/.git" ]; then
    info "Initializing dotfiles repo at $REPO_DIR"
    mkdir -p "$REPO_DIR"
    cd "$REPO_DIR" && git init
    git remote add origin "$REMOTE" 2>/dev/null || true
fi

cd "$REPO_DIR"

# ── Package list ───────────────────────────────────────────────────────────────
info "Saving package list..."
pacman -Qqe > "$REPO_DIR/pkglist.txt"
ok "Package list saved"

# ── Configs ────────────────────────────────────────────────────────────────────
info "Copying ~/.config directories..."
CONFIG_DIRS=(
    hypr
    noctalia
    rofi
    swappy
    wal
    alacritty
    kitty
    nvim
    fastfetch
)

mkdir -p "$REPO_DIR/config"
for dir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$HOME/.config/$dir" ]; then
        cp -r "$HOME/.config/$dir" "$REPO_DIR/config/"
        ok "Copied ~/.config/$dir"
    fi
done

# ── Local bin scripts ──────────────────────────────────────────────────────────
info "Copying ~/.local/bin scripts..."
mkdir -p "$REPO_DIR/local/bin"
cp -r "$HOME/.local/bin/." "$REPO_DIR/local/bin/" 2>/dev/null && ok "Copied ~/.local/bin" || info "~/.local/bin is empty or missing"

# ── Fonts ──────────────────────────────────────────────────────────────────────
info "Copying fonts..."
mkdir -p "$REPO_DIR/fonts"
cp -r "$HOME/.local/share/fonts/." "$REPO_DIR/fonts/" 2>/dev/null && ok "Copied fonts" || info "No user fonts found"

# ── SDDM theme ─────────────────────────────────────────────────────────────────
info "Copying SDDM theme..."
mkdir -p "$REPO_DIR/sddm/themes"
sudo cp -r /usr/share/sddm/themes/simple_sddm_2 "$REPO_DIR/sddm/themes/" && ok "Copied SDDM theme"
sudo chown -R "$USER:$USER" "$REPO_DIR/sddm"

# ── SDDM config ────────────────────────────────────────────────────────────────
info "Copying SDDM config..."
mkdir -p "$REPO_DIR/sddm"
sudo cp /etc/sddm.conf "$REPO_DIR/sddm/sddm.conf" 2>/dev/null && ok "Copied /etc/sddm.conf"
sudo chown "$USER:$USER" "$REPO_DIR/sddm/sddm.conf" 2>/dev/null || true

# ── Sudoers rule ───────────────────────────────────────────────────────────────
info "Copying sudoers rule..."
mkdir -p "$REPO_DIR/sudoers"
sudo cp /etc/sudoers.d/sddm-sync "$REPO_DIR/sudoers/sddm-sync" 2>/dev/null && ok "Copied sudoers rule"
sudo chown "$USER:$USER" "$REPO_DIR/sudoers/sddm-sync" 2>/dev/null || true

# ── Ryujinx saves ─────────────────────────────────────────────────────────────
info "Copying Ryujinx saves..."
mkdir -p "$REPO_DIR/ryujinx"
cp -r "$HOME/.config/Ryujinx/." "$REPO_DIR/ryujinx/" 2>/dev/null && ok "Copied Ryujinx data" || info "No Ryujinx data found"

# ── Shell configs ──────────────────────────────────────────────────────────────
info "Copying shell configs..."
for f in .zshrc .bashrc .zprofile .profile .zshenv; do
    if [ -f "$HOME/$f" ]; then
        cp "$HOME/$f" "$REPO_DIR/$f"
        ok "Copied ~/$f"
    fi
done

# ── Git commit and push ────────────────────────────────────────────────────────
info "Committing and pushing to GitHub..."
cd "$REPO_DIR"
git add -A
git commit -m "dotfiles backup $(date '+%Y-%m-%d %H:%M:%S')" || info "Nothing new to commit"

# Try pushing, set upstream on first push
git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null

if [ $? -eq 0 ]; then
    ok "Pushed to github.com/$GITHUB_USER/$REPO_NAME"
else
    err "Push failed — make sure the repo exists on GitHub and SSH keys are set up"
    info "Create the repo at: https://github.com/new"
    info "Then run: cd ~/.dotfiles && git push -u origin main"
fi

echo ""
ok "Backup complete! Repo: $REPO_DIR"
