cmake_minimum_required(VERSION 3.16)

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

set(CMAKE_BUILD_TYPE "Release")

# Allow disabling Qt deploy script generation (useful for older distro Qt packages or CI)
option(ENABLE_QT_DEPLOY_SCRIPT "Generate and run Qt deploy script during install" ON)

# set(CMAKE_BUILD_TYPE "Debug")
# Use Windows-specific Boost hint only on developer machines without toolchains; don't pollute CI
if(WIN32 AND NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    set(Boost_ROOT D:/Dev/boost_1_87_0/stage)
    list(APPEND CMAKE_PREFIX_PATH ${Boost_ROOT})
elseif(NOT WIN32)
    # Force FindBoost module instead of a BoostConfig.cmake on Linux
    set(Boost_NO_BOOST_CMAKE ON)
endif()

set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/install)

project(FolderCustomizer VERSION 0.1.0)
set(PROJECT_NAME FolderCustomizer)
set(PROJECT_SOURCE ${CMAKE_SOURCE_DIR}/src)
message("\nPROJECT SOURCE: " ${PROJECT_SOURCE})

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

        if(WIN32 AND DEFINED BOOST_ROOT)
            if(EXISTS "${BOOST_ROOT}/include/boost")
                target_include_directories(${SUBDIR_NAME} PRIVATE "${BOOST_ROOT}/include")
            endif()

            if(EXISTS "${BOOST_ROOT}/boost")
                target_include_directories(${SUBDIR_NAME} PRIVATE "${BOOST_ROOT}")
            endif()

            target_link_libraries(${SUBDIR_NAME} PUBLIC "boost_program_options")
        else()
            target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS})
            target_link_libraries(${SUBDIR_NAME} PUBLIC ${BOOST_COMPONENT})
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

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    message("Removing Console...\n")
    set_property(TARGET ${PROJECT_NAME} PROPERTY WIN32_EXECUTABLE true)
endif()

set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "FolderCustomizer")

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)

target_link_libraries(${PROJECT_NAME} PRIVATE Core Logger Utils Customizer UserInterface Qt6::Widgets Qt6::Core)

# Propagate Boost availability to the app target too
if(BOOST_AVAILABLE)
    target_compile_definitions(${PROJECT_NAME} PRIVATE HAVE_BOOST_PROGRAM_OPTIONS=1)
else()
    target_compile_definitions(${PROJECT_NAME} PRIVATE HAVE_BOOST_PROGRAM_OPTIONS=0)
endif()

# Install PNG icons for Linux .directory support in /bin/Icons (used by the program)
file(GLOB ICONS_PNG_DARK "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Dark/PNG/*.png")
file(GLOB ICONS_PNG_LIGHT "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Light/PNG/*.png")
file(GLOB ICONS_PNG_NORMAL "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Normal/PNG/*.png")
install(FILES ${ICONS_PNG_DARK}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Dark/PNG)
install(FILES ${ICONS_PNG_LIGHT}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Light/PNG)
install(FILES ${ICONS_PNG_NORMAL}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Normal/PNG)

# Install system eUpdater if available
find_program(EUPDATER_EXECUTABLE NAMES eUpdater eUpdater.exe)

if(EUPDATER_EXECUTABLE)
    get_filename_component(EUPDATER_DIR ${EUPDATER_EXECUTABLE} DIRECTORY)
    install(PROGRAMS ${EUPDATER_EXECUTABLE} DESTINATION ${CMAKE_INSTALL_BINDIR})
    message(STATUS "Found eUpdater: ${EUPDATER_EXECUTABLE}")
else()
    message(WARNING "eUpdater not found in system PATH. Update functionality may not work.")
endif()

# Install main app icon to /icons (for install package)
set(ROOT_ICON "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Folder Customizer.png")
set(ROOT_ICON_ICO "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Folder Customizer.ico")

if(EXISTS ${ROOT_ICON})
    install(FILES ${ROOT_ICON} DESTINATION ${CMAKE_INSTALL_ICONDIR})
endif()

if(EXISTS ${ROOT_ICON_ICO})
    # Install ICO to both /icons (for installer) and /bin/Icons (for program use)
    install(FILES ${ROOT_ICON_ICO} DESTINATION ${CMAKE_INSTALL_ICONDIR})
    install(FILES ${ROOT_ICON_ICO} DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons)
endif()

# Install manifest.json to root
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/manifest.json" DESTINATION .)

# Install install.sh (the generic desktop install script) to root
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/scripts/generic-desktop-install.sh")
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/scripts/generic-desktop-install.sh"
        DESTINATION .
        RENAME "install.sh")

    # Make install.sh executable during install
    install(CODE "execute_process(COMMAND chmod +x \"${CMAKE_INSTALL_PREFIX}/install.sh\")")
endif()

# Install the main application executable so install_local populates ./install
install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_BINDIR})

# Generate and run Qt deploy script (guarded for older Qt and can be disabled)
if(ENABLE_QT_DEPLOY_SCRIPT)
    if(APPLE)
        if(COMMAND qt_generate_deploy_app_script)
            # Only run the Qt deploy script generator on macOS (the helper's
            # signature has varied between Qt versions and some platforms don't
            # provide it). This avoids the "Unexpected arguments" error on other
            # platforms.
            qt_generate_deploy_app_script(
                TARGET ${PROJECT_NAME} OUTPUT_SCRIPT deploy_script
            ) # create deploy script
            install(SCRIPT ${deploy_script}) # run deploy script
        else()
            message(STATUS "qt_generate_deploy_app_script not available on this Qt build; skipping deploy script generation on macOS")
        endif()
    elseif(WIN32)
        # On Windows, prefer to run windeployqt (if available) after install.
        find_program(WINDEPLOYQT_EXECUTABLE
            NAMES windeployqt.exe windeployqt
            HINTS $ENV{Qt6_DIR} PATH_SUFFIXES bin
        )

        if(WINDEPLOYQT_EXECUTABLE)
            message(STATUS "windeployqt found: ${WINDEPLOYQT_EXECUTABLE}; adding install-time invocation")

            # Run windeployqt as part of the install step so the ./install tree
            # gets populated with Qt runtime artifacts. Use install(CODE ...) so
            # it runs at install time.
            install(CODE "execute_process(COMMAND \"${WINDEPLOYQT_EXECUTABLE}\" --release --dir \"${CMAKE_INSTALL_PREFIX}\" \"${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/${PROJECT_NAME}.exe\"\n)")
        else()
            message(STATUS "windeployqt not found; skipping automatic windeployqt invocation on Windows")
        endif()
    else()
        # Linux and other platforms: do not call the Qt deploy script here. On
        # Linux we package via separate scripts (deb/rpm/AppImage) and calling
        # the Qt deployment generator may be unsupported or unnecessary.
        message(STATUS "Skipping qt_generate_deploy_app_script on this platform (not macOS)")
    endif()
else()
    message(STATUS "ENABLE_QT_DEPLOY_SCRIPT=OFF; skipping Qt deploy script generation")
endif()

# --- Convenience install targets -------------------------------------------
# install_local: Build app + eUpdater (+ context menu on Windows), then remove
# ./install and perform an installation into ./install using cmake --install.
set(INSTALL_LOCAL_DIR "${CMAKE_SOURCE_DIR}/install")

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
