# eUpdater Integration - Hybrid approach
# Prefers local development copy, falls back to FetchContent

option(EUPDATER_USE_LOCAL "Use local eUpdater source directory if available" ON)
option(EUPDATER_FORCE_FETCH "Force download eUpdater via FetchContent" OFF)

set(EUPDATER_LOCAL_DIR "${CMAKE_SOURCE_DIR}/../eUpdater" CACHE PATH "Path to local eUpdater source")

# Set eUpdater configuration variables
set(EUPDATER_DEFAULT_MANIFEST_URL "https://raw.githubusercontent.com/Deadbush225/Folder-Customizer/main/manifest.json" CACHE STRING "Default manifest URL for eUpdater")
set(EUPDATER_DEFAULT_RELEASE_API_URL "https://api.github.com/repos/Deadbush225/folder-customizer/releases/latest" CACHE STRING "Default release API URL for eUpdater")

# set(ENABLE_EUPDATER OFF CACHE BOOL "Enable eUpdater integration")
set(ENABLE_EUPDATER ON CACHE BOOL "Enable eUpdater integration")

if(NOT ENABLE_EUPDATER)
    message(STATUS "eUpdater integration is disabled.")
    return()
endif()

# Try local directory first (for development)
if(EUPDATER_USE_LOCAL AND NOT EUPDATER_FORCE_FETCH AND EXISTS "${EUPDATER_LOCAL_DIR}/CMakeLists.txt")
    message(STATUS "Using local eUpdater source at: ${EUPDATER_LOCAL_DIR}")
    add_subdirectory("${EUPDATER_LOCAL_DIR}" "${CMAKE_BINARY_DIR}/eUpdater-build")
    set(EUPDATER_FOUND TRUE)
    set(EUPDATER_SOURCE "local")
else()
    # Fall back to FetchContent
    message(STATUS "Downloading eUpdater via FetchContent...")
    include(FetchContent)

    FetchContent_Declare(
        eUpdater
        GIT_REPOSITORY https://github.com/eliazar-sll/eUpdater.git # Replace with actual repo
        GIT_TAG main # or specific version tag
        SOURCE_DIR "${CMAKE_BINARY_DIR}/eUpdater-src"
        BINARY_DIR "${CMAKE_BINARY_DIR}/eUpdater-build"
    )

    FetchContent_MakeAvailable(eUpdater)
    set(EUPDATER_FOUND TRUE)
    set(EUPDATER_SOURCE "fetchcontent")
endif()

# --- Icon resource integration ---
# Copy eicon.png from main app to eUpdater build dir
set(FOLDER_CUSTOMIZER_ICON_PATH "${CMAKE_SOURCE_DIR}/Icons/Folder Customizer.png")

# set(EUPDATER_ICON_DEST "${CMAKE_BINARY_DIR}/eicon.png")
if(EXISTS "${FOLDER_CUSTOMIZER_ICON_PATH}")
    file(COPY "${FOLDER_CUSTOMIZER_ICON_PATH}" DESTINATION "${CMAKE_BINARY_DIR}")
    message(STATUS "Copied Folder Customizer.png for eUpdater icon resource.")
else()
    message(WARNING "Folder Customizer.png not found in main app Icons directory!")
endif()

# Generate .qrc for eUpdater to use
# configure_file(
# "${CMAKE_SOURCE_DIR}/cmake/eupdater_icon_template.qrc"
# "${CMAKE_BINARY_DIR}/eUpdater-build/eupdater_icon.qrc"
# @ONLY
# )
message(STATUS "Generated eUpdater icon .qrc file.")

if(EUPDATER_FOUND)
    message(STATUS "eUpdater integration: ${EUPDATER_SOURCE}")

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
else()
    message(STATUS "eUpdater not found - update functionality will be disabled")
endif()