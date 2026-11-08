#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FILES="$ROOT_DIR/playbook/files"

if [ "$EUID" -eq 0 ]; then
  echo "Не запускай от root"
  exit 1
fi

sudo -v

IS_KDE=false
IS_GNOME=false
pgrep -x plasmashell >/dev/null && IS_KDE=true
pgrep -x gnome-shell >/dev/null && IS_GNOME=true

# ---------- Списки пакетов ----------
pacman_packages=(
  adobe-source-code-pro-fonts noto-fonts-emoji noto-fonts-cjk ttf-ubuntu-font-family
  cups anki dnscrypt-proxy ffmpeg vlc-plugins-all
  fwupd git base-devel tmux btop vlc gst-plugin-pipewire duperemove neovim
  mtr bluez wireplumber pipewire-pulse plasma-workspace-wallpapers gnome-backgrounds
  snapper inotify-tools blanket grub-btrfs fish whois adobe-source-serif-fonts
  spotify-launcher tuned tuned-ppd obsidian pacman-contrib tldr
  ttf-jetbrains-mono-nerd inter-font ripgrep 7zip openssh ldns
  wl-clipboard gamescope lutris lib32-gnutls umu-launcher steam less jq
)

aur_packages=(
  btrfs-assistant spotx-git splix google-chrome 
)

remove_packages=(
  firefox htop epiphany totem gnome-tour snapshot gnome-maps rhythmbox
  gnome-music showtime gnome-boxes gnome-console evolution decibels
  gnome-software gnome-user-share gnome-contacts kdf
)

enable_services=(
  tuned tuned-ppd paccache.timer ufw grub-btrfsd sshd bluetooth cups
)

enable_user_services=(
  pipewire pipewire-pulse wireplumber
)

kde_packages=(
  breeze breeze-cursors breeze-gtk breeze-icons kwalletmanager filelight
  dolphin dolphin-plugins kdeplasma-addons plasma-activities ark gwenview
  ffmpegthumbs kdegraphics-thumbnailers bluedevil
  plasma-vault print-manager qbittorrent kio-admin kdf plasma-pa plasma-nm
)

kde_aur_packages=( konsave )

gnome_packages=(ptyxis extension-manager gnome-firmware gnome-tweaks seahorse fragments)

gnome_aur_packages=( nautilus-open-in-ptyxis )

# KDE-настройки в формате "file|group|key|value"
kde_settings=(
  "kcminputrc|Keyboard|NumLock|0"
  "kdeglobals|General|activeFont|Ubuntu,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|desktopFont|Ubuntu,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|fixed|JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|font|Ubuntu,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|menuFont|Ubuntu,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|smallFont|Ubuntu,8,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|taskbarFont|Ubuntu,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|toolbarFont|Ubuntu,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|XftAntialias|true"
  "kdeglobals|General|XftHinting|true"
  "kdeglobals|General|XftHintStyle|hintfull"
  "kdeglobals|General|XftSubPixel|rgb"
  "klaunchrc|BusyCursorSettings|Bouncing|false"
  "klaunchrc|FeedbackStyle|BusyCursor|false"
  "kscreenlockerrc|Daemon|Autolock|false"
  "kwalletrc|Wallet|Enabled|false"
  "kwinrc|Plugins|shakecursorEnabled|false"
  "kxkbrc|Layout|LayoutList|us,ru"
  "kxkbrc|Layout|Options|kpdl:dotoss,grp:alt_shift_toggle,grp:win_space_toggle"
  "kxkbrc|Layout|ResetOldOptions|true"
  "kxkbrc|Layout|ShowLayoutIndicator|false"
  "kxkbrc|Layout|Use|true"
  "kxkbrc|Layout|VariantList|,"
  "plasma-localerc|Formats|LANG|ru_RU.UTF-8"
  "plasma-localerc|Language|Language|ru:en"
  "plasmarc|OSD|kbdLayoutChangedEnabled|false"
  "powermanagementprofilesrc|AC|TurnOffDisplayIdleTimeoutSec|0"
  "powermanagementprofilesrc|Display|TurnOffDisplayIdleTimeoutSec|0"
  "sddm.conf|General|Numlock|on"
)

# ---------- Локали ----------
for loc in "ru_RU.UTF-8 UTF-8"; do
  grep -qxF "$loc" /etc/locale.gen || echo "$loc" | sudo tee -a /etc/locale.gen >/dev/null
done
sudo locale-gen
sudo localectl set-locale LANG=ru_RU.UTF-8

# ---------- KDE: настройка интерфейса ----------
if $IS_KDE; then
  for entry in "${kde_settings[@]}"; do
    IFS='|' read -r file group key value <<< "$entry"
    kwriteconfig6 --file "$file" --group "$group" --key "$key" "$value"
  done

  # Язык для новых пользователей
  sudo mkdir -p /etc/skel/.config
  printf '[Language]\nLanguage=ru:en\n' | sudo tee /etc/skel/.config/plasma-localerc >/dev/null
fi

# ---------- GNOME: настройка интерфейса ----------
if $IS_GNOME; then
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
  gsettings set org.gnome.shell enabled-extensions "['dash-to-dock@micxgx.gmail.com', 'clipboard-indicator@tudmotu.com', 'ding@rastersoft.com']"
  gsettings set org.gnome.desktop.input-sources mru-sources "[('xkb', 'ru'), ('xkb', 'us')]"
  gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'ru'), ('xkb', 'us')]"
  gsettings set org.gnome.desktop.input-sources xkb-options "['kpdl:dotoss', 'grp:alt_shift_toggle']"
  gsettings set org.gnome.shell favorite-apps "['obsidian.desktop', 'md.obsidian.Obsidian.desktop', 'spotify-launcher.desktop', 'com.spotify.Client.desktop', 'steam.desktop', 'code.desktop', 'com.obsproject.Studio.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Calculator.desktop']"
  gsettings set org.gnome.system.locale region 'ru_RU.UTF-8'
fi

# ---------- Настройка pacman ----------
sudo sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
sudo sed -i 's/^#\?Color$/Color/' /etc/pacman.conf
sudo sed -i 's/^#\?VerbosePkgLists$/VerbosePkgLists/' /etc/pacman.conf

# ---------- Зеркала ----------
sudo pacman -S --needed --noconfirm reflector
sudo reflector --protocol https,http --latest 50 -n 5 --sort rate --save /etc/pacman.d/mirrorlist

# ---------- База ----------
sudo pacman -Syu --needed --noconfirm base-devel git less

# ---------- yay-bin ----------
if ! command -v yay >/dev/null; then
  rm -rf /tmp/yay-bin
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
  (cd /tmp/yay-bin && makepkg -si --noconfirm)
fi

# ---------- Основные пакеты ----------
sudo pacman -S --needed --noconfirm "${pacman_packages[@]}"

if $IS_KDE; then
  sudo pacman -S --needed --noconfirm "${kde_packages[@]}"
fi

if $IS_GNOME; then
  sudo pacman -S --needed --noconfirm "${gnome_packages[@]}"
fi

# ---------- AUR ----------
yay -Syu --noconfirm --needed "${aur_packages[@]}"

if $IS_KDE && [ ${#kde_aur_packages[@]} -gt 0 ]; then
  yay -S --noconfirm --needed "${kde_aur_packages[@]}"
fi

if $IS_GNOME && [ ${#gnome_aur_packages[@]} -gt 0 ]; then
  yay -S --noconfirm --needed "${gnome_aur_packages[@]}"
fi

# ---------- Конфиги ----------
mkdir -p "$HOME/.config/fish" "$HOME/.config/fontconfig" "$HOME/.config/nvim"

cp -v "$FILES/tmux/.tmux.conf"       "$HOME/.tmux.conf"
cp -v "$FILES/fish/config.fish"      "$HOME/.config/fish/config.fish"
cp -v "$FILES/neovim/init.lua"       "$HOME/.config/nvim/init.lua"
cp -v "$FILES/neovim/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"
cp -v "$FILES/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"

# sudo mkdir -p /etc/dnscrypt-proxy
# sudo cp -v "$FILES/dnscrypt/dnscrypt-proxy.toml" /etc/dnscrypt-proxy/
# sudo cp -v "$FILES/dnscrypt/cloaking-rules.txt"  /etc/dnscrypt-proxy/
# sudo cp -v "$FILES/dnscrypt/blocked-names.txt"   /etc/dnscrypt-proxy/

# ---------- Shell ----------
sudo chsh -s /usr/bin/fish "$USER"

# ---------- Сервисы ----------
sudo systemctl daemon-reload
for svc in "${enable_services[@]}"; do
  sudo systemctl enable --now "$svc" || true
done
for svc in "${enable_user_services[@]}"; do
  systemctl --user enable --now "$svc" || true
done

# ---------- KDE: импорт konsave ----------
if $IS_KDE && command -v konsave >/dev/null; then
  (
    cd "$FILES/konsave"
    7z x konsave.7z.001 -y >/dev/null
    konsave -i konsave.knsv || true
    konsave -a konsave || true
  )
fi

# ---------- Удаление лишнего ----------
for pkg in "${remove_packages[@]}"; do
  if pacman -Qi "$pkg" &>/dev/null; then
    sudo pacman -Rsn "$pkg" --noconfirm || true
  fi
done

# debug-пакеты
debug_pkgs=$(pacman -Qq 2>/dev/null | rg -- '-debug$' || true)
if [ -n "$debug_pkgs" ]; then
  sudo pacman -Rsn $debug_pkgs --noconfirm || true
fi

# осиротевшие
orphans=$(pacman -Qtdq 2>/dev/null || true)
if [ -n "$orphans" ]; then
  sudo pacman -Rsn $orphans --noconfirm || true
fi

# ---------- Удаление иконок ненужных приложений ----------
files=$(grep -rlE "Name=(Avahi|Electron|Qt)" /usr/share/applications/ 2>/dev/null || true)
if [ -n "$files" ]; then
  sudo rm $files
fi

# ---------- Кэши ----------
yay -Scc --noconfirm || true
fc-cache -f

# ---------- SSH ----------
[ -f "$HOME/.ssh/id_ed25519" ] || ssh-keygen -t ed25519 -N "" -a 32 -f "$HOME/.ssh/id_ed25519"
sudo ufw allow ssh

# ---------- Перезагрузка ----------
echo "Готово. Перезагрузка через 5 секунд..."
sleep 5
sudo reboot
