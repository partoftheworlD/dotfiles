#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FILES="$ROOT_DIR/files"

if [ ! -d "$FILES" ]; then
  echo "Не нашёл папку files/ рядом со скриптом ($FILES)"
  exit 1
fi

if [ "$EUID" -eq 0 ]; then
  echo "Не запускай от root. Запусти от обычного пользователя."
  exit 1
fi

sudo -v

# ---------- Пакеты ----------
apt_packages=(
  tmux btop git curl neovim gamescope lutris steam-installer qbittorrent vlc
  obs-studio fonts-inter-variable fonts-jetbrains-mono gnome-software
  gnome-software-plugin-deb gnome-software-plugin-fwupd gnome-software-plugin-flatpak
  ubuntu-restricted-extras gnome-tweaks tldr-py blanket printer-driver-splix
  flatseal ffmpeg fish flatpak fwupd fonts-adobe-sourcesans3 wget python3-pip
  apt-transport-https ca-certificates software-properties-common gnupg
  gnome-shell-extensions unzip ripgrep apt-file mtr dnscrypt-proxy
  btrfs-assistant snapper 7zip
)

flatpak_packages=(
  com.heroicgameslauncher.hgl
  com.vysp3r.ProtonPlus
  md.obsidian.Obsidian
  com.mattjakeman.ExtensionManager
  net.ankiweb.Anki
)

remove_packages=(
  'firefox*' 'libreoffice*' totem-video-thumbnailer gnome-tour gnome-maps
  rhythmbox gnome-music showtime gnome-contacts gnome-boxes gnome-snapshot
  gnome-terminal evolution gnome-sound-recorder shotwell vim-tiny vim-common
)

# ---------- Базовая подготовка ----------
sudo dpkg --add-architecture i386
sudo apt update
sudo apt upgrade -y
sudo hostnamectl set-hostname megabuntu

# ---------- Удаление snapd ----------
sudo systemctl stop snapd.service snapd.socket 2>/dev/null || true
sudo systemctl disable snapd.service snapd.socket 2>/dev/null || true
sudo systemctl mask snapd.service snapd.socket 2>/dev/null || true

sudo apt purge -y snapd || true
sudo apt-mark hold snapd || true

sudo rm -rf /var/cache/snapd/ /root/snap/ "$HOME/snap/"
echo -e "Package: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee /etc/apt/preferences.d/nosnap.pref > /dev/null

# ---------- Установка APT-пакетов ----------
sudo apt install -y "${apt_packages[@]}"

# ---------- Flatpak ----------
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak mask --user org.freedesktop.Platform.openh264 || true
flatpak repair --user || true
flatpak update --user -y
flatpak install --user -y flathub "${flatpak_packages[@]}"

# ---------- Сторонние приложения ----------
curl -fsS https://dl.brave.com/install.sh | sudo sh

wget -O /tmp/code.deb https://update.code.visualstudio.com/latest/linux-deb-x64/stable
sudo apt install -y /tmp/code.deb

curl -sSL https://spotx-official.github.io/run.sh | sudo bash -s -f --installdeb || true

# ---------- Шрифты ----------
sudo fc-cache -f

# ---------- Конфиги пользователя ----------
mkdir -p "$HOME/.config/fish" "$HOME/.config/nvim" "$HOME/.config/fontconfig"

cp -v "$FILES/tmux/.tmux.conf"       "$HOME/.tmux.conf"
cp -v "$FILES/fish/config.fish"      "$HOME/.config/fish/config.fish"
cp -v "$FILES/neovim/init.lua"       "$HOME/.config/nvim/init.lua"
cp -v "$FILES/neovim/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"
cp -v "$FILES/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"

# ---------- Конфиги dnscrypt (системные) ----------
sudo mkdir -p /etc/dnscrypt-proxy
sudo cp -v "$FILES/dnscrypt/dnscrypt-proxy.toml" /etc/dnscrypt-proxy/
sudo cp -v "$FILES/dnscrypt/cloaking-rules.txt"  /etc/dnscrypt-proxy/
sudo cp -v "$FILES/dnscrypt/blocked-names.txt"   /etc/dnscrypt-proxy/

# ---------- Смена shell на fish ----------
sudo chsh -s /usr/bin/fish "$USER"

# ---------- Удаление лишнего ----------
sudo apt purge -y "${remove_packages[@]}" || true
sudo apt autoremove -y --purge || true
sudo apt clean || true

# ---------- SSH-ключ ----------
[ -f "$HOME/.ssh/id_ed25519" ] || ssh-keygen -t ed25519 -N "" -a 32 -f "$HOME/.ssh/id_ed25519"

if pgrep -x gnome-shell >/dev/null; then
  gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'
  gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu 11'
  gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
  gsettings set org.gnome.desktop.interface font-hinting 'full'
  gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
  gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 11'
  gsettings set org.gnome.desktop.interface toolkit-accessibility false
  gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true
  gsettings set org.gnome.desktop.peripherals.keyboard remember-numlock-state true
  gsettings set org.gnome.desktop.screensaver lock-enabled false
  gsettings set org.gnome.settings-daemon.plugins.housekeeping donation-reminder-enabled false
  gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
  gsettings set org.gnome.shell enabled-extensions "['background-logo@fedorahosted.org', 'dash-to-dock@micxgx.gmail.com', 'clipboard-indicator@tudmotu.com', 'ding@rastersoft.com']"
  gsettings set org.gnome.desktop.input-sources mru-sources "[('xkb', 'ru'), ('xkb', 'us')]"
  gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'ru'), ('xkb', 'us')]"
  gsettings set org.gnome.desktop.input-sources xkb-options "['kpdl:dotoss', 'grp:alt_shift_toggle']"
  gsettings set org.gnome.shell favorite-apps "['brave-browser.desktop', 'obsidian.desktop', 'md.obsidian.Obsidian.desktop', 'spotify-launcher.desktop', 'com.spotify.Client.desktop', 'steam.desktop', 'code.desktop', 'com.obsproject.Studio.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Calculator.desktop']"
  gsettings set org.gnome.system.locale region 'ru_RU.UTF-8'
fi

echo "Готово. Перезагрузка через 5 секунд..."
sleep 5
sudo systemctl reboot -i