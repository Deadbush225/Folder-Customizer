#!/bin/bash
# Generic cross-platform deployment script
# Usage: ./eDeployLinux.sh [all|windows|linux|appimage|deb|rpm|arch]
#
# Environment variables:
# - CLEAN_BUILD=1: Force clean build (removes build directory)
# - KEEP_OLD_DIST=1: Keep old packages in release/ directory
# - BUILD_TYPE: CMake build type (default: Release)
#
# This script expects the following environment variables or config file:
# - APP_NAME: Display name (e.g., "Folder Customizer", "Download Sorter")
# - APP_BINARY: Binary name (e.g., "FolderCustomizer", "DownloadSorter")
# - APP_PACKAGE: Package name (e.g., "folder-customizer", "download-sorter")
# - APP_DESCRIPTION: Short description
# - APP_CATEGORIES: Desktop categories (e.g., "Utility;FileManager;")
# - APP_MAINTAINER: Maintainer info
# - APP_URL: Project URL
# - APP_LICENSE: License type (e.g., "MIT")
#
# Optional:
# - APP_ICON_SOURCE: Path to icon source (default: detect from project)
# - APP_DEPS_DEB: Debian dependencies
# - APP_DEPS_RPM: RPM dependencies
# - EXTRA_HELPERS: Additional helper scripts to include

set -e

# Get the project root (where this script is called from)
PROJECT_ROOT="$(pwd)"
BUILD_DIR="$PROJECT_ROOT/build/build-linux"
INSTALL_DIR="$PROJECT_ROOT/dist/linux"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

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

# Load deployment configuration
load_config() {
    # Read configuration from manifest.json
    if [ ! -f "$PROJECT_ROOT/manifest.json" ]; then
        log_error "manifest.json not found in project root"
        exit 1
    fi

    # Check if jq is available for JSON parsing
    if ! command -v jq &> /dev/null; then
        log_warning "jq not found, using fallback JSON parsing"
        # Fallback to grep-based parsing
        APP_NAME=$(grep -o '"name"[^"]*"[^"]*"' "$PROJECT_ROOT/manifest.json" | sed 's/.*"\([^"]*\)"/\1/')
        VERSION=$(grep -o '"version"[^"]*"[0-9.]*"' "$PROJECT_ROOT/manifest.json" | sed 's/.*"\([0-9.]*\)"/\1/')
        APP_DESCRIPTION=$(grep -o '"description"[^"]*"[^"]*"' "$PROJECT_ROOT/manifest.json" | sed 's/.*"\([^"]*\)"/\1/')
        APP_BINARY=$(grep -o '"executable"[^"]*"[^"]*"' "$PROJECT_ROOT/manifest.json" | sed 's/.*"\([^"]*\)"/\1/')
        APP_PACKAGE=$(grep -o '"package_id"[^"]*"[^"]*"' "$PROJECT_ROOT/manifest.json" | sed 's/.*"\([^"]*\)"/\1/')
        APP_CATEGORIES=$(grep -o '"categories"[^"]*"[^"]*"' "$PROJECT_ROOT/manifest.json" | sed 's/.*"\([^"]*\)"/\1/')
        # Set defaults for complex fields when jq is not available
        APP_MAINTAINER="Unknown <unknown@example.com>"
        APP_URL="https://github.com/user/repo"
        APP_LICENSE="MIT"
        APP_DEPS_DEB="libc6, libqt6core6, libqt6gui6, libqt6widgets6"
        APP_DEPS_RPM="qt6-qtbase qt6-qtbase-gui"
    else
        log_info "Loading configuration from: $PROJECT_ROOT/manifest.json"
        # Use jq for precise JSON parsing
        APP_NAME=$(jq -r '.name' "$PROJECT_ROOT/manifest.json")
        VERSION=$(jq -r '.version' "$PROJECT_ROOT/manifest.json")
        APP_DESCRIPTION=$(jq -r '.description' "$PROJECT_ROOT/manifest.json")
        APP_BINARY=$(jq -r '.desktop.executable' "$PROJECT_ROOT/manifest.json")
        APP_PACKAGE=$(jq -r '.desktop.package_id' "$PROJECT_ROOT/manifest.json")
        APP_CATEGORIES=$(jq -r '.desktop.categories' "$PROJECT_ROOT/manifest.json")
        APP_MAINTAINER=$(jq -r '.maintainer // "Unknown <unknown@example.com>"' "$PROJECT_ROOT/manifest.json")
        APP_URL=$(jq -r '.homepage // "https://github.com/user/repo"' "$PROJECT_ROOT/manifest.json")
        APP_LICENSE=$(jq -r '.license // "MIT"' "$PROJECT_ROOT/manifest.json")
        APP_DEPS_DEB=$(jq -r '.deployment.dependencies.deb // "libc6, libqt6core6, libqt6gui6, libqt6widgets6"' "$PROJECT_ROOT/manifest.json")
        APP_DEPS_RPM=$(jq -r '.deployment.dependencies.rpm // "qt6-qtbase qt6-qtbase-gui"' "$PROJECT_ROOT/manifest.json")
    fi
    
    # Validate required configuration
    if [ -z "$APP_NAME" ] || [ -z "$APP_BINARY" ] || [ -z "$APP_PACKAGE" ]; then
        log_error "Missing required configuration in manifest.json"
        log_info "Ensure manifest.json contains:"
        echo "  \"name\": \"Your App Name\""
        echo "  \"desktop\": {"
        echo "    \"executable\": \"YourAppBinary\","
        echo "    \"package_id\": \"your-app-package\""
        echo "  }"
        exit 1
    fi
    
    echo "=== Generic Deployment Script ==="
    echo "Application: $APP_NAME"
    echo "Binary: $APP_BINARY"
    echo "Package: $APP_PACKAGE"
    echo "Version: $VERSION"
    echo "Project root: $PROJECT_ROOT"
}

# Build and install project
build_project() {
    log_info "Building project..."
    
    # Set build configuration
    BUILD_TYPE="${BUILD_TYPE:-Release}"
    
    # Detect source directory (some projects have CMakeLists.txt in src/, others in root)
    SOURCE_DIR="$PROJECT_ROOT"
    if [ -f "$PROJECT_ROOT/src/CMakeLists.txt" ]; then
        SOURCE_DIR="$PROJECT_ROOT/src"
        log_info "Detected CMakeLists.txt in src/ directory"
    elif [ -f "$PROJECT_ROOT/CMakeLists.txt" ]; then
        SOURCE_DIR="$PROJECT_ROOT"
        log_info "Detected CMakeLists.txt in root directory"
    else
        log_error "CMakeLists.txt not found in root or src/ directory"
        exit 1
    fi
    
    # Clean build directory if requested or if it seems corrupted
    if [ "${CLEAN_BUILD:-0}" = "1" ] || [ ! -f "$BUILD_DIR/CMakeCache.txt" ]; then
        log_info "Cleaning build directory..."
        rm -rf "$BUILD_DIR"
    fi
    
    # Configure with CMake
    log_info "Configuring with CMake (Build Type: $BUILD_TYPE, Source: $SOURCE_DIR)..."
    cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" "$SOURCE_DIR"
    
    if [ $? -ne 0 ]; then
        log_error "CMake configuration failed"
        exit 1
    fi
    
    # Build the project
    log_info "Building with CMake..."
    cmake --build "$BUILD_DIR" --config "$BUILD_TYPE"
    
    if [ $? -ne 0 ]; then
        log_error "Build failed"
        exit 1
    fi
    
    # Install to dist/linux directory
    log_info "Installing to $INSTALL_DIR..."
    cmake --install "$BUILD_DIR" --config "$BUILD_TYPE" --prefix "$INSTALL_DIR"
    
    if [ $? -ne 0 ]; then
        log_error "Installation failed"
        exit 1
    fi
    
    log_success "Build and installation completed successfully"
}

# Check if build exists and find executables
check_build() {
    log_info "Checking for build artifacts in: $INSTALL_DIR"
    if [ ! -d "$INSTALL_DIR" ]; then
        log_info "Install directory '$INSTALL_DIR' does not exist. Building project..."
        build_project
    fi

    # Show what's in the install directory to help debugging
    echo "--- Install directory structure ---"
    find "$INSTALL_DIR" -type f | head -20 || true
    echo "--- End structure ---"

    # Find main executable in bin/ (prioritize main app over utilities)
    BIN_NAME=""
    if [ -d "$INSTALL_DIR/bin" ]; then
        # First look for the specified binary
        if [ -f "$INSTALL_DIR/bin/$APP_BINARY" ] && [ -x "$INSTALL_DIR/bin/$APP_BINARY" ]; then
            BIN_NAME="$APP_BINARY"
            MAIN_EXECUTABLE="$INSTALL_DIR/bin/$APP_BINARY"
            log_info "Found main executable: $BIN_NAME"
        else
            # Fallback to any executable that's not a utility
            for f in "$INSTALL_DIR/bin"/*; do
                if [ -f "$f" ] && [ -x "$f" ]; then
                    basename_f="$(basename "$f")"
                    # Skip known utilities
                    case "$basename_f" in
                        eUpdater|eUpdater.exe) continue ;;
                        *) BIN_NAME="$basename_f"; MAIN_EXECUTABLE="$f"; log_info "Found executable: $BIN_NAME"; break ;;
                    esac
                fi
            done
        fi
    fi
    
    if [ -z "$BIN_NAME" ]; then
        log_error "No executable found in $INSTALL_DIR/bin/ even after building."
        exit 1
    fi
}

# Prepare release and pack directories
prepare_dist() {
    mkdir -p "$PROJECT_ROOT/release"
    mkdir -p "$PROJECT_ROOT/pack/arch"
    mkdir -p "$PROJECT_ROOT/pack/deb"
    mkdir -p "$PROJECT_ROOT/pack/appdir"
    mkdir -p "$PROJECT_ROOT/pack/rpm"
    
    if [ "${KEEP_OLD_DIST:-0}" != "1" ]; then
        log_info "Cleaning release/ and pack/ (set KEEP_OLD_DIST=1 to keep)"
        rm -rf "$PROJECT_ROOT/pack/arch"/* "$PROJECT_ROOT/pack/deb"/* "$PROJECT_ROOT/pack/appdir"/* "$PROJECT_ROOT/pack/rpm"/* 2>/dev/null || true
        rm -rf "$PROJECT_ROOT"/release/${APP_PACKAGE}-* "$PROJECT_ROOT"/release/${APP_BINARY}-* 2>/dev/null || true
    fi
}

# Find and copy icon
copy_icon() {
    local dest="$1"
    local icon_name="$2"
    
    # Try various icon locations in order of preference
    local icon_sources=(
        "$INSTALL_DIR/icons/${APP_NAME}.png"
        "$INSTALL_DIR/icons/${APP_BINARY}.png"
        "$APP_ICON_SOURCE"
        "$PROJECT_ROOT/Icons/${APP_NAME}.png"
        "$PROJECT_ROOT/src/icons/${APP_NAME}.png"
        "$PROJECT_ROOT/icons/${APP_NAME}.png"
    )
    
    for icon_src in "${icon_sources[@]}"; do
        if [ -n "$icon_src" ] && [ -f "$icon_src" ]; then
            cp "$icon_src" "$dest/$icon_name"
            log_info "Copied icon from: $icon_src"
            return 0
        fi
    done
    
    log_warning "Icon not found, using placeholder"
    # Create a simple placeholder icon
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > "$dest/$icon_name" 2>/dev/null || true
    return 1
}

# Bundle libraries for portable packages
bundle_libraries() {
    local mode="${1:---all}"
    log_info "Bundling libraries for portable deployment (mode: $mode)..."
    
    if [ -f "$SCRIPTS_DIR/bundle-libraries.sh" ]; then
        bash "$SCRIPTS_DIR/bundle-libraries.sh" "$INSTALL_DIR" "$mode"
    else
        log_warning "bundle-libraries.sh not found, portable packages may not work on systems without required libraries"
    fi
}

# Process template files by replacing placeholders
process_template() {
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        log_error "Template file not found: $template_file"
        return 1
    fi
    
    log_info "Processing template: $(basename "$template_file")"
    
    # Escape special characters for sed
    local app_name_esc=$(printf '%s\n' "$APP_NAME" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local app_binary_esc=$(printf '%s\n' "$APP_BINARY" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local app_package_esc=$(printf '%s\n' "$APP_PACKAGE" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local version_esc=$(printf '%s\n' "$VERSION" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local app_description_esc=$(printf '%s\n' "$APP_DESCRIPTION" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local app_categories_esc=$(printf '%s\n' "$APP_CATEGORIES" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local app_maintainer_esc=$(printf '%s\n' "$APP_MAINTAINER" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local app_url_esc=$(printf '%s\n' "$APP_URL" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local app_license_esc=$(printf '%s\n' "$APP_LICENSE" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local app_deps_deb_esc=$(printf '%s\n' "$APP_DEPS_DEB" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local app_deps_rpm_esc=$(printf '%s\n' "$APP_DEPS_RPM" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local project_root_esc=$(printf '%s\n' "$PROJECT_ROOT" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local install_dir_esc=$(printf '%s\n' "$INSTALL_DIR" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    local scripts_dir_esc=$(printf '%s\n' "$SCRIPTS_DIR" | sed 's/[[\.*^$(){}?+|/]/\\&/g')
    
    # Read template and replace placeholders using safe escaped values
    sed \
        -e "s|{{APP_NAME}}|$app_name_esc|g" \
        -e "s|{{APP_BINARY}}|$app_binary_esc|g" \
        -e "s|{{APP_PACKAGE}}|$app_package_esc|g" \
        -e "s|{{VERSION}}|$version_esc|g" \
        -e "s|{{APP_DESCRIPTION}}|$app_description_esc|g" \
        -e "s|{{APP_CATEGORIES}}|$app_categories_esc|g" \
        -e "s|{{APP_MAINTAINER}}|$app_maintainer_esc|g" \
        -e "s|{{APP_URL}}|$app_url_esc|g" \
        -e "s|{{APP_LICENSE}}|$app_license_esc|g" \
        -e "s|{{APP_DEPS_DEB}}|$app_deps_deb_esc|g" \
        -e "s|{{APP_DEPS_RPM}}|$app_deps_rpm_esc|g" \
        -e "s|{{PROJECT_ROOT}}|$project_root_esc|g" \
        -e "s|{{INSTALL_DIR}}|$install_dir_esc|g" \
        -e "s|{{SCRIPTS_DIR}}|$scripts_dir_esc|g" \
        "$template_file" > "$output_file"
    
    log_success "Template processed: $output_file"
}

# Create tar.gz fallback package with eInstall.sh and post-install.sh
create_tarball_fallback() {
    local filename="$1"
    log_info "Creating tar.gz fallback: $filename"
    
    # Only bundle libraries for portable tarball fallback (not for Arch .pkg.tar)
    # If this is called as a fallback for Arch, do NOT bundle $INSTALL_DIR/lib
    cd "$PROJECT_ROOT/release"
    local tempdir="${filename%.tar.gz}-temp"
    mkdir -p "$tempdir"
    # Copy only bin, icons, manifest, scripts (no lib)
    [ -d "$INSTALL_DIR/bin" ] && cp -r "$INSTALL_DIR/bin" "$tempdir/"
    [ -d "$INSTALL_DIR/icons" ] && cp -r "$INSTALL_DIR/icons" "$tempdir/"
    [ -f "$INSTALL_DIR/manifest.json" ] && cp "$INSTALL_DIR/manifest.json" "$tempdir/"
    # Add installation scripts for tar.gz format
    if [ -f "$SCRIPTS_DIR/eInstall.sh" ]; then
        cp "$SCRIPTS_DIR/eInstall.sh" "$tempdir/"
        log_info "Added eInstall.sh to tar.gz"
    fi
    if [ -f "$SCRIPTS_DIR/post-install.sh" ]; then
        cp "$SCRIPTS_DIR/post-install.sh" "$tempdir/"
        log_info "Added post-install.sh to tar.gz"
    fi
    tar czf "$filename" -C . "$tempdir"
    rm -rf "$tempdir"
    log_success "Archive created: release/$filename"
}

# Create AppImage (Universal Linux)
create_appimage() {
    log_info "Creating AppImage..."
    
    # Bundle all libraries for portable deployment
    bundle_libraries --all
    
    local appdir="$PROJECT_ROOT/pack/appdir/${APP_BINARY}.AppDir"
    rm -rf "$appdir"
    mkdir -p "$appdir/usr/bin"
    mkdir -p "$appdir/usr/lib"
    
    # Copy application
    cp "$MAIN_EXECUTABLE" "$appdir/usr/bin/$APP_BINARY"
    
    # Copy manifest.json if available
    if [ -f "$INSTALL_DIR/manifest.json" ]; then
        cp "$INSTALL_DIR/manifest.json" "$appdir/usr/bin/manifest.json"
    fi
    
    # Copy eUpdater if available
    if [ -f "$INSTALL_DIR/bin/eUpdater" ] || [ -f "$INSTALL_DIR/bin/eUpdater.exe" ]; then
        cp "$INSTALL_DIR/bin"/eUpdater* "$appdir/usr/bin/" 2>/dev/null || true
    fi
    
    # Copy libraries from lib/
    if [ -d "$INSTALL_DIR/lib" ] && ls "$INSTALL_DIR/lib"/*.so* 1> /dev/null 2>&1; then
        cp "$INSTALL_DIR/lib"/*.so* "$appdir/usr/lib/" 2>/dev/null || true
    fi
    
    # Copy eInstall.sh script for uninstall functionality
    if [ -f "$SCRIPTS_DIR/eInstall.sh" ]; then
        cp "$SCRIPTS_DIR/eInstall.sh" "$appdir/usr/bin/eInstall.sh"
        chmod +x "$appdir/usr/bin/eInstall.sh"
        log_info "Added eInstall.sh to AppImage"
    else
        log_warning "eInstall.sh not found in $SCRIPTS_DIR"
    fi
    
    # Copy post-install.sh if available
    if [ -f "$SCRIPTS_DIR/post-install.sh" ]; then
        cp "$SCRIPTS_DIR/post-install.sh" "$appdir/usr/bin/post-install.sh"
        chmod +x "$appdir/usr/bin/post-install.sh"
        log_info "Added post-install.sh to AppImage"
    else
        log_warning "post-install.sh not found in $SCRIPTS_DIR"
    fi
    
    # Include any app-specific customizations for AppImage
    if command -v "${APP_PACKAGE//-/_}_appimage_extras" >/dev/null 2>&1; then
        "${APP_PACKAGE//-/_}_appimage_extras" "$appdir"
    fi
    
    # Create desktop file
    cat > "$appdir/${APP_BINARY}.desktop" << EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=$APP_DESCRIPTION
Exec=$APP_BINARY
Icon=${APP_PACKAGE}
Categories=$APP_CATEGORIES
EOF
    
    # Copy icon
    copy_icon "$appdir" "${APP_PACKAGE}.png"
    
    # Create AppRun script
    cat > "$appdir/AppRun" << EOF
#!/bin/bash
HERE="\$(dirname "\$(readlink -f "\${0}")")"
export LD_LIBRARY_PATH="\${HERE}/usr/lib:\${LD_LIBRARY_PATH}"
export PATH="\${HERE}/usr/bin:\${PATH}"

# Qt configuration for bundled libraries
export QT_PLUGIN_PATH="\${HERE}/usr/lib/qt6/plugins:\${QT_PLUGIN_PATH}"
export QML_IMPORT_PATH="\${HERE}/usr/lib/qt6/qml:\${QML_IMPORT_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="\${HERE}/usr/lib/qt6/plugins/platforms"

# Execute the application
exec "\${HERE}/usr/bin/$APP_BINARY" "\$@"
EOF
    chmod +x "$appdir/AppRun"
    
    # Download appimagetool if needed
    if [ ! -f "$SCRIPTS_DIR/appimagetool" ]; then
        log_info "Downloading appimagetool..."
        mkdir -p "$SCRIPTS_DIR"
        wget -O "$SCRIPTS_DIR/appimagetool" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" || true
        chmod +x "$SCRIPTS_DIR/appimagetool" 2>/dev/null || true
    fi

    mkdir -p "$PROJECT_ROOT/release"
    cd "$PROJECT_ROOT/pack/appdir"

    # Try to run appimagetool normally (requires FUSE)
    if "$SCRIPTS_DIR/appimagetool" "$appdir" "$PROJECT_ROOT/release/${APP_BINARY}-${VERSION}-x86_64.AppImage" 2>appimage.err; then
        log_success "AppImage created: release/${APP_BINARY}-${VERSION}-x86_64.AppImage"
        return
    fi

    # If FUSE is missing, extract and run embedded appimagetool without FUSE
    if grep -qi "libfuse" appimage.err; then
        log_warning "FUSE not available, trying extracted appimagetool"
        (
            cd "$SCRIPTS_DIR" && \
            ./appimagetool --appimage-extract >/dev/null 2>&1 && \
            chmod +x "$SCRIPTS_DIR/squashfs-root/AppRun" && \
            "$SCRIPTS_DIR/squashfs-root/AppRun" "$appdir" "$PROJECT_ROOT/release/${APP_BINARY}-${VERSION}-x86_64.AppImage"
        ) && {
            log_success "AppImage created (no FUSE): release/${APP_BINARY}-${VERSION}-x86_64.AppImage"
            return
        }
    fi

    # Fallback to tarball
    cd "$PROJECT_ROOT/release"
    tar czf "${APP_PACKAGE}-${VERSION}-x86_64.tar.gz" -C "$(dirname "$appdir")" "$(basename "$appdir")"
    log_success "Archive created: release/${APP_PACKAGE}-${VERSION}-x86_64.tar.gz"
}

# Create DEB package (Ubuntu/Debian)
create_deb() {
    log_info "Creating DEB package..."
    
    local debdir="$PROJECT_ROOT/pack/deb/${APP_PACKAGE}_${VERSION}_amd64"
    rm -rf "$debdir"
    mkdir -p "$debdir/DEBIAN"
    mkdir -p "$debdir/usr/bin"
    mkdir -p "$debdir/usr/lib/$APP_PACKAGE"
    mkdir -p "$debdir/usr/share/applications"
    mkdir -p "$debdir/usr/share/icons/hicolor/256x256/apps"
    
    # Copy application (do not copy libraries for DEB)
    cp "$MAIN_EXECUTABLE" "$debdir/usr/lib/$APP_PACKAGE/$APP_BINARY"
    # Copy manifest.json if available
    if [ -f "$INSTALL_DIR/manifest.json" ]; then
        cp "$INSTALL_DIR/manifest.json" "$debdir/usr/lib/$APP_PACKAGE/"
    fi
    # Copy eUpdater if available
    if [ -f "$INSTALL_DIR/bin/eUpdater" ] || [ -f "$INSTALL_DIR/bin/eUpdater.exe" ]; then
        cp "$INSTALL_DIR/bin"/eUpdater* "$debdir/usr/lib/$APP_PACKAGE/" 2>/dev/null || true
    fi
    # Do NOT copy $INSTALL_DIR/lib or any .so files for DEB
    
    # Copy post-install.sh if available (for DEBIAN/postinst to use)
    if [ -f "$SCRIPTS_DIR/post-install.sh" ]; then
        cp "$SCRIPTS_DIR/post-install.sh" "$debdir/usr/lib/$APP_PACKAGE/post-install.sh"
        chmod +x "$debdir/usr/lib/$APP_PACKAGE/post-install.sh"
        log_info "Added post-install.sh to DEB package"
    else
        log_warning "post-install.sh not found in $SCRIPTS_DIR"
    fi
    
    # Include any app-specific customizations for DEB
    if command -v "${APP_PACKAGE//-/_}_deb_extras" >/dev/null 2>&1; then
        "${APP_PACKAGE//-/_}_deb_extras" "$debdir"
    fi
    
    # Create wrapper script
    cat > "$debdir/usr/bin/$APP_PACKAGE" << EOF
#!/bin/bash
exec "/usr/lib/$APP_PACKAGE/$APP_BINARY" "\\\$@"
EOF
    chmod +x "$debdir/usr/bin/$APP_PACKAGE"
    
    # Create desktop file
    cat > "$debdir/usr/share/applications/$APP_PACKAGE.desktop" << EOF
[Desktop Entry]
Name=$APP_NAME
Comment=$APP_DESCRIPTION
Exec=$APP_PACKAGE
Icon=$APP_PACKAGE
Type=Application
Categories=$APP_CATEGORIES
EOF
    
    # Copy icon
    copy_icon "$debdir/usr/share/icons/hicolor/256x256/apps" "$APP_PACKAGE.png"
    
    # Create control file
    cat > "$debdir/DEBIAN/control" << EOF
Package: $APP_PACKAGE
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Maintainer: $APP_MAINTAINER
Description: $APP_NAME - $APP_DESCRIPTION
 $APP_DESCRIPTION
Depends: $APP_DEPS_DEB
EOF

    # Create DEBIAN/postinst script
    if [ -f "$SCRIPTS_DIR/post-install.sh" ]; then
        cat > "$debdir/DEBIAN/postinst" << EOF
#!/bin/bash
set -e

# Run post-install.sh if it exists
POST_INSTALL_SCRIPT="/usr/lib/$APP_PACKAGE/post-install.sh"
if [ -f "\$POST_INSTALL_SCRIPT" ]; then
    echo "Running post-installation customization..."
    bash "\$POST_INSTALL_SCRIPT" "/usr" "$APP_PACKAGE" "$APP_NAME" || true
fi

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
fi

# Update icon cache  
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -t /usr/share/icons/hicolor 2>/dev/null || true
fi

exit 0
EOF
        chmod +x "$debdir/DEBIAN/postinst"
        log_info "Created DEBIAN/postinst script"
    fi
    
    # Build package
    if command -v dpkg-deb &> /dev/null; then
        fakeroot dpkg-deb --build "$debdir" "$PROJECT_ROOT/release/${APP_PACKAGE}_${VERSION}_amd64.deb"
        log_success "DEB package created: release/${APP_PACKAGE}_${VERSION}_amd64.deb"
    else
        log_warning "dpkg-deb not found, creating tar.gz instead"
        cd "$PROJECT_ROOT/release"
        tar czf "${APP_PACKAGE}_${VERSION}_amd64.tar.gz" -C "$debdir" .
        log_success "Archive created: release/${APP_PACKAGE}_${VERSION}_amd64.tar.gz"
    fi
}

# Create RPM package (Fedora/RHEL)
create_rpm() {
    log_info "Creating RPM package..."

    # Force tarball on non-RPM distros or when requested
    if [ "${FORCE_RPM_TARBALL:-}" = "1" ]; then
        log_warning "FORCE_RPM_TARBALL=1 set; creating tar.gz instead of RPM"
        create_tarball_fallback "${APP_PACKAGE}-${VERSION}-1.x86_64.tar.gz"
        return
    fi

    # Check for rpmbuild and appropriate distro
    if ! command -v rpmbuild &> /dev/null; then
        log_warning "rpmbuild not found, creating tar.gz instead"
        create_tarball_fallback "${APP_PACKAGE}-${VERSION}-1.x86_64.tar.gz"
        return
    fi

    if [ -r /etc/os-release ]; then
        . /etc/os-release
        case "${ID_LIKE}${ID}" in
            *fedora*|*rhel*|*centos*|*suse*) : ;;
            *)
                log_warning "Non-RPM-based distro detected (${ID:-unknown}); creating tar.gz instead"
                create_tarball_fallback "${APP_PACKAGE}-${VERSION}-1.x86_64.tar.gz"
                return
                ;;
        esac
    fi
    
    local rpmdir="$PROJECT_ROOT/pack/rpm"
    rm -rf "$rpmdir"
    mkdir -p "$rpmdir"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
    
    # Create spec file from template
    if [ -f "$SCRIPTS_DIR/templates/rpm.spec.template" ]; then
        process_template "$SCRIPTS_DIR/templates/rpm.spec.template" "$rpmdir/SPECS/$APP_PACKAGE.spec"
    else
        # Fallback to inline spec file
        cat > "$rpmdir/SPECS/$APP_PACKAGE.spec" << EOF
Name:           $APP_PACKAGE
Version:        $VERSION
Release:        1%{?dist}
Summary:        $APP_DESCRIPTION
License:        $APP_LICENSE
URL:            $APP_URL
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  qt6-qtbase-devel
Requires:       $APP_DEPS_RPM

%description
$APP_DESCRIPTION

%prep
%setup -q

%build
# Files are pre-built

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/lib/%{name}
mkdir -p %{buildroot}/usr/share/applications

# Install files
cp -r * %{buildroot}/usr/lib/%{name}/

# Create wrapper script
cat > %{buildroot}/usr/bin/%{name} << 'EOFSCRIPT'
#!/bin/bash
exec "/usr/lib/$APP_PACKAGE/$APP_BINARY" "\$@"
EOFSCRIPT
chmod +x %{buildroot}/usr/bin/%{name}

%files
/usr/bin/%{name}
/usr/lib/%{name}/
%if 0%{?fedora} || 0%{?rhel} >= 8
/usr/share/applications/%{name}.desktop
%endif

%post
# Run post-install.sh if it exists
if [ -f "/usr/lib/%{name}/post-install.sh" ]; then
    echo "Running post-installation customization..."
    bash "/usr/lib/%{name}/post-install.sh" "/usr" "%{name}" "$APP_NAME" || true
fi

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
fi

# Update icon cache
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -t /usr/share/icons/hicolor 2>/dev/null || true
fi

%changelog
* $(date +'%a %b %d %Y') $APP_MAINTAINER - $VERSION-1
- Initial RPM package
EOF
    fi
    
    # Create source tarball
    cd "$PROJECT_ROOT"
    mkdir -p "$rpmdir/SOURCES/build-temp"
    
    # Copy files from install directory
    if [ -d "$INSTALL_DIR/bin" ]; then
        cp -r "$INSTALL_DIR/bin" "$rpmdir/SOURCES/build-temp/"
    fi
    # Note: RPM packages should use system dependencies, not bundle libraries
    # Libraries are only bundled for portable formats (AppImage, tar.gz)
    if [ -d "$INSTALL_DIR/icons" ]; then
        cp -r "$INSTALL_DIR/icons" "$rpmdir/SOURCES/build-temp/"
    fi
    if [ -f "$INSTALL_DIR/manifest.json" ]; then
        cp "$INSTALL_DIR/manifest.json" "$rpmdir/SOURCES/build-temp/"
    fi
    
    # Copy post-install.sh for %post to use
    if [ -f "$SCRIPTS_DIR/post-install.sh" ]; then
        cp "$SCRIPTS_DIR/post-install.sh" "$rpmdir/SOURCES/build-temp/"
        log_info "Added post-install.sh to RPM package"
    else
        log_warning "post-install.sh not found in $SCRIPTS_DIR"
    fi
    
    cd "$rpmdir/SOURCES"
    tar czf "${APP_PACKAGE}-${VERSION}.tar.gz" -C build-temp .
    rm -rf build-temp
    
    # Build RPM
    if ! rpmbuild --define "_topdir $rpmdir" -bb "$rpmdir/SPECS/$APP_PACKAGE.spec"; then
        log_warning "RPM build failed, creating tar.gz"
        create_tarball_fallback "${APP_PACKAGE}-${VERSION}-1.x86_64.tar.gz"
        return
    fi
    
    # Copy result to release directory
    cp "$rpmdir/RPMS/x86_64/${APP_PACKAGE}-${VERSION}-1."*.rpm "$PROJECT_ROOT/release/" 2>/dev/null || true
    log_success "RPM package created in release/"
}

# Create Arch Linux package
create_arch() {
    log_info "Creating Arch Linux package..."
    
    local archdir="$PROJECT_ROOT/pack/arch"
    rm -rf "$archdir"
    mkdir -p "$archdir"
    
    if ! command -v makepkg &> /dev/null; then
        log_warning "makepkg not found, creating tar.gz instead"
        create_tarball_fallback "${APP_PACKAGE}-${VERSION}-x86_64.tar.gz"
        return
    fi
    
    # Create PKGBUILD from template
    if [ -f "$SCRIPTS_DIR/templates/PKGBUILD.template" ]; then
        process_template "$SCRIPTS_DIR/templates/PKGBUILD.template" "$archdir/PKGBUILD"
    else
        # Fallback to inline PKGBUILD
        cat > "$archdir/PKGBUILD" << EOF
# Maintainer: $APP_MAINTAINER
pkgname=$APP_PACKAGE
pkgver=$VERSION
pkgrel=1
pkgdesc="$APP_DESCRIPTION"
arch=('x86_64')
url="$APP_URL"
license=('$APP_LICENSE')
depends=('qt6-base')
source=()
md5sums=()

package() {
    # Install binary (do not copy libraries for Arch)
    install -dm755 "\$pkgdir/usr/lib/\$pkgname"
    if [ -f "$INSTALL_DIR/bin/$APP_BINARY" ]; then
        cp "$INSTALL_DIR/bin/$APP_BINARY" "\$pkgdir/usr/lib/\$pkgname/$APP_BINARY"
    fi
    # Copy manifest.json if available
    if [ -f "$INSTALL_DIR/manifest.json" ]; then
        cp "$INSTALL_DIR/manifest.json" "\$pkgdir/usr/lib/\$pkgname/"
    fi
    # Copy post-install.sh for post_install() function to use
    if [ -f "$PROJECT_ROOT/scripts/post-install.sh" ]; then
        cp "$PROJECT_ROOT/scripts/post-install.sh" "\$pkgdir/usr/lib/\$pkgname/post-install.sh"
        chmod +x "\$pkgdir/usr/lib/\$pkgname/post-install.sh"
    fi
    # Do NOT copy $INSTALL_DIR/lib or any .so files for Arch
    
    # Create wrapper script
    install -dm755 "\$pkgdir/usr/bin"
    cat > "\$pkgdir/usr/bin/\$pkgname" << 'EOFSCRIPT'
#!/bin/bash
exec "/usr/lib/$APP_PACKAGE/$APP_BINARY" "\$@"
EOFSCRIPT
    chmod +x "\$pkgdir/usr/bin/\$pkgname"
    
    # Desktop file
    install -dm755 "\$pkgdir/usr/share/applications"
    cat > "\$pkgdir/usr/share/applications/\$pkgname.desktop" << 'EOFDESKTOP'
[Desktop Entry]
Name=$APP_NAME
Comment=$APP_DESCRIPTION
Exec=$APP_PACKAGE
Icon=$APP_PACKAGE
Type=Application
Categories=$APP_CATEGORIES
EOFDESKTOP

    # Application icon
    install -dm755 "\$pkgdir/usr/share/icons/hicolor/256x256/apps"
}

post_install() {
    # Run post-install.sh if it exists
    if [ -f "/usr/lib/$APP_PACKAGE/post-install.sh" ]; then
        echo "Running post-installation customization..."
        bash "/usr/lib/$APP_PACKAGE/post-install.sh" "/usr" "$APP_PACKAGE" "$APP_NAME" || true
    fi
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database /usr/share/applications 2>/dev/null || true
    fi
    
    # Update icon cache
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -t /usr/share/icons/hicolor 2>/dev/null || true
    fi
}
EOF
    fi
    
    cd "$archdir"
    makepkg -f || {
        log_warning "makepkg failed, creating tar.gz instead"
        create_tarball_fallback "${APP_PACKAGE}-${VERSION}-x86_64.tar.gz"
        return
    }
    
    # Copy result to release directory
    cp *.pkg.tar.* "$PROJECT_ROOT/release/" 2>/dev/null || true
    log_success "Arch package created in release/"
}

# Create all Linux packages
create_linux() {
    log_info "Creating all Linux packages..."
    create_appimage
    create_deb
    create_rpm
    create_arch
}

# Create Windows installer (placeholder)
create_windows() {
    log_info "Creating Windows installer..."
    
    if command -v powershell &> /dev/null; then
        cd "$PROJECT_ROOT"
        if [ -f "./scripts/update_installer.ps1" ]; then
            powershell -ExecutionPolicy Bypass -File "./scripts/update_installer.ps1"
            log_success "Windows installer created"
        else
            log_warning "update_installer.ps1 not found in scripts/"
        fi
    else
        log_warning "PowerShell not found. Run update_installer.ps1 on Windows."
    fi
}

# Main deployment function
deploy_all() {
    log_info "Creating all deployment packages..."
    prepare_dist
    create_linux
    create_windows
    log_success "All packages created in release/ directory"
}

# Main script logic
main() {
    load_config
    
    case "${1:-all}" in
        "all")
            check_build
            deploy_all
            ;;
        "windows")
            create_windows
            ;;
        "linux")
            check_build
            create_linux
            ;;
        "appimage")
            check_build
            create_appimage
            ;;
        "deb")
            check_build
            create_deb
            ;;
        "rpm")
            check_build
            create_rpm
            ;;
        "arch")
            check_build
            create_arch
            ;;
        *)
            echo "Usage: $0 [all|windows|linux|appimage|deb|rpm|arch]"
            exit 1
            ;;
    esac
    
    log_success "Deployment completed!"
}

# Only run main if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
