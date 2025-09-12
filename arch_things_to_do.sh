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
sed -i 's/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen > /dev/null 2>&1

# Optimize pacman package manager for faster downloads and efficient updates
color_echo "yellow" "Configuring pacman Package Manager..."
backup_file "/etc/pacman.conf"
pacman -S reflector --noconfirm > /dev/null 2>&1
reflector --verbose --latest 10 --sort rate > /dev/null 2>&1
sed -i 's/#Color/Color/' /etc/pacman.conf

# System Upgrade
color_echo "blue" "Performing system upgrade... This may take a while..."
pacman -Syyu --noconfirm > /dev/null 2>&1

# Install Flatpak
color_echo "yellow" "Installing Flathub"
pacman -S flatpak --noconfirm > /dev/null 2>&1
flatpak mask org.freedesktop.Platform.openh264
flatpak repair > /dev/null 2>&1
flatpak update > /dev/null 2>&1

# Check and apply firmware updates to improve hardware compatibility and performance
color_echo "yellow" "Checking for firmware updates..."
pacman -S fwupd --noconfirm > /dev/null 2>&1
fwupdmgr refresh --force > /dev/null 2>&1
fwupdmgr get-updates -y > /dev/null 2>&1
fwupdmgr update -y > /dev/null 2>&1

# Enable AUR repositories to access additional software packages
color_echo "yellow" "Enabling AUR repositories..."
pacman -S --needed git base-devel --noconfirm > /dev/null 2>&1
sudo -u $ACTUAL_USER git clone https://aur.archlinux.org/paru-bin.git > /dev/null 2>&1
cd paru-bin
sudo -u $ACTUAL_USER makepkg -si --noconfirm > /dev/null 2>&1

# Install multimedia codecs to enhance multimedia capabilities
color_echo "yellow" "Installing multimedia codecs..."
pacman -S flac faac svt-av1 aom dav1d rav1e x265 x264 libvpx lib32-libvpx --noconfirm > /dev/null 2>&1

# App Installation
# Install essential applications
color_echo "yellow" "Installing essential applications..."
pacman -S tmux btop git wget curl ttf-jetbrains-mono inter-font duperemove neovim gamescope lutris steam gamemode less spotify-launcher code gufw tuned cups splix obs-studio obsidian pacman-contrib tldr gnome-firmware fwupd --noconfirm > /dev/null 2>&1
sudo -u $ACTUAL_USER paru -S btrfs-assistant brave-bin --noconfirm > /dev/null 2>&1
sudo -u $ACTUAL_USER flatpak install heroic protonplus bazaar -y > /dev/null 2>&1
color_echo "green" "Essential applications installed successfully."

# Download dotfiles
color_echo "yellow" "Download configs..."
cd /tmp/
git clone https://github.com/partoftheworlD/dotfiles/ > /dev/null 2>&1
color_echo "green" "Configs downloaded successfully."

# Customization
# Install Microsoft Windows fonts (windows)
# color_echo "yellow" "Installing Microsoft Fonts (windows)..."
# pacman -S -y wget cabextract fontconfig
# wget -4 -O /tmp/winfonts.zip https://mktr.sbs/fonts
# mkdir -p $ACTUAL_HOME/.local/share/fonts/windows
# unzip /tmp/winfonts.zip -d $ACTUAL_HOME/.local/share/fonts/windows
# rm -f /tmp/winfonts.zip
# fc-cache -fv
# color_echo "green" "Microsoft Fonts (windows) installed successfully."

# Install Adobe fonts collection
color_echo "yellow" "Installing Adobe Fonts..."
pacman -S adobe-source-sans-fonts adobe-source-serif-fonts adobe-source-code-pro-fonts --noconfirm > /dev/null 2>&1
fc-cache -fv > /dev/null 2>&1
color_echo "green" "Adobe Fonts installed successfully."

# Install Ubuntu fonts collection
color_echo "yellow" "Installing Ubuntu Fonts..."
pacman -S ttf-ubuntu-font-family --noconfirm > /dev/null 2>&1
fc-cache -fv > /dev/null 2>&1
color_echo "green" "Ubuntu Fonts installed successfully."

# Copy tmux config
color_echo "yellow" "Installing tmux config..."
cp /tmp/dotfiles/.tmux.conf $ACTUAL_HOME
color_echo "green" "Tmux config installed successfully."

# Remove Firefox
color_echo "yellow" "Removing Firefox..."
pacman -Rsn firefox htop --noconfirm > /dev/null 2>&1
color_echo "green" "Firefox removed successfully."

# Install SpotX
color_echo "yellow" "Installing SpotX..."
sudo -u $ACTUAL_USER paru -S spotx-git --noconfirm > /dev/null 2>&1
color_echo "green" "SpotX installed successfully."

# Custom user-defined commands
color_echo "yellow" "Cleanup.."
pacman -Rsn $(pacman -Qtdq) --noconfirm  > /dev/null 2>&1

#KDE fix italic font for desktop icons
# sed -i 's/font.italic: model.isLink/\/\/ \0/' /usr/share/plasma/plasmoids/org.kde.desktopcontainment/contents/ui/FolderItemDelegate.qml

# Install konsave and restore desktop
# sudo -u $ACTUAL_USER paru -S konsave --noconfirm > /dev/null 2>&1
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
