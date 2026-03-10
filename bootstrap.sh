#!/bin/bash
# Full bootstrap script for aarjithk
# Run this on a fresh Arch base install (no DE needed)
# It will install everything and restore your dotfiles

GITHUB_USER="genfire209"
REPO_NAME="dotfiles"
REPO_DIR="$HOME/.dotfiles"

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

# ── Install openssh early ──────────────────────────────────────────────────────
step "Installing openssh..."
sudo pacman -S --needed --noconfirm openssh
ok "openssh installed"

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

# ── Install all packages ───────────────────────────────────────────────────────
step "Installing packages (this will take a while)..."

# Pacman packages (filter out AUR-only ones)
PACMAN_PKGS=(
    adobe-source-code-pro-fonts amd-ucode base base-devel bc
    blueman bluez bluez-utils brightnessctl btop cava cliphist
    cpupower cups cups-pk-helper dnsmasq efibootmgr fastfetch
    ffmpegthumbnailer firefox flatpak fzf gdb ghostscript git
    gnome-system-monitor go grim grub gst-plugin-pipewire
    gtk-engine-murrine gvfs gvfs-mtp hyprland imagemagick
    intel-compute-runtime intel-graphics-compiler inxi iptables-nft
    jdk-openjdk jq keyd kitty kvantum less libpulse libspng
    libvirt linux linux-firmware loupe lsd ltrace mercurial micro
    mpv mpv-mpris nano neovim network-manager-applet networkmanager
    nodejs noto-fonts noto-fonts-emoji npm ntfs-3g nvtop opendoas
    os-prober otf-font-awesome pacman-contrib pamixer pavucontrol
    perl-image-exiftool pipewire pipewire-alsa pipewire-jack
    pipewire-pulse playerctl powertop python-pip python-pywal
    python-requests qalculate-gtk qemu-full qt5-quickcontrols2
    qt6-5compat qt6-virtualkeyboard rofi ruby sddm sharutils
    slurp sof-firmware sox spice-vdagent stow sudo swappy
    system-config-printer tcpdump thunar thunar-archive-plugin
    thunar-volman tk tlp tlp-rdw ttf-droid ttf-fira-code
    ttf-jetbrains-mono tumbler umockdev unrar unzip upower vim
    virt-manager virt-viewer vulkan-radeon wget wireplumber
    wlsunset wpa_supplicant xarchiver xdg-desktop-portal-gtk
    xdg-user-dirs zram-generator zsh zsh-completions
    multimon-ng inxi binwalk hashcat hexedit john wireshark-cli
)

sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" 2>/dev/null
ok "Pacman packages installed"

# AUR packages
AUR_PKGS=(
    noctalia-shell
    noctalia-qs
    grimblast-git
    python-pywalfox
    python-passlib
    python-pyquery
    ttf-fantasque-nerd
    ttf-jetbrains-mono-nerd
    ttf-victor-mono
    yay-bin
    rockyou
    ryujinx-bin
    tor-browser-bin
    steghide
    stegseek
    rocm-llvm
    rocm-opencl-runtime
    radeontool
    multimon-ng
)

info "Installing AUR packages..."
yay -S --needed --noconfirm "${AUR_PKGS[@]}" 2>/dev/null
ok "AUR packages installed"

# ── Set up SSH key for GitHub ──────────────────────────────────────────────────
step "Setting up SSH key for GitHub..."
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "genfire2009@gmail.com" -f "$HOME/.ssh/id_ed25519" -N ""
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}║  Add this SSH key to GitHub before continuing:       ║${RESET}"
    echo -e "${YELLOW}║  https://github.com/settings/keys                    ║${RESET}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${RESET}"
    echo ""
    cat "$HOME/.ssh/id_ed25519.pub"
    echo ""
    read -p "Press Enter once you've added the key to GitHub..."
else
    ok "SSH key already exists"
fi

# Test GitHub connection
ssh -T git@github.com 2>&1 | grep -q "successfully authenticated" && ok "GitHub SSH OK" || {
    err "GitHub SSH not working. Make sure you added the key."
    exit 1
}

# ── Clone dotfiles ─────────────────────────────────────────────────────────────
step "Cloning dotfiles from GitHub..."
if [ ! -d "$REPO_DIR/.git" ]; then
    git clone git@github.com:$GITHUB_USER/$REPO_NAME.git "$REPO_DIR"
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
    cp -r "$REPO_DIR/ryujinx/." "$HOME/.config/Ryujinx/"
    ok "Ryujinx saves restored"
fi

# ── Enable services ────────────────────────────────────────────────────────────
step "Enabling services..."
sudo systemctl enable sddm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable libvirtd
sudo systemctl enable tlp
ok "Services enabled"

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

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║           Bootstrap complete! Reboot now.            ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
read -p "Reboot now? (y/n): " REBOOT
[[ "$REBOOT" == "y" ]] && sudo reboot
