#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Building A1Nas...${NC}"

# Build frontend
echo -e "${GREEN}Building frontend...${NC}"
cd ../frontend
npm install
npm run build

# Build backend
echo -e "${GREEN}Building backend...${NC}"
cd ../backend
go mod tidy
go build -o a1nasd

# Create distribution directory
echo -e "${GREEN}Creating distribution...${NC}"
cd ..
mkdir -p dist
cp backend/a1nasd dist/
cp -r frontend/dist dist/frontend
cp build/installer.sh dist/

# Create archive
echo -e "${GREEN}Creating archive...${NC}"
tar -czf a1nas.tar.gz dist/

echo -e "${GREEN}Build complete! Output: a1nas.tar.gz${NC}" 