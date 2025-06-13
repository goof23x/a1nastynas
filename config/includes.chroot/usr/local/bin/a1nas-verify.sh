#!/bin/bash
# A1NAS Verification Script - Checks installation completeness

LOG_FILE="/var/log/a1nas/verification.log"
BUILD_LOG="/var/log/a1nas/build.log"

# Ensure log directory exists
mkdir -p /var/log/a1nas

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if package is installed
check_package() {
    local package=$1
    if dpkg -l | grep -q "^ii  $package "; then
        log "✅ PACKAGE: $package - INSTALLED"
        echo "$package: INSTALLED" >> "$BUILD_LOG"
        return 0
    else
        log "❌ PACKAGE: $package - MISSING"
        echo "$package: MISSING" >> "$BUILD_LOG"
        return 1
    fi
}

# Function to check if service exists
check_service() {
    local service=$1
    if systemctl list-unit-files | grep -q "$service"; then
        log "✅ SERVICE: $service - EXISTS"
        echo "$service: EXISTS" >> "$BUILD_LOG"
        return 0
    else
        log "❌ SERVICE: $service - MISSING"
        echo "$service: MISSING" >> "$BUILD_LOG"
        return 1
    fi
}

# Function to check if file exists
check_file() {
    local file=$1
    local description=$2
    if [ -f "$file" ]; then
        log "✅ FILE: $description ($file) - EXISTS"
        echo "$description: EXISTS" >> "$BUILD_LOG"
        return 0
    else
        log "❌ FILE: $description ($file) - MISSING"
        echo "$description: MISSING" >> "$BUILD_LOG"
        return 1
    fi
}

# Function to check if directory exists
check_directory() {
    local dir=$1
    local description=$2
    if [ -d "$dir" ]; then
        log "✅ DIRECTORY: $description ($dir) - EXISTS"
        echo "$description: EXISTS" >> "$BUILD_LOG"
        return 0
    else
        log "❌ DIRECTORY: $description ($dir) - MISSING"
        echo "$description: MISSING" >> "$BUILD_LOG"
        return 1
    fi
}

# Function to check if user exists
check_user() {
    local user=$1
    if id "$user" &>/dev/null; then
        log "✅ USER: $user - EXISTS"
        echo "User $user: EXISTS" >> "$BUILD_LOG"
        return 0
    else
        log "❌ USER: $user - MISSING"
        echo "User $user: MISSING" >> "$BUILD_LOG"
        return 1
    fi
}

log "=================================================================================="
log "A1NAS INSTALLATION VERIFICATION STARTED"
log "=================================================================================="

# Initialize counters
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Core NAS Storage & File Systems
log ""
log "🗄️  CHECKING STORAGE & FILE SYSTEMS..."
packages=(
    "zfsutils-linux"
    "samba"
    "samba-common-bin"
    "nfs-kernel-server"
    "nfs-common"
    "mdadm"
    "lvm2"
    "parted"
    "gdisk"
)

for package in "${packages[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if check_package "$package"; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
done

# Container & Virtualization
log ""
log "🐳 CHECKING CONTAINER & VIRTUALIZATION..."
packages=(
    "docker.io"
    "docker-compose"
)

for package in "${packages[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if check_package "$package"; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
done

# Network Services
log ""
log "🌐 CHECKING NETWORK SERVICES..."
packages=(
    "nginx"
    "openssh-server"
    "fail2ban"
    "ufw"
)

for package in "${packages[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if check_package "$package"; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
done

# System Management & Monitoring
log ""
log "📊 CHECKING MONITORING TOOLS..."
packages=(
    "htop"
    "iotop"
    "smartmontools"
    "hdparm"
    "iperf3"
    "nmap"
    "tcpdump"
    "psmisc"
    "procps"
)

for package in "${packages[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if check_package "$package"; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
done

# Check Services
log ""
log "🔧 CHECKING SYSTEMD SERVICES..."
services=(
    "nginx.service"
    "ssh.service"
    "docker.service"
    "smbd.service"
    "nmbd.service"
    "nfs-kernel-server.service"
    "a1nas-backend.service"
)

for service in "${services[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if check_service "$service"; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
done

# Check A1NAS Files
log ""
log "📁 CHECKING A1NAS FILES..."
files=(
    "/opt/a1nas/backend/a1nasd:A1NAS Backend Binary"
    "/opt/a1nas/frontend/package.json:A1NAS Frontend"
    "/opt/a1nas/cli/a1nas-cli.go:A1NAS CLI"
    "/opt/a1nas/installer.sh:A1NAS Installer"
    "/etc/a1nas/config.yaml:A1NAS Configuration"
    "/etc/nginx/sites-available/a1nas:Nginx A1NAS Config"
    "/etc/systemd/system/a1nas-backend.service:A1NAS Service"
)

for file_desc in "${files[@]}"; do
    file="${file_desc%:*}"
    desc="${file_desc#*:}"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if check_file "$file" "$desc"; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
done

# Check Directories
log ""
log "📂 CHECKING DIRECTORIES..."
directories=(
    "/var/lib/a1nas:A1NAS Data Directory"
    "/var/log/a1nas:A1NAS Log Directory"
    "/var/lib/a1nas/shares:A1NAS Shares Directory"
)

for dir_desc in "${directories[@]}"; do
    dir="${dir_desc%:*}"
    desc="${dir_desc#*:}"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if check_directory "$dir" "$desc"; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
done

# Check Users
log ""
log "👤 CHECKING USERS..."
users=("a1nas" "admin")

for user in "${users[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if check_user "$user"; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
done

# Calculate completion percentage
COMPLETION_PERCENT=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

log ""
log "=================================================================================="
log "VERIFICATION SUMMARY"
log "=================================================================================="
log "Total Checks: $TOTAL_CHECKS"
log "Passed: $PASSED_CHECKS"
log "Failed: $((TOTAL_CHECKS - PASSED_CHECKS))"
log "Completion: $COMPLETION_PERCENT%"

# Write summary to build log
echo "" >> "$BUILD_LOG"
echo "VERIFICATION SUMMARY:" >> "$BUILD_LOG"
echo "Total Checks: $TOTAL_CHECKS" >> "$BUILD_LOG"
echo "Passed: $PASSED_CHECKS" >> "$BUILD_LOG"
echo "Failed: $((TOTAL_CHECKS - PASSED_CHECKS))" >> "$BUILD_LOG"
echo "Completion: $COMPLETION_PERCENT%" >> "$BUILD_LOG"

if [ $COMPLETION_PERCENT -ge 80 ]; then
    log "🎉 SUCCESS: A1NAS installation is $COMPLETION_PERCENT% complete!"
    echo "STATUS: SUCCESS - $COMPLETION_PERCENT% complete" >> "$BUILD_LOG"
else
    log "⚠️  WARNING: A1NAS installation is only $COMPLETION_PERCENT% complete"
    echo "STATUS: INCOMPLETE - $COMPLETION_PERCENT% complete" >> "$BUILD_LOG"
fi

log "=================================================================================="

# Return appropriate exit code
if [ $COMPLETION_PERCENT -ge 80 ]; then
    exit 0
else
    exit 1
fi 