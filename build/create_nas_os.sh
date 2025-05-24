#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Create working directory
WORK_DIR=$(mktemp -d)
echo -e "${YELLOW}Working directory: ${WORK_DIR}${NC}"

# Create custom files structure
mkdir -p "${WORK_DIR}/custom/opt/a1nas"
mkdir -p "${WORK_DIR}/custom/etc/systemd/system"
mkdir -p "${WORK_DIR}/custom/etc/a1nas"
mkdir -p "${WORK_DIR}/custom/usr/local/bin"

# Create first-boot wizard script
cat > "${WORK_DIR}/custom/usr/local/bin/a1nas-wizard" << 'EOF'
#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Security hardening
echo -e "${YELLOW}Applying security hardening...${NC}"

# Disable root login
passwd -l root

# Configure SSH
cat > /etc/ssh/sshd_config << 'SSHD'
Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
MaxAuthTries 3
MaxSessions 3
ClientAliveInterval 300
ClientAliveCountMax 2
SSHD

# Configure firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable

# Install fail2ban
apt-get update
apt-get install -y fail2ban
cat > /etc/fail2ban/jail.local << 'FAIL2BAN'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
FAIL2BAN

systemctl enable fail2ban
systemctl start fail2ban

# Check for LSI 9300-16i
echo -e "${YELLOW}Checking for LSI 9300-16i controller...${NC}"
if lspci | grep -q "LSI Logic / Symbios Logic SAS3008"; then
    echo -e "${GREEN}LSI 9300-16i detected!${NC}"
    echo "options mpt3sas max_queue_depth=10000 max_sectors=32767" > /etc/modprobe.d/mpt3sas.conf
    modprobe -r mpt3sas
    modprobe mpt3sas
fi

# Detect available drives
echo -e "${YELLOW}Detecting available drives...${NC}"
DRIVES=($(lsblk -d -o NAME,SIZE,MODEL | grep -v "loop" | awk 'NR>1 {print $1}'))

if [ ${#DRIVES[@]} -eq 0 ]; then
    echo -e "${RED}No drives detected!${NC}"
    exit 1
fi

# Display drive information
echo -e "${GREEN}Detected drives:${NC}"
for drive in "${DRIVES[@]}"; do
    echo "  /dev/$drive: $(lsblk -d -o SIZE,MODEL /dev/$drive | awk 'NR>1')"
done

# Simple RAID configuration
echo -e "${YELLOW}Configuring storage...${NC}"
if [ ${#DRIVES[@]} -ge 2 ]; then
    echo "Creating RAID 1 (Mirror) with all drives..."
    zpool create -f a1nas mirror ${DRIVES[@]/#/\/dev\/}
else
    echo "Creating single drive pool..."
    zpool create -f a1nas ${DRIVES[@]/#/\/dev\/}
fi

# Create basic datasets
zfs create a1nas/data
zfs create a1nas/docker
zfs create a1nas/backup

# Set mountpoints
zfs set mountpoint=/mnt/a1nas/data a1nas/data
zfs set mountpoint=/var/lib/docker a1nas/docker
zfs set mountpoint=/mnt/a1nas/backup a1nas/backup

# Configure Docker
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'DOCKER'
{
    "storage-driver": "zfs",
    "data-root": "/var/lib/docker",
    "no-new-privileges": true,
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
DOCKER

# Start services
systemctl enable docker
systemctl start docker
systemctl enable a1nas
systemctl start a1nas

# Configure network
read -p "Enter hostname [a1nas]: " HOSTNAME
HOSTNAME=${HOSTNAME:-a1nas}
hostnamectl set-hostname $HOSTNAME

# Configure nginx with SSL
apt-get install -y certbot python3-certbot-nginx
cat > /etc/nginx/sites-available/a1nas << 'NGINX'
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name _;

    ssl_certificate /etc/letsencrypt/live/a1nas/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/a1nas/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    add_header Strict-Transport-Security "max-age=63072000" always;

    location / {
        root /opt/a1nas/frontend;
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/a1nas /etc/nginx/sites-enabled/
systemctl restart nginx

# Get SSL certificate
certbot --nginx -d $(hostname -f) --non-interactive --agree-tos --email admin@$(hostname -f)

# Create admin user
echo -e "${YELLOW}Creating admin user...${NC}"
read -p "Enter admin username [admin]: " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}
read -sp "Enter admin password: " ADMIN_PASS
echo

useradd -m -s /bin/bash $ADMIN_USER
echo "$ADMIN_USER:$ADMIN_PASS" | chpasswd
usermod -aG sudo $ADMIN_USER

# Remove wizard
rm -f /usr/local/bin/a1nas-wizard
systemctl disable a1nas-wizard

echo -e "${GREEN}A1Nas setup complete!${NC}"
echo -e "You can now access A1Nas at https://$(hostname -f)"
echo -e "Login with username: $ADMIN_USER"
EOF

chmod +x "${WORK_DIR}/custom/usr/local/bin/a1nas-wizard"

# Create wizard service
cat > "${WORK_DIR}/custom/etc/systemd/system/a1nas-wizard.service" << 'EOF'
[Unit]
Description=A1Nas First Boot Wizard
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/a1nas-wizard
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Create preseed file
cat > "${WORK_DIR}/preseed/a1nas.seed" << 'EOF'
# A1Nas Preseed Configuration
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string a1nas
d-i netcfg/get_domain string local
d-i mirror/country string manual
d-i mirror/http/hostname string archive.ubuntu.com
d-i mirror/http/directory string /ubuntu
d-i mirror/http/proxy string
d-i time/zone string UTC
d-i clock-setup/utc boolean true
d-i clock-setup/utc-auto boolean true
d-i partman-auto/method string lvm
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-auto-lvm/guided_size string max
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i apt-setup/restricted boolean true
d-i apt-setup/universe boolean true
d-i apt-setup/backports boolean true
d-i pkgsel/update-policy select none
d-i pkgsel/upgrade select none
d-i pkgsel/include string openssh-server zfsutils-linux docker.io nginx ufw fail2ban
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i finish-install/reboot_in_progress note
EOF

# Build ISO using cubic
echo -e "${YELLOW}Starting cubic...${NC}"
echo -e "${YELLOW}Please follow these steps in cubic:${NC}"
echo "1. Select Ubuntu 22.04 LTS as the base"
echo "2. Copy the contents of ${WORK_DIR}/custom to the custom files section"
echo "3. Copy the contents of ${WORK_DIR}/preseed to the preseed section"
echo "4. Build the ISO"

# Cleanup
echo -e "${GREEN}Cleaning up...${NC}"
rm -rf "${WORK_DIR}"

echo -e "${GREEN}Build process complete!${NC}"
echo -e "${YELLOW}Please use cubic to build the final ISO.${NC}" 