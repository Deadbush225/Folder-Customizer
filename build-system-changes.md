# Build System Changes Summary

## Overview
This document summarizes the changes made to the build and deployment structure for the following projects:
- folder-customizer
- download-sorter
- printing-rates

## Changes Implemented

### 1. Output Directory Changes
- Changed the output directory from `dist/` to `release/` for all Linux packages
  - Updated deployment scripts to use the new directory

### 2. Build Directory Structure
- Created a new organized build directory structure:
  - `build/build-linux`: For Linux builds
  - `build/build-windows`: For Windows builds
- Updated build scripts to use the appropriate build directory based on the platform

### 3. Build Scripts
- Created/updated platform-specific build scripts:
  - `build-linux.sh`: For Linux builds using CMake in `build/build-linux` directory
  - `build-windows.ps1`: For Windows builds using CMake in `build/build-windows` directory
- Updated the main `build.sh` script to detect the platform and use the appropriate build directory

### 4. GitHub Release Management
- Removed GitHub workflows (`.github/workflows/build-release.yml`)
- Added `github_upload.sh` script in the `scripts/` directory of each project
  - Uses GitHub CLI (`gh`) to create releases and upload assets
  - Automatically detects version from manifest.json
  - Supports custom release notes

## Usage Instructions

### Building Projects
1. Use the main build script which automatically detects the platform:
   ```bash
   ./build.sh
   ```

2. For platform-specific builds:
   - Linux: `./build-linux.sh`
   - Windows: `./build-windows.ps1`

### Creating Releases
1. Build the project using the build scripts
2. Upload to GitHub using the new script:
   ```bash
   ./scripts/github_upload.sh [version] [notes-file]
   ```
   - If version is omitted, it will be extracted from manifest.json
   - If notes-file is omitted, it will use release_notes.md

## Prerequisites for GitHub CLI Upload
- GitHub CLI (`gh`) must be installed:
  ```bash
  # Ubuntu/Debian
  sudo apt install gh
  
  # Fedora
  sudo dnf install gh
  
  # Windows (using winget)
  winget install GitHub.cli
  ```
- GitHub CLI must be authenticated:
  ```bash
  gh auth login
  ```

## Files Modified/Created
- build/build-linux/ (directory created)
- build/build-windows/ (directory created)
- build-linux.sh (created)
- build-windows.ps1 (created)
- build.sh (updated)
- scripts/eDeployLinux.sh (updated to use "release" directory)
- scripts/github_upload.sh (created)

## Removed Files
- .github/workflows/build-release.yml
