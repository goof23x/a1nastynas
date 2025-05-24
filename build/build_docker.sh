#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Setting up A1Nas build environment...${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker Desktop for Mac first.${NC}"
    echo "Download from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Create build directory
mkdir -p build_output

# Build the Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t a1nas-builder -f build/Dockerfile .

# Run the build process
echo -e "${YELLOW}Starting build process...${NC}"
docker run --rm -v "$(pwd):/a1nas" a1nas-builder

echo -e "${GREEN}Build complete!${NC}"
echo -e "Your ISO should be in the build_output directory"
echo -e "You can now use Etcher to create a bootable USB drive" 