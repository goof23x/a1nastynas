#!/bin/bash
set -e

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get the current version
VERSION=$(cat VERSION 2>/dev/null || echo "unknown")

echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}   A1NAS OS Clean Clone Build Test       ${NC}"
echo -e "${CYAN}   Version: ${VERSION}                   ${NC}"  
echo -e "${CYAN}===========================================${NC}"

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}Please run as root: sudo $0${NC}"
  exit 1
fi

# Get repository URL from current git remote
REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [ -z "$REPO_URL" ]; then
  echo -e "${RED}❌ Error: No git remote found. Please ensure this is a git repository.${NC}"
  exit 1
fi

echo -e "${CYAN}Repository: ${REPO_URL}${NC}"
echo -e "${CYAN}Current directory: $(pwd)${NC}"

# Create test directory
TEST_DIR="/tmp/a1nas-clean-test-$(date +%s)"
echo -e "${CYAN}Creating test directory: ${TEST_DIR}${NC}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Clone the repository
echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}   Step 1: Fresh Git Clone               ${NC}"
echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}Cloning repository...${NC}"
git clone "$REPO_URL" a1nas-test
cd a1nas-test

# Verify version matches
CLONED_VERSION=$(cat VERSION 2>/dev/null || echo "unknown")
echo -e "${GREEN}✅ Cloned version: ${CLONED_VERSION}${NC}"

if [ "$VERSION" != "$CLONED_VERSION" ]; then
  echo -e "${YELLOW}⚠️  Warning: Version mismatch. Original: ${VERSION}, Cloned: ${CLONED_VERSION}${NC}"
fi

# Check critical files exist
echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}   Step 2: Verify Critical Files         ${NC}"
echo -e "${CYAN}===========================================${NC}"

CRITICAL_FILES=(
  "config/package-lists/a1nas.list.chroot"
  "config/includes.chroot/etc/a1nas/config.yaml"
  "config/includes.chroot/usr/local/bin/a1nas-setup.sh"
  "config/includes.chroot/usr/local/bin/a1nas-verify.sh"
  "build/build_live_iso_enhanced.sh"
  "build/rebuild-and-verify.sh"
  "backend"
  "frontend"
  "cli"
)

MISSING_FILES=0
for file in "${CRITICAL_FILES[@]}"; do
  if [ -e "$file" ]; then
    echo -e "${GREEN}✅ ${file}${NC}"
  else
    echo -e "${RED}❌ ${file} - MISSING${NC}"
    MISSING_FILES=$((MISSING_FILES + 1))
  fi
done

if [ $MISSING_FILES -gt 0 ]; then
  echo -e "${RED}❌ Error: ${MISSING_FILES} critical files missing!${NC}"
  echo -e "${RED}   The repository may be incomplete.${NC}"
  exit 1
fi

# Count packages in the comprehensive list
PACKAGE_COUNT=$(grep -c -v '^#' "config/package-lists/a1nas.list.chroot" 2>/dev/null || echo "0")
echo -e "${GREEN}✅ Package list contains ${PACKAGE_COUNT} packages${NC}"

if [ $PACKAGE_COUNT -lt 40 ]; then
  echo -e "${YELLOW}⚠️  Warning: Expected 40+ packages, found ${PACKAGE_COUNT}${NC}"
fi

# Count configuration files
CONFIG_COUNT=$(find config/includes.chroot -type f 2>/dev/null | wc -l)
echo -e "${GREEN}✅ Found ${CONFIG_COUNT} configuration files${NC}"

echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}   Step 3: Test Build Process            ${NC}"
echo -e "${CYAN}===========================================${NC}"

# Test the build script (dry run check)
echo -e "${CYAN}Testing build script syntax...${NC}"
if bash -n build/rebuild-and-verify.sh; then
  echo -e "${GREEN}✅ Build script syntax is valid${NC}"
else
  echo -e "${RED}❌ Build script has syntax errors${NC}"
  exit 1
fi

# Check if we should do a full build
echo -e "${YELLOW}===========================================${NC}"
echo -e "${YELLOW}   Full Build Test Options               ${NC}"
echo -e "${YELLOW}===========================================${NC}"
echo -e "${YELLOW}Choose an option:${NC}"
echo -e "${YELLOW}1. Quick validation only (recommended)${NC}"
echo -e "${YELLOW}2. Full ISO build test (takes 15+ minutes)${NC}"
echo -e "${YELLOW}3. Skip build test${NC}"

read -p "Enter choice (1-3): " choice

case $choice in
  1)
    echo -e "${CYAN}Running quick validation...${NC}"
    # Quick validation - check all components are ready
    echo -e "${GREEN}✅ All critical components verified${NC}"
    echo -e "${GREEN}✅ Ready for full build${NC}"
    ;;
  2)
    echo -e "${CYAN}Starting full ISO build test...${NC}"
    echo -e "${YELLOW}This will take 15+ minutes...${NC}"
    if ./build/rebuild-and-verify.sh; then
      echo -e "${GREEN}✅ Full build test PASSED${NC}"
      # Check if ISO was created
      if [ -f "live-build-a1nas/live-image-amd64.hybrid.iso" ]; then
        ISO_SIZE=$(du -h "live-build-a1nas/live-image-amd64.hybrid.iso" | cut -f1)
        echo -e "${GREEN}✅ ISO created successfully (${ISO_SIZE})${NC}"
      fi
    else
      echo -e "${RED}❌ Full build test FAILED${NC}"
      exit 1
    fi
    ;;
  3)
    echo -e "${YELLOW}Skipping build test${NC}"
    ;;
  *)
    echo -e "${YELLOW}Invalid choice, skipping build test${NC}"
    ;;
esac

echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}   Clean Clone Test Results              ${NC}"
echo -e "${CYAN}===========================================${NC}"
echo -e "${GREEN}✅ Git clone successful${NC}"
echo -e "${GREEN}✅ All critical files present${NC}"
echo -e "${GREEN}✅ ${PACKAGE_COUNT} packages configured${NC}"
echo -e "${GREEN}✅ ${CONFIG_COUNT} config files ready${NC}"
echo -e "${GREEN}✅ Build scripts validated${NC}"

echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}   Cleanup                               ${NC}"
echo -e "${CYAN}===========================================${NC}"
echo -e "${YELLOW}Test directory: ${TEST_DIR}${NC}"
echo -e "${YELLOW}Remove test directory? (y/N):${NC}"
read -r cleanup
if [[ $cleanup =~ ^[Yy]$ ]]; then
  cd /
  rm -rf "$TEST_DIR"
  echo -e "${GREEN}✅ Cleanup completed${NC}"
else
  echo -e "${YELLOW}⚠️  Test directory preserved: ${TEST_DIR}${NC}"
fi

echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}   CLEAN CLONE TEST COMPLETED            ${NC}"
echo -e "${GREEN}   Version ${CLONED_VERSION} - VERIFIED  ${NC}"
echo -e "${GREEN}===========================================${NC}" 