cmake_minimum_required(VERSION 3.16)
set(Boost_NO_BOOST_CMAKE ON)

set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)

if(POLICY CMP0167)
    cmake_policy(SET CMP0167 NEW)
endif()

# Enable improved language standard/extension flag handling
if(POLICY CMP0128)
    cmake_policy(SET CMP0128 NEW)
endif()

# Set policy for install path normalization
if(POLICY CMP0177)
    cmake_policy(SET CMP0177 NEW)
endif()

# Set default build type only if not specified
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()

# Allow disabling Qt deploy script generation (useful for older distro Qt packages or CI)
option(ENABLE_QT_DEPLOY_SCRIPT "Generate and run Qt deploy script during install" ON)

# set(CMAKE_BUILD_TYPE "Debug")
# Install directories based on platform
project(FolderCustomizer VERSION 0.1.0)
set(PROJECT_NAME FolderCustomizer)
set(PROJECT_SOURCE ${CMAKE_SOURCE_DIR}/src)
message("\nPROJECT SOURCE: " ${PROJECT_SOURCE})

# Configure Boost after project() when compiler is detected
if(MINGW)
    message(STATUS "MinGW detected - using MSYS2 system Boost")
    set(Boost_NO_BOOST_CMAKE ON)
elseif(WIN32 AND NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    # Use Windows-specific Boost hint only for MSVC builds
    message(STATUS "MSVC detected - using custom Boost build")
    set(Boost_ROOT D:/Dev/boost_1_87_0/stage)
    list(APPEND CMAKE_PREFIX_PATH ${Boost_ROOT})
elseif(NOT WIN32)
    # Force FindBoost module instead of a BoostConfig.cmake on Linux
    set(Boost_NO_BOOST_CMAKE ON)
endif()

# Global C++ standard settings for all targets
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Common Windows definitions
if(WIN32)
    add_compile_definitions(WIN32_LEAN_AND_MEAN NOMINMAX)
endif()

# Turn on automatic invocation of the MOC, UIC & RCC
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Prefer static libs for distribution packages to avoid version conflicts
if(NOT WIN32)
    set(Boost_USE_STATIC_LIBS ON)
endif()

find_package(Qt6 REQUIRED COMPONENTS Widgets Core)
qt_standard_project_setup()

find_package(Boost REQUIRED COMPONENTS program_options)

include(GNUInstallDirs)

# Set custom install directories for the new structure
set(CMAKE_INSTALL_BINDIR "bin")
set(CMAKE_INSTALL_LIBDIR "lib")
set(CMAKE_INSTALL_ICONDIR "icons")

message(STATUS "Using toolchain file: ${CMAKE_TOOLCHAIN_FILE}")

# Simple Boost setup - only need program_options
if(WIN32 AND DEFINED BOOST_ROOT)
    message(STATUS "Using BOOST_ROOT: ${BOOST_ROOT}")

    # Candidate include directories
    set(_BOOST_INC_DIRS)

    if(EXISTS "${BOOST_ROOT}/include/boost")
        list(APPEND _BOOST_INC_DIRS "${BOOST_ROOT}/include")
    endif()

    if(EXISTS "${BOOST_ROOT}/boost")
        list(APPEND _BOOST_INC_DIRS "${BOOST_ROOT}")
    endif()

    if(NOT _BOOST_INC_DIRS)
        message(WARNING "Could not find Boost headers under ${BOOST_ROOT}")
    else()
        foreach(_inc IN LISTS _BOOST_INC_DIRS)
            include_directories("${_inc}")
            message(STATUS "Boost includes: ${_inc}")
        endforeach()
    endif()

    # Candidate library directories
    foreach(_cand IN ITEMS
        "${BOOST_ROOT}/lib"
        "${BOOST_ROOT}/stage/lib"
        "${BOOST_ROOT}/lib64-msvc-14.3"
        "${BOOST_ROOT}/lib64-msvc-14.2"
    )
        if(EXISTS "${_cand}")
            link_directories("${_cand}")
            message(STATUS "Boost libs: ${_cand}")
        endif()
    endforeach()

    set(BOOST_AVAILABLE TRUE)
else()
    # Use system Boost on Linux (or non-Windows). Try regular find_package first,
    # then fall back to a manual search for headers/libs so CI systems with
    # non-standard layouts get clearer diagnostics.
    find_package(Boost QUIET COMPONENTS program_options)

    if(Boost_FOUND)
        include_directories(${Boost_INCLUDE_DIRS})
        set(BOOST_AVAILABLE TRUE)
        message(STATUS "Using system Boost: ${Boost_VERSION}")
    else()
        # Fallback: try to locate the program_options header and library manually
        message(STATUS "find_package(Boost) failed; attempting manual detection...")
        find_path(Boost_INCLUDE_DIRS NAMES boost/program_options.hpp
            PATHS /usr/include /usr/local/include /opt/local/include ${CMAKE_SYSTEM_PREFIX_PATH}
            NO_DEFAULT_PATH)

        if(Boost_INCLUDE_DIRS)
            include_directories(${Boost_INCLUDE_DIRS})
            message(STATUS "Found Boost headers at: ${Boost_INCLUDE_DIRS}")

            # Try to find the program_options library
            find_library(Boost_PROGRAM_OPTIONS_LIBRARY
                NAMES boost_program_options boost_program_options-mt
                PATHS /usr/lib /usr/local/lib /usr/lib64 /usr/local/lib64
                NO_DEFAULT_PATH)

            if(Boost_PROGRAM_OPTIONS_LIBRARY)
                message(STATUS "Found Boost program_options library: ${Boost_PROGRAM_OPTIONS_LIBRARY}")
                set(BOOST_AVAILABLE TRUE)

                # expose variables similar to FindBoost
                set(Boost_INCLUDE_DIRS ${Boost_INCLUDE_DIRS})
                set(Boost_LIBRARIES ${Boost_PROGRAM_OPTIONS_LIBRARY})
            else()
                message(WARNING "Boost headers found but program_options library not found; program_options will be disabled")
                set(BOOST_AVAILABLE FALSE)
            endif()
        else()
            set(BOOST_AVAILABLE FALSE)
            message(WARNING "Boost not found - program_options features disabled")
            message(STATUS "Searched include paths: /usr/include /usr/local/include /opt/local/include and CMAKE_SYSTEM_PREFIX_PATH")
        endif()
    endif()
endif()

# Expose Boost availability to all targets as a macro
if(BOOST_AVAILABLE)
    add_compile_definitions(HAVE_BOOST_PROGRAM_OPTIONS=1)
else()
    add_compile_definitions(HAVE_BOOST_PROGRAM_OPTIONS=0)
endif()

# utility functions
function(u_include_header_only_boost SUBDIR_NAME)
    if(BOOST_AVAILABLE)
        message("Including Boost Headers for ${SUBDIR_NAME}...")

        if(WIN32 AND DEFINED BOOST_ROOT)
            if(EXISTS "${BOOST_ROOT}/include/boost")
                target_include_directories(${SUBDIR_NAME} PRIVATE "${BOOST_ROOT}/include")
            endif()

            if(EXISTS "${BOOST_ROOT}/boost")
                target_include_directories(${SUBDIR_NAME} PRIVATE "${BOOST_ROOT}")
            endif()
        else()
            target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS})
        endif()
    endif()
endfunction()

function(u_include_and_link_compiled_boost SUBDIR_NAME BOOST_COMPONENT)
    if(BOOST_AVAILABLE)
        message("Linking Boost program_options for ${SUBDIR_NAME}...")

        if(WIN32 AND DEFINED BOOST_ROOT AND NOT MINGW)
            # Custom Boost build (MSVC)
            if(EXISTS "${BOOST_ROOT}/include/boost")
                target_include_directories(${SUBDIR_NAME} PRIVATE "${BOOST_ROOT}/include")
            endif()

            if(EXISTS "${BOOST_ROOT}/boost")
                target_include_directories(${SUBDIR_NAME} PRIVATE "${BOOST_ROOT}")
            endif()

            target_link_libraries(${SUBDIR_NAME} PUBLIC "boost_program_options")
        else()
            # System Boost (Linux or MinGW)
            target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS})

            if(TARGET Boost::program_options)
                target_link_libraries(${SUBDIR_NAME} PUBLIC Boost::program_options)
            else()
                target_link_libraries(${SUBDIR_NAME} PUBLIC ${BOOST_COMPONENT})
            endif()
        endif()
    endif()
endfunction()

include_directories(${PROJECT_SOURCE_DIR}/Include)

add_subdirectory(src/Core)
add_subdirectory(src/Logger)
add_subdirectory(src/Customizer)
add_subdirectory(src/Utils)
add_subdirectory(src/UserInterface)

# Windows-only shell extension
if(WIN32)
    add_subdirectory(src/context-menu)
endif()

# eUpdater will be installed as system dependency
set(SOURCE_FILES ${PROJECT_SOURCE}/main.cpp)

# binary's icon
set(app_icon_resource_windows "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Folder Customizer.rc")

add_executable(${PROJECT_NAME} ${SOURCE_FILES}
    ${app_icon_resource_windows}
    Icons/resource.qrc)

# if(CMAKE_BUILD_TYPE STREQUAL "Release")
# message("Removing Console...\n")
# set_property(TARGET ${PROJECT_NAME} PROPERTY WIN32_EXECUTABLE true)
# endif()
set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "FolderCustomizer")

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)

target_link_libraries(${PROJECT_NAME} PRIVATE Core Logger Utils Customizer UserInterface Qt6::Widgets Qt6::Core)

# Link Boost program_options - handle both modern CMake targets and legacy variables
if(BOOST_AVAILABLE)
    if(TARGET Boost::program_options)
        target_link_libraries(${PROJECT_NAME} PRIVATE Boost::program_options)
        message(STATUS "Linking with Boost::program_options target")
    elseif(MINGW)
        # For MinGW with system Boost, link with the libraries found by find_package
        target_link_libraries(${PROJECT_NAME} PRIVATE ${Boost_LIBRARIES})
        message(STATUS "Linking with system Boost libraries: ${Boost_LIBRARIES}")
    else()
        # Fallback for custom builds
        target_link_libraries(${PROJECT_NAME} PRIVATE "boost_program_options")
    endif()
endif()

# Propagate Boost availability to the app target too
if(BOOST_AVAILABLE)
    target_compile_definitions(${PROJECT_NAME} PRIVATE HAVE_BOOST_PROGRAM_OPTIONS=1)
else()
    target_compile_definitions(${PROJECT_NAME} PRIVATE HAVE_BOOST_PROGRAM_OPTIONS=0)
endif()

# Install PNG icons for Linux .directory support in /bin/Icons (used by the program)
file(GLOB ICONS_ICO_DARK "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Dark/ICO/*.ico")
list(FILTER ICONS_ICO_DARK EXCLUDE REGEX "-16\\.ico$")
file(GLOB ICONS_ICO_LIGHT "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Light/ICO/*.ico")
list(FILTER ICONS_ICO_LIGHT EXCLUDE REGEX "-16\\.ico$")
file(GLOB ICONS_ICO_NORMAL "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Normal/ICO/*.ico")
list(FILTER ICONS_ICO_NORMAL EXCLUDE REGEX "-16\\.ico$")

install(FILES ${ICONS_ICO_DARK}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Dark/)
install(FILES ${ICONS_ICO_LIGHT}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Light/)
install(FILES ${ICONS_ICO_NORMAL}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Normal/)

# Install system eUpdater if available (avoid duplicate DLLs)
find_program(EUPDATER_EXECUTABLE NAMES eUpdater eUpdater.exe)

if(EUPDATER_EXECUTABLE)
    get_filename_component(EUPDATER_DIR ${EUPDATER_EXECUTABLE} DIRECTORY)

    # Only install to bin, not to root
    install(PROGRAMS ${EUPDATER_EXECUTABLE} DESTINATION ${CMAKE_INSTALL_BINDIR})
    message(STATUS "Found eUpdater: ${EUPDATER_EXECUTABLE}")
else()
    message(WARNING "eUpdater not found in system PATH. Update functionality may not work.")
endif()

# Install main app icon to /icons (for install package and installer)
set(ROOT_ICON_PNG "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Folder Customizer.png")
set(ROOT_ICON_ICO "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Folder Customizer.ico")

# if(EXISTS ${ROOT_ICON_PNG})
# install(FILES ${ROOT_ICON_PNG} DESTINATION ${CMAKE_INSTALL_ICONDIR})
# endif()

# Install ICO files for Windows installer and program use
if(EXISTS ${ROOT_ICON_ICO})
    # Install to /icons for Windows installer
    # install(FILES ${ROOT_ICON_ICO} DESTINATION ${CMAKE_INSTALL_ICONDIR})

    # Install to /bin/Icons for program use
    install(FILES ${ROOT_ICON_ICO} DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons)
endif()

# Install manifest.json to root
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/manifest.json" DESTINATION ${CMAKE_INSTALL_BINDIR})

# Install install.sh (the generic desktop install script) to root
if(UNIX AND NOT APPLE)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/scripts/eInstall.sh")
        install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/scripts/eInstall.sh"
            DESTINATION .
            RENAME "install.sh")

        # Make install.sh executable during install
        install(CODE "execute_process(COMMAND chmod +x \"${CMAKE_INSTALL_PREFIX}/install.sh\")")
    endif()
endif()

# Install the main application executable and DLLs only to bin
install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_BINDIR})

# Enhanced Qt deployment with diagnostics and fallback
if(ENABLE_QT_DEPLOY_SCRIPT)
    if(WIN32)
        # Use enhanced Qt deployment with multiple detection methods and fallback
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/EnhancedQtDeploy.cmake")
            include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/EnhancedQtDeploy.cmake")
            deploy_qt_enhanced(${PROJECT_NAME})
        else()
            message(FATAL_ERROR "EnhancedQtDeploy.cmake not found - Qt deployment will fail")
        endif()

        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PruneInstall.cmake")
            install(SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PruneInstall.cmake")
        else()
            message(FATAL_ERROR "PruneInstall.cmake not found - Qt deployment will fail")
        endif()
    else()
        message(STATUS "Skipping qt_generate_deploy_app_script on this platform")
    endif()
else()
    message(STATUS "ENABLE_QT_DEPLOY_SCRIPT=OFF; skipping Qt deploy script generation")
endif()

# Deploy only needed Boost DLLs (if using dynamic linking) - AFTER Qt deployment
# if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/BoostDeploy.cmake")
# include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/BoostDeploy.cmake")
# deploy_boost_program_options()
# endif()

# Prune optional/banned bits that may remain or from previous installs using a script file

# --- Convenience install targets -------------------------------------------
# install_local: Build app + eUpdater (+ context menu on Windows), then remove
# ../install/linux or ../install/windows and perform an installation using cmake --install.
if(WIN32)
    set(INSTALL_LOCAL_DIR "${CMAKE_SOURCE_DIR}/dist/windows")
else()
    set(INSTALL_LOCAL_DIR "${CMAKE_SOURCE_DIR}/dist/linux")
endif()

add_custom_target(install_local
    COMMAND ${CMAKE_COMMAND} -E echo "Cleaning ${INSTALL_LOCAL_DIR}"
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${INSTALL_LOCAL_DIR}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_LOCAL_DIR}"
    COMMAND ${CMAKE_COMMAND} -E echo "Installing to ${INSTALL_LOCAL_DIR}"
    COMMAND ${CMAKE_COMMAND} --install "${CMAKE_BINARY_DIR}" --config $<IF:$<BOOL:$<CONFIG>>,$<CONFIG>,Release> --prefix "${INSTALL_LOCAL_DIR}"
    USES_TERMINAL
    COMMENT "Build + local install to ${INSTALL_LOCAL_DIR}"
)

add_dependencies(install_local ${PROJECT_NAME})

if(TARGET FCContextMenuHandler)
    add_dependencies(install_local FCContextMenuHandler)
endif()

# Note: Previous 'reinstall' target removed; use 'install_local' and package from ./install
