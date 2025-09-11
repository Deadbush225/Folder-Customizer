#!/bin/bash
# Folder Customizer Linux Installation Script
# This script installs Folder Customizer on Linux and can apply icons via .directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Prompt helper (yes/no)
confirm() {
    read -r -p "${1:-Are you sure?} [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    INSTALL_PREFIX="/usr"
    INSTALL_USER="system-wide"
else
    INSTALL_PREFIX="$HOME/.local"
    INSTALL_USER="user-specific"
fi

log_info "Folder Customizer Installation Script"
log_info "Installing for: $INSTALL_USER"
log_info "Install prefix: $INSTALL_PREFIX"

# Parse args
ACTION="install"
FOLDER=""
TONE=""
COLOR=""
TAG=""
AUTO_YES=0
for arg in "$@"; do
    case "$arg" in
        uninstall|--uninstall)
            ACTION="uninstall" ;;
        apply|--apply)
            ACTION="apply" ;;
        validate|--validate)
            ACTION="validate" ;;
        -y|--yes)
            AUTO_YES=1 ;;
        -h|--help)
            echo "Usage: $0 [--uninstall] [--apply] [--validate] [-y] [--folder PATH --tone T --color C --tag TAG]";
            echo "  (no args)   Install Folder Customizer";
            echo "  --uninstall Uninstall Folder Customizer";
            echo "  --apply     Apply an icon to a folder using .directory (Linux)";
            echo "  --validate  Validate desktop integration is working";
            echo "  --folder    Target folder path for --apply";
            echo "  --tone      Tone for icon (Dark|Light|Normal) for --apply";
            echo "  --color     Color for icon (e.g. Red, Blue, ...) for --apply";
            echo "  --tag       Optional tag/comment to write to .directory";
            echo "  -y, --yes   Skip confirmation prompts";
            exit 0 ;;
        --folder=*) FOLDER="${arg#*=}" ;;
        --tone=*|--Tone=*) TONE="${arg#*=}" ;;
        --color=*|--Color=*) COLOR="${arg#*=}" ;;
        --tag=*|--Tag=*) TAG="${arg#*=}" ;;
    esac
done

# Uninstall routine
do_uninstall() {
    log_info "Uninstalling Folder Customizer from $INSTALL_PREFIX ..."

    if [ "$AUTO_YES" -ne 1 ]; then
        if ! confirm "Remove Folder Customizer from $INSTALL_PREFIX?"; then
            log_warning "Uninstall cancelled"
            exit 0
        fi
    fi

    # Remove binaries and libraries
    rm -f "$INSTALL_PREFIX/bin/folder-customizer" || true
    rm -f "$INSTALL_PREFIX/bin/fc-directory" || true
    rm -rf "$INSTALL_PREFIX/lib/folder-customizer" || true
    
    # Remove desktop integration
    rm -f "$INSTALL_PREFIX/share/applications/folder-customizer.desktop" || true
    rm -f "$INSTALL_PREFIX/share/icons/hicolor/256x256/apps/folder-customizer.png" || true
    rm -rf "$INSTALL_PREFIX/share/folder-customizer" || true
    
    # Remove any additional icon sizes that might have been installed
    find "$INSTALL_PREFIX/share/icons" -name "folder-customizer.png" -delete 2>/dev/null || true

    # Update system databases
    if command -v update-desktop-database &> /dev/null; then
        log_info "Updating desktop database..."
        update-desktop-database "$INSTALL_PREFIX/share/applications" 2>/dev/null || true
    fi

    if command -v gtk-update-icon-cache &> /dev/null; then
        log_info "Updating icon cache..."
        gtk-update-icon-cache -f -t "$INSTALL_PREFIX/share/icons/hicolor" 2>/dev/null || true
    fi

    # Clean up any remaining empty directories
    rmdir "$INSTALL_PREFIX/share/folder-customizer" 2>/dev/null || true
    rmdir "$INSTALL_PREFIX/lib" 2>/dev/null || true

    log_success "Folder Customizer uninstalled from $INSTALL_PREFIX"
    exit 0
}

if [ "$ACTION" = "uninstall" ]; then
    do_uninstall
fi

do_install() {
    # Locate package/build directory relative to this script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    INSTALL_DIR="$SCRIPT_DIR/install"

    # Support repo root (with install/) or packaged release in current dir
    if [ -f "$SCRIPT_DIR/install/FolderCustomizer" ] || [ -f "$SCRIPT_DIR/install/Folder\ Customizer" ]; then
        INSTALL_DIR="$SCRIPT_DIR/install"
    elif [ -f "$SCRIPT_DIR/FolderCustomizer" ] || [ -f "$SCRIPT_DIR/Folder\ Customizer" ]; then
        INSTALL_DIR="$SCRIPT_DIR"
    else
        INSTALL_DIR="$SCRIPT_DIR"
    fi

    # Resolve binary name in package/build
    if [ -f "$INSTALL_DIR/FolderCustomizer" ]; then
        BIN_SRC="FolderCustomizer"
    elif [ -f "$INSTALL_DIR/Folder Customizer" ]; then
        BIN_SRC="Folder Customizer"
    else
        log_error "Package not found."
        echo "Run this script from the extracted package directory (containing 'FolderCustomizer' and 'manifest.json'),"
        echo "or build the project and run it from the repo root after 'install_local' to use ./packages/com.mainprogram/data/bin/."
        exit 1
    fi

    # Read version from manifest.json if available
    if [ -f "$INSTALL_DIR/manifest.json" ]; then
        VERSION=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$INSTALL_DIR/manifest.json" | sed 's/.*: *"\([^"]*\)".*/\1/')
        log_info "Installing version $VERSION"
    else
        log_info "Installing version (unknown)"
    fi

    # Create directories
    log_info "Creating installation directories..."
    mkdir -p "$INSTALL_PREFIX/bin"
    mkdir -p "$INSTALL_PREFIX/lib/folder-customizer"
    mkdir -p "$INSTALL_PREFIX/share/applications"
    mkdir -p "$INSTALL_PREFIX/share/icons/hicolor/256x256/apps"
    mkdir -p "$INSTALL_PREFIX/share/folder-customizer/icons"

    # Install application and libraries
    log_info "Installing Folder Customizer..."
    cp "$INSTALL_DIR/$BIN_SRC" "$INSTALL_PREFIX/lib/folder-customizer/"
    cp "$INSTALL_DIR/manifest.json" "$INSTALL_PREFIX/lib/folder-customizer/" 2>/dev/null || true

    # Install eUpdater if available
    if [ -f "$INSTALL_DIR/eUpdater" ] || [ -f "$INSTALL_DIR/eUpdater.exe" ]; then
        log_info "Installing eUpdater..."
        cp "$INSTALL_DIR"/eUpdater* "$INSTALL_PREFIX/lib/folder-customizer/" 2>/dev/null || true
    fi

    # Copy Qt libraries
    if ls "$INSTALL_DIR"/*.so* 1> /dev/null 2>&1; then
        log_info "Installing Qt libraries..."
        cp "$INSTALL_DIR"/*.so* "$INSTALL_PREFIX/lib/folder-customizer/" 2>/dev/null || true
    fi

    # Create wrapper script
    log_info "Creating launcher script..."
        cat > "$INSTALL_PREFIX/bin/folder-customizer" << EOF
#!/bin/bash

# Debug mode - uncomment to enable troubleshooting
# export FC_DEBUG=1

if [ "\$FC_DEBUG" = "1" ]; then
    echo "=== Folder Customizer Debug Mode ==="
    echo "LD_LIBRARY_PATH: \$LD_LIBRARY_PATH"
    echo "PATH: \$PATH"
    echo "Checking dependencies..."
    ldd "$INSTALL_PREFIX/lib/folder-customizer/$BIN_SRC" 2>/dev/null | grep -E "(boost|not found)" || true
    echo "Checking eUpdater..."
    ls -la "$INSTALL_PREFIX/lib/folder-customizer/eUpdater"* 2>/dev/null || echo "eUpdater not found in $INSTALL_PREFIX/lib/folder-customizer/"
    echo "=================================="
fi

export LD_LIBRARY_PATH="$INSTALL_PREFIX/lib/folder-customizer:\$LD_LIBRARY_PATH"
export PATH="$INSTALL_PREFIX/lib/folder-customizer:\$PATH"
exec "$INSTALL_PREFIX/lib/folder-customizer/$BIN_SRC" "\$@"
EOF
        chmod +x "$INSTALL_PREFIX/bin/folder-customizer"

        # Install helper to apply .directory icons
        cat > "$INSTALL_PREFIX/bin/fc-directory" << 'EOF'
#!/bin/bash
set -e
usage() { echo "Usage: fc-directory --folder PATH --tone (Dark|Light|Normal) --color COLOR [--tag TEXT]" >&2; }
for arg in "$@"; do
    case "$arg" in
        --folder=*) FOLDER="${arg#*=}" ;;
        --tone=*) TONE="${arg#*=}" ;;
        --color=*) COLOR="${arg#*=}" ;;
        --tag=*) TAG="${arg#*=}" ;;
    esac
done
[ -z "$FOLDER" ] && usage && exit 2
[ -z "$TONE" ] && usage && exit 2
[ -z "$COLOR" ] && usage && exit 2
ICON_BASE_SYS="/usr/share/folder-customizer/icons"
ICON_BASE_USR="$HOME/.local/share/folder-customizer/icons"
if [ -f "$ICON_BASE_SYS/$TONE/$COLOR.png" ]; then
    ICON_PATH="$ICON_BASE_SYS/$TONE/$COLOR.png"
elif [ -f "$ICON_BASE_USR/$TONE/$COLOR.png" ]; then
    ICON_PATH="$ICON_BASE_USR/$TONE/$COLOR.png"
else
    echo "Icon not found: $TONE/$COLOR.png" >&2; exit 3
fi
mkdir -p "$FOLDER"
cat > "$FOLDER/.directory" <<EOD
[Desktop Entry]
Icon=$ICON_PATH
EOD
[ -n "$TAG" ] && echo "Comment=$TAG" >> "$FOLDER/.directory"
echo "Applied icon to $FOLDER"
EOF
        chmod +x "$INSTALL_PREFIX/bin/fc-directory"

    # Install desktop file
    log_info "Installing desktop entry..."
    if [ -f "$SCRIPT_DIR/folder-customizer.desktop" ]; then
        # Use the comprehensive desktop file from the project
        cp "$SCRIPT_DIR/folder-customizer.desktop" "$INSTALL_PREFIX/share/applications/"
        # Update the Exec path to use the installed wrapper script
        sed -i 's|Exec=folder-customizer|Exec=folder-customizer|g' "$INSTALL_PREFIX/share/applications/folder-customizer.desktop"
    elif [ -f "$INSTALL_DIR/folder-customizer.desktop" ]; then
        cp "$INSTALL_DIR/folder-customizer.desktop" "$INSTALL_PREFIX/share/applications/"
        sed -i 's|Exec=folder-customizer|Exec=folder-customizer|g' "$INSTALL_PREFIX/share/applications/folder-customizer.desktop"
    else
        # Fallback: create a comprehensive desktop file
        cat > "$INSTALL_PREFIX/share/applications/folder-customizer.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Folder Customizer
GenericName=Folder Icon Customizer
Comment=Customize folder icons and add tags to organize your directories
Exec=folder-customizer %F
Icon=folder-customizer
Terminal=false
MimeType=inode/directory;
Categories=Utility;FileManager;Qt;
Keywords=folder;icon;customize;tag;organize;directory;
StartupNotify=true
StartupWMClass=FolderCustomizer
Actions=NewInstance;

[Desktop Action NewInstance]
Name=New Instance
Exec=folder-customizer
EOF
    fi
    chmod 644 "$INSTALL_PREFIX/share/applications/folder-customizer.desktop"

    # Install icon if available
        if [ -f "$SCRIPT_DIR/Icons/Folder Customizer.png" ]; then
        log_info "Installing application icon..."
                cp "$SCRIPT_DIR/Icons/Folder Customizer.png" "$INSTALL_PREFIX/share/icons/hicolor/256x256/apps/folder-customizer.png"
    else
        log_warning "No icon found, application will use default icon"
    fi

        # Install PNG icon set for Linux helper
        for tone in Dark Light Normal; do
            if [ -d "$SCRIPT_DIR/Icons/$tone/PNG" ]; then
                mkdir -p "$INSTALL_PREFIX/share/folder-customizer/icons/$tone"
                cp "$SCRIPT_DIR/Icons/$tone/PNG"/*.png "$INSTALL_PREFIX/share/folder-customizer/icons/$tone/" 2>/dev/null || true
            fi
        done

    # Update desktop database if available
    if command -v update-desktop-database &> /dev/null; then
        log_info "Updating desktop database..."
        update-desktop-database "$INSTALL_PREFIX/share/applications" 2>/dev/null || true
    fi

    # Update icon cache if available
    if command -v gtk-update-icon-cache &> /dev/null; then
        log_info "Updating icon cache..."
        gtk-update-icon-cache -t "$INSTALL_PREFIX/share/icons/hicolor" 2>/dev/null || true
    fi

    log_success "Folder Customizer installed successfully!"
    log_info "You can now run 'folder-customizer' from the command line"
    log_info "Or find it in your application menu under Utilities"

    # Show additional usage information
    echo ""
    log_info "Usage examples:"
    echo "  folder-customizer                    # Open the GUI"
    echo "  FC_DEBUG=1 folder-customizer         # Debug mode (if issues occur)"
    echo "  fc-directory --folder /path --tone Dark --color Blue  # CLI icon application"

    # Offer to add to PATH for user installs
    if [ "$EUID" -ne 0 ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo ""
        log_warning "~/.local/bin is not in your PATH"
        if [ -n "$ZSH_VERSION" ]; then
            echo "Add this line to your ~/.zprofile or ~/.zshrc:"
        else
            echo "Add this line to your ~/.bashrc or ~/.profile:"
        fi
        echo "export PATH=\"$HOME/.local/bin:\$PATH\""
        echo "Then restart your terminal or run: source ~/.bashrc"
    fi

    echo ""
    log_info "Desktop integration features:"
    echo "  • Application appears in your applications menu"
    echo "  • Supports drag & drop of folders"
    echo "  • Right-click context menu support (if configured)"
    echo "  • Automatic updates via Help → Check Updates"

    echo ""
    log_info "To validate the installation, run:"
    echo "  $0 --validate"

    log_success "Installation complete!"
}

# Run install when requested
if [ "$ACTION" = "install" ]; then
    do_install
fi

# Apply icon via .directory when requested
if [ "$ACTION" = "apply" ]; then
    if [ -z "$FOLDER" ] || [ -z "$TONE" ] || [ -z "$COLOR" ]; then
        log_error "--apply requires --folder=, --tone= and --color="
        exit 2
    fi
    log_info "Applying icon ($TONE/$COLOR) to $FOLDER"
    "$INSTALL_PREFIX/bin/fc-directory" --folder="$FOLDER" --tone="$TONE" --color="$COLOR" ${TAG:+--tag="$TAG"}
    log_success ".directory icon applied"
fi

# Validate desktop integration when requested
if [ "$ACTION" = "validate" ]; then
    log_info "Validating desktop integration ($INSTALL_USER)"
    echo ""

    # Check desktop file
    DESKTOP_FILE="$INSTALL_PREFIX/share/applications/folder-customizer.desktop"
    if [ -f "$DESKTOP_FILE" ]; then
        log_success "Desktop file found: $DESKTOP_FILE"
        
        # Validate desktop file
        if command -v desktop-file-validate >/dev/null 2>&1; then
            if desktop-file-validate "$DESKTOP_FILE" 2>/dev/null; then
                log_success "Desktop file is valid"
            else
                log_warning "Desktop file validation warnings:"
                desktop-file-validate "$DESKTOP_FILE" 2>&1 || true
            fi
        else
            log_info "desktop-file-validate not available (install desktop-file-utils to validate)"
        fi
        
        # Check if executable exists
        EXEC_LINE=$(grep "^Exec=" "$DESKTOP_FILE" | head -1)
        if [ -n "$EXEC_LINE" ]; then
            EXEC_CMD=$(echo "$EXEC_LINE" | sed 's/Exec=//; s/ %F//; s/ %U//; s/ %f//; s/ %u//')
            if command -v "$EXEC_CMD" >/dev/null 2>&1; then
                log_success "Executable is available: $EXEC_CMD"
            else
                log_error "Executable not found: $EXEC_CMD"
            fi
        fi
    else
        log_error "Desktop file not found: $DESKTOP_FILE"
    fi

    # Check icon
    ICON_FILE="$INSTALL_PREFIX/share/icons/hicolor/256x256/apps/folder-customizer.png"
    if [ -f "$ICON_FILE" ]; then
        log_success "Icon found: $ICON_FILE"
        
        # Check icon size
        if command -v identify >/dev/null 2>&1; then
            ICON_SIZE=$(identify "$ICON_FILE" 2>/dev/null | awk '{print $3}' | head -1)
            log_info "Icon size: $ICON_SIZE"
        fi
    else
        log_warning "Icon not found: $ICON_FILE (application will use default icon)"
    fi

    # Check desktop database
    echo ""
    log_info "Desktop database status:"
    DESKTOP_CACHE="$INSTALL_PREFIX/share/applications/mimeinfo.cache"
    if [ -f "$DESKTOP_CACHE" ]; then
        if grep -q "folder-customizer" "$DESKTOP_CACHE" 2>/dev/null; then
            log_success "Application registered in desktop database"
        else
            log_warning "Application not found in desktop database"
            echo "   Try running: update-desktop-database $INSTALL_PREFIX/share/applications"
        fi
    else
        log_info "Desktop database cache not found (this may be normal)"
    fi

    # Check icon cache
    ICON_CACHE="$INSTALL_PREFIX/share/icons/hicolor/icon-theme.cache"
    if [ -f "$ICON_CACHE" ]; then
        log_success "Icon cache exists"
    else
        log_warning "Icon cache not found"
        echo "   Try running: gtk-update-icon-cache $INSTALL_PREFIX/share/icons/hicolor"
    fi

    echo ""
    log_info "Manual test suggestions:"
    echo "1. Check if 'Folder Customizer' appears in your application launcher"
    echo "2. Try searching for 'folder' or 'customize' in your app menu"
    echo "3. Test drag & drop by dragging a folder onto the app icon"
    echo "4. Test command line: folder-customizer"
    if command -v gtk-launch >/dev/null 2>&1; then
        echo "5. Test desktop launch: gtk-launch folder-customizer"
    fi

    log_success "Validation complete!"
fi