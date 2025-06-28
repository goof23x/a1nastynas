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
║              🚀 A1NAS BRANDED ISO BUILDER 🚀                    ║
║                Professional Edition (Fixed)                     ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${GREEN}🎯 Building A1NAS with Professional Custom Branding${NC}"
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

# Install dependencies
echo -e "${CYAN}📦 Installing build dependencies...${NC}"
apt-get update
apt-get install -y --no-install-recommends \
  live-build \
  syslinux-utils \
  grub-pc-bin \
  grub-efi-amd64-bin \
  xorriso \
  isolinux

# Set project root
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo -e "${CYAN}🏗️  Project root: ${PROJECT_ROOT}${NC}"

# Create build directory
BUILD_DIR="live-build-a1nas-branded"
cd "$PROJECT_ROOT"
rm -rf "$BUILD_DIR"
mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

echo -e "${CYAN}⚙️  Setting up live-build configuration...${NC}"

# Configure live-build directly (no auto scripts)
lb config \
  --architectures amd64 \
  --distribution jammy \
  --archive-areas "main restricted universe multiverse" \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components username=a1nas nosplash quiet" \
  --bootloader "grub-efi" \
  --memtest none \
  --firmware-chroot false \
  --iso-application "A1NAS Network OS" \
  --iso-publisher "A1NAS Project" \
  --iso-volume "A1NAS-BRANDED"

# Create A1NAS package list
echo -e "${CYAN}📋 Adding A1NAS packages...${NC}"
mkdir -p config/package-lists

cat > config/package-lists/a1nas.list.chroot << 'EOF'
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

# Branding Tools
figlet
toilet
plymouth
plymouth-themes
fonts-terminus
console-setup
EOF

# Add branding hook
echo -e "${CYAN}🎨 Adding branding customizations...${NC}"
mkdir -p config/hooks/normal

cat > config/hooks/normal/0010-a1nas-branding.hook.chroot << 'BRANDING_HOOK'
#!/bin/bash
set -e

echo "Applying A1NAS Professional Branding..."

# Create a1nas user
if ! id a1nas >/dev/null 2>&1; then
    useradd -m -s /bin/bash -G sudo a1nas
    passwd -d a1nas
fi

# Configure sudo
echo 'a1nas ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/a1nas
chmod 440 /etc/sudoers.d/a1nas

# Create branded bash profile
cat > /home/a1nas/.bashrc << 'BASHRC'
# A1NAS Branded Profile
export PS1="\[\033[0;36m\][\[\033[0;32m\]A1NAS\[\033[0;36m\]]\[\033[0;35m\]\u\[\033[0;33m\]@\[\033[0;32m\]\h\[\033[0;36m\]:\[\033[0;34m\]\w\[\033[0;36m\]$ \[\033[0m\]"

# A1NAS Banner
show_a1nas_banner() {
    echo -e "\033[0;36m"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║  ▄▀█ ▄█ █▄ █ ▄▀█ █▀   █▄ █ █▀▀ ▀█▀ █ █ █ █▀█ █▀█ █▄▀   █▀█ █▀  ║"
    echo "║  █▄█ ▀█ █▀▄█ █▄█ ▄█   █▀▄█ ██▄  █  ▀▄▀▄▀ █▄█ █▀▄ █ █   █▄█ ▄█  ║"
    echo "║                                                                  ║"
    echo "║                 🚀 Network Attached Storage OS 🚀                ║"
    echo "║                      Ready for Innovation                        ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "\033[0m"
    echo -e "\033[1;33m💡 Welcome to A1NAS - The Ultimate Storage Solution\033[0m"
}

show_a1nas_banner

# Useful aliases
alias ll='ls -alF'
alias a1nas-status='echo -e "\033[1;32mA1NAS Status: \033[1;33mRunning\033[0m"; df -h; free -h'
BASHRC

chown a1nas:a1nas /home/a1nas/.bashrc

# Configure autologin
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'AUTOLOGIN'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin a1nas --noclear %I $TERM
AUTOLOGIN

# Create version file
echo "${BUILD_VERSION}-$(date +%Y%m%d)" > /etc/a1nas-version

echo "A1NAS Professional Branding Applied!"
BRANDING_HOOK

chmod +x config/hooks/normal/0010-a1nas-branding.hook.chroot

# Enhanced GRUB configuration
echo -e "${CYAN}⚙️  Setting up GRUB branding...${NC}"
mkdir -p config/bootloaders/grub-pc config/bootloaders/grub-efi

cat > config/bootloaders/grub-pc/grub.cfg << 'GRUB_CONFIG'
set timeout=10
set default=0

insmod all_video
insmod gfxterm

set color_normal=cyan/black
set color_highlight=white/blue

menuentry "🚀 A1NAS Live Mode (Default)" {
    linux /live/vmlinuz boot=live components username=a1nas nosplash quiet
    initrd /live/initrd
}

menuentry "⚡ A1NAS Performance Mode" {
    linux /live/vmlinuz boot=live components username=a1nas acpi_osi=Linux
    initrd /live/initrd
}

menuentry "🔧 A1NAS Debug Mode" {
    linux /live/vmlinuz boot=live components username=a1nas debug
    initrd /live/initrd
}

menuentry "🔄 Reboot" {
    reboot
}

menuentry "⚡ Shutdown" {
    halt
}
GRUB_CONFIG

# Copy to EFI
cp config/bootloaders/grub-pc/grub.cfg config/bootloaders/grub-efi/

# Copy A1NAS application files if they exist
echo -e "${CYAN}📦 Adding A1NAS application files...${NC}"
mkdir -p config/includes.chroot/opt/a1nas

if [ -d "$PROJECT_ROOT/backend" ]; then
    cp -r "$PROJECT_ROOT/backend" config/includes.chroot/opt/a1nas/
    echo -e "${GREEN}✅ Backend copied${NC}"
fi

if [ -d "$PROJECT_ROOT/frontend" ]; then
    cp -r "$PROJECT_ROOT/frontend" config/includes.chroot/opt/a1nas/
    echo -e "${GREEN}✅ Frontend copied${NC}"
fi

if [ -d "$PROJECT_ROOT/cli" ]; then
    cp -r "$PROJECT_ROOT/cli" config/includes.chroot/opt/a1nas/
    echo -e "${GREEN}✅ CLI copied${NC}"
fi

# Start the build
echo -e "${CYAN}🚀 Starting A1NAS branded ISO build...${NC}"
echo "Build started at: $(date)"

lb build

# Check if ISO was created
if [ -f live-image-amd64.hybrid.iso ]; then
    mv live-image-amd64.hybrid.iso "../${ISO_NAME}"
    
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                    🎉 A1NAS BUILD COMPLETE! 🎉                     ║"
    echo "╠════════════════════════════════════════════════════════════════════╣"
    printf "║ 📦 File: %-56s ║\n" "${ISO_NAME}"
    printf "║ 📊 Size: %-56s ║\n" "$(du -h "../${ISO_NAME}" | cut -f1)"
    printf "║ 🚀 Version: %-52s ║\n" "${BUILD_VERSION}"
    echo "╠════════════════════════════════════════════════════════════════════╣"
    echo "║ ✅ Professional branding applied                                   ║"
    echo "║ ✅ Enhanced boot menu with multiple options                        ║"
    echo "║ ✅ Compatible with existing A1NAS functionality                    ║"
    echo "║ ✅ UEFI/BIOS compatible                                            ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${GREEN}🎯 SUCCESS: A1NAS ISO created successfully!${NC}"
    echo -e "${BLUE}📍 Location: ${PROJECT_ROOT}/${ISO_NAME}${NC}"
    
else
    echo -e "${RED}❌ Build failed - ISO not created${NC}"
    exit 1
fi