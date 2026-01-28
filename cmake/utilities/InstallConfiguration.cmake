# Installation configuration
# Defines install directories and handles icon/manifest installation

include(GNUInstallDirs)

# Set custom install directories
set(CMAKE_INSTALL_BINDIR "bin")
set(CMAKE_INSTALL_LIBDIR "lib")
set(CMAKE_INSTALL_ICONDIR "icons")

# Install PNG icons for Linux .directory support in /bin/Icons (used by the program)
# Use install(DIRECTORY) for cleaner output and better incremental behavior
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Dark/ICO/"
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Dark
    COMPONENT Prerequisites
    FILES_MATCHING PATTERN "*.ico"
    PATTERN "*-16.ico" EXCLUDE)

install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Light/ICO/"
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Light
    COMPONENT Prerequisites
    FILES_MATCHING PATTERN "*.ico"
    PATTERN "*-16.ico" EXCLUDE)

install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Normal/ICO/"
    DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons/Normal
    COMPONENT Prerequisites
    FILES_MATCHING PATTERN "*.ico"
    PATTERN "*-16.ico" EXCLUDE)

# Install main app icons to /icons (for install package and installer)
set(ROOT_ICON_PNG "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Folder Customizer.png")
set(ROOT_ICON_ICO "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Folder Customizer.ico")

if(UNIX AND NOT APPLE)
    if(EXISTS ${ROOT_ICON_PNG})
        install(FILES ${ROOT_ICON_PNG} DESTINATION ${CMAKE_INSTALL_ICONDIR} RENAME "folder-customizer.png" COMPONENT Prerequisites)
    endif()
endif()

# Install ico for program use
if(EXISTS ${ROOT_ICON_ICO})
    install(FILES ${ROOT_ICON_ICO} DESTINATION ${CMAKE_INSTALL_BINDIR}/Icons COMPONENT Prerequisites)
endif()

# Install manifest.json to root
if(WIN32)
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/manifest.json" DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT Application)
else()
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/manifest.json" DESTINATION . COMPONENT Application)
endif()

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

message(STATUS "Installation configuration complete")
