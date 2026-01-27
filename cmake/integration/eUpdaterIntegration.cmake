# eUpdater Integration - Hybrid approach
# Prefers local development copy, falls back to FetchContent

option(EUPDATER_USE_LOCAL "Use local eUpdater source directory if available" ON)
option(EUPDATER_FORCE_FETCH "Force download eUpdater via FetchContent" OFF)
option(ENABLE_EUPDATER "Enable eUpdater integration" ON)

# Set eUpdater configuration variables
set(EUPDATER_DEFAULT_MANIFEST_URL "https://raw.githubusercontent.com/Deadbush225/Folder-Customizer/main/manifest.json" CACHE STRING "Default manifest URL for eUpdater")
set(EUPDATER_DEFAULT_RELEASE_API_URL "https://api.github.com/repos/Deadbush225/folder-customizer/releases/latest" CACHE STRING "Default release API URL for eUpdater")

if(NOT ENABLE_EUPDATER)
    message(STATUS "eUpdater integration is disabled.")
    return()
endif()

# --- eUpdater Integration: Use global package discovery ---
# Directly set eUpdater_DIR to the directory containing eUpdaterConfig.cmake
if(NOT eUpdater_DIR)
    if(WIN32)
        set(eUpdater_DIR "F:/System/Coding/Projects/eUpdater/cmake")
    else()
        set(eUpdater_DIR "/media/deadbush225/LocalDisk/System/Coding/Projects/eUpdater/cmake")
    endif()
endif()

find_package(eUpdater REQUIRED)

add_updater_to_project(
    TARGET ${PROJECT_NAME}
    MANIFEST_URL "https://raw.githubusercontent.com/Deadbush225/Folder-Customizer/main/manifest.json"
    RELEASE_API_URL "https://api.github.com/repos/Deadbush225/folder-customizer/releases/latest"
)

message(STATUS "eUpdater integration: found")

# Ensure main app depends on eUpdater
if(TARGET eUpdater)
    add_dependencies(${PROJECT_NAME} eUpdater)

    # Install eUpdater alongside main executable
    install(TARGETS eUpdater DESTINATION ${CMAKE_INSTALL_BINDIR})

    # Add convenience target for rebuilding just eUpdater
    add_custom_target(build_updater
        COMMAND ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}" --target eUpdater
        COMMENT "Rebuild eUpdater"
    )
else()
    message(WARNING "eUpdater target not found after integration")
endif()