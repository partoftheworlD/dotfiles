#!/bin/bash
# "Things To Do!" script for a fresh Arch installation

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# Funtion to echo colored text
color_echo() {
    local color="$1"
    local text="$2"
    case "$color" in
        "red")     echo -e "\033[0;31m$text\033[0m" ;;
        "green")   echo -e "\033[0;32m$text\033[0m" ;;
        "yellow")  echo -e "\033[1;33m$text\033[0m" ;;
        "blue")    echo -e "\033[0;34m$text\033[0m" ;;
        *)         echo "$text" ;;
    esac
}

# Set variables
ACTUAL_USER=$SUDO_USER
ACTUAL_HOME=$(eval echo ~$SUDO_USER)
LOG_FILE="/var/log/arch_things_to_do.log"
INITIAL_DIR=$(pwd)

# Function to generate timestamps
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Function to log messages
log_message() {
    local message="$1"
    echo "$(get_timestamp) - $message" | tee -a "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    local exit_code=$?
    local message="$1"
    if [ $exit_code -ne 0 ]; then
        color_echo "red" "ERROR: $message"
        exit $exit_code
    fi
}

# Function to prompt for reboot
prompt_reboot() {
    sudo -u $ACTUAL_USER bash -c 'read -p "It is time to reboot the machine. Would you like to do it now? (y/n): " choice; [[ $choice == [yY] ]]'
    if [ $? -eq 0 ]; then
        color_echo "green" "Rebooting..."
        reboot
    else
        color_echo "red" "Reboot canceled."
    fi
}

# Function to backup configuration files
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.bak"
        handle_error "Failed to backup $file"
        color_echo "green" "Backed up $file"
    fi
}

color_echo "red" "Don't run this script if you didn't build it yourself or don't know what it does."
echo ""
read -p "Press Enter to continue or CTRL+C to cancel..."

# Change locale
color_echo "yellow" "Setup Russian locale..."
sed -i 's/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/; s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# Optimize pacman package manager for faster downloads and efficient updates
color_echo "yellow" "Configuring pacman Package Manager..."

backup_file "/etc/pacman.conf"
sed -i 's/ParallelDownloads = 5/ParallelDownloads = 10\nColor\nVerbosePkgLists/' /etc/pacman.conf
pacman -S reflector --noconfirm
reflector --verbose --protocol https,http --latest 50 -n 5 --sort rate --save /etc/pacman.d/mirrorlist
sed -i 's/https/https,http/; s/age/rate/' /etc/xdg/reflector/reflector.conf

# System Upgrade
color_echo "blue" "Performing system upgrade... This may take a while..."
pacman -Syyu --noconfirm

# Install Flatpak
color_echo "yellow" "Installing Flathub"

pacman -S flatpak --noconfirm
flatpak mask org.freedesktop.Platform.openh264
flatpak repair
flatpak update

# Check and apply firmware updates to improve hardware compatibility and performance
color_echo "yellow" "Checking for firmware updates..."

pacman -S fwupd --noconfirm
fwupdmgr refresh --force
fwupdmgr get-updates -y
fwupdmgr update -y

# Enable AUR repositories to access additional software packages
color_echo "yellow" "Enabling AUR repositories..."

pacman -S --needed git base-devel --noconfirm
sudo pacman -S --needed git base-devel
sudo -u $ACTUAL_USER git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
sudo -u $ACTUAL_USER makepkg -si --noconfirm

# Install multimedia codecs to enhance multimedia capabilities
color_echo "yellow" "Installing multimedia codecs..."
pacman -S ffmpeg gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav aom dav1d libwebp lame opencore-amr libfdk-aac flac opus faac libavif libheif libvpx --noconfirm

# App Installation
# Install essential applications
color_echo "yellow" "Installing essential applications..."
pacman -S tmux btop git vlc wget curl duperemove neovim gamescope lutris steam gamemode less spotify-launcher code gufw tuned tuned-ppd cups splix obs-studio obsidian pacman-contrib tldr gnome-firmware bash-completion seahorse snapper blanket ptyxis extension-manager apparmor grub-btrfs inotify-tools libva-mesa-driver lib32-libva-mesa-driver fish --noconfirm
sudo -u $ACTUAL_USER yay -S btrfs-assistant brave-bin --noconfirm
sudo -u $ACTUAL_USER flatpak install heroic protonplus -y
color_echo "green" "Essential applications installed successfully."

# Install Adobe fonts collection
color_echo "yellow" "Update Fonts cache..."
pacman -S adobe-source-sans-fonts adobe-source-serif-fonts adobe-source-code-pro-fonts noto-fonts-emoji ttf-ubuntu-font-family ttf-jetbrains-mono inter-font ttf-liberation ttf-dejavu --noconfirm
fc-cache -fv

# Copy tmux config
color_echo "yellow" "Installing tmux config..."
cp /tmp/dotfiles/tmux/.tmux.conf $ACTUAL_HOME
color_echo "green" "Tmux config installed successfully."

# Remove Unwanted applications
color_echo "yellow" "Removing unwanted applications..."
pacman -Rsn $(pacman -Qs | grep -oP '/\K(firefox|htop|epiphany|totem|gnome-tour|snapshot|gnome-maps|rhytmbox|gnome-music|showtime|gnome-boxes|gnome-console|evolution|vim|vim-runtime|decibels)(?=\s|$)') --noconfirm 
color_echo "green" "Unwanted applications removed"

# Install SpotX
color_echo "yellow" "Installing SpotX..."
sudo -u $ACTUAL_USER yay -S spotx-git --noconfirm
color_echo "green" "SpotX installed successfully."

# Custom user-defined commands
# systemctl list-units-files --type=service --state=disabled
color_echo "yellow" "Turn on Services.."

systemctl enable --now tuned
systemctl enable --now tuned-ppd

systemctl enable --now paccache.timer
systemctl enable --now ufw
systemctl enable --now apparmor

systemctl enable --now grub-btrfsd

color_echo "yellow" "Cleanup.."
pacman -Rsn $(pacman -Qtdq) --noconfirm
sudo -u $ACTUAL_USER yay -Sc --noconfirm

#Remove icons
rm $(grep -rE "Name=(Avahi|Electron|Qt)" /usr/share/applications/ | awk -F":" '{print $1}')

# Change bash to fish
chsh -s /usr/bin/fish $ACTUAL_USER

#KDE fix italic font for desktop icons
# sed -i 's/font.italic: model.isLink/\/\/ \0/' /usr/share/plasma/plasmoids/org.kde.desktopcontainment/contents/ui/FolderItemDelegate.qml

# Install konsave and restore desktop
# sudo -u $ACTUAL_USER paru -S konsave --noconfirm
# export PATH="$ACTUAL_HOME/.local/bin:$PATH"

# cp -r /tmp/dotfiles/konsave/ $ACTUAL_HOME
# konsave -i $ACTUAL_HOME/konsave/kde_desktop.knsv
# konsave -a kde_desktop

# Custom user-defined commands
echo "Created with ❤️ for Open Source"


# Before finishing, ensure we're in a safe directory
cd /tmp || cd $ACTUAL_HOME || cd /

# Finish
color_echo "green" "All steps completed. Enjoy!"

# Prompt for reboot
prompt_reboot
