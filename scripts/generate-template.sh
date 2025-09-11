#!/bin/bash
# Template Generator for Generic Desktop Integration Framework

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Generic Desktop Integration Template Generator${NC}"
echo "=============================================="

# Get project information
read -p "Project name: " PROJECT_NAME
read -p "Project version (1.0.0): " PROJECT_VERSION
PROJECT_VERSION=${PROJECT_VERSION:-1.0.0}
read -p "Project description: " PROJECT_DESCRIPTION
read -p "Main executable name: " EXECUTABLE_NAME
read -p "Package ID (lowercase, no spaces): " PACKAGE_ID

# Generate package ID if not provided
if [ -z "$PACKAGE_ID" ]; then
    PACKAGE_ID=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
fi

echo ""
echo -e "${BLUE}Generating unified configuration file...${NC}"

# Generate unified manifest.json with desktop section
cat > manifest.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "$PROJECT_VERSION",
  "description": "$PROJECT_DESCRIPTION",
  "desktop": {
    "desktop_name": "$PROJECT_NAME",
    "generic_name": "",
    "comment": "$PROJECT_DESCRIPTION",
    "categories": "Utility;",
    "keywords": "",
    "mime_types": "",
    "executable": "$EXECUTABLE_NAME",
    "icon_path": "Icons/$PROJECT_NAME.png",
    "package_id": "$PACKAGE_ID",
    "supports_files": false,
    "cli_helper": false
  }
}
EOF

echo -e "${GREEN}✓${NC} Created unified manifest.json with desktop integration"

# Create directory structure
mkdir -p install
mkdir -p Icons

echo -e "${GREEN}✓${NC} Created install/ directory"
echo -e "${GREEN}✓${NC} Created Icons/ directory"

# Copy the framework script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/generic-desktop-install.sh" ]; then
    cp "$SCRIPT_DIR/generic-desktop-install.sh" install.sh
    chmod +x install.sh
    echo -e "${GREEN}✓${NC} Created install.sh"
else
    echo -e "${YELLOW}⚠${NC} Could not find generic-desktop-install.sh"
    echo "You'll need to copy it manually to install.sh"
fi

echo ""
echo -e "${GREEN}Template generated successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Build your application and place files in install/"
echo "2. Add an icon to Icons/$PROJECT_NAME.png"
echo "3. Customize the desktop section in manifest.json as needed"
echo "4. Test with: ./install.sh"
echo ""
echo "Directory structure:"
echo "├── manifest.json (unified config with desktop integration)"
echo "├── install.sh"
echo "├── install/ (place your built app here)"
echo "└── Icons/ (place your app icon here)"
