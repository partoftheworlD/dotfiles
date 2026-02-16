#!/bin/bash
# "Things To Do!" script for a fresh Ubuntu installation


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
LOG_FILE="/var/log/ubuntu_things_to_do.log"
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

echo "Don't run this script if you didn't build it yourself or don't know what it does."
echo ""
read -p "Press Enter to continue or CTRL+C to cancel..."

# System Upgrade
color_echo "blue" "Performing system upgrade... This may take a while..."
dpkg --add-architecture i386 
apt update -y
apt upgrade -y

# System Configuration
# Set the system hostname to uniquely identify the machine on the network
color_echo "yellow" "Setting hostname..."
hostnamectl set-hostname ubuntu

# Remove snaps
color_echo "blue" "Remove snap"
# snap list | awk 'NR>1 {print $1}' | xargs -r snap remove --purge
apt remove --purge snapd -y

apt-mark hold snapd

systemctl stop snapd.service snapd.socket
systemctl disable snapd.service snapd.socket
systemctl mask snapd.service snapd.socket

echo 'Package: snapd\nPin: release a=*\nPin-Priority: -10' | tee /etc/apt/preferences.d/nosnap.pref
rm -rf /var/cache/snapd/ ~/snap/

# Flatpak
color_echo "yellow" "Setup Flathub..."
apt install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak repair
flatpak mask org.freedesktop.Platform.openh264
flatpak update -y

# Check and apply firmware updates to improve hardware compatibility and performance
color_echo "yellow" "Checking for firmware updates..."
fwupdmgr refresh --force
fwupdmgr get-updates -y
fwupdmgr update -y

# App Installation
# Install essential applications
color_echo "yellow" "Installing essential applications..."
apt install tmux btop git curl neovim gamescope lutris steam qbittorrent vlc obs-studio fonts-inter-variable fonts-jetbrains-mono gnome-software gnome-software-plugin-deb gnome-software-plugin-fwupd gnome-software-plugin-flatpak ubuntu-restricted-extras gnome-tweaks tldr-py blanket printer-driver-splix flatseal ffmpeg fish -y
# apt-btrfs-snapshot
flatpak install heroic protonplus bazaar md.obsidian.Obsidian -y
color_echo "green" "Essential applications installed successfully."

# Install Internet & Communication applications
color_echo "yellow" "Installing Brave..."
curl -fsS https://dl.brave.com/install.sh | sh
color_echo "green" "Brave installed successfully."

# Install Coding and DevOps applications
color_echo "yellow" "Installing Visual Studio Code..."
wget -4 -O code.deb https://update.code.visualstudio.com/latest/linux-deb-x64/stable
apt install ./code.deb -y
color_echo "green" "Visual Studio Code installed successfully."

# Customization
# Install Microsoft Windows fonts (windows)
# color_echo "yellow" "Installing Microsoft Fonts (windows)..."
# apt install -y wget cabextract xorg-x11-font-utils fontconfig
# wget -4 -O /tmp/winfonts.zip https://mktr.sbs/fonts
# mkdir -p $ACTUAL_HOME/.local/share/fonts/windows
# unzip /tmp/winfonts.zip -d $ACTUAL_HOME/.local/share/fonts/windows
# rm -f /tmp/winfonts.zip
# fc-cache -fv
# color_echo "green" "Microsoft Fonts (windows) installed successfully."

# Install Adobe fonts collection
color_echo "yellow" "Installing Adobe Fonts..."
mkdir -p $ACTUAL_HOME/.local/share/fonts/adobe-fonts
apt install fonts-adobe-sourcesans3 -y
git clone --depth 1 https://github.com/adobe-fonts/source-serif.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-serif
git clone --depth 1 https://github.com/adobe-fonts/source-code-pro.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-code-pro
fc-cache -fv
color_echo "green" "Adobe Fonts installed successfully."

# Copy tmux config
color_echo "yellow" "Installing tmux config..."
cp /tmp/dotfiles/tmux/.tmux.conf $ACTUAL_HOME
color_echo "green" "Tmux config installed successfully."

# Install spotify
color_echo "yellow" "Installing Spotify..."
curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
apt update -y
apt install spotify-client -y
color_echo "green" "Spotify installed successfully."

# Install SpotX
color_echo "yellow" "Installing SpotX..."
bash <(curl -sSL https://spotx-official.github.io/run.sh) --installdeb
color_echo "green" "SpotX installed successfully."

# Remove Unwanted applications
color_echo "yellow" "Removing unwanted applications..."
apt remove firefox* libreoffice* totem-video-thumbnailer gnome-tour gnome-maps rhythmbox gnome-music showtime gnome-contacts gnome-boxes gnome-snapshot gnome-terminal evolution gnome-sound-recorder shotwell -y
color_echo "green" "Unwanted applications removed successfully."

chsh -s /usr/bin/fish
mkdir -p $ACTUAL_HOME/.config/fish
echo 'set -g fish_greeting ""' | tee "$ACTUAL_HOME/.config/fish/config.fish" > /dev/null

apt autoremove -y
apt clean all

#KDE fix italic font for desktop icons
# sed -i 's/font.italic: model.isLink/\/\/ \0/' /usr/share/plasma/plasmoids/org.kde.desktopcontainment/contents/ui/FolderItemDelegate.qml

# Install konsave and restore desktop
# apt install python3-pip -y
# python -m pip install konsave

# cp -r /tmp/dotfiles/konsave/ $ACTUAL_HOME
# konsave -i $ACTUAL_HOME/konsave/kde_desktop.knsv
# konsave -a kde_desktop

# Custom user-defined commands
# echo "Created with ❤️ for Open Source"


# Before finishing, ensure we're in a safe directory
cd /tmp || cd $ACTUAL_HOME || cd /

# Finish
color_echo "green" "All steps completed. Enjoy!"

# Prompt for reboot
prompt_reboot
