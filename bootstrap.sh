#!/bin/bash
# Full bootstrap script for aarjithk
# Run this on a fresh Arch base install (no DE needed)

GITHUB_USER="genfire209"
REPO_NAME="dotfiles"
REPO_DIR="$HOME/.dotfiles"
FAILED_PKGS=()

GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; CYAN="\e[36m"; RESET="\e[0m"
ok()   { echo -e "${GREEN}[OK]${RESET} $1"; }
info() { echo -e "${YELLOW}[INFO]${RESET} $1"; }
err()  { echo -e "${RED}[ERROR]${RESET} $1"; }
step() { echo -e "\n${CYAN}==> $1${RESET}"; }

# ── Must not run as root ───────────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
    err "Do not run as root. Run as your normal user."
    exit 1
fi

# ── Check internet ─────────────────────────────────────────────────────────────
step "Checking internet connection..."
if ! ping -c 1 archlinux.org &>/dev/null; then
    err "No internet connection. Connect first."
    exit 1
fi
ok "Internet OK"

# ── Full system update ─────────────────────────────────────────────────────────
step "Updating system..."
sudo pacman -Syu --noconfirm
ok "System updated"

# ── Install yay ───────────────────────────────────────────────────────────────
step "Installing yay AUR helper..."
if ! command -v yay &>/dev/null; then
    sudo pacman -S --needed --noconfirm git base-devel
    cd /tmp
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin && makepkg -si --noconfirm
    cd ~ && rm -rf /tmp/yay-bin
    ok "yay installed"
else
    ok "yay already installed"
fi

# ── Helper to install packages one by one and track failures ──────────────────
install_pacman_pkg() {
    local pkg="$1"
    if ! sudo pacman -S --needed --noconfirm "$pkg" &>/dev/null; then
        err "Failed to install: $pkg"
        FAILED_PKGS+=("$pkg")
    else
        ok "Installed: $pkg"
    fi
}

install_aur_pkg() {
    local pkg="$1"
    if ! yay -S --needed --noconfirm "$pkg"; then
        err "Failed to install AUR: $pkg"
        FAILED_PKGS+=("$pkg (AUR)")
    else
        ok "Installed AUR: $pkg"
    fi
}

# ── Install pacman packages ────────────────────────────────────────────────────
step "Installing pacman packages (this will take a while)..."

PACMAN_PKGS=(
    adobe-source-code-pro-fonts amd-ucode base base-devel bc
    blueman bluez bluez-utils brightnessctl btop cava cliphist
    cpupower cups cups-pk-helper dnsmasq efibootmgr fastfetch
    ffmpegthumbnailer firefox flatpak fzf gdb ghostscript git
    gnome-system-monitor go grim grub gst-plugin-pipewire
    gtk-engine-murrine gvfs gvfs-mtp hyprland imagemagick
    inxi iptables-nft jdk-openjdk jq keyd kitty kvantum less
    libpulse libspng libvirt linux linux-firmware loupe lsd ltrace
    mercurial micro mpv mpv-mpris nano neovim network-manager-applet
    networkmanager nodejs noto-fonts noto-fonts-emoji npm ntfs-3g
    nvtop opendoas os-prober otf-font-awesome pacman-contrib pamixer
    pavucontrol perl-image-exiftool pipewire pipewire-alsa pipewire-jack
    pipewire-pulse playerctl powertop python-pip python-pywal
    python-requests qalculate-gtk qemu-full qt5-quickcontrols2
    qt6-5compat qt6-multimedia qt6-virtualkeyboard rofi ruby sddm
    sharutils slurp sof-firmware sox spice-vdagent stow sudo swappy
    system-config-printer tcpdump thunar thunar-archive-plugin
    thunar-volman tk tlp tlp-rdw ttf-droid ttf-fira-code
    ttf-jetbrains-mono tumbler umockdev unrar unzip upower vim
    virt-manager virt-viewer vulkan-radeon wget wireplumber
    wlsunset wpa_supplicant xarchiver xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland xdg-user-dirs zram-generator
    zsh zsh-completions binwalk hashcat hexedit john wireshark-cli
)

for pkg in "${PACMAN_PKGS[@]}"; do
    install_pacman_pkg "$pkg"
done
ok "Pacman packages done"

# ── Install AUR packages ───────────────────────────────────────────────────────
step "Installing AUR packages (this will take a while)..."

AUR_PKGS=(
    grimblast-git
    python-pywalfox
    python-passlib
    python-pyquery
    ttf-fantasque-nerd
    ttf-jetbrains-mono-nerd
    ttf-victor-mono
    rockyou
    ryujinx-bin
    tor-browser-bin
    steghide
    stegseek
    rocm-llvm
    rocm-opencl-runtime
    radeontop
    multimon-ng
)

for pkg in "${AUR_PKGS[@]}"; do
    install_aur_pkg "$pkg"
done
ok "AUR packages done"

# ── Install Noctalia explicitly ────────────────────────────────────────────────
step "Installing Noctalia..."
install_aur_pkg "noctalia-qs"
install_aur_pkg "noctalia-shell"
ok "Noctalia done"

# ── Clone dotfiles ─────────────────────────────────────────────────────────────
step "Cloning dotfiles from GitHub..."
if [ ! -d "$REPO_DIR/.git" ]; then
    git clone https://github.com/$GITHUB_USER/$REPO_NAME.git "$REPO_DIR"
    ok "Dotfiles cloned"
else
    cd "$REPO_DIR" && git pull
    ok "Dotfiles updated"
fi

# ── Restore configs ────────────────────────────────────────────────────────────
step "Restoring configs..."
mkdir -p "$HOME/.config"
cp -r "$REPO_DIR/config/." "$HOME/.config/"
ok "Configs restored"

# ── Restore local bin scripts ──────────────────────────────────────────────────
step "Restoring scripts..."
mkdir -p "$HOME/.local/bin"
cp -r "$REPO_DIR/local/bin/." "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/"* 2>/dev/null
ok "Scripts restored"

# ── Restore fonts ──────────────────────────────────────────────────────────────
step "Restoring fonts..."
mkdir -p "$HOME/.local/share/fonts"
if [ -d "$REPO_DIR/fonts" ] && [ "$(ls -A $REPO_DIR/fonts 2>/dev/null)" ]; then
    cp -r "$REPO_DIR/fonts/." "$HOME/.local/share/fonts/"
    fc-cache -f
    ok "Fonts restored"
fi

# ── Restore SDDM theme ─────────────────────────────────────────────────────────
step "Restoring SDDM theme..."
sudo mkdir -p /usr/share/sddm/themes/
sudo cp -r "$REPO_DIR/sddm/themes/simple_sddm_2" /usr/share/sddm/themes/
sudo cp "$REPO_DIR/sddm/sddm.conf" /etc/sddm.conf
sudo chmod 666 /usr/share/sddm/themes/simple_sddm_2/Backgrounds/default
ok "SDDM theme restored"

# ── Restore sudoers rule ───────────────────────────────────────────────────────
step "Restoring sudoers rule..."
sudo cp "$REPO_DIR/sudoers/sddm-sync" /etc/sudoers.d/sddm-sync
sudo chmod 440 /etc/sudoers.d/sddm-sync
ok "Sudoers rule restored"

# ── Restore shell configs ──────────────────────────────────────────────────────
step "Restoring shell configs..."
for f in .zshrc .bashrc .zprofile .profile .zshenv; do
    [ -f "$REPO_DIR/$f" ] && cp "$REPO_DIR/$f" "$HOME/$f" && ok "Restored ~/$f"
done

# ── Restore Ryujinx saves ──────────────────────────────────────────────────────
step "Restoring Ryujinx saves..."
mkdir -p "$HOME/.config/Ryujinx"
if [ -d "$REPO_DIR/ryujinx" ] && [ "$(ls -A $REPO_DIR/ryujinx 2>/dev/null)" ]; then
    cp -r "$REPO_DIR/ryujinx/bis" "$HOME/.config/Ryujinx/"
    cp -r "$REPO_DIR/ryujinx/profiles" "$HOME/.config/Ryujinx/" 2>/dev/null
    cp "$REPO_DIR/ryujinx/Config.json" "$HOME/.config/Ryujinx/" 2>/dev/null
    cp -r "$REPO_DIR/ryujinx/system" "$HOME/.config/Ryujinx/" 2>/dev/null
    ok "Ryujinx saves restored — saves will appear automatically when you launch Ryujinx"
fi

# ── Enable services ────────────────────────────────────────────────────────────
step "Enabling services..."
sudo systemctl enable sddm && ok "sddm enabled" || err "sddm failed"
sudo systemctl enable NetworkManager && ok "NetworkManager enabled" || err "NetworkManager failed"
sudo systemctl enable bluetooth && ok "bluetooth enabled" || err "bluetooth failed"
sudo systemctl enable libvirtd && ok "libvirtd enabled" || err "libvirtd failed"
sudo systemctl enable tlp && ok "tlp enabled" || err "tlp failed"

# ── Add user to groups ─────────────────────────────────────────────────────────
step "Adding user to groups..."
sudo usermod -aG libvirt,input,video,audio "$USER"
ok "Groups updated"

# ── Set zsh as default shell ───────────────────────────────────────────────────
step "Setting zsh as default shell..."
chsh -s /bin/zsh
ok "zsh set as default shell"

# ── Git identity ───────────────────────────────────────────────────────────────
git config --global user.email "genfire2009@gmail.com"
git config --global user.name "genfire209"

# ── Summary of failed packages ────────────────────────────────────────────────
echo ""
if [ ${#FAILED_PKGS[@]} -gt 0 ]; then
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║         The following packages failed to install:    ║${RESET}"
    echo -e "${RED}╚══════════════════════════════════════════════════════╝${RESET}"
    for pkg in "${FAILED_PKGS[@]}"; do
        echo -e "  ${RED}✗${RESET} $pkg"
    done
    echo ""
    echo -e "${YELLOW}Install them manually with:${RESET}"
    echo -e "  pacman: sudo pacman -S <package>"
    echo -e "  AUR:    yay -S <package>"
else
    echo -e "${GREEN}All packages installed successfully!${RESET}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║           Bootstrap complete! Reboot now.            ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
read -p "Reboot now? (y/n): " REBOOT
[[ "$REBOOT" == "y" ]] && sudo reboot
