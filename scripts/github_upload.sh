#!/bin/bash
# GitHub CLI upload script
# This script replaces the GitHub Actions workflow for uploading releases
# Usage: ./github_upload.sh [version] [notes-file]
#
# Prerequisites:
# - GitHub CLI (gh) must be installed and authenticated
# - You must have a release/ directory with the built packages

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

# Get the project root (where this script is called from)
PROJECT_ROOT="$(pwd)"
RELEASE_DIR="$PROJECT_ROOT/release"
VERSION=${1:-}
NOTES_FILE=${2:-"$PROJECT_ROOT/release_notes.md"}

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is not installed. Please install it first."
    echo "  Visit https://cli.github.com/ for installation instructions."
    exit 1
fi

# Check if GitHub CLI is authenticated
if ! gh auth status &> /dev/null; then
    log_error "GitHub CLI is not authenticated. Please run 'gh auth login' first."
    exit 1
fi

# Validate VERSION
if [ -z "$VERSION" ]; then
    # Try to get version from manifest.json
    if [ -f "$PROJECT_ROOT/manifest.json" ]; then
        if command -v jq &> /dev/null; then
            VERSION=$(jq -r '.version' "$PROJECT_ROOT/manifest.json")
        else
            VERSION=$(grep -o '"version"[^"]*"[^"]*"' "$PROJECT_ROOT/manifest.json" | head -1 | sed 's/.*"\([^"]*\)"/\1/')
        fi
    fi

    if [ -z "$VERSION" ]; then
        log_error "Version not specified. Please provide a version number."
        echo "Usage: $0 [version] [notes-file]"
        exit 1
    fi
fi

# Validate release notes
if [ ! -f "$NOTES_FILE" ]; then
    log_warning "Release notes file not found: $NOTES_FILE"
    log_info "Creating a simple release notes file..."
    
    echo "# Release v$VERSION" > "$PROJECT_ROOT/release_notes.md"
    echo "" >> "$PROJECT_ROOT/release_notes.md"
    echo "## Changes" >> "$PROJECT_ROOT/release_notes.md"
    echo "" >> "$PROJECT_ROOT/release_notes.md"
    echo "- New features and improvements" >> "$PROJECT_ROOT/release_notes.md"
    echo "- Bug fixes" >> "$PROJECT_ROOT/release_notes.md"
    
    NOTES_FILE="$PROJECT_ROOT/release_notes.md"
    log_info "Created release notes at: $NOTES_FILE"
    log_info "Please edit this file before continuing."
    
    read -p "Press Enter to continue after editing the release notes, or Ctrl+C to cancel..." </dev/tty
fi

# Check if release directory exists and has files
if [ ! -d "$RELEASE_DIR" ]; then
    log_error "Release directory not found: $RELEASE_DIR"
    log_info "Please build the project first using the build script."
    exit 1
fi

# Count files in release directory
FILE_COUNT=$(find "$RELEASE_DIR" -type f -not -path "*/\.*" | wc -l)
if [ "$FILE_COUNT" -lt 1 ]; then
    log_error "No files found in release directory: $RELEASE_DIR"
    log_info "Please build the project first using the build script."
    exit 1
fi

# Create a new GitHub release
log_info "Creating GitHub release v$VERSION..."
gh release create "v$VERSION" --title "v$VERSION" --notes-file "$NOTES_FILE"

# Upload all files from release directory
log_info "Uploading release assets..."
find "$RELEASE_DIR" -type f -not -path "*/\.*" | while read -r file; do
    filename=$(basename "$file")
    log_info "Uploading: $filename"
    gh release upload "v$VERSION" "$file" --clobber
done

log_success "Release v$VERSION created and assets uploaded successfully!"
