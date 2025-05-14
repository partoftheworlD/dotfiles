#!/bin/bash
# "Things To Do!" script for a fresh Fedora Workstation installation



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
echo "This script automates \"Things To Do!\" steps after a fresh Fedora Workstation installation"
echo "ver. 25.03"
echo ""
echo "Don't run this script if you didn't build it yourself or don't know what it does."
echo ""
read -p "Press Enter to continue or CTRL+C to cancel..."

# System Upgrade
color_echo "blue" "Performing system upgrade... This may take a while..."
dnf upgrade -y > /dev/null 2>&1


# System Configuration
# Set the system hostname to uniquely identify the machine on the network
color_echo "yellow" "Setting hostname..."
hostnamectl set-hostname fedora > /dev/null 2>&1

# Optimize DNF package manager for faster downloads and efficient updates
color_echo "yellow" "Configuring DNF Package Manager..."
backup_file "/etc/dnf/dnf.conf" > /dev/null 2>&1
echo "max_parallel_downloads=10" | tee -a /etc/dnf/dnf.conf > /dev/null > /dev/null 2>&1
dnf -y install dnf-plugins-core > /dev/null 2>&1

# Replace Fedora Flatpak Repo with Flathub for better package management and apps stability
color_echo "yellow" "Replacing Fedora Flatpak Repo with Flathub..."
dnf install -y flatpak > /dev/null 2>&1
flatpak remote-delete fedora --force || true > /dev/null 2>&1
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo > /dev/null 2>&1
sudo flatpak repair > /dev/null 2>&1
flatpak update > /dev/null 2>&1

# Check and apply firmware updates to improve hardware compatibility and performance
color_echo "yellow" "Checking for firmware updates..."
fwupdmgr refresh --force > /dev/null 2>&1
fwupdmgr get-updates > /dev/null 2>&1
fwupdmgr update -y > /dev/null 2>&1

# Enable RPM Fusion repositories to access additional software packages and codecs
color_echo "yellow" "Enabling RPM Fusion repositories..."
dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm > /dev/null 2>&1
dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm > /dev/null 2>&1
dnf group update core -y > /dev/null 2>&1

# Install multimedia codecs to enhance multimedia capabilities
color_echo "yellow" "Installing multimedia codecs..."
dnf swap ffmpeg-free ffmpeg --allowerasing -y > /dev/null 2>&1
dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf update @sound-and-video -y

# Install Hardware Accelerated Codecs for AMD GPUs. This improves video playback and encoding performance on systems with AMD graphics.
color_echo "yellow" "Installing AMD Hardware Accelerated Codecs..."
dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y > /dev/null 2>&1
dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y > /dev/null 2>&1


# App Installation
# Install essential applications
color_echo "yellow" "Installing essential applications..."
dnf install -y btop git wget curl jetbrains-mono-fonts rsms-inter-fonts duperemove btrfs-assistant neovim gamescope lutris steam distrobox > /dev/null 2>&1
color_echo "green" "Essential applications installed successfully."

# Install Internet & Communication applications
color_echo "yellow" "Installing Brave..."
dnf install -y dnf-plugins-core > /dev/null 2>&1
if command -v dnf4 &>/dev/null; then > /dev/null 2>&1
  dnf4 config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo > /dev/null 2>&1
else > /dev/null 2>&1
  dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo > /dev/null 2>&1
fi > /dev/null 2>&1
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc > /dev/null 2>&1
dnf install -y brave-browser > /dev/null 2>&1
color_echo "green" "Brave installed successfully."

# Install Coding and DevOps applications
color_echo "yellow" "Installing Visual Studio Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc > /dev/null 2>&1
echo -e "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null > /dev/null 2>&1
dnf check-update > /dev/null 2>&1
dnf install -y code > /dev/null 2>&1
color_echo "green" "Visual Studio Code installed successfully."

# Customization
# Install Microsoft Windows fonts (windows)
color_echo "yellow" "Installing Microsoft Fonts (windows)..."
dnf install -y wget cabextract xorg-x11-font-utils fontconfig > /dev/null 2>&1
wget -O /tmp/winfonts.zip https://mktr.sbs/fonts > /dev/null 2>&1
mkdir -p $ACTUAL_HOME/.local/share/fonts/windows > /dev/null 2>&1
unzip /tmp/winfonts.zip -d $ACTUAL_HOME/.local/share/fonts/windows > /dev/null 2>&1
rm -f /tmp/winfonts.zip > /dev/null 2>&1
fc-cache -fv > /dev/null 2>&1
color_echo "green" "Microsoft Fonts (windows) installed successfully."

# Install Adobe fonts collection
color_echo "yellow" "Installing Adobe Fonts..."
mkdir -p $ACTUAL_HOME/.local/share/fonts/adobe-fonts > /dev/null 2>&1
git clone --depth 1 https://github.com/adobe-fonts/source-sans.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-sans > /dev/null 2>&1
git clone --depth 1 https://github.com/adobe-fonts/source-serif.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-serif > /dev/null 2>&1
git clone --depth 1 https://github.com/adobe-fonts/source-code-pro.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-code-pro > /dev/null 2>&1
fc-cache -f > /dev/null 2>&1
color_echo "green" "Adobe Fonts installed successfully."

# Remove Firefox
color_echo "yellow" "Removing Firefox..."
dnf rm firefox -y
color_echo "green" "Firefox deleted successfully."

# Custom user-defined commands
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
