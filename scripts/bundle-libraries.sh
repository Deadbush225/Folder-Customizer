#!/bin/bash
# Advanced Library Bundler - Bundles ALL dependencies for portable deployment
# Usage: ./bundle-libraries.sh <install_dir> [--qt-only|--all]

set -e

INSTALL_DIR="$1"
BUNDLE_MODE="${2:---all}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[BUNDLE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[BUNDLE]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[BUNDLE]${NC} $1"
}

log_error() {
    echo -e "${RED}[BUNDLE]${NC} $1"
}

if [ -z "$INSTALL_DIR" ] || [ ! -d "$INSTALL_DIR" ]; then
    log_error "Usage: $0 <install_dir> [--qt-only|--all]"
    log_error "Install directory must exist and contain executables"
    exit 1
fi

LIB_DIR="$INSTALL_DIR/lib"
BIN_DIR="$INSTALL_DIR/bin"

# Ensure lib directory exists
mkdir -p "$LIB_DIR"

log_info "Starting dependency bundling ($BUNDLE_MODE mode)"
log_info "Target directory: $INSTALL_DIR"

# Find all executables in the install directory
EXECUTABLES=()
while IFS= read -r -d '' exe; do
    if [ -x "$exe" ] && file "$exe" | grep -q "ELF.*executable"; then
        EXECUTABLES+=("$exe")
        log_info "Found executable: $(basename "$exe")"
    fi
done < <(find "$BIN_DIR" -type f -executable -print0 2>/dev/null)

if [ ${#EXECUTABLES[@]} -eq 0 ]; then
    log_error "No executables found in $BIN_DIR"
    exit 1
fi

# List of library directories to search (in order of preference)
LIB_SEARCH_PATHS=(
    "/usr/lib"
    "/usr/lib64" 
    "/usr/lib/x86_64-linux-gnu"
    "/usr/local/lib"
    "/usr/local/lib64"
    "/lib"
    "/lib64"
    "/lib/x86_64-linux-gnu"
)

# System libraries that should NOT be bundled (always available on Linux systems)
SYSTEM_LIBS_REGEX="^(linux-vdso\.so|ld-linux.*\.so|libc\.so|libm\.so|libdl\.so|libpthread\.so|librt\.so|libresolv\.so|libnsl\.so|libutil\.so|libcrypt\.so|libgcc_s\.so)"

# Libraries that are safe to bundle based on mode
declare -A LIB_BUNDLE_RULES
LIB_BUNDLE_RULES["qt-only"]="libQt[0-9]|libqt[0-9]"
LIB_BUNDLE_RULES["all"]=".*"  # Bundle everything except system libs

# Function to copy a library and its dependencies recursively
copy_library_recursive() {
    lib_path="$1"
    max_depth="${2:-10}"
    
    if [ $max_depth -le 0 ]; then
        log_warning "Max recursion depth reached for $lib_path"
        return
    fi
    
    if [ ! -f "$lib_path" ]; then
        return
    fi
    
    lib_name="$(basename "$lib_path")"
    target_path="$LIB_DIR/$lib_name"
    
    # Skip if already copied
    if [ -f "$target_path" ]; then
        return
    fi
    
    # Skip system libraries
    if [[ "$lib_name" =~ $SYSTEM_LIBS_REGEX ]]; then
        return
    fi
    
    # Check if this library should be bundled based on mode
    should_bundle=false
    case "$BUNDLE_MODE" in
        "--qt-only")
            if [[ "$lib_name" =~ ${LIB_BUNDLE_RULES["qt-only"]} ]]; then
                should_bundle=true
            fi
            ;;
        "--all")
            # Bundle everything except system libs (already filtered above)
            should_bundle=true
            ;;
    esac
    
    if [ "$should_bundle" = "false" ]; then
        return
    fi
    
    # Copy the library
    log_info "Bundling: $lib_name"
    cp "$lib_path" "$target_path"
    chmod 755 "$target_path"
    
    # Strip debug symbols to reduce size
    if command -v strip >/dev/null 2>&1; then
        strip --strip-unneeded "$target_path" 2>/dev/null || true
    fi
    
    # Recursively copy dependencies
    deps=$(ldd "$lib_path" 2>/dev/null | grep -E "=> /.+" | awk '{print $3}' || true)
    
    for dep in $deps; do
        if [ -n "$dep" ] && [ -f "$dep" ]; then
            copy_library_recursive "$dep" $((max_depth - 1))
        fi
    done
}

# Function to find library in search paths
find_library() {
    local lib_name="$1"
    
    for search_path in "${LIB_SEARCH_PATHS[@]}"; do
        if [ -f "$search_path/$lib_name" ]; then
            echo "$search_path/$lib_name"
            return 0
        fi
    done
    
    return 1
}

# Process each executable
TOTAL_LIBS_COPIED=0
for exe in "${EXECUTABLES[@]}"; do
    log_info "Processing dependencies for: $(basename "$exe")"
    
    # Get all dependencies
    deps=$(ldd "$exe" 2>/dev/null | grep -E "=> /.+" | awk '{print $3}' || true)
    
    for dep in $deps; do
        if [ -n "$dep" ] && [ -f "$dep" ]; then
            lib_name="$(basename "$dep")"
            
            # Skip if already processed
            if [ ! -f "$LIB_DIR/$lib_name" ]; then
                copy_library_recursive "$dep"
                ((TOTAL_LIBS_COPIED++)) || true
            fi
        fi
    done
done

# Bundle Qt plugins if Qt libraries were bundled
if [ "$BUNDLE_MODE" != "--qt-only" ] || ls "$LIB_DIR"/libQt*.so* >/dev/null 2>&1; then
    log_info "Bundling Qt plugins..."
    
    QT_PLUGIN_DIRS=(
        "/usr/lib/qt6/plugins"
        "/usr/lib/x86_64-linux-gnu/qt6/plugins" 
        "/usr/local/lib/qt6/plugins"
    )
    
    for qt_plugin_dir in "${QT_PLUGIN_DIRS[@]}"; do
        if [ -d "$qt_plugin_dir" ]; then
            log_info "Found Qt plugins in: $qt_plugin_dir"
            
            # Copy essential plugins
            ESSENTIAL_PLUGINS=("platforms" "imageformats" "iconengines" "platformthemes")
            
            for plugin_type in "${ESSENTIAL_PLUGINS[@]}"; do
                if [ -d "$qt_plugin_dir/$plugin_type" ]; then
                    mkdir -p "$LIB_DIR/qt6/plugins/$plugin_type"
                    cp -r "$qt_plugin_dir/$plugin_type"/* "$LIB_DIR/qt6/plugins/$plugin_type/" 2>/dev/null || true
                    log_info "Bundled Qt $plugin_type plugins"
                fi
            done
            break
        fi
    done
fi

# Create a library dependency report
REPORT_FILE="./bundled-libs-report.txt"
{
    echo "=== Library Bundling Report ==="
    echo "Date: $(date)"
    echo "Mode: $BUNDLE_MODE"
    echo "Target: $INSTALL_DIR"
    echo ""
    echo "=== Bundled Libraries ==="
    find "$LIB_DIR" -name "*.so*" -type f | sort
    echo ""
    echo "=== Bundled Qt Plugins ==="
    find "$LIB_DIR" -path "*/qt6/plugins/*" -type f | sort
} > "$REPORT_FILE"

log_success "Library bundling completed!"
log_info "Total libraries copied: $TOTAL_LIBS_COPIED"
log_info "Library directory size: $(du -sh "$LIB_DIR" | cut -f1)"
log_info "Report saved to: $REPORT_FILE"

# Basic verification - just check that executables exist
VERIFICATION_TOTAL=${#EXECUTABLES[@]}
log_success "Basic verification: $VERIFICATION_TOTAL executable(s) found and processed"
log_info "Runtime library resolution will be handled by LD_LIBRARY_PATH at execution time"
