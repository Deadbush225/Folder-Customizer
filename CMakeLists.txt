cmake_minimum_required(VERSION 3.16)

if(POLICY CMP0167)
    cmake_policy(SET CMP0167 NEW)
endif()

# Enable improved language standard/extension flag handling
if(POLICY CMP0128)
    cmake_policy(SET CMP0128 NEW)
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

set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/packages/com.mainprogram/data)

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

# set(Boost_USE_STATIC_LIBS OFF)
find_package(Qt6 REQUIRED COMPONENTS Widgets Core)
qt_standard_project_setup()
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
    # Use system Boost on Linux
    find_package(Boost QUIET COMPONENTS program_options)

    if(Boost_FOUND)
        include_directories(${Boost_INCLUDE_DIRS})
        set(BOOST_AVAILABLE TRUE)
        message(STATUS "Using system Boost: ${Boost_VERSION}")
    else()
        set(BOOST_AVAILABLE FALSE)
        message(WARNING "Boost not found - program_options features disabled")
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

add_subdirectory(Updater)

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

# installer
install(CODE "file(REMOVE_RECURSE \"${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}\")")

install(TARGETS ${PROJECT_NAME} BUNDLE DESTINATION . RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}) # move the executable

install(FILES "./manifest.json" DESTINATION ${CMAKE_INSTALL_BINDIR})

# Install .ico files from Icons/Dark (non-recursive)
file(GLOB ICONS_DARK_FILES "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Dark/*.ico")
install(FILES ${ICONS_DARK_FILES}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Dark)

file(GLOB ICONS_LIGHT_FILES "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Light/*.ico")
install(FILES ${ICONS_LIGHT_FILES}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Light)

file(GLOB ICONS_NORMAL_FILES "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Normal/*.ico")
install(FILES ${ICONS_NORMAL_FILES}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Normal)

# Also install PNG icons for Linux .directory support
file(GLOB ICONS_PNG_DARK "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Dark/PNG/*.png")
file(GLOB ICONS_PNG_LIGHT "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Light/PNG/*.png")
file(GLOB ICONS_PNG_NORMAL "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Normal/PNG/*.png")
install(FILES ${ICONS_PNG_DARK}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Dark/PNG)
install(FILES ${ICONS_PNG_LIGHT}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Light/PNG)
install(FILES ${ICONS_PNG_NORMAL}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Normal/PNG)

# Install the Updater executable
install(TARGETS Updater DESTINATION ${CMAKE_INSTALL_BINDIR})

set(ROOT_ICON "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Folder Customizer.ico")
install(FILES ${ROOT_ICON} DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons)

# Move DLL to the installation folder
install(TARGETS Updater DESTINATION ${CMAKE_INSTALL_BINDIR})

# Generate and run Qt deploy script (guarded for older Qt and can be disabled)
if(ENABLE_QT_DEPLOY_SCRIPT)
    if(COMMAND qt_generate_deploy_app_script)
        qt_generate_deploy_app_script(
            TARGET ${PROJECT_NAME} OUTPUT_SCRIPT deploy_script
        ) # create deploy script
        install(SCRIPT ${deploy_script}) # run deploy script
    else()
        message(STATUS "qt_generate_deploy_app_script not available; skipping deploy script generation")
    endif()
else()
    message(STATUS "ENABLE_QT_DEPLOY_SCRIPT=OFF; skipping Qt deploy script generation")
endif()

# --- Convenience install targets -------------------------------------------
# install_local: Build app + Updater (+ context menu on Windows), then remove
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

add_dependencies(install_local ${PROJECT_NAME} Updater)

if(TARGET FCContextMenuHandler)
    add_dependencies(install_local FCContextMenuHandler)
endif()

# Note: Previous 'reinstall' target removed; use 'install_local' and package from ./install
