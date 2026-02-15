#!/bin/bash
# "Things To Do!" script for a fresh Fedora installation


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
LOG_FILE="/var/log/fedora_things_to_do.log"
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

echo "";
echo "╔═════════════════════════════════════════════════════════════════════════════╗";
echo "║                                                                             ║";
echo "║   ░█▀▀░█▀▀░█▀▄░█▀█░█▀▄░█▀█░░░█░█░█▀█░█▀▄░█░█░█▀▀░▀█▀░█▀█░▀█▀░▀█▀░█▀█░█▀█░   ║";
echo "║   ░█▀▀░█▀▀░█░█░█░█░█▀▄░█▀█░░░█▄█░█░█░█▀▄░█▀▄░▀▀█░░█░░█▀█░░█░░░█░░█░█░█░█░   ║";
echo "║   ░▀░░░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░░░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░░▀░░▀░▀░░▀░░▀▀▀░▀▀▀░▀░▀░   ║";
echo "║   ░░░░░░░░░░░░▀█▀░█░█░▀█▀░█▀█░█▀▀░█▀▀░░░▀█▀░█▀█░░░█▀▄░█▀█░█░░░░░░░░░░░░░░   ║";
echo "║   ░░░░░░░░░░░░░█░░█▀█░░█░░█░█░█░█░▀▀█░░░░█░░█░█░░░█░█░█░█░▀░░░░░░░░░░░░░░   ║";
echo "║   ░░░░░░░░░░░░░▀░░▀░▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░░░░▀░░▀▀▀░░░▀▀░░▀▀▀░▀░░░░░░░░░░░░░░   ║";
echo "║                                                                             ║";
echo "╚═════════════════════════════════════════════════════════════════════════════╝";
echo "";
echo "This script automates \"Things To Do!\" steps after a fresh Fedora installation"
echo "ver. 25.03"
echo ""
echo "Don't run this script if you didn't build it yourself or don't know what it does."
echo ""
read -p "Press Enter to continue or CTRL+C to cancel..."

# Optimize DNF package manager for faster downloads and efficient updates
color_echo "yellow" "Configuring DNF Package Manager..."
backup_file "/etc/dnf/dnf.conf"
echo -e "max_parallel_downloads=5\nfastestmirror=True\ntimeout=5\nminrate=1M" | tee -a /etc/dnf/dnf.conf
dnf config-manager setopt fedora-cisco-openh264.enabled=0
dnf config-manager setopt copr:copr.fedorainfracloud.org:phracek:PyCharm.enabled=0
dnf config-manager setopt rpmfusion-nonfree-nvidia-driver.enabled=0

color_echo "blue" "Performing system upgrade... This may take a while..."

dnf update -y --refresh

# System Configuration
# Set the system hostname to uniquely identify the machine on the network
color_echo "yellow" "Setting hostname..."
hostnamectl set-hostname fedora

# Replace Fedora Flatpak Repo with Flathub for better package management and apps stability
color_echo "yellow" "Replacing Fedora Flatpak Repo with Flathub..."

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-delete fedora --force || true
flatpak mask org.freedesktop.Platform.openh264
flatpak repair
flatpak update

# Check and apply firmware updates to improve hardware compatibility and performance
color_echo "yellow" "Checking for firmware updates..."
fwupdmgr refresh --force
fwupdmgr get-updates -y
fwupdmgr update -y

# Install and enable SSH server for secure remote access and file transfers
color_echo "yellow" "Installing and enabling SSH..."
systemctl enable --now sshd

# Enable RPM Fusion and Terra repositories to access additional software packages and codecs
color_echo "yellow" "Enabling RPM Fusion repositories..."
dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf update @core -y

# Install multimedia codecs to enhance multimedia capabilities
color_echo "yellow" "Installing multimedia codecs..."
dnf swap ffmpeg-free ffmpeg --allowerasing -y
dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf install @sound-and-video -y

# Install Hardware Accelerated Codecs for AMD GPUs. 
# This improves video playback and encoding performance on systems with AMD graphics.
color_echo "yellow" "Installing AMD Hardware Accelerated Codecs..."
dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y

# App Installation
# Install essential applications
color_echo "yellow" "Installing essential applications..."
dnf install -y tmux btop git wget curl jetbrains-mono-fonts rsms-inter-fonts duperemove btrfs-assistant neovim gamescope lutris steam gamemode gnome-tweaks splix tldr vlc libavcodec-freeworld ffmpeg-libs yaru-theme xdg-terminal-exec seahorse fish
flatpak install -y heroic protonplus com.mattjakeman.ExtensionManager com.github.tchx84.Flatseal md.obsidian.Obsidian spotify blanket
color_echo "green" "Essential applications installed successfully."

# Install Internet & Communication applications
color_echo "yellow" "Installing Brave..."
dnf install -y dnf-plugins-core
curl -fsS https://dl.brave.com/install.sh | sh
color_echo "green" "Brave installed successfully."

# Install Coding and DevOps applications
color_echo "yellow" "Installing Visual Studio Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo
dnf check-update
dnf install -y code

color_echo "green" "Visual Studio Code installed successfully."

# Install Adobe fonts collection
color_echo "yellow" "Installing Adobe Fonts..."
dnf in adobe-source-sans-pro-fonts adobe-source-code-pro-fonts adobe-source-serif-pro-fonts -y
color_echo "green" "Adobe Fonts installed successfully."

# Install Ubuntu fonts collection
color_echo "yellow" "Installing Ubuntu Fonts..."
mkdir -p $ACTUAL_HOME/.local/share/fonts/ubuntu
cd /tmp/
wget -4 -O ubuntu.zip https://assets.ubuntu.com/v1/0cef8205-ubuntu-font-family-0.83.zip
unzip ubuntu.zip
chmod 644 ubuntu-font-family-0.83/*.ttf
cp ubuntu-font-family-0.83/*.ttf $ACTUAL_HOME/.local/share/fonts/ubuntu
fc-cache -fv
color_echo "green" "Ubuntu Fonts installed successfully."

# color_echo "yellow" "Installing Microsoft Fonts (windows)..."
# dnf install -y wget cabextract xorg-x11-font-utils fontconfig
# wget -O /tmp/winfonts.zip https://mktr.sbs/fonts
# mkdir -p $ACTUAL_HOME/.local/share/fonts/windows
# unzip /tmp/winfonts.zip -d $ACTUAL_HOME/.local/share/fonts/windows
# rm -f /tmp/winfonts.zip
# fc-cache -fv
# color_echo "green" "Microsoft Fonts (windows) installed successfully."

# Copy tmux config
color_echo "yellow" "Installing tmux config..."
cp /tmp/dotfiles/tmux/.tmux.conf $ACTUAL_HOME
color_echo "green" "Tmux config installed successfully."

# Remove Unwanted applications
color_echo "yellow" "Removing unwanted applications..."
dnf rm firefox* libreoffice* totem-video-thumbnailer gnome-tour gnome-maps rhythmbox gnome-music yelp showtime gnome-contacts gnome-boxes snapshot evolution gnome-sound-recorder shotwell decibels -y
color_echo "green" "Unwanted applications removed successfully."

# Install SpotX
color_echo "yellow" "Installing SpotX..."
bash <(curl -sSL https://spotx-official.github.io/run.sh)
color_echo "green" "SpotX installed successfully."

chsh -s /usr/bin/fish
mkdir -p $ACTUAL_HOME/.config/fish
echo 'set -g fish_greeting ""' | tee "$ACTUAL_HOME/.config/fish/config.fish" > /dev/null

dnf autoremove -y
dnf clean all

#KDE fix italic font for desktop icons
#sed -i 's/font.italic: model.isLink/\/\/ \0/' /usr/share/plasma/plasmoids/org.kde.desktopcontainment/contents/ui/FolderItemDelegate.qml

# Install konsave and restore desktop
#dnf in python3-pip -y
#python -m pip install konsave

#cp -r /tmp/dotfiles/konsave/ $ACTUAL_HOME
#konsave -i $ACTUAL_HOME/konsave/kde_desktop.knsv
#konsave -a kde_desktop

# Custom user-defined commands
echo "Created with ❤️ for Open Source"


# Before finishing, ensure we're in a safe directory
cd /tmp || cd $ACTUAL_HOME || cd /

# Finish
echo "";
echo "╔═════════════════════════════════════════════════════════════════════════╗";
echo "║                                                                         ║";
echo "║   ░█░█░█▀▀░█░░░█▀▀░█▀█░█▄█░█▀▀░░░▀█▀░█▀█░░░█▀▀░█▀▀░█▀▄░█▀█░█▀▄░█▀█░█░   ║";
echo "║   ░█▄█░█▀▀░█░░░█░░░█░█░█░█░█▀▀░░░░█░░█░█░░░█▀▀░█▀▀░█░█░█░█░█▀▄░█▀█░▀░   ║";
echo "║   ░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░░░░▀░░▀▀▀░░░▀░░░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░▀░   ║";
echo "║                                                                         ║";
echo "╚═════════════════════════════════════════════════════════════════════════╝";
echo "";
color_echo "green" "All steps completed. Enjoy!"

# Prompt for reboot
prompt_reboot
