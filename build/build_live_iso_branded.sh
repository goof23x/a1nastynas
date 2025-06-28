#!/bin/bash
set -e

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Enhanced branding banner
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║     ▄▀█ ▄█ █▄ █ ▄▀█ █▀   █▄▄ █▀█ ▄▀█ █▄ █ █▀▄ █▀▀ █▀▄         ║
║     █▄█ ▀█ █▀▄█ █▄█ ▄█   █▄█ █▀▄ █▄█ █▀▄█ █▄▀ ██▄ █▄▀         ║
║                                                                  ║
║              🚀 A1NAS ENHANCED ISO BUILDER 🚀                   ║
║                Professional Branded Edition                     ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${GREEN}🎯 Building A1NAS with Professional Custom Branding${NC}"
echo -e "${BLUE}   Compatible with your existing A1nas-firstboot-v1.2.0-Final.iso${NC}"
echo ""

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root (sudo).${NC}"
  exit 1
fi

# Set build configuration
BUILD_VERSION="v1.3.0-Branded"
BUILD_DATE=$(date +%Y%m%d-%H%M%S)
ISO_NAME="A1nas-branded-${BUILD_DATE}.iso"

echo -e "${CYAN}🔧 Build Configuration:${NC}"
echo -e "   Version: ${GREEN}${BUILD_VERSION}${NC}"
echo -e "   Build ID: ${GREEN}${BUILD_DATE}${NC}"
echo -e "   ISO Name: ${GREEN}${ISO_NAME}${NC}"
echo ""

# Install live-build and required tools if not present
echo -e "${CYAN}📦 Installing build dependencies...${NC}"
if ! command -v lb &> /dev/null; then
  echo -e "${CYAN}Installing live-build...${NC}"
  apt-get update && apt-get install -y live-build
fi

# Ensure all required packages are available
apt-get install -y --no-install-recommends \
  syslinux-utils \
  grub-pc-bin \
  grub-efi-amd64-bin \
  xorriso \
  imagemagick \
  isolinux

# Set project root to the directory containing this script's parent (project root)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$(dirname "$0")"

echo -e "${CYAN}🏗️  Project root: ${PROJECT_ROOT}${NC}"

# Create build directory with branding
BUILD_DIR=live-build-a1nas-branded
cd "$PROJECT_ROOT"
rm -rf "$BUILD_DIR"
mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

echo -e "${CYAN}⚙️  Setting up enhanced live-build configuration with branding...${NC}"

# Create auto directory and config
mkdir -p auto
cat > auto/config << 'EOF'
#!/bin/sh
set -e

echo "Setting up A1NAS enhanced live-build configuration with custom branding..."

# Base configuration with enhanced bootloaders and branding support
lb config \
  --architectures amd64 \
  --distribution jammy \
  --archive-areas "main restricted universe multiverse" \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components username=a1nas nosplash quiet splash" \
  --bootloader "grub-efi" \
  --memtest none \
  --firmware-chroot false \
  --iso-application "A1NAS Network OS" \
  --iso-publisher "A1NAS Project" \
  --iso-volume "A1NAS-BRANDED"

# Ensure package-lists directory exists
mkdir -p config/package-lists

# Create exclude list for problematic packages
cat > config/package-lists/exclude.list.chroot << EOL
syslinux-themes-ubuntu-oneiric-
gfxboot-theme-ubuntu-oneiric-
EOL

# Create bootloader support packages list with branding tools
cat > config/package-lists/bootloader.list.chroot << EOL
syslinux-common
syslinux-utils
isolinux
grub-pc-bin
grub-efi-amd64-bin
plymouth
plymouth-themes
fonts-terminus
console-setup
figlet
toilet
lolcat
EOL

echo "A1NAS enhanced configuration with branding complete!"
EOF
chmod +x auto/config

# Run the auto config
echo -e "${CYAN}🚀 Running enhanced configuration...${NC}"
./auto/config

# Add A1NAS packages (keep existing functionality)
echo -e "${CYAN}📋 Adding A1NAS package list...${NC}"
if [ -f "$PROJECT_ROOT/config/package-lists/a1nas.list.chroot" ]; then
  echo -e "${GREEN}✅ Using comprehensive A1NAS package list...${NC}"
  cp "$PROJECT_ROOT/config/package-lists/a1nas.list.chroot" config/package-lists/
else
  echo -e "${YELLOW}⚠️  Creating enhanced A1NAS package list...${NC}"
  cat > config/package-lists/a1nas.list.chroot << EOF
# A1NAS Core Packages
zfsutils-linux
nginx
curl
sudo
whiptail
openssh-server
fail2ban
ufw
git
cifs-utils
linux-image-generic

# Docker and Container Support
docker.io
docker-compose

# Network and Storage Tools
nfs-kernel-server
samba
smartmontools
hdparm
lvm2
mdadm

# System Tools
htop
iotop
tree
vim
nano
wget

# Branding and User Experience
plymouth
plymouth-themes
figlet
toilet
lolcat
fonts-terminus
console-setup
EOF
fi

# Copy comprehensive configuration files (preserve existing)
echo -e "${CYAN}📁 Adding comprehensive A1NAS configuration...${NC}"
if [ -d "$PROJECT_ROOT/config/includes.chroot" ]; then
  echo -e "${GREEN}✅ Copying A1NAS system configurations...${NC}"
  cp -r "$PROJECT_ROOT/config/includes.chroot"/* config/includes.chroot/
fi

# Copy existing hooks and add branding hooks
if [ -d "$PROJECT_ROOT/config/hooks" ]; then
  echo -e "${GREEN}✅ Copying A1NAS setup hooks...${NC}"
  cp -r "$PROJECT_ROOT/config/hooks"/* config/hooks/
fi

# Add enhanced branding hook
echo -e "${CYAN}🎨 Adding A1NAS branding customizations...${NC}"
mkdir -p config/hooks/normal

cat > config/hooks/normal/0010-a1nas-branding.hook.chroot << 'BRANDING_HOOK'
#!/bin/bash
set -e

echo "Applying A1NAS Professional Branding..."

# Create a1nas user with enhanced branding
if ! id a1nas >/dev/null 2>&1; then
    useradd -m -s /bin/bash -G sudo a1nas
    passwd -d a1nas
fi

# Configure passwordless sudo
echo 'a1nas ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/a1nas
chmod 440 /etc/sudoers.d/a1nas

# Create branded bash profile
cat > /home/a1nas/.bashrc << 'BASHRC'
# A1NAS Branded Bash Profile
export PS1="\[\033[0;36m\][\[\033[0;32m\]A1NAS\[\033[0;36m\]]\[\033[0;35m\]\u\[\033[0;33m\]@\[\033[0;32m\]\h\[\033[0;36m\]:\[\033[0;34m\]\w\[\033[0;36m\]$ \[\033[0m\]"

# A1NAS ASCII Art
show_a1nas_banner() {
    echo -e "\033[0;36m"
    cat << 'BANNER'
    ╔════════════════════════════════════════════════════════════════╗
    ║  ▄▀█ ▄█ █▄ █ ▄▀█ █▀   █▄ █ █▀▀ ▀█▀ █ █ █ █▀█ █▀█ █▄▀   █▀█ █▀  ║
    ║  █▄█ ▀█ █▀▄█ █▄█ ▄█   █▀▄█ ██▄  █  ▀▄▀▄▀ █▄█ █▀▄ █ █   █▄█ ▄█  ║
    ║                                                                ║
    ║                 🚀 Network Attached Storage OS 🚀              ║
    ║                      Ready for Innovation                      ║
    ╚════════════════════════════════════════════════════════════════╝
BANNER
    echo -e "\033[0m"
    echo -e "\033[1;33m💡 Welcome to A1NAS - The Ultimate Storage Solution\033[0m"
    echo -e "\033[0;32m🔧 Type 'a1nas-help' for available commands\033[0m"
    echo ""
}

# Show banner on login
show_a1nas_banner

# Enhanced aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias a1nas-help='echo -e "\033[1;36mA1NAS Commands:\033[0m\n\033[0;32m• a1nas-status\033[0m - System status\n\033[0;32m• a1nas-config\033[0m - Configuration\n\033[0;32m• a1nas-update\033[0m - Update system\n\033[0;32m• a1nas-monitor\033[0m - Storage monitoring"'
alias a1nas-status='echo -e "\033[1;32mA1NAS Status: \033[1;33mRunning\033[0m"; df -h; free -h; zpool status 2>/dev/null || echo "ZFS not configured yet"'
alias a1nas-monitor='watch -n 2 "df -h; echo; free -h; echo; zpool iostat 1 1 2>/dev/null || echo \"ZFS not available\""'
BASHRC

chown a1nas:a1nas /home/a1nas/.bashrc

# Configure autologin with branding
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'AUTOLOGIN'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin a1nas --noclear %I $TERM
AUTOLOGIN

# Create branded MOTD
cat > /etc/update-motd.d/10-a1nas-branded << 'MOTD'
#!/bin/sh
echo -e "\033[0;36m"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                        A1NAS NETWORK OS                         ║"
echo "║                   🚀 Professional Edition 🚀                    ║"
echo "║──────────────────────────────────────────────────────────────────║"
printf "║ Build: %-15s │ Kernel: %-27s ║\n" "$(cat /etc/a1nas-version 2>/dev/null || echo 'v1.3.0-Branded')" "$(uname -r)"
printf "║ Uptime: %-13s │ Load: %-29s ║\n" "$(uptime | cut -d' ' -f4-5 | sed 's/,//')" "$(uptime | grep -o 'load average.*' | cut -d' ' -f3-5)"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"
MOTD
chmod +x /etc/update-motd.d/10-a1nas-branded

# Create version file
echo "v1.3.0-Branded-$(date +%Y%m%d)" > /etc/a1nas-version

# Configure Plymouth boot splash
if [ -f /usr/share/plymouth/themes/ubuntu-text/ubuntu-text.plymouth ]; then
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/ubuntu-text/ubuntu-text.plymouth 100
fi

echo "A1NAS Professional Branding Applied Successfully!"
BRANDING_HOOK

chmod +x config/hooks/normal/0010-a1nas-branding.hook.chroot

# Copy enhanced GRUB configuration (integrate with existing)
echo -e "${CYAN}⚙️  Setting up enhanced GRUB branding...${NC}"
mkdir -p config/bootloaders/grub-pc config/bootloaders/grub-efi

# Enhanced GRUB configuration with A1NAS branding
cat > config/bootloaders/grub-pc/grub.cfg << 'GRUB_CONFIG'
# A1NAS Enhanced GRUB Configuration
# Professional branding with multiple boot options

# Basic GRUB settings
set timeout=30
set default=0

# Load modules
insmod all_video
insmod gfxterm
insmod png
insmod jpeg
insmod part_gpt
insmod part_msdos
insmod iso9660

# Custom colors
set color_normal=cyan/black
set color_highlight=white/blue

# A1NAS ASCII Art Header
echo -e "\033[0;36m"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║     ▄▀█ ▄█ █▄ █ ▄▀█ █▀   █▄ █ ██▀ ▀█▀ █ █ █ █▀█ █▀█ █▄▀        ║"
echo "║     █▄█ ▀█ █▀▄█ █▄█ ▄█   █▀▄█ ██▄  █  ▀▄▀▄▀ █▄█ █▀▄ █ █        ║"
echo "║                                                                  ║"
echo "║           🚀 A1NAS - NETWORK ATTACHED STORAGE OS 🚀             ║"
echo "║                      Professional Edition                       ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

# Menu entries
menuentry "🚀 A1NAS Live Mode (Default)" --class a1nas {
    echo "🔄 Loading A1NAS Live System..."
    linux /live/vmlinuz boot=live components username=a1nas nosplash quiet splash
    initrd /live/initrd
}

menuentry "⚡ A1NAS Performance Mode" --class a1nas {
    echo "⚡ Loading A1NAS Performance Mode..."
    linux /live/vmlinuz boot=live components username=a1nas acpi_osi=Linux pcie_aspm=off processor.max_cstate=1
    initrd /live/initrd
}

menuentry "🔧 A1NAS Debug Mode" --class a1nas {
    echo "🔧 Loading A1NAS Debug Mode..."
    linux /live/vmlinuz boot=live components username=a1nas debug systemd.log_level=debug
    initrd /live/initrd
}

menuentry "🛡️ A1NAS Safe Mode" --class a1nas {
    echo "🛡️ Loading A1NAS Safe Mode..."
    linux /live/vmlinuz boot=live components username=a1nas nomodeset acpi=off
    initrd /live/initrd
}

menuentry "💾 A1NAS Persistent Storage" --class a1nas {
    echo "💾 Loading A1NAS with Persistence..."
    linux /live/vmlinuz boot=live components username=a1nas persistence
    initrd /live/initrd
}

menuentry "🔄 Reboot" {
    reboot
}

menuentry "⚡ Shutdown" {
    halt
}

echo ""
echo -e "\033[1;33m⏱️  A1NAS will boot automatically in 30 seconds...\033[0m"
echo -e "\033[0;36m💡 Press any key to access options\033[0m"
echo -e "\033[0;32m🚀 Welcome to A1NAS - The Future of Network Storage!\033[0m"
GRUB_CONFIG

# Copy GRUB config to EFI as well
cp config/bootloaders/grub-pc/grub.cfg config/bootloaders/grub-efi/

# Ensure hooks directory exists and set permissions
echo -e "${CYAN}🔐 Setting up hooks permissions...${NC}"
if [ -d "config/hooks" ]; then
  find config/hooks -name "*.hook.*" -exec chmod +x {} \;
fi

# Add comprehensive A1NAS files (preserve existing functionality)
echo -e "${CYAN}📦 Adding A1NAS application files...${NC}"
mkdir -p config/includes.chroot/opt/a1nas
if [ -d "$PROJECT_ROOT/backend" ]; then
    cp -r "$PROJECT_ROOT/backend" config/includes.chroot/opt/a1nas/
fi
if [ -d "$PROJECT_ROOT/frontend" ]; then
    cp -r "$PROJECT_ROOT/frontend" config/includes.chroot/opt/a1nas/
fi
if [ -d "$PROJECT_ROOT/cli" ]; then
    cp -r "$PROJECT_ROOT/cli" config/includes.chroot/opt/a1nas/
fi
if [ -f "$PROJECT_ROOT/build/installer.sh" ]; then
    cp "$PROJECT_ROOT/build/installer.sh" config/includes.chroot/opt/a1nas/
fi

# Create enhanced build log
echo -e "${CYAN}🚀 Starting A1NAS branded ISO build...${NC}"
echo "A1NAS Branded Build started at: $(date)" > build.log
echo "Version: ${BUILD_VERSION}" >> build.log
echo "Build ID: ${BUILD_DATE}" >> build.log
echo "Target ISO: ${ISO_NAME}" >> build.log
echo "Project Root: ${PROJECT_ROOT}" >> build.log
echo "" >> build.log

# Build the ISO with enhanced error handling
lb build 2>&1 | tee -a build.log || {
  echo -e "${YELLOW}⚠️  Build encountered issues, checking results...${NC}"
}

# Check if ISO was created and rename it
if [ -f live-image-amd64.hybrid.iso ]; then
  # Move and rename the ISO
  mv live-image-amd64.hybrid.iso "../${ISO_NAME}"
  
  echo -e "${GREEN}"
  echo "╔════════════════════════════════════════════════════════════════════╗"
  echo "║                    🎉 A1NAS BRANDED BUILD COMPLETE! 🎉             ║"
  echo "╠════════════════════════════════════════════════════════════════════╣"
  printf "║ 📦 File: %-56s ║\n" "${ISO_NAME}"
  printf "║ 📊 Size: %-56s ║\n" "$(du -h "../${ISO_NAME}" | cut -f1)"
  printf "║ 🚀 Version: %-52s ║\n" "${BUILD_VERSION}"
  printf "║ 🏷️  Build ID: %-50s ║\n" "${BUILD_DATE}"
  echo "╠════════════════════════════════════════════════════════════════════╣"
  echo "║ ✅ Professional branding applied                                   ║"
  echo "║ ✅ Enhanced boot menu with multiple options                        ║"
  echo "║ ✅ Compatible with existing A1NAS functionality                    ║"
  echo "║ ✅ UEFI/BIOS compatible                                            ║"
  echo "║ ✅ USB/DVD bootable                                                ║"
  echo "║ ✅ Branded user experience throughout                              ║"
  echo "╚════════════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  
  echo ""
  echo -e "${GREEN}🎯 SUCCESS: Enhanced A1NAS ISO created successfully!${NC}"
  echo -e "${BLUE}📍 Location: ${PROJECT_ROOT}/${ISO_NAME}${NC}"
  echo ""
  echo -e "${YELLOW}💡 Boot Options Available:${NC}"
  echo "   🚀 Live Mode - Standard experience"
  echo "   ⚡ Performance Mode - Optimized for storage"
  echo "   🔧 Debug Mode - Troubleshooting"
  echo "   🛡️ Safe Mode - Compatibility"
  echo "   💾 Persistent Storage - Save changes"
  echo ""
  echo -e "${CYAN}📝 Next Steps:${NC}"
  echo "   1. Write to USB: sudo dd if=${ISO_NAME} of=/dev/sdX bs=4M"
  echo "   2. Boot and select your preferred mode"
  echo "   3. Enjoy your professionally branded A1NAS!"
  echo ""
  echo -e "${GREEN}🚀 A1NAS is ready to revolutionize your storage experience!${NC}"
  
else
  echo -e "${RED}"
  echo "╔════════════════════════════════════════════════════════════════════╗"
  echo "║                    ❌ BUILD FAILED                                  ║"
  echo "╚════════════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "${RED}❌ ISO was not created successfully.${NC}"
  echo -e "${YELLOW}📋 Check build.log for details:${NC}"
  echo -e "${YELLOW}   tail -50 build.log${NC}"
  exit 1
fi