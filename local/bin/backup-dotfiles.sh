#!/bin/bash
GITHUB_USER="genfire209"
REPO_NAME="dotfiles"
REPO_DIR="$HOME/.dotfiles"
REMOTE="git@github.com:$GITHUB_USER/$REPO_NAME.git"

GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
ok()   { echo -e "${GREEN}[OK]${RESET} $1"; }
info() { echo -e "${YELLOW}[INFO]${RESET} $1"; }
err()  { echo -e "${RED}[ERROR]${RESET} $1"; }

if [ ! -d "$REPO_DIR/.git" ]; then
    info "Initializing dotfiles repo..."
    mkdir -p "$REPO_DIR" && cd "$REPO_DIR" && git init
    git remote add origin "$REMOTE"
fi

cd "$REPO_DIR"
info "Saving package list..."; pacman -Qqe > "$REPO_DIR/pkglist.txt"; ok "Packages saved"

mkdir -p "$REPO_DIR/config"
for dir in hypr noctalia rofi swappy wal alacritty kitty nvim fastfetch; do
    [ -d "$HOME/.config/$dir" ] && cp -r "$HOME/.config/$dir" "$REPO_DIR/config/" && ok "Copied ~/.config/$dir"
done

mkdir -p "$REPO_DIR/local/bin"
cp -r "$HOME/.local/bin/." "$REPO_DIR/local/bin/" 2>/dev/null && ok "Copied ~/.local/bin"

mkdir -p "$REPO_DIR/fonts"
cp -r "$HOME/.local/share/fonts/." "$REPO_DIR/fonts/" 2>/dev/null

mkdir -p "$REPO_DIR/sddm/themes"
sudo cp -r /usr/share/sddm/themes/simple_sddm_2 "$REPO_DIR/sddm/themes/" && sudo chown -R "$USER:$USER" "$REPO_DIR/sddm"
sudo cp /etc/sddm.conf "$REPO_DIR/sddm/sddm.conf" 2>/dev/null && sudo chown "$USER:$USER" "$REPO_DIR/sddm/sddm.conf"

mkdir -p "$REPO_DIR/sudoers"
sudo cp /etc/sudoers.d/sddm-sync "$REPO_DIR/sudoers/sddm-sync" 2>/dev/null && sudo chown "$USER:$USER" "$REPO_DIR/sudoers/sddm-sync"

for f in .zshrc .bashrc .zprofile .profile .zshenv; do
    [ -f "$HOME/$f" ] && cp "$HOME/$f" "$REPO_DIR/$f" && ok "Copied ~/$f"
done

info "Pushing to GitHub..."
git add -A
git commit -m "dotfiles backup $(date '+%Y-%m-%d %H:%M:%S')"
git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null
[ $? -eq 0 ] && ok "Pushed to github.com/$GITHUB_USER/$REPO_NAME" || err "Push failed"
