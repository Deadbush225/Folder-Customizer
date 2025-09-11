# Generalized Deployment Scripts

This document describes the generalized deployment system that replaces the project-specific deploy.sh scripts with a reusable solution.

## Overview

Both `folder-customizer` and `download-sorter` projects now use a unified deployment system consisting of:

1. **Generic deployment script**: `scripts/generic-deploy.sh`
2. **Project configuration**: `deploy.conf`
3. **Simplified wrapper**: `scripts/deploy.sh`

## Structure

### Generic Script (`scripts/generic-deploy.sh`)

- Contains all common deployment logic
- Supports AppImage, DEB, RPM, and Arch Linux package creation
- Handles icon detection, library copying, and manifest inclusion
- Supports app-specific customizations via callback functions

### Configuration File (`deploy.conf`)

- Located in project root
- Defines app-specific metadata:
  - `APP_NAME`: Display name (e.g., "Folder Customizer")
  - `APP_BINARY`: Executable name (e.g., "FolderCustomizer")
  - `APP_PACKAGE`: Package name (e.g., "folder-customizer")
  - `APP_DESCRIPTION`: Short description
  - `APP_CATEGORIES`: Desktop categories
  - `APP_MAINTAINER`: Maintainer information
  - `APP_URL`: Project URL
  - `APP_LICENSE`: License type
  - `APP_DEPS_DEB`: Debian package dependencies
  - `APP_DEPS_RPM`: RPM package dependencies

### Wrapper Script (`scripts/deploy.sh`)

- Simple script that sources the generic script and calls main()
- Maintains backward compatibility with existing usage

## App-Specific Customizations

The system supports app-specific customizations through callback functions defined in `deploy.conf`:

### Folder Customizer Example

```bash
# Define custom functions for folder-customizer specific features
folder_customizer_deb_extras() {
    local debdir="$1"
    # Create fc-directory helper script
    # Install folder icons for different themes
}

folder_customizer_appimage_extras() {
    local appdir="$1"
    # Create fc-directory helper for AppImage
    # Install folder icons in AppImage structure
}
```

These functions are automatically called during package creation if they exist.

## Usage

Same as before:

```bash
./scripts/deploy.sh [all|windows|linux|appimage|deb|rpm|arch]
```

## Benefits

1. **Code Reuse**: ~90% reduction in duplicated deployment code
2. **Consistency**: Identical packaging logic across projects
3. **Maintainability**: Single source of truth for deployment logic
4. **Flexibility**: App-specific customizations still supported
5. **Standardization**: Consistent package structure and naming

## Files Changed

### Folder Customizer

- `scripts/deploy.sh`: Simplified to 15 lines (was ~800 lines)
- `scripts/generic-deploy.sh`: New generic deployment script
- `deploy.conf`: New configuration file with app-specific settings

### Download Sorter

- `scripts/deploy.sh`: Simplified to 15 lines (was ~400 lines)
- `scripts/generic-deploy.sh`: Copy of generic deployment script
- `deploy.conf`: New configuration file with app-specific settings

## Validation

Both projects successfully create packages using the new system:

- ✅ DEB packages: Creates proper Debian packages with dependencies
- ✅ AppImage: Creates universal Linux AppImages with app-specific helpers
- ✅ Icon handling: Automatically detects and includes icons from multiple locations
- ✅ Custom features: Folder Customizer's fc-directory helper properly included

## Future Extensions

The system can be easily extended to support:

- Additional package formats
- More app-specific customizations
- Cross-project shared components
- Automated CI/CD integration
