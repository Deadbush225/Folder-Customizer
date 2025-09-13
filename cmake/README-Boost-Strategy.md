# Selective Boost Deployment Strategy

## Overview

Instead of deploying all Boost libraries and then removing unwanted ones, we now use a **targeted deployment approach** that only installs the specific Boost components each project needs.

## How It Works

### 1. Targeted Deployment (Primary Method)

- **File**: `cmake/BoostDeploy.cmake`
- **Function**: `deploy_boost_dlls(component1 component2 ...)`
- **When**: During CMake install phase
- **Approach**: Proactively find and install only needed Boost DLLs

### 2. Fallback Pruning (Backup Method)

- **File**: `cmake/PruneInstall.cmake`
- **Function**: `install_needed_boost_libs(needed_libs)`
- **When**: After Qt deployment (as cleanup)
- **Approach**: Reactively remove unwanted Boost DLLs if they were deployed

## Per-Project Configuration

### Folder Customizer

- **Needed components**: `program_options`
- **Deployment**: `deploy_boost_program_options()`
- **Fallback pruning**: Keeps only `*boost*program_options*` DLLs

### Printing Rates

- **Needed components**: `log`, `log_setup`
- **Deployment**: `deploy_boost_log()`
- **Fallback pruning**: Keeps only `*boost*log*` DLLs

### Download Sorter

- **Needed components**: None (no Boost usage)
- **Deployment**: No Boost deployment
- **Fallback pruning**: Removes all Boost DLLs

## Advantages of This Approach

### ✅ **More Efficient**

- Only finds and deploys needed DLLs instead of deploying everything then removing most
- Faster build and install process
- Smaller installer packages

### ✅ **More Reliable**

- Less prone to missing dependencies
- Clear intent - explicitly specify what's needed
- Better error messages when components are missing

### ✅ **More Maintainable**

- Easy to add new Boost components: just update the deployment call
- Self-documenting - you can see exactly what each project uses
- Centralized logic in `BoostDeploy.cmake`

### ✅ **Backwards Compatible**

- Fallback pruning still works if selective deployment fails
- Handles both static and dynamic linking automatically
- Works with different Boost installation methods (vcpkg, Chocolatey, manual)

## Implementation Details

### Search Strategy

The deployment script searches for Boost DLLs in this order:

1. `Boost_LIBRARY_DIRS` (from find_package)
2. `BOOST_ROOT/lib`, `BOOST_ROOT/stage/lib`, `BOOST_ROOT/bin`
3. Common system paths (`C:/local/boost*`, `C:/vcpkg/installed/*/bin`, etc.)

### Naming Patterns

Supports multiple Boost DLL naming conventions:

- `boost_component_*.dll` (standard)
- `libboost_component_*.dll` (MinGW)
- `*boost*component*.dll` (fuzzy match)

### Build Type Handling

- **Release builds**: Excludes debug DLLs (`*d.dll`)
- **Debug builds**: Prefers debug DLLs but accepts release if needed
- **Static linking**: Skips DLL deployment entirely

## Migration Benefits

| Old Approach                     | New Approach                    |
| -------------------------------- | ------------------------------- |
| Deploy everything → Remove most  | Deploy only what's needed       |
| ~50+ file operations (removals)  | ~2-3 file operations (installs) |
| Hard to debug missing deps       | Clear error messages            |
| Negative logic (remove unwanted) | Positive logic (add needed)     |
| Fragile glob patterns            | Targeted component search       |

This approach is much more aligned with CMake best practices and makes the build system more reliable and maintainable.
