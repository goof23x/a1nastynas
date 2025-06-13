#!/bin/bash
set -e

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}   A1NAS OS - Simple Direct Build        ${NC}"
echo -e "${CYAN}===========================================${NC}"

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}Please run as root: sudo $0${NC}"
  exit 1
fi

# Set project root
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo -e "${CYAN}Project root: ${PROJECT_ROOT}${NC}"

# Create clean build directory
BUILD_DIR="$PROJECT_ROOT/live-build-simple"
echo -e "${CYAN}Creating clean build directory: ${BUILD_DIR}${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Direct live-build configuration (no auto scripts)
echo -e "${CYAN}Configuring live-build directly...${NC}"
lb config \
  --architectures amd64 \
  --distribution jammy \
  --archive-areas "main restricted universe multiverse" \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components username=a1nas nosplash" \
  --bootloader grub-efi

# Copy package list
echo -e "${CYAN}Adding package list...${NC}"
mkdir -p config/package-lists
cp "$PROJECT_ROOT/config/package-lists/a1nas.list.chroot" config/package-lists/

# Copy configuration files
echo -e "${CYAN}Adding system configuration files...${NC}"
if [ -d "$PROJECT_ROOT/config/includes.chroot" ]; then
  cp -r "$PROJECT_ROOT/config/includes.chroot" config/
fi

# Copy hooks
echo -e "${CYAN}Adding setup hooks...${NC}"
if [ -d "$PROJECT_ROOT/config/hooks" ]; then
  cp -r "$PROJECT_ROOT/config/hooks" config/
fi

# Add A1NAS application files
echo -e "${CYAN}Adding A1NAS application files...${NC}"
mkdir -p config/includes.chroot/opt/a1nas
cp -r "$PROJECT_ROOT/backend" config/includes.chroot/opt/a1nas/
cp -r "$PROJECT_ROOT/frontend" config/includes.chroot/opt/a1nas/
cp -r "$PROJECT_ROOT/cli" config/includes.chroot/opt/a1nas/

# Add basic build hook
echo -e "${CYAN}Adding basic setup hook...${NC}"
mkdir -p config/hooks/normal
cat > config/hooks/normal/0010-basic-setup.hook.chroot << 'EOF'
#!/bin/bash
set -e
echo "Basic A1NAS setup..."

# Enable services
systemctl enable nginx 2>/dev/null || true
systemctl enable ssh 2>/dev/null || true
systemctl enable docker 2>/dev/null || true

# Create basic directories
mkdir -p /var/lib/a1nas /var/log/a1nas /etc/a1nas

echo "Basic setup completed!"
EOF
chmod +x config/hooks/normal/0010-basic-setup.hook.chroot

# Set permissions on all hooks
find config/hooks -name "*.hook.*" -exec chmod +x {} \;

# Build the ISO
echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}   Building ISO...                       ${NC}"
echo -e "${CYAN}===========================================${NC}"

if lb build; then
  echo -e "${GREEN}===========================================${NC}"
  echo -e "${GREEN}   ISO BUILD SUCCESSFUL!                ${NC}"
  echo -e "${GREEN}===========================================${NC}"
  
  if [ -f live-image-amd64.hybrid.iso ]; then
    ISO_SIZE=$(du -h live-image-amd64.hybrid.iso | cut -f1)
    echo -e "${GREEN}✅ ISO Created: live-image-amd64.hybrid.iso${NC}"
    echo -e "${GREEN}✅ Size: ${ISO_SIZE}${NC}"
    echo -e "${GREEN}✅ Location: $(pwd)/live-image-amd64.hybrid.iso${NC}"
    
    # Copy to project root for easy access
    cp live-image-amd64.hybrid.iso "$PROJECT_ROOT/a1nas-v0.0.9.iso"
    echo -e "${GREEN}✅ Copied to: $PROJECT_ROOT/a1nas-v0.0.9.iso${NC}"
    
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${CYAN}   NEXT STEPS                           ${NC}"
    echo -e "${CYAN}===========================================${NC}"
    echo -e "${YELLOW}1. Test ISO in VM: a1nas-v0.0.9.iso${NC}"
    echo -e "${YELLOW}2. Boot and login with: ubuntu (no password)${NC}"
    echo -e "${YELLOW}3. Check packages: dpkg -l | grep -E 'docker|nginx|samba'${NC}"
    echo -e "${YELLOW}4. Verify files: ls -la /opt/a1nas/${NC}"
    
  else
    echo -e "${RED}❌ ISO file not found${NC}"
    exit 1
  fi
  
else
  echo -e "${RED}===========================================${NC}"
  echo -e "${RED}   BUILD FAILED                         ${NC}"
  echo -e "${RED}===========================================${NC}"
  exit 1
fi 