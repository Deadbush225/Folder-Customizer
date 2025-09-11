#!/bin/bash
# Desktop file validation script for Folder Customizer

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Folder Customizer Desktop File Validator${NC}"
echo "==========================================="

# Determine installation type
if [ "$EUID" -eq 0 ]; then
    INSTALL_PREFIX="/usr"
    INSTALL_TYPE="system-wide"
else
    INSTALL_PREFIX="$HOME/.local"
    INSTALL_TYPE="user-specific"
fi

echo "Checking $INSTALL_TYPE installation in: $INSTALL_PREFIX"
echo ""

# Check desktop file
DESKTOP_FILE="$INSTALL_PREFIX/share/applications/folder-customizer.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    echo -e "${GREEN}✓${NC} Desktop file found: $DESKTOP_FILE"
    
    # Validate desktop file
    if command -v desktop-file-validate >/dev/null 2>&1; then
        if desktop-file-validate "$DESKTOP_FILE" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Desktop file is valid"
        else
            echo -e "${YELLOW}⚠${NC} Desktop file validation warnings:"
            desktop-file-validate "$DESKTOP_FILE" 2>&1 || true
        fi
    else
        echo -e "${BLUE}ℹ${NC} desktop-file-validate not available (install desktop-file-utils to validate)"
    fi
    
    # Check if executable exists
    EXEC_LINE=$(grep "^Exec=" "$DESKTOP_FILE" | head -1)
    if [ -n "$EXEC_LINE" ]; then
        EXEC_CMD=$(echo "$EXEC_LINE" | sed 's/Exec=//; s/ %F//; s/ %U//; s/ %f//; s/ %u//')
        if command -v "$EXEC_CMD" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Executable is available: $EXEC_CMD"
        else
            echo -e "${RED}✗${NC} Executable not found: $EXEC_CMD"
        fi
    fi
else
    echo -e "${RED}✗${NC} Desktop file not found: $DESKTOP_FILE"
fi

# Check icon
ICON_FILE="$INSTALL_PREFIX/share/icons/hicolor/256x256/apps/folder-customizer.png"
if [ -f "$ICON_FILE" ]; then
    echo -e "${GREEN}✓${NC} Icon found: $ICON_FILE"
    
    # Check icon size
    if command -v identify >/dev/null 2>&1; then
        ICON_SIZE=$(identify "$ICON_FILE" 2>/dev/null | awk '{print $3}' | head -1)
        echo -e "${BLUE}ℹ${NC} Icon size: $ICON_SIZE"
    fi
else
    echo -e "${YELLOW}⚠${NC} Icon not found: $ICON_FILE"
    echo "   Application will use a default icon"
fi

# Check if application appears in menu
echo ""
echo "Menu integration test:"
if command -v gtk-launch >/dev/null 2>&1; then
    if gtk-launch --version >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} gtk-launch is available for testing"
        echo "   You can test launching with: gtk-launch folder-customizer"
    fi
else
    echo -e "${BLUE}ℹ${NC} gtk-launch not available"
fi

# Check desktop database
echo ""
echo "Desktop database status:"
DESKTOP_CACHE="$INSTALL_PREFIX/share/applications/mimeinfo.cache"
if [ -f "$DESKTOP_CACHE" ]; then
    if grep -q "folder-customizer" "$DESKTOP_CACHE" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Application registered in desktop database"
    else
        echo -e "${YELLOW}⚠${NC} Application not found in desktop database"
        echo "   Try running: update-desktop-database $INSTALL_PREFIX/share/applications"
    fi
else
    echo -e "${BLUE}ℹ${NC} Desktop database cache not found (this may be normal)"
fi

# Check icon cache
ICON_CACHE="$INSTALL_PREFIX/share/icons/hicolor/icon-theme.cache"
if [ -f "$ICON_CACHE" ]; then
    echo -e "${GREEN}✓${NC} Icon cache exists"
else
    echo -e "${YELLOW}⚠${NC} Icon cache not found"
    echo "   Try running: gtk-update-icon-cache $INSTALL_PREFIX/share/icons/hicolor"
fi

echo ""
echo "Manual test suggestions:"
echo "1. Check if 'Folder Customizer' appears in your application launcher"
echo "2. Try searching for 'folder' or 'customize' in your app menu"
echo "3. Test drag & drop by dragging a folder onto the app icon"
echo "4. Right-click on a folder and look for context menu options (if configured)"

echo ""
echo -e "${BLUE}Validation complete!${NC}"
