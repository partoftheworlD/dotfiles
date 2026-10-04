#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FILES="$ROOT_DIR/files"

if [ ! -d "$FILES" ]; then
  echo "Не нашёл папку files/ рядом со скриптом ($FILES)"
  exit 1
fi

if [ "$EUID" -eq 0 ]; then
  echo "Не запускай от root"
  exit 1
fi

sudo -v

IS_KDE=false
pgrep -x plasmashell >/dev/null && IS_KDE=true

# ---------- Списки пакетов ----------
pacman_packages=(
  fwupd git base-devel tmux btop vlc gst-plugin-pipewire duperemove neovim
  wl-clipboard gamescope lutris lib32-gnutls umu-launcher steam less
  spotify-launcher tuned tuned-ppd obs-studio obsidian pacman-contrib tldr
  snapper inotify-tools blanket grub-btrfs fish whois adobe-source-serif-fonts
  adobe-source-code-pro-fonts noto-fonts-emoji noto-fonts-cjk ttf-ubuntu-font-family
  ttf-jetbrains-mono-nerd inter-font ripgrep firewall-config 7zip openssh ldns
  mtr bluez wireplumber pipewire-pulse plasma-workspace-wallpapers gnome-backgrounds
  cups anki dnscrypt-proxy
)

aur_packages=(
  btrfs-assistant brave-bin spotx-git splix heroic-games-launcher-bin
)

remove_packages=(
  firefox htop epiphany totem gnome-tour snapshot gnome-maps rhythmbox
  gnome-music showtime gnome-boxes gnome-console evolution decibels
  gnome-software gnome-user-share gnome-contacts kdf
)

enable_services=(
  tuned tuned-ppd paccache.timer firewalld grub-btrfsd sshd bluetooth cups
)

enable_user_services=(
  pipewire pipewire-pulse wireplumber
)

kde_packages=(
  breeze breeze-cursors breeze-gtk breeze-icons kwalletmanager filelight
  dolphin dolphin-plugins kdeplasma-addons plasma-activities ark gwenview
  plasma-vault print-manager qbittorrent kio-admin kdf plasma-pa plasma-nm
  ffmpegthumbs kdegraphics-thumbnailers bluedevil
)

kde_aur_packages=( konsave )

# KDE-настройки в формате "file|group|key|value"
kde_settings=(
  "plasma-localerc|Language|Language|ru:en"
  "plasma-localerc|Formats|LANG|ru_RU.UTF-8"
  "kxkbrc|Layout|LayoutList|us,ru"
  "kxkbrc|Layout|Use|true"
  "kxkbrc|Layout|VariantList|,"
  "kxkbrc|Layout|ResetOldOptions|true"
  "kxkbrc|Layout|ShowLayoutIndicator|false"
  "kxkbrc|Layout|Options|kpdl:dotoss,grp:alt_shift_toggle,grp:win_space_toggle"
  "kscreenlockerrc|Daemon|Autolock|false"
  "powermanagementprofilesrc|AC|TurnOffDisplayIdleTimeoutSec|0"
  "powermanagementprofilesrc|Display|TurnOffDisplayIdleTimeoutSec|0"
  "kcminputrc|Keyboard|NumLock|0"
  "sddm.conf|General|Numlock|on"
  "klaunchrc|BusyCursorSettings|Bouncing|false"
  "klaunchrc|FeedbackStyle|BusyCursor|false"
  "kwinrc|Plugins|shakecursorEnabled|false"
  "plasmarc|OSD|kbdLayoutChangedEnabled|false"
  "kdeglobals|General|font|Ubuntu,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|menuFont|Ubuntu,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|smallFont|Ubuntu,8,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|toolbarFont|Ubuntu,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|activeFont|Ubuntu,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|taskbarFont|Ubuntu,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|desktopFont|Ubuntu,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|fixed|JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
  "kdeglobals|General|XftAntialias|true"
  "kdeglobals|General|XftHinting|true"
  "kdeglobals|General|XftHintStyle|hintfull"
  "kdeglobals|General|XftSubPixel|rgb"
  "kwalletrc|Wallet|Enabled|false"
)

# ---------- Локали ----------
for loc in "ru_RU.UTF-8 UTF-8" "en_US.UTF-8 UTF-8"; do
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

# ---------- Настройка pacman ----------
sudo sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
sudo sed -i 's/^#\?Color$/Color/' /etc/pacman.conf
sudo sed -i 's/^#\?VerbosePkgLists$/VerbosePkgLists/' /etc/pacman.conf

# ---------- Зеркала ----------
sudo pacman -S --needed --noconfirm reflector
sudo reflector --protocol https,http --latest 35 -n 5 --sort rate --save /etc/pacman.d/mirrorlist

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

# ---------- AUR ----------
yay -Syu --noconfirm --needed "${aur_packages[@]}"

if $IS_KDE && [ ${#kde_aur_packages[@]} -gt 0 ]; then
  yay -S --noconfirm --needed "${kde_aur_packages[@]}"
fi

# ---------- Конфиги ----------
mkdir -p "$HOME/.config/fish" "$HOME/.config/fontconfig" "$HOME/.config/nvim"

cp -v "$FILES/tmux/.tmux.conf"       "$HOME/.tmux.conf"
cp -v "$FILES/fish/config.fish"      "$HOME/.config/fish/config.fish"
cp -v "$FILES/neovim/init.lua"       "$HOME/.config/nvim/init.lua"
cp -v "$FILES/neovim/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"
cp -v "$FILES/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"

sudo mkdir -p /etc/dnscrypt-proxy
sudo cp -v "$FILES/dnscrypt/dnscrypt-proxy.toml" /etc/dnscrypt-proxy/
sudo cp -v "$FILES/dnscrypt/cloaking-rules.txt"  /etc/dnscrypt-proxy/
sudo cp -v "$FILES/dnscrypt/blocked-names.txt"   /etc/dnscrypt-proxy/

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

# ---------- Перезагрузка ----------
echo "Готово. Перезагрузка через 5 секунд..."
sleep 5
sudo reboot