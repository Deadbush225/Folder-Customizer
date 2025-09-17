#!/bin/bash
# Helper script to set up the correct CMake build directory

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

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Detect platform
PLATFORM="linux"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
    PLATFORM="windows"
fi

# Determine build directory
if [[ "$PLATFORM" == "windows" ]]; then
    BUILD_DIR="$PROJECT_ROOT/build/build-windows"
    log_info "Detected Windows platform, using build directory: $BUILD_DIR"
else
    BUILD_DIR="$PROJECT_ROOT/build/build-linux"
    log_info "Detected Linux platform, using build directory: $BUILD_DIR"
fi

# Ensure build directory exists
mkdir -p "$BUILD_DIR"

# Parse command line arguments
BUILD_TYPE="Release"
CLEAN=0
INSTALL=0
PACKAGE=0
JOBS=$(nproc 2>/dev/null || echo 2)

while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --clean)
            CLEAN=1
            shift
            ;;
        --install)
            INSTALL=1
            shift
            ;;
        --package)
            PACKAGE=1
            shift
            ;;
        -j|--jobs)
            if [[ $2 =~ ^[0-9]+$ ]]; then
                JOBS=$2
                shift 2
            else
                log_error "Error: --jobs requires a number"
                exit 1
            fi
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Usage: $0 [--debug] [--clean] [--install] [--package] [-j|--jobs <number>]"
            exit 1
            ;;
    esac
done

# Clean if requested
if [ "$CLEAN" -eq 1 ]; then
    log_info "Cleaning build directory..."
    rm -rf "$BUILD_DIR"/*
fi

# Configure
log_info "Configuring with CMake (BUILD_TYPE=$BUILD_TYPE)..."
cd "$PROJECT_ROOT"
cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DCMAKE_INSTALL_PREFIX="$PROJECT_ROOT/install"

# Build
log_info "Building with $JOBS jobs..."
cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" --parallel "$JOBS"

# Install locally if requested
if [ "$INSTALL" -eq 1 ]; then
    log_info "Installing to $PROJECT_ROOT/install..."
    cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" --target install
fi

# Create packages if requested
if [ "$PACKAGE" -eq 1 ]; then
    log_info "Creating packages..."
    cd "$PROJECT_ROOT"
    if [[ "$PLATFORM" == "windows" ]]; then
        powershell -ExecutionPolicy Bypass -File "./scripts/update_installer.ps1"
    else
        ./scripts/eDeployLinux.sh all
    fi
fi

log_success "Build completed successfully!"
