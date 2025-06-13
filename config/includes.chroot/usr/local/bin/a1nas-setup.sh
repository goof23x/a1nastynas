#!/bin/bash
# A1NAS Setup Script - Configures the system for A1NAS operation

set -e

# Setup logging
LOG_FILE="/var/log/a1nas/setup.log"
BUILD_LOG="/var/log/a1nas/build.log"

# Ensure log directory exists
mkdir -p /var/log/a1nas

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to log to build log
build_log() {
    echo "$1" >> "$BUILD_LOG"
}

log "🚀 Setting up A1NAS system..."
build_log "=================================================================================="
build_log "A1NAS SETUP PHASE STARTED - $(date)"
build_log "=================================================================================="

# Create A1NAS user and group
log "Creating A1NAS user and group..."
if ! id "a1nas" &>/dev/null; then
    log "Creating a1nas user..."
    useradd -r -s /bin/bash -d /opt/a1nas -c "A1NAS System User" a1nas
    usermod -aG docker a1nas 2>/dev/null || true
    build_log "User a1nas: CREATED"
else
    log "User a1nas already exists"
    build_log "User a1nas: ALREADY EXISTS"
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p /var/lib/a1nas/{data,shares}
mkdir -p /var/log/a1nas
mkdir -p /etc/a1nas

# Set permissions
echo "Setting permissions..."
chown -R a1nas:a1nas /opt/a1nas
chown -R a1nas:a1nas /var/lib/a1nas
chown -R a1nas:a1nas /var/log/a1nas
chown a1nas:a1nas /etc/a1nas

# Make backend executable
chmod +x /opt/a1nas/backend/a1nasd 2>/dev/null || true

# Configure nginx
echo "Configuring nginx..."
if [ -f /etc/nginx/sites-available/a1nas ]; then
    ln -sf /etc/nginx/sites-available/a1nas /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
fi

# Enable services
echo "Enabling services..."
systemctl enable nginx 2>/dev/null || true
systemctl enable ssh 2>/dev/null || true
systemctl enable docker 2>/dev/null || true
systemctl enable a1nas-backend 2>/dev/null || true
systemctl enable fail2ban 2>/dev/null || true

# Configure UFW firewall
echo "Configuring firewall..."
ufw --force enable 2>/dev/null || true
ufw allow ssh 2>/dev/null || true
ufw allow 80/tcp 2>/dev/null || true
ufw allow 443/tcp 2>/dev/null || true
ufw allow 445/tcp 2>/dev/null || true  # Samba
ufw allow 2049/tcp 2>/dev/null || true # NFS

# Configure Samba
echo "Configuring Samba..."
if [ -f /etc/samba/smb.conf ]; then
    cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
    cat >> /etc/samba/smb.conf << 'EOF'

[A1NAS-Shares]
   comment = A1NAS Shared Storage
   path = /var/lib/a1nas/shares
   browseable = yes
   read only = no
   guest ok = no
   valid users = a1nas
   create mask = 0664
   directory mask = 0775
EOF
fi

# Set up default admin user
echo "Setting up default admin user..."
if ! id "admin" &>/dev/null; then
    useradd -m -s /bin/bash -G sudo,docker admin
    echo "admin:a1nas123" | chpasswd
    echo "Default admin user created with password: a1nas123"
    echo "Please change this password after first login!"
fi

# Create a1nas CLI symlink
echo "Setting up CLI..."
ln -sf /opt/a1nas/cli/a1nas-cli /usr/local/bin/a1nas

echo "✅ A1NAS setup completed!"
echo ""
echo "🌐 Access A1NAS web interface at: http://[your-ip]"
echo "🔑 Default admin credentials: admin / a1nas123"
echo "🛠️  Use 'a1nas' command for CLI management"
echo "" 