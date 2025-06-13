#!/bin/bash
set -e

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}   A1Nas Enhanced ISO Builder (Tier 3)   ${NC}"
echo -e "${CYAN}===========================================${NC}"

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}Please run as root (sudo).${NC}"
  exit 1
fi

# Install live-build and required tools if not present
echo -e "${CYAN}Installing build dependencies...${NC}"
if ! command -v lb &> /dev/null; then
  echo -e "${CYAN}Installing live-build...${NC}"
  apt-get update && apt-get install -y live-build
fi

# Ensure syslinux-utils is available for isohybrid
apt-get install -y --no-install-recommends syslinux-utils

# Set project root to the directory containing this script's parent (project root)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$(dirname "$0")"

echo -e "${CYAN}Project root: ${PROJECT_ROOT}${NC}"

# Create build directory
BUILD_DIR=live-build-a1nas
cd "$PROJECT_ROOT"
rm -rf "$BUILD_DIR"
mkdir "$BUILD_DIR"
cd "$BUILD_DIR"

echo -e "${CYAN}Setting up enhanced live-build configuration...${NC}"

# Create auto directory and config
mkdir -p auto
cat > auto/config << 'EOF'
#!/bin/sh
set -e

echo "Setting up enhanced live-build configuration..."

# Base configuration with modern bootloaders
lb config \
  --architectures amd64 \
  --distribution jammy \
  --archive-areas "main restricted universe multiverse" \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components username=a1nas nosplash" \
  --bootloader "grub-efi" \
  --memtest none \
  --firmware-chroot false

# Ensure package-lists directory exists
mkdir -p config/package-lists

# Create exclude list for problematic packages
cat > config/package-lists/exclude.list.chroot << EOL
syslinux-themes-ubuntu-oneiric-
gfxboot-theme-ubuntu-
EOL

# Create bootloader support packages list
cat > config/package-lists/bootloader.list.chroot << EOL
syslinux-common
syslinux-utils
isolinux
grub-pc-bin
grub-efi-amd64-bin
EOL

echo "Enhanced configuration complete!"
EOF
chmod +x auto/config

# Run the auto config
echo -e "${CYAN}Running enhanced configuration...${NC}"
./auto/config

# Add original A1Nas packages
echo -e "${CYAN}Adding A1Nas package list...${NC}"
# Copy the comprehensive package list instead of creating a basic one
if [ -f "$PROJECT_ROOT/config/package-lists/a1nas.list.chroot" ]; then
  echo -e "${CYAN}Using comprehensive A1NAS package list...${NC}"
  cp "$PROJECT_ROOT/config/package-lists/a1nas.list.chroot" config/package-lists/
else
  echo -e "${YELLOW}Warning: Comprehensive package list not found, creating basic list...${NC}"
  cat > config/package-lists/a1nas.list.chroot << EOF
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
EOF
fi

# Copy all comprehensive configuration files
echo -e "${CYAN}Adding comprehensive A1NAS configuration...${NC}"
if [ -d "$PROJECT_ROOT/config/includes.chroot" ]; then
  echo -e "${CYAN}Copying A1NAS system configurations...${NC}"
  cp -r "$PROJECT_ROOT/config/includes.chroot"/* config/includes.chroot/
fi

# Copy comprehensive hooks
if [ -d "$PROJECT_ROOT/config/hooks" ]; then
  echo -e "${CYAN}Copying A1NAS setup hooks...${NC}"
  cp -r "$PROJECT_ROOT/config/hooks"/* config/hooks/
fi

# Ensure hooks directory exists and set permissions
echo -e "${CYAN}Setting up hooks permissions...${NC}"
if [ -d "config/hooks" ]; then
  find config/hooks -name "*.hook.*" -exec chmod +x {} \;
fi

# Add essential build hooks if not present
if [ ! -f "config/hooks/normal/0005-fix-path.hook.chroot" ]; then
  mkdir -p config/hooks/normal
  cat > config/hooks/normal/0005-fix-path.hook.chroot << 'EOF'
#!/bin/sh
set -e
export PATH="$PATH:/sbin:/usr/sbin"
echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/no-recommends
echo 'APT::Install-Suggests "false";' > /etc/apt/apt.conf.d/no-suggests
EOF
  chmod +x config/hooks/normal/0005-fix-path.hook.chroot
fi

# Add custom includes for A1Nas
echo -e "${CYAN}Adding A1Nas files...${NC}"
mkdir -p config/includes.chroot/opt/a1nas
cp -r "$PROJECT_ROOT/backend" "$PROJECT_ROOT/frontend" "$PROJECT_ROOT/cli" config/includes.chroot/opt/a1nas/
cp "$PROJECT_ROOT/build/installer.sh" config/includes.chroot/opt/a1nas/

# Create a comprehensive build log
echo -e "${CYAN}Starting enhanced ISO build...${NC}"
echo "Build started at: $(date)" > build.log

# Build the ISO with enhanced error handling
lb build 2>&1 | tee -a build.log || {
  echo -e "${YELLOW}Build encountered issues, but may have succeeded partially.${NC}"
  echo -e "${YELLOW}Check build.log for details.${NC}"
}

# Check if ISO was created successfully
if [ -f live-image-amd64.hybrid.iso ]; then
  echo -e "${GREEN}===========================================${NC}"
  echo -e "${GREEN}   SUCCESS: ISO BUILD COMPLETED!        ${NC}"
  echo -e "${GREEN}===========================================${NC}"
  echo -e "${GREEN}ISO created: live-image-amd64.hybrid.iso${NC}"
  echo -e "${GREEN}Size: $(du -h live-image-amd64.hybrid.iso | cut -f1)${NC}"
  echo -e "${GREEN}Location: $(pwd)/live-image-amd64.hybrid.iso${NC}"
  echo -e "${CYAN}===========================================${NC}"
  echo -e "${CYAN}You can now test this ISO in a VM or${NC}"
  echo -e "${CYAN}write it to a USB drive for installation.${NC}"
  echo -e "${CYAN}===========================================${NC}"
else
  echo -e "${YELLOW}===========================================${NC}"
  echo -e "${YELLOW}   BUILD COMPLETED WITH WARNINGS        ${NC}"
  echo -e "${YELLOW}===========================================${NC}"
  echo -e "${YELLOW}ISO may not have been created successfully.${NC}"
  echo -e "${YELLOW}Check build.log for details:${NC}"
  echo -e "${YELLOW}  tail -50 build.log${NC}"
  echo -e "${YELLOW}===========================================${NC}"
  exit 1
fi 