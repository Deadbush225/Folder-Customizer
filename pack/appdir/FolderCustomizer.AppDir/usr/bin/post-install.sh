#!/bin/bash
# Post-installation customization script for Folder Customizer
# This script is called by generic-desktop-install.sh after the main installation
#
# Arguments:
# $1 - INSTALL_PREFIX (e.g., /usr/local)
# $2 - PACKAGE_ID (e.g., folder-customizer)
# $3 - APP_NAME (e.g., "Folder Customizer")

set -e

INSTALL_PREFIX="$1"
PACKAGE_ID="$2"
APP_NAME="$3"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[POST-INSTALL]${NC} $1"; }
log_success() { echo -e "${GREEN}[POST-INSTALL]${NC} $1"; }

# Create fc-directory CLI helper
log_info "Creating fc-directory helper..."
mkdir -p "$INSTALL_PREFIX/bin"
cat > "$INSTALL_PREFIX/bin/fc-directory" << 'EOF'
#!/bin/bash
# fc-directory - CLI helper for Folder Customizer
# Creates a folder and opens Folder Customizer for immediate customization

if [ $# -eq 0 ]; then
    echo "Usage: fc-directory <folder-name>"
    echo "Creates a folder and opens Folder Customizer for customization"
    exit 1
fi

FOLDER_NAME="$1"

# Create the folder if it doesn't exist
if [ ! -d "$FOLDER_NAME" ]; then
    mkdir -p "$FOLDER_NAME"
    echo "Created folder: $FOLDER_NAME"
else
    echo "Folder already exists: $FOLDER_NAME"
fi

# Open Folder Customizer with the folder
if command -v folder-customizer >/dev/null 2>&1; then
    folder-customizer "$FOLDER_NAME"
else
    echo "Error: folder-customizer command not found"
    exit 1
fi
EOF

chmod +x "$INSTALL_PREFIX/bin/fc-directory"
log_success "Created fc-directory helper script"

# Add any other Folder Customizer specific post-install tasks here
log_success "Folder Customizer post-install customization completed"
