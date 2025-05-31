#!/bin/bash
set -e

# Colors for output
CYAN='\033[0;36m'
NC='\033[0m'

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo -e "${CYAN}Please run as root (sudo).${NC}"
  exit 1
fi

# Install live-build if not present
if ! command -v lb &> /dev/null; then
  echo -e "${CYAN}Installing live-build...${NC}"
  apt-get update && apt-get install -y live-build
fi

# Create build directory
BUILD_DIR=live-build-a1nas
rm -rf $BUILD_DIR
mkdir $BUILD_DIR
cd $BUILD_DIR

# Bootstrap config
lb config \
  --distribution jammy \
  --archive-areas "main restricted universe multiverse" \
  --debian-installer live \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components username=a1nas nosplash"

# Add custom packages
cat <<EOF > config/package-lists/a1nas.list.chroot
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
EOF

# Add custom hooks for A1Nas
mkdir -p config/includes.chroot/opt/a1nas
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "PROJECT_ROOT is: $PROJECT_ROOT"
ls "$PROJECT_ROOT"
cp -r "$PROJECT_ROOT/backend" "$PROJECT_ROOT/frontend" "$PROJECT_ROOT/cli" config/includes.chroot/opt/a1nas/
cp "$PROJECT_ROOT/build/installer.sh" config/includes.chroot/opt/a1nas/

# Add a post-install hook to enable services and set up system
mkdir -p config/hooks
cat <<'EOF' > config/hooks/010-a1nas-setup.chroot
#!/bin/bash
set -e
# Enable and start nginx
systemctl enable nginx
# Enable SSH
systemctl enable ssh
# Enable fail2ban
systemctl enable fail2ban
# Enable UFW and allow needed ports
ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable
# Make installer executable
chmod +x /opt/a1nas/installer.sh
EOF
chmod +x config/hooks/010-a1nas-setup.chroot

# Print instructions
cat <<EOM
${CYAN}Live-build config is ready!${NC}
To build your ISO, run:
  cd $BUILD_DIR
  sudo lb build
The ISO will be created as live-image-amd64.hybrid.iso in this directory.
EOM 