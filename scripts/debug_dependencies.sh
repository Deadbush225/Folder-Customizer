#!/bin/bash
# Debug script to check dependencies of the built executable

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="$PROJECT_ROOT/install"

echo "=== Folder Customizer Dependency Debug ==="
echo "Project root: $PROJECT_ROOT"
echo "Install directory: $INSTALL_DIR"

# Find the main executable
BIN_NAME=""
if [ -f "$INSTALL_DIR/FolderCustomizer" ]; then
    BIN_NAME="FolderCustomizer"
elif [ -f "$INSTALL_DIR/Folder Customizer" ]; then
    BIN_NAME="Folder Customizer"
else
    echo "ERROR: Main executable not found in $INSTALL_DIR"
    ls -la "$INSTALL_DIR" || true
    exit 1
fi

echo "Found executable: $BIN_NAME"
echo ""

# Check file info
echo "=== File Information ==="
file "$INSTALL_DIR/$BIN_NAME"
echo ""

# Check linked libraries
echo "=== Linked Libraries (ldd) ==="
if command -v ldd >/dev/null 2>&1; then
    ldd "$INSTALL_DIR/$BIN_NAME" 2>/dev/null || echo "ldd failed"
else
    echo "ldd not available"
fi
echo ""

# Check specifically for Boost libraries
echo "=== Boost Dependencies ==="
if command -v ldd >/dev/null 2>&1; then
    boost_deps=$(ldd "$INSTALL_DIR/$BIN_NAME" 2>/dev/null | grep -i boost || echo "No Boost dependencies found")
    echo "$boost_deps"
else
    echo "Cannot check Boost dependencies (ldd not available)"
fi
echo ""

# Check eUpdater
echo "=== eUpdater Information ==="
if [ -f "$INSTALL_DIR/eUpdater" ]; then
    echo "eUpdater found at: $INSTALL_DIR/eUpdater"
    file "$INSTALL_DIR/eUpdater"
    if command -v ldd >/dev/null 2>&1; then
        echo "eUpdater dependencies:"
        ldd "$INSTALL_DIR/eUpdater" 2>/dev/null || echo "ldd failed for eUpdater"
    fi
else
    echo "eUpdater not found in install directory"
fi
echo ""

# Check what's in the install directory
echo "=== Install Directory Contents ==="
ls -la "$INSTALL_DIR" || true
echo ""

# Check for library files
echo "=== Library Files ==="
find "$INSTALL_DIR" -name "*.so*" -type f 2>/dev/null || echo "No .so files found"
echo ""

echo "=== System Boost Libraries ==="
find /usr/lib /usr/local/lib -name "*boost_program_options*" 2>/dev/null | head -10 || echo "No system Boost libraries found"

echo ""
echo "Debug complete."
