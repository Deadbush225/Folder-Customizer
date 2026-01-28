# eUpdater Integration - Hybrid approach
# Prefers local development copy, falls back to FetchContent

option(EUPDATER_USE_LOCAL "Use local eUpdater source directory if available" ON)
option(EUPDATER_FORCE_FETCH "Force download eUpdater via FetchContent" OFF)
option(ENABLE_EUPDATER "Enable eUpdater integration" ON)

# Set eUpdater configuration variables
set(EUPDATER_DEFAULT_MANIFEST_URL "https://raw.githubusercontent.com/Deadbush225/Folder-Customizer/main/manifest.json")
set(EUPDATER_DEFAULT_RELEASE_API_URL "https://api.github.com/repos/Deadbush225/folder-customizer/releases/latest")

if(NOT ENABLE_EUPDATER)
    message(STATUS "eUpdater integration is disabled.")
    return()
endif()

# --- eUpdater Integration: Use local source if available ---
if(EUPDATER_USE_LOCAL)
    # Check for eUpdater in sibling directory
    get_filename_component(PROJECT_PARENT_DIR "${CMAKE_SOURCE_DIR}" DIRECTORY)
    set(LOCAL_EUPDATER_PATH "${PROJECT_PARENT_DIR}/eUpdater")
    
    if(EXISTS "${LOCAL_EUPDATER_PATH}/CMakeLists.txt")
        message(STATUS "Found local eUpdater at: ${LOCAL_EUPDATER_PATH}")
        set(eUpdater_DIR "${LOCAL_EUPDATER_PATH}/cmake")
        set(eUpdater_ROOT "${LOCAL_EUPDATER_PATH}")
    else()
        message(WARNING "EUPDATER_USE_LOCAL is ON but local eUpdater not found at ${LOCAL_EUPDATER_PATH}")
    endif()
endif()

# --- eUpdater Integration: fallback to global package discovery ---
# find_package(eUpdater REQUIRED)
#         set(eUpdater_DIR "F:/System/Coding/Projects/eUpdater/cmake")
#     else()
#         set(eUpdater_DIR "/media/deadbush225/LocalDisk/System/Coding/Projects/eUpdater/cmake")
#     endif()
# endif()

find_package(eUpdater REQUIRED)

add_updater_to_project(
    TARGET ${PROJECT_NAME}
    MANIFEST_URL "https://raw.githubusercontent.com/Deadbush225/Folder-Customizer/main/manifest.json"
    RELEASE_API_URL "https://api.github.com/repos/Deadbush225/folder-customizer/releases/latest"
    ICON_QRC "${CMAKE_CURRENT_SOURCE_DIR}/resource/eupdater_icon.qrc"
)

message(STATUS "eUpdater integration: found")

# Ensure main app depends on eUpdater
if(TARGET eUpdater)
    add_dependencies(${PROJECT_NAME} eUpdater)

    # Install eUpdater alongside main executable
    install(TARGETS eUpdater DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT Application)

    # Add convenience target for rebuilding just eUpdater
    add_custom_target(build_updater
        COMMAND ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}" --target eUpdater
        COMMENT "Rebuild eUpdater"
    )
else()
    message(WARNING "eUpdater target not found after integration")
endif()