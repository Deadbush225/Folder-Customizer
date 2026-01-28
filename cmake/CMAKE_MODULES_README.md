# CMake Module Organization

This directory contains modularized CMake configuration files for FolderCustomizer. The main `CMakeLists.txt` has been refactored to include these separate modules for better maintainability and organization.

## Directory Structure

```
cmake/
├── config/                          # Dependency detection and configuration
│   ├── BoostConfig.cmake           # Boost detection and setup
│   └── QtConfig.cmake              # Qt6 detection and setup
├── utilities/                       # Reusable helper functions
│   ├── BoostUtilities.cmake        # Boost integration functions
│   ├── InstallConfiguration.cmake  # Installation paths and icon setup
│   └── PostBuildOptimization.cmake # Binary optimization and install_local target
├── integration/                     # External project integration
│   └── eUpdaterIntegration.cmake   # eUpdater integration and configuration
├── deployment/                      # Deployment and installation scripts
│   ├── EnhancedQtDeploy.cmake      # Advanced Qt deployment with diagnostics
│   └── PruneInstall.cmake          # Installation cleanup script
└── BoostDeploy.cmake               # UNUSED - kept for reference only
```

## Module Descriptions

### Configuration Modules (`config/`)
These modules handle dependency detection and configuration:

- **BoostConfig.cmake**: Detects and configures Boost libraries
  - Handles Windows custom Boost builds, MSVC, MinGW, and Linux system Boost
  - Exports: `BOOST_AVAILABLE`, `Boost_INCLUDE_DIRS`, `Boost_LIBRARIES`

- **QtConfig.cmake**: Detects and configures Qt6
  - Sets up Qt standard project configuration
  - Exports: `Qt6_FOUND`, `Qt6Core_VERSION`

### Utility Modules (`utilities/`)
These modules provide reusable functionality:

- **BoostUtilities.cmake**: Helper functions for Boost integration
  - `u_include_header_only_boost(TARGET)`: Include Boost headers
  - `u_include_and_link_compiled_boost(TARGET, COMPONENT)`: Link compiled Boost libraries
  - `u_link_boost_program_options(TARGET)`: Convenience wrapper for program_options

- **InstallConfiguration.cmake**: Installation paths and icon setup
  - Defines standard install directories (bin, lib, icons)
  - Handles icon installation for all platforms
  - Manages manifest.json and install script deployment
  - **Incremental Install Support**: 
      - Uses `COMPONENT Prerequisites` for static assets (icons, etc.) to allow skipping them during development builds.
      - Uses `install(DIRECTORY ...)` for cleaner log output.

- **PostBuildOptimization.cmake**: Binary optimization and installation
  - **`install_local` Target**:
      - Defines the "Smart Install" logic.
      - **Application Component**: Always installed (exe, manifest).
      - **Prerequisites Component**: Only installed if `Q6Core.dll` is missing from the destination.
  - *Note*: Binary stripping and UPX are disabled for `install_local` to preserve build artifacts for debugging and incremental checks.

### Deployment Modules (`deployment/`)

- **EnhancedQtDeploy.cmake**:
  - Automatically runs `windeployqt` to copy Qt DLLs.
  - **Optimization**: Checks for existing `Qt6Core.dll` in destination. If found, strictly skips `windeployqt` execution to speed up iteration.
  - Deployment logic happens under the `Prerequisites` component.

- **MinGWDeploy.cmake**: 
  - Copies MinGW runtime DLLs (libgcc, libstdc++, etc.).
  - Tagged as `COMPONENT Prerequisites`.

- **PruneInstall.cmake**:
  - Cleans up unnecessary files from the installation directory (duplicates, temp files).

## Installation Components

The project uses CMake components to separate frequently changed files from static dependencies:

| Component | Contents | Install Behavior |
| :--- | :--- | :--- |
| **`Application`** | `.exe` files, `manifest.json` | **Always Installed** |
| **`Prerequisites`** | Qt DLLs, MinGW DLLs, Icons, Context Menu DLL | **Conditional** (Skipped if `Qt6Core.dll` exists) |

This structure ensures that hitting "Build" is nearly instantaneous when only modifying source code.
  - `setup_install_local_target(PROJECT_NAME)`: Creates install_local target
  - `add_context_menu_dependency(TARGET_NAME)`: Adds context menu handler dependency
  - Handles binary stripping and UPX compression for Unix/MinGW

### Integration Modules (`integration/`)
- **eUpdaterIntegration.cmake**: eUpdater integration and configuration

### Deployment Modules (`deployment/`)
- **EnhancedQtDeploy.cmake**: Advanced Qt deployment with diagnostics
- **PruneInstall.cmake**: Installation cleanup script

## Unused Files

- **BoostDeploy.cmake**: No longer used; Boost DLLs are now deployed through standard deployment mechanisms
  - Kept in root cmake/ for reference only
  - Safe to delete if needed

## Usage in Main CMakeLists.txt

The main `CMakeLists.txt` has been simplified to:
1. Set up basic project configuration
2. Include all cmake modules
3. Define targets and link libraries
4. Setup installation and deployment

All detailed configuration logic is now encapsulated in the respective modules.

## Modification Guidelines

When updating build configuration:
- **Boost-related changes** → Update `config/BoostConfig.cmake` or `utilities/BoostUtilities.cmake`
- **Qt-related changes** → Update `config/QtConfig.cmake`
- **Installation changes** → Update `utilities/InstallConfiguration.cmake`
- **Post-build optimizations** → Update `utilities/PostBuildOptimization.cmake`
- **Deployment changes** → Update `deployment/` modules
- **Main build logic** → Update `CMakeLists.txt` (which should remain concise)
