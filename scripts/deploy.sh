#!/bin/bash
# Cross-platform deployment script for Folder Customizer
# Usage: ./deploy.sh [all|windows|linux|appimage|deb|rpm|arch]

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
# Prefer local './install' created by the 'install_local' target
INSTALL_DIR="$PROJECT_ROOT/install/bin"
# Fallback to legacy packages path for older workflows that still install there
if [ ! -d "$INSTALL_DIR" ]; then
    LEGACY_INSTALL="$PROJECT_ROOT/packages/com.mainprogram/data/bin"
    if [ -d "$LEGACY_INSTALL" ]; then
        INSTALL_DIR="$LEGACY_INSTALL"
    fi
fi
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
# Read version from manifest.json
VERSION=$(grep -o '"version"[^"]*"[0-9.]*"' "$PROJECT_ROOT/manifest.json" | sed 's/.*"\([0-9.]*\)"/\1/')

echo "=== Folder Customizer Deployment Script ==="
echo "Version: $VERSION"
echo "Project root: $PROJECT_ROOT"
echo "Using install dir: $INSTALL_DIR"

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

# Prepare dist directory (clean unless KEEP_OLD_DIST=1)
prepare_dist() {
    mkdir -p "$PROJECT_ROOT/dist"
    if [ "${KEEP_OLD_DIST:-0}" != "1" ]; then
        log_info "Cleaning dist/ (set KEEP_OLD_DIST=1 to keep)"
        rm -f "$PROJECT_ROOT"/dist/folder-customizer-* "$PROJECT_ROOT"/dist/FolderCustomizer-* 2>/dev/null || true
    fi
}

# Find manifest.json from common locations and expose as MANIFEST_SRC
locate_manifest() {
    MANIFEST_SRC=""
    if [ -f "$INSTALL_DIR/manifest.json" ]; then
        MANIFEST_SRC="$INSTALL_DIR/manifest.json"
    elif [ -f "$PROJECT_ROOT/install/manifest.json" ]; then
        MANIFEST_SRC="$PROJECT_ROOT/install/manifest.json"
    elif [ -f "$PROJECT_ROOT/manifest.json" ]; then
        MANIFEST_SRC="$PROJECT_ROOT/manifest.json"
    fi
}

# Ensure manifest.json is present under INSTALL_DIR for uniform packaging
ensure_manifest_in_install() {
    locate_manifest
    if [ -n "$MANIFEST_SRC" ] && [ ! -f "$INSTALL_DIR/manifest.json" ]; then
        log_info "Including manifest.json from $(basename "$MANIFEST_SRC") into install/bin"
        cp "$MANIFEST_SRC" "$INSTALL_DIR/manifest.json" 2>/dev/null || true
    fi
}

# Check if build exists
check_build() {
    log_info "Checking for build artifacts in: $INSTALL_DIR"
    if [ ! -d "$INSTALL_DIR" ]; then
        log_error "Install directory '$INSTALL_DIR' does not exist. Please run the install_local target first."
        exit 1
    fi

    # Show what's in the install directory to help CI debugging
    echo "--- ls -la output ---"
    ls -la "$INSTALL_DIR" || true
    echo "--- find -maxdepth 1 -printf ---"
    find "$INSTALL_DIR" -maxdepth 1 -printf '%M %u %g %s %p\n' || true

    # Prefer exact expected names first
    if [ -f "$INSTALL_DIR/FolderCustomizer" ]; then
        BIN_NAME="FolderCustomizer"
        log_info "Found exact match: $BIN_NAME"
        return
    fi

    if [ -f "$INSTALL_DIR/Folder Customizer" ]; then
        BIN_NAME="Folder Customizer"
        log_info "Found exact match with space: $BIN_NAME"
        return
    fi

    # Fallback: look for any executable file in the install dir
    # Try explicit name patterns (exact, with space, with extension)
    shopt -s nullglob 2>/dev/null || true
    candidates=("$INSTALL_DIR/FolderCustomizer" "$INSTALL_DIR/Folder Customizer" "$INSTALL_DIR/FolderCustomizer.exe" "$INSTALL_DIR/Folder Customizer.exe")
    for c in "${candidates[@]}"; do
        if [ -f "$c" ]; then
            BIN_NAME="$(basename "$c")"
            log_info "Found candidate by name: $BIN_NAME"
            return
        fi
    done

    # Look for any file starting with FolderCustomizer or Folder
    for c in "$INSTALL_DIR"/FolderCustomizer* "$INSTALL_DIR"/Folder*; do
        if [ -e "$c" ] && [ -f "$c" ]; then
            BIN_NAME="$(basename "$c")"
            if [ -x "$c" ]; then
                log_info "Found executable candidate: $BIN_NAME"
            else
                log_warning "Found candidate without +x: $BIN_NAME (will use anyway)"
            fi
            return
        fi
    done

    # Fallback: any regular file
    for f in "$INSTALL_DIR"/*; do
        if [ -f "$f" ]; then
            BIN_NAME="$(basename "$f")"
            log_warning "Using first regular file fallback: $BIN_NAME"
            return
        fi
    done

    log_error "Build not found after searching $INSTALL_DIR. Please build the project first:"
    echo "  cmake -B build -DCMAKE_BUILD_TYPE=Release"
    echo "  cmake --build build"
    echo "  cmake --build build --target install_local"
    exit 1
}

# Create AppImage (Universal Linux)
create_appimage() {
    log_info "Creating AppImage..."
    ensure_manifest_in_install
    
        local appdir="$PROJECT_ROOT/dist/FolderCustomizer.AppDir"
    rm -rf "$appdir"
    mkdir -p "$appdir/usr/bin"
    mkdir -p "$appdir/usr/lib"
        mkdir -p "$appdir/usr/share/folder-customizer/icons"
    
    # Copy application
        cp "$INSTALL_DIR/$BIN_NAME" "$appdir/usr/bin/FolderCustomizer"
    # Include manifest.json (ensured in INSTALL_DIR by check_build)
    if [ -f "$INSTALL_DIR/manifest.json" ]; then
        cp "$INSTALL_DIR/manifest.json" "$appdir/usr/bin/manifest.json"
    fi
    # Copy updater if built
    if [ -f "$INSTALL_DIR/Updater" ]; then
        cp "$INSTALL_DIR/Updater" "$appdir/usr/bin/"
    fi
    
    # Copy libraries
    cp -r "$INSTALL_DIR"/*.so* "$appdir/usr/lib/" 2>/dev/null || true
    
        # Install helper and icons
            cat > "$appdir/usr/bin/fc-directory" << 'EOF'
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
    ICON_BASE_APP="$(dirname "$(readlink -f "$0")")/../share/folder-customizer/icons"
    if [ ! -f "$ICON_BASE_APP/$TONE/$COLOR.png" ]; then
        echo "Icon not found in AppImage: $TONE/$COLOR.png" >&2; exit 3
    fi
    # Persist a copy under user-local share so the .directory works after app exits
    DEST_BASE="$HOME/.local/share/folder-customizer/icons/$TONE"
    mkdir -p "$DEST_BASE"
    cp -f "$ICON_BASE_APP/$TONE/$COLOR.png" "$DEST_BASE/"
    ICON_PATH="$DEST_BASE/$COLOR.png"
mkdir -p "$FOLDER"
cat > "$FOLDER/.directory" <<EOD
[Desktop Entry]
Icon=$ICON_PATH
EOD
[ -n "$TAG" ] && echo "Comment=$TAG" >> "$FOLDER/.directory"

# Refresh mechanism: prefer gio, fall back to gvfs-set-attribute, then touch and force desktop icon update
if command -v gio >/dev/null 2>&1; then
    gio set "$FOLDER" metadata::custom-icon "file://$ICON_PATH" >/dev/null 2>&1 || true
elif command -v gvfs-set-attribute >/dev/null 2>&1; then
    gvfs-set-attribute -t string "$FOLDER" metadata::custom-icon "file://$ICON_PATH" >/dev/null 2>&1 || true
fi

# Touch folder to nudge file managers to re-evaluate .directory
touch "$FOLDER" || true

# Some environments support forcing icon refresh via xdg-desktop-icon
if command -v xdg-desktop-icon >/dev/null 2>&1; then
    xdg-desktop-icon forceupdate >/dev/null 2>&1 || true
fi

echo "Applied icon to $FOLDER"
EOF
        chmod +x "$appdir/usr/bin/fc-directory"
        for tone in Dark Light Normal; do
            if [ -d "$PROJECT_ROOT/Icons/$tone/PNG" ]; then
                mkdir -p "$appdir/usr/share/folder-customizer/icons/$tone"
                cp "$PROJECT_ROOT/Icons/$tone/PNG"/*.png "$appdir/usr/share/folder-customizer/icons/$tone/" 2>/dev/null || true
            fi
        done
    
    # Create desktop file (no leading spaces per spec)
        cat > "$appdir/FolderCustomizer.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Folder Customizer
Comment=Customize folder icons and tags
Exec=FolderCustomizer
Icon=folder-customizer
Categories=Utility;FileManager;
EOF
    
    # Copy icon (you'll need to have this)
        if [ -f "$PROJECT_ROOT/Icons/Folder Customizer.png" ]; then
                cp "$PROJECT_ROOT/Icons/Folder Customizer.png" "$appdir/folder-customizer.png"
    else
        log_warning "Icon not found, AppImage will have default icon"
        # Create a simple placeholder icon
                echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > "$appdir/folder-customizer.png" 2>/dev/null || true
    fi
    
    # Create AppRun script
    cat > "$appdir/AppRun" << 'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/FolderCustomizer" "$@"
EOF
    chmod +x "$appdir/AppRun"
    
    # Download appimagetool (as AppImage)
    if [ ! -f "$SCRIPTS_DIR/appimagetool" ]; then
        log_info "Downloading appimagetool..."
        mkdir -p "$SCRIPTS_DIR"
        wget -O "$SCRIPTS_DIR/appimagetool" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" || true
        chmod +x "$SCRIPTS_DIR/appimagetool" 2>/dev/null || true
    fi

    mkdir -p "$PROJECT_ROOT/dist"
    cd "$PROJECT_ROOT/dist"

    # Try to run appimagetool normally (requires FUSE)
    if "$SCRIPTS_DIR/appimagetool" "$appdir" "FolderCustomizer-${VERSION}-x86_64.AppImage" 2>appimage.err; then
        log_success "AppImage created: dist/FolderCustomizer-${VERSION}-x86_64.AppImage"
        return
    fi

    # If FUSE is missing, extract and run embedded appimagetool without FUSE
    if grep -qi "libfuse" appimage.err; then
        log_warning "FUSE not available, trying extracted appimagetool"
        (
            cd "$SCRIPTS_DIR" && \
            ./appimagetool --appimage-extract >/dev/null 2>&1 && \
            chmod +x "$SCRIPTS_DIR/squashfs-root/AppRun" && \
        "$SCRIPTS_DIR/squashfs-root/AppRun" "$appdir" "$PROJECT_ROOT/dist/FolderCustomizer-${VERSION}-x86_64.AppImage"
        ) && {
        log_success "AppImage created (no FUSE): dist/FolderCustomizer-${VERSION}-x86_64.AppImage"
            return
        }
    fi

    # Standardize fallback tarball name; skip if already present to avoid duplicates
    STD_TAR="folder-customizer-${VERSION}-x86_64.tar.gz"
    if [ -f "$STD_TAR" ]; then
        log_warning "Tarball $STD_TAR already exists; skipping AppImage fallback tar creation"
    else
        tar czf "$STD_TAR" -C "$(dirname "$appdir")" "$(basename "$appdir")"
        log_success "Archive created: dist/$STD_TAR"
    fi
}

# Create DEB package (Ubuntu/Debian)
create_deb() {
    log_info "Creating DEB package..."
    ensure_manifest_in_install
    
        local debdir="$PROJECT_ROOT/dist/deb"
    rm -rf "$debdir"
    mkdir -p "$debdir/DEBIAN"
    mkdir -p "$debdir/usr/bin"
        mkdir -p "$debdir/usr/lib/folder-customizer"
    mkdir -p "$debdir/usr/share/applications"
    mkdir -p "$debdir/usr/share/icons/hicolor/256x256/apps"
        mkdir -p "$debdir/usr/share/folder-customizer/icons"
    
    # Copy application and libraries
        cp "$INSTALL_DIR/$BIN_NAME" "$debdir/usr/lib/folder-customizer/FolderCustomizer"
    # Include manifest.json in the app lib directory if present
    if [ -f "$INSTALL_DIR/manifest.json" ]; then
        cp "$INSTALL_DIR/manifest.json" "$debdir/usr/lib/folder-customizer/"
    fi
    # Copy updater if built
    if [ -f "$INSTALL_DIR/Updater" ]; then
                cp "$INSTALL_DIR/Updater" "$debdir/usr/lib/folder-customizer/"
    fi
        cp -r "$INSTALL_DIR"/*.so* "$debdir/usr/lib/folder-customizer/" 2>/dev/null || true
    
        # Helper and PNG icons
        cat > "$debdir/usr/bin/fc-directory" << 'EOF'
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
ICON_BASE="/usr/share/folder-customizer/icons"
if [ -f "$ICON_BASE/$TONE/$COLOR.png" ]; then
    ICON_PATH="$ICON_BASE/$TONE/$COLOR.png"
else
    echo "Icon not found: $TONE/$COLOR.png" >&2; exit 3
fi
mkdir -p "$FOLDER"
cat > "$FOLDER/.directory" <<EOD
[Desktop Entry]
Icon=$ICON_PATH
EOD
[ -n "$TAG" ] && echo "Comment=$TAG" >> "$FOLDER/.directory"

# Refresh mechanism: prefer gio, fall back to gvfs-set-attribute, then touch and force desktop icon update
if command -v gio >/dev/null 2>&1; then
    gio set "$FOLDER" metadata::custom-icon "file://$ICON_PATH" >/dev/null 2>&1 || true
elif command -v gvfs-set-attribute >/dev/null 2>&1; then
    gvfs-set-attribute -t string "$FOLDER" metadata::custom-icon "file://$ICON_PATH" >/dev/null 2>&1 || true
fi

# Touch folder to nudge file managers to re-evaluate .directory
touch "$FOLDER" || true

# Some environments support forcing icon refresh via xdg-desktop-icon
if command -v xdg-desktop-icon >/dev/null 2>&1; then
    xdg-desktop-icon forceupdate >/dev/null 2>&1 || true
fi

echo "Applied icon to $FOLDER"
EOF
        chmod +x "$debdir/usr/bin/fc-directory"
        for tone in Dark Light Normal; do
            if [ -d "$PROJECT_ROOT/Icons/$tone/PNG" ]; then
                mkdir -p "$debdir/usr/share/folder-customizer/icons/$tone"
                cp "$PROJECT_ROOT/Icons/$tone/PNG"/*.png "$debdir/usr/share/folder-customizer/icons/$tone/" 2>/dev/null || true
            fi
        done
    
    # Create wrapper script
        cat > "$debdir/usr/bin/folder-customizer" << EOF
#!/bin/bash
export LD_LIBRARY_PATH="/usr/lib/folder-customizer:\$LD_LIBRARY_PATH"
exec "/usr/lib/folder-customizer/FolderCustomizer" "\$@"
EOF
        chmod +x "$debdir/usr/bin/folder-customizer"
    
    # Create desktop file
        cat > "$debdir/usr/share/applications/folder-customizer.desktop" << EOF
[Desktop Entry]
Name=Folder Customizer
Comment=Customize folder icons and tags
Exec=folder-customizer
Icon=folder-customizer
Type=Application
Categories=Utility;FileManager;
EOF
    
    # Copy icon if available
        if [ -f "$PROJECT_ROOT/Icons/Folder Customizer.png" ]; then
                cp "$PROJECT_ROOT/Icons/Folder Customizer.png" "$debdir/usr/share/icons/hicolor/256x256/apps/folder-customizer.png"
    fi
    
    # Create control file
        cat > "$debdir/DEBIAN/control" << EOF
Package: folder-customizer
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Deadbush225 <your-email@example.com>
Description: Folder Customizer - Customize folder icons and tags
 A Qt-based application that helps you customize folder icons and annotate folders.
Depends: libc6, libqt6core6, libqt6gui6, libqt6widgets6, libqt6network6
EOF
    
    # Build package
    if command -v dpkg-deb &> /dev/null; then
                dpkg-deb --build "$debdir" "$PROJECT_ROOT/dist/folder-customizer_${VERSION}_amd64.deb"
                log_success "DEB package created: dist/folder-customizer_${VERSION}_amd64.deb"
    else
        log_warning "dpkg-deb not found, creating tar.gz instead"
        cd "$PROJECT_ROOT/dist"
                tar czf "folder-customizer_${VERSION}_amd64.tar.gz" -C "$debdir" .
                log_success "Archive created: dist/folder-customizer_${VERSION}_amd64.tar.gz"
    fi
}

# Create RPM package (Fedora/RHEL)
create_rpm() {
    log_info "Creating RPM package..."
    ensure_manifest_in_install

    # Force tarball on non-RPM distros or when requested
    if [ "${FORCE_RPM_TARBALL:-}" = "1" ]; then
        log_warning "FORCE_RPM_TARBALL=1 set; creating portable tar.gz instead of RPM"
        cd "$PROJECT_ROOT/dist"
        STD_TAR="folder-customizer-${VERSION}-x86_64.tar.gz"
        if [ -f "$STD_TAR" ]; then
            log_warning "Tarball $STD_TAR already exists; skipping RPM fallback tar creation"
        else
            tar czf "$STD_TAR" -C "$INSTALL_DIR" .
            log_success "Archive created: dist/$STD_TAR"
        fi
        return
    fi

    # If rpmbuild not available OR distro is not Fedora/RHEL/SUSE, fallback
    if ! command -v rpmbuild &> /dev/null; then
        log_warning "rpmbuild not found, creating portable tar.gz instead"
    cd "$PROJECT_ROOT/dist"
    STD_TAR="folder-customizer-${VERSION}-x86_64.tar.gz"
    if [ -f "$STD_TAR" ]; then
        log_warning "Tarball $STD_TAR already exists; skipping RPM fallback tar creation"
    else
        tar czf "$STD_TAR" -C "$INSTALL_DIR" .
        log_success "Archive created: dist/$STD_TAR"
    fi
        return
    fi

    if [ -r /etc/os-release ]; then
        . /etc/os-release
        case "${ID_LIKE}${ID}" in
            *fedora*|*rhel*|*centos*|*suse*) : ;;
            *)
                log_warning "Non-RPM-based distro detected (${ID:-unknown}); creating portable tar.gz instead"
                                cd "$PROJECT_ROOT/dist"
                                STD_TAR="folder-customizer-${VERSION}-x86_64.tar.gz"
                                if [ -f "$STD_TAR" ]; then
                                    log_warning "Tarball $STD_TAR already exists; skipping RPM fallback tar creation"
                                else
                                    tar czf "$STD_TAR" -C "$INSTALL_DIR" .
                                    log_success "Archive created: dist/$STD_TAR"
                                fi
                return
                ;;
        esac
    fi
    
    local rpmdir="$PROJECT_ROOT/dist/rpm"
    rm -rf "$rpmdir"
    mkdir -p "$rpmdir"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
    
    # Create spec file
        cat > "$rpmdir/SPECS/folder-customizer.spec" << EOF
Name:           folder-customizer
Version:        $VERSION
Release:        1%{?dist}
Summary:        Customize folder icons and tags
License:        MIT
URL:            https://github.com/Deadbush225/folder-customizer
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  qt6-qtbase-devel
Requires:       qt6-qtbase qt6-qtbase-gui

%description
A Qt-based application that helps you customize folder icons and annotate folders.

%prep
%setup -q

%build
# Files are pre-built

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/lib/%{name}
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/folder-customizer/icons
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps

# Install files
cp -r * %{buildroot}/usr/lib/%{name}/

# Create wrapper script
cat > %{buildroot}/usr/bin/%{name} << 'EOFSCRIPT'
#!/bin/bash
export LD_LIBRARY_PATH="/usr/lib/folder-customizer:$LD_LIBRARY_PATH"
exec "/usr/lib/folder-customizer/FolderCustomizer" "$@"
EOFSCRIPT
chmod +x %{buildroot}/usr/bin/%{name}

# Helper
cat > %{buildroot}/usr/bin/fc-directory << 'EOFH'
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
ICON_BASE="/usr/share/folder-customizer/icons"
if [ -f "$ICON_BASE/$TONE/$COLOR.png" ]; then
    ICON_PATH="$ICON_BASE/$TONE/$COLOR.png"
else
    echo "Icon not found: $TONE/$COLOR.png" >&2; exit 3
fi
mkdir -p "$FOLDER"
cat > "$FOLDER/.directory" <<EOD
[Desktop Entry]
Icon=$ICON_PATH
EOD
[ -n "$TAG" ] && echo "Comment=$TAG" >> "$FOLDER/.directory"

# Refresh mechanism: prefer gio, fall back to gvfs-set-attribute, then touch and force desktop icon update
if command -v gio >/dev/null 2>&1; then
    gio set "$FOLDER" metadata::custom-icon "file://$ICON_PATH" >/dev/null 2>&1 || true
elif command -v gvfs-set-attribute >/dev/null 2>&1; then
    gvfs-set-attribute -t string "$FOLDER" metadata::custom-icon "file://$ICON_PATH" >/dev/null 2>&1 || true
fi

# Touch folder to nudge file managers to re-evaluate .directory
touch "$FOLDER" || true

# Some environments support forcing icon refresh via xdg-desktop-icon
if command -v xdg-desktop-icon >/dev/null 2>&1; then
    xdg-desktop-icon forceupdate >/dev/null 2>&1 || true
fi

echo "Applied icon to $FOLDER"
EOFH
chmod +x %{buildroot}/usr/bin/fc-directory

# Desktop and icons
cat > %{buildroot}/usr/share/applications/%{name}.desktop << 'EOFD'
[Desktop Entry]
Name=Folder Customizer
Comment=Customize folder icons and tags
Exec=folder-customizer
Icon=folder-customizer
Type=Application
Categories=Utility;FileManager;
EOFD
cp -r Icons/*/PNG %{buildroot}/usr/share/folder-customizer/icons/ 2>/dev/null || true
install -m 644 "Icons/Folder Customizer.png" "%{buildroot}/usr/share/icons/hicolor/256x256/apps/folder-customizer.png" 2>/dev/null || true

%files
/usr/bin/%{name}
/usr/bin/fc-directory
/usr/lib/%{name}/
%if 0%{?fedora} || 0%{?rhel} >= 8
/usr/share/applications/%{name}.desktop
/usr/share/folder-customizer/icons/
/usr/share/icons/hicolor/256x256/apps/folder-customizer.png
%endif

%changelog
* $(date +'%a %b %d %Y') Deadbush225 <your-email@example.com> - $VERSION-1
- Initial RPM package
EOF
    
    # Create source tarball
    cd "$INSTALL_DIR"
        tar czf "$rpmdir/SOURCES/folder-customizer-${VERSION}.tar.gz" *
    
    # Build RPM
        if ! rpmbuild --define "_topdir $rpmdir" -bb "$rpmdir/SPECS/folder-customizer.spec"; then
        log_warning "RPM build failed, creating portable tar.gz"
        cd "$PROJECT_ROOT/dist"
                STD_TAR="folder-customizer-${VERSION}-x86_64.tar.gz"
                if [ -f "$STD_TAR" ]; then
                    log_warning "Tarball $STD_TAR already exists; skipping RPM fallback tar creation"
                else
                    tar czf "$STD_TAR" -C "$INSTALL_DIR" .
                    log_success "Archive created: dist/$STD_TAR"
                fi
        return
    fi
    
    # Copy result
        cp "$rpmdir/RPMS/x86_64/folder-customizer-${VERSION}-1."*.rpm "$PROJECT_ROOT/dist/" 2>/dev/null || true
    log_success "RPM package created in dist/"
}

# Create Arch Linux package (for Manjaro)
create_arch() {
    log_info "Creating Arch Linux package..."
    ensure_manifest_in_install
    
    local archdir="$PROJECT_ROOT/dist/arch"
    rm -rf "$archdir"
    mkdir -p "$archdir"
    
    if ! command -v makepkg &> /dev/null; then
        log_warning "makepkg not found, creating portable tar.gz instead of Arch package"
                cd "$PROJECT_ROOT/dist"
                STD_TAR="folder-customizer-${VERSION}-x86_64.tar.gz"
                if [ -f "$STD_TAR" ]; then
                    log_warning "Tarball $STD_TAR already exists; skipping Arch fallback tar creation"
                else
                    tar czf "$STD_TAR" -C "$INSTALL_DIR" .
                    log_success "Archive created: dist/$STD_TAR"
                fi
        return
    fi
    
    # Create PKGBUILD
        cat > "$archdir/PKGBUILD" << EOF
# Maintainer: Deadbush225 <your-email@example.com>
pkgname=folder-customizer
pkgver=$VERSION
pkgrel=1
pkgdesc="Customize folder icons and tags"
arch=('x86_64')
url="https://github.com/Deadbush225/folder-customizer"
license=('MIT')
depends=('qt6-base')
source=()
md5sums=()

package() {
    # Install binary and libraries
        install -dm755 "$pkgdir/usr/lib/$pkgname"
    cp -r "$INSTALL_DIR"/* "$pkgdir/usr/lib/$pkgname/"
        if [ -f "$pkgdir/usr/lib/$pkgname/$BIN_NAME" ]; then
                mv "$pkgdir/usr/lib/$pkgname/$BIN_NAME" "$pkgdir/usr/lib/$pkgname/FolderCustomizer"
        fi
    
    # Create wrapper script
    install -dm755 "$pkgdir/usr/bin"
        cat > "$pkgdir/usr/bin/$pkgname" << 'EOFSCRIPT'
#!/bin/bash
export LD_LIBRARY_PATH="/usr/lib/folder-customizer:$LD_LIBRARY_PATH"
exec "/usr/lib/folder-customizer/FolderCustomizer" "$@"
EOFSCRIPT
    chmod +x "$pkgdir/usr/bin/$pkgname"
    
    # Desktop file
    install -dm755 "$pkgdir/usr/share/applications"
        cat > "$pkgdir/usr/share/applications/$pkgname.desktop" << 'EOFDESKTOP'
[Desktop Entry]
Name=Folder Customizer
Comment=Customize folder icons and tags
Exec=folder-customizer
Icon=folder-customizer
Type=Application
Categories=Utility;FileManager;
EOFDESKTOP

        # Helper and icons
        install -dm755 "$pkgdir/usr/share/folder-customizer/icons"
        for tone in Dark Light Normal; do
            if [ -d "$PROJECT_ROOT/Icons/$tone/PNG" ]; then
                install -dm755 "$pkgdir/usr/share/folder-customizer/icons/$tone"
                cp "$PROJECT_ROOT/Icons/$tone/PNG"/*.png "$pkgdir/usr/share/folder-customizer/icons/$tone/" 2>/dev/null || true
            fi
        done
        cat > "$pkgdir/usr/bin/fc-directory" << 'EOFH'
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
ICON_BASE="/usr/share/folder-customizer/icons"
if [ -f "$ICON_BASE/$TONE/$COLOR.png" ]; then
    ICON_PATH="$ICON_BASE/$TONE/$COLOR.png"
else
    echo "Icon not found: $TONE/$COLOR.png" >&2; exit 3
fi
mkdir -p "$FOLDER"
cat > "$FOLDER/.directory" <<EOD
[Desktop Entry]
Icon=$ICON_PATH
EOD
[ -n "$TAG" ] && echo "Comment=$TAG" >> "$FOLDER/.directory"

# Refresh mechanism: prefer gio, fall back to gvfs-set-attribute, then touch and force desktop icon update
if command -v gio >/dev/null 2>&1; then
    gio set "$FOLDER" metadata::custom-icon "file://$ICON_PATH" >/dev/null 2>&1 || true
elif command -v gvfs-set-attribute >/dev/null 2>&1; then
    gvfs-set-attribute -t string "$FOLDER" metadata::custom-icon "file://$ICON_PATH" >/dev/null 2>&1 || true
fi

# Touch folder to nudge file managers to re-evaluate .directory
touch "$FOLDER" || true

# Some environments support forcing icon refresh via xdg-desktop-icon
if command -v xdg-desktop-icon >/dev/null 2>&1; then
    xdg-desktop-icon forceupdate >/dev/null 2>&1 || true
fi

echo "Applied icon to $FOLDER"
EOFH
        chmod +x "$pkgdir/usr/bin/fc-directory"
    
        # Application icon
        install -dm755 "$pkgdir/usr/share/icons/hicolor/256x256/apps"
        if [ -f "$PROJECT_ROOT/Icons/Folder Customizer.png" ]; then
                cp "$PROJECT_ROOT/Icons/Folder Customizer.png" "$pkgdir/usr/share/icons/hicolor/256x256/apps/folder-customizer.png"
        fi
}
EOF
    
    cd "$archdir"
    makepkg -f || {
        log_warning "makepkg failed, creating portable tar.gz instead of Arch package"
        cd "$PROJECT_ROOT/dist"
        STD_TAR="folder-customizer-${VERSION}-x86_64.tar.gz"
        if [ -f "$STD_TAR" ]; then
            log_warning "Tarball $STD_TAR already exists; skipping Arch fallback tar creation"
        else
            tar czf "$STD_TAR" -C "$INSTALL_DIR" .
            log_success "Archive created: dist/$STD_TAR"
        fi
        return
    }
    
    # Copy result
    cp *.pkg.tar.* "$PROJECT_ROOT/dist/" 2>/dev/null || true
    
    log_success "Arch package created in dist/"
}

# Create all Linux packages
create_linux() {
    log_info "Creating all Linux packages..."
    prepare_dist
    
    create_appimage
    create_deb
    create_rpm
    create_arch
}

# Create Windows installer
create_windows() {
    log_info "Creating Windows installer..."
    
    if command -v powershell &> /dev/null; then
        cd "$PROJECT_ROOT"
        powershell -ExecutionPolicy Bypass -File "./scripts/update_installer.ps1"
        log_success "Windows installer created"
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
    log_success "All packages created in dist/ directory"
}

# Main script logic
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
