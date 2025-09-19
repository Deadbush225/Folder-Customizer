#!/bin/bash
# Generic Manifest Template Generator
# Generates a manifest.json template for the project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST_FILE="$PROJECT_ROOT/manifest.json"

log_info "Generic Manifest Template Generator"
echo "===================================="

# Check if manifest.json already exists
if [ -f "$MANIFEST_FILE" ]; then
    log_warning "manifest.json already exists at $MANIFEST_FILE"
    read -p "Do you want to overwrite it? [y/N]: " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled"
        exit 0
    fi
fi

# Interactive prompts with defaults
read -p "Application Name: " APP_NAME
read -p "Application Version [1.0.0]: " APP_VERSION
APP_VERSION=${APP_VERSION:-1.0.0}

read -p "Description: " APP_DESCRIPTION
read -p "Author/Maintainer: " APP_AUTHOR
read -p "License [MIT]: " APP_LICENSE
APP_LICENSE=${APP_LICENSE:-MIT}

read -p "Homepage URL: " APP_URL
read -p "Desktop Name (display name) [$APP_NAME]: " DESKTOP_NAME
DESKTOP_NAME=${DESKTOP_NAME:-$APP_NAME}

read -p "Generic Name (subtitle): " GENERIC_NAME
read -p "Categories [Utility;]: " CATEGORIES
CATEGORIES=${CATEGORIES:-Utility;}

read -p "Keywords (semicolon separated): " KEYWORDS
read -p "Main executable name: " EXECUTABLE_NAME
read -p "Package ID (lowercase-with-dashes): " PACKAGE_ID

# Generate package ID if not provided
if [ -z "$PACKAGE_ID" ]; then
    PACKAGE_ID=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    log_info "Generated package ID: $PACKAGE_ID"
fi

read -p "Supports file opening [false]: " SUPPORTS_FILES
SUPPORTS_FILES=${SUPPORTS_FILES:-false}

read -p "Has CLI helper [false]: " CLI_HELPER
CLI_HELPER=${CLI_HELPER:-false}

read -p "MIME types (if supports files): " MIME_TYPES

# Generate manifest.json
log_info "Generating manifest.json..."

cat > "$MANIFEST_FILE" << EOF
{
  "name": "$APP_NAME",
  "version": "$APP_VERSION",
  "description": "$APP_DESCRIPTION",
  "author": "$APP_AUTHOR",
  "license": "$APP_LICENSE",
  "homepage": "$APP_URL",
  "desktop": {
    "desktop_name": "$DESKTOP_NAME",
    "generic_name": "$GENERIC_NAME",
    "comment": "$APP_DESCRIPTION",
    "categories": "$CATEGORIES",
    "keywords": "$KEYWORDS",
    "executable": "$EXECUTABLE_NAME",
    "package_id": "$PACKAGE_ID",
    "supports_files": $SUPPORTS_FILES,
    "cli_helper": $CLI_HELPER,
    "mime_types": "$MIME_TYPES",
    "icon_path": "icons/$APP_NAME.png"
  },
  "build": {
    "cmake_minimum": "3.16",
    "qt_version": "6.0",
    "boost_required": true
  },
  "deployment": {
    "linux": {
      "categories": "$CATEGORIES",
      "dependencies_deb": "libc6, libstdc++6, libgcc-s1",
      "dependencies_rpm": "glibc, libstdc++, libgcc"
    },
    "windows": {
      "installer_name": "${PACKAGE_ID}-setup.exe",
      "company": "$APP_AUTHOR"
    }
  }
}
EOF

log_success "Generated manifest.json at $MANIFEST_FILE"
log_info "You can now edit this file to customize the configuration further"

# Show the generated content
log_info "Generated manifest content:"
echo "=================================="
cat "$MANIFEST_FILE"
echo "=================================="
