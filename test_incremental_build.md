# Testing Incremental Build Optimization

This document describes how to test the CMake build optimization changes.

## What Changed

The CMake configuration has been optimized to prevent unnecessary full rebuilds by:

1. **Removed global `include_directories()`** from root CMakeLists.txt
2. **Added target-specific `target_include_directories()`** to each library and executable
3. **Removed headers from sources** in UserInterface library (they were causing rebuild triggers)
4. **Fixed context-menu DLL** to use target-specific includes

## Expected Benefits

- **Faster incremental builds**: Changing a single source file should only rebuild that module and its dependents
- **Reduced context menu DLL rebuilds**: The context menu DLL will only rebuild when its dependencies actually change
- **Better dependency tracking**: CMake can properly track which targets depend on which headers

## Testing Procedure

### 1. Clean Build (Baseline)

First, do a clean build to establish a baseline:

```bash
# Create build directory
mkdir -p build
cd build

# Configure
cmake ..

# Clean build
cmake --build . --clean-first

# Note the build time
```

### 2. Test Incremental Build - No Changes

Build again without any changes (should be very fast):

```bash
cmake --build .
# Should see: "Build files have been written" or similar, very quick
```

### 3. Test Incremental Build - Single Source File Change

Make a trivial change to one source file and verify only that module rebuilds:

```bash
# Make a small change (add a comment)
echo "// Test comment" >> ../src/Core/registry.cpp

# Rebuild
cmake --build . --verbose

# Expected: Only Core OBJECT library should recompile
# The main executable will relink but won't recompile other modules
```

### 4. Test Incremental Build - Header Change

Make a change to a header and verify appropriate rebuilds:

```bash
# Make a small change to a header
echo "// Test comment" >> ../Include/Core/registry.h

# Rebuild
cmake --build . --verbose

# Expected: Only modules that include Core/registry.h should rebuild
# NOT all modules (which would happen with global includes)
```

### 5. Test Context Menu DLL Independence

Make a change to main application source and verify context menu doesn't rebuild:

```bash
# Make a small change to main.cpp
echo "// Test comment" >> ../src/main.cpp

# Rebuild
cmake --build . --verbose

# Expected: Context menu DLL should NOT rebuild
# Only the main executable should recompile and relink
```

### 6. Verify Application Runs

After all changes, verify the application still builds and runs correctly:

```bash
# Install to a local directory
cmake --install . --prefix ./install_test

# Run the application
./install_test/bin/FolderCustomizer --help
```

## Validation Checklist

- [ ] Clean build completes successfully
- [ ] All OBJECT libraries (Core, Logger, Utils, Customizer, UserInterface) compile
- [ ] Context menu DLL compiles (Windows only)
- [ ] Main executable links successfully
- [ ] Incremental build with no changes is fast (< 5 seconds)
- [ ] Changing a single .cpp file only rebuilds that module
- [ ] Context menu DLL doesn't rebuild when changing main application code
- [ ] Application runs and functions correctly

## Comparison: Before vs After

### Before (Global Includes)
- Change to any header in `Include/` → Full rebuild of ALL targets
- Change to any source file → May trigger unnecessary header dependency checks
- Context menu DLL rebuilds even when main app changes

### After (Target-Specific Includes)
- Change to a header → Only affected targets rebuild
- Change to a source file → Only that target rebuilds + relinking dependents
- Context menu DLL only rebuilds when its sources or its headers change
- Much faster incremental builds for daily development

## Troubleshooting

If you encounter build errors:

1. **Missing includes**: Check that all source files that need headers are getting them via the target-specific includes
2. **Undefined references**: Verify all targets are still linked correctly in CMakeLists.txt
3. **Qt/Boost not found**: Make sure Qt6 and Boost are properly installed and findable by CMake

## Performance Metrics

You can measure build time improvements by timing the build commands:

```bash
# Before changes (use git to check out previous commit)
time cmake --build . --clean-first

# After changes
time cmake --build . --clean-first

# Compare times
```

For incremental builds:

```bash
# Touch a file and rebuild
touch ../src/Core/registry.cpp
time cmake --build .

# Should be significantly faster than a full rebuild
```
