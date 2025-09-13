# Qt Deployment Pipeline Fix for GitHub Actions Windows

## Problem Identified

The folder-customizer and other projects were showing only **2.7MB size** instead of the expected **15-50MB** with Qt DLLs, indicating Qt deployment was failing in GitHub Actions Windows workflow.

## Root Causes Found & Fixed

### 1. **windeployqt Detection Failure**

**Problem**: Used fragile `find_program()` with environment variables that don't exist in GitHub Actions

```cmake
# OLD - FRAGILE APPROACH
find_program(WINDEPLOYQT_EXECUTABLE
    NAMES windeployqt.exe windeployqt
    HINTS $ENV{Qt6_DIR} PATH_SUFFIXES bin  # ❌ $ENV{Qt6_DIR} not set in CI
)
```

**Solution**: Use robust `Qt6::qmake` target approach (like download-sorter)

```cmake
# NEW - ROBUST APPROACH
get_target_property(QT_QMAKE_EXECUTABLE Qt6::qmake IMPORTED_LOCATION)
if(QT_QMAKE_EXECUTABLE)
    get_filename_component(QT_WINDEPLOYQT_EXECUTABLE ${QT_QMAKE_EXECUTABLE} PATH)
    set(QT_WINDEPLOYQT_EXECUTABLE "${QT_WINDEPLOYQT_EXECUTABLE}/windeployqt.exe")
```

### 2. **Wrong `--dir` Parameter**

**Problem**: Pointed to `/bin` subdirectory instead of install root

```cmake
# OLD - WRONG DIRECTORY
--dir "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}"  # ❌ Points to /bin
```

**Solution**: Point to install root where windeployqt can find and deploy alongside executable

```cmake
# NEW - CORRECT DIRECTORY
--dir "${CMAKE_INSTALL_PREFIX}"  # ✅ Points to install root
```

### 3. **Wrong Deployment Order**

**Problem**: Tried to deploy Boost DLLs before Qt DLLs existed

```cmake
# OLD - WRONG ORDER
install(TARGETS ${PROJECT_NAME} ...)        # 1. Install executable
deploy_boost_program_options()               # 2. ❌ Try to deploy Boost (no Qt DLLs yet)
install(CODE "...windeployqt...")           # 3. Deploy Qt DLLs
install(SCRIPT PruneInstall.cmake)          # 4. Cleanup
```

**Solution**: Follow correct sequence: Qt → Boost → Cleanup

```cmake
# NEW - CORRECT ORDER
install(TARGETS ${PROJECT_NAME} ...)        # 1. ✅ Install executable
install(CODE "...windeployqt...")           # 2. ✅ Deploy Qt DLLs
deploy_boost_program_options()               # 3. ✅ Deploy Boost DLLs
install(SCRIPT PruneInstall.cmake)          # 4. ✅ Strip unnecessary files
```

## Deployment Sequence Now Implemented

### **Folder Customizer & Printing Rates:**

1. **Build** - CMake builds the executable
2. **Install Executable** - `install(TARGETS ${PROJECT_NAME})`
3. **Deploy Qt** - `windeployqt` with robust detection
4. **Add Boost DLLs** - `deploy_boost_program_options()` / `deploy_boost_log()`
5. **Strip Unnecessary** - `PruneInstall.cmake` removes unwanted DLLs
6. **Pack** - Ready for installer creation

### **Download Sorter:**

Uses advanced `DeployRuntime.cmake.in` template system but follows same sequence.

## Expected Results

### **Before Fix:**

- ❌ **2.7MB** packages (no Qt DLLs)
- ❌ Applications crash on systems without Qt
- ❌ Silent deployment failures in CI

### **After Fix:**

- ✅ **15-50MB** packages (with Qt DLLs)
- ✅ Self-contained applications that run anywhere
- ✅ Clear error messages if deployment fails
- ✅ Proper deployment sequence ensuring dependencies are met

## Files Modified

### **folder-customizer/CMakeLists.txt**

- Fixed windeployqt detection using `Qt6::qmake` target
- Corrected `--dir` parameter to point to install root
- Reordered deployment: Qt → Boost → Cleanup
- Added PruneInstall.cmake step

### **printing-rates/CMakeLists.txt**

- Same fixes as folder-customizer
- Uses `deploy_boost_log()` instead of `deploy_boost_program_options()`

### **download-sorter/src/CMakeLists.txt**

- Already had robust deployment via `DeployRuntime.cmake.in`
- No changes needed (was working correctly)

## Verification Steps

1. Check that windeployqt is found: Look for `"windeployqt found: ..."` message
2. Verify Qt DLLs are deployed: Final package should be 15-50MB, not 2.7MB
3. Confirm Boost integration: Needed Boost DLLs should be present
4. Validate cleanup: Unnecessary DLLs should be removed

This fix ensures all three projects have consistent, reliable Qt deployment in GitHub Actions Windows builds.
