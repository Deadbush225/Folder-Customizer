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
        -y|--yes)
            AUTO_YES=1 ;;
        -h|--help)
            echo "Usage: $0 [--uninstall] [--apply] [-y] [--folder PATH --tone T --color C --tag TAG]";
            echo "  (no args)   Install Folder Customizer";
            echo "  --uninstall Uninstall Folder Customizer";
            echo "  --apply     Apply an icon to a folder using .directory (Linux)";
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

    rm -f "$INSTALL_PREFIX/bin/folder-customizer" || true
    rm -f "$INSTALL_PREFIX/bin/fc-directory" || true
    rm -rf "$INSTALL_PREFIX/lib/folder-customizer" || true
    rm -f "$INSTALL_PREFIX/share/applications/folder-customizer.desktop" || true
    rm -f "$INSTALL_PREFIX/share/icons/hicolor/256x256/apps/folder-customizer.png" || true
    rm -rf "$INSTALL_PREFIX/share/folder-customizer" || true

    if command -v update-desktop-database &> /dev/null; then
        log_info "Updating desktop database..."
        update-desktop-database "$INSTALL_PREFIX/share/applications" 2>/dev/null || true
    fi

    if command -v gtk-update-icon-cache &> /dev/null; then
        log_info "Updating icon cache..."
        gtk-update-icon-cache -t "$INSTALL_PREFIX/share/icons/hicolor" 2>/dev/null || true
    fi

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
export LD_LIBRARY_PATH="$INSTALL_PREFIX/lib/folder-customizer:\$LD_LIBRARY_PATH"
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

    # Create desktop file
    log_info "Creating desktop entry..."
    cat > "$INSTALL_PREFIX/share/applications/folder-customizer.desktop" << EOF
[Desktop Entry]
Name=Folder Customizer
Comment=Customize folder icons and tags
Exec=folder-customizer
Icon=folder-customizer
Type=Application
Categories=Utility;FileManager;Qt;
StartupNotify=true
EOF

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

    # Offer to add to PATH for user installs
    if [ "$EUID" -ne 0 ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log_warning "~/.local/bin is not in your PATH"
        if [ -n "$ZSH_VERSION" ]; then
            echo "Add this line to your ~/.zprofile or ~/.zshrc:"
        else
            echo "Add this line to your ~/.bashrc or ~/.profile:"
        fi
        echo "export PATH=\"$HOME/.local/bin:\$PATH\""
    fi

    log_info "Installation complete!"
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