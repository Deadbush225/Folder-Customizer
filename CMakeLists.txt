cmake_minimum_required(VERSION 3.16)

if(POLICY CMP0167)
    cmake_policy(SET CMP0167 NEW)
endif()

set(CMAKE_BUILD_TYPE "Release")

# set(CMAKE_BUILD_TYPE "Debug")
set(Boost_ROOT D:/Dev/boost_1_87_0/stage)
set(CMAKE_PREFIX_PATH ${Boost_ROOT})

set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/packages/com.mainprogram/data)

project(FolderCustomizer VERSION 0.1.0)
set(PROJECT_NAME FolderCustomizer)
set(PROJECT_SOURCE ${CMAKE_SOURCE_DIR}/src)
message("\nPROJECT SOURCE: " ${PROJECT_SOURCE})

# Turn on automatic invocation of the MOC, UIC & RCC
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# set(Boost_USE_STATIC_LIBS OFF)
find_package(Qt6 REQUIRED COMPONENTS Widgets Core)
qt_standard_project_setup()
find_package(Boost REQUIRED COMPONENTS program_options)

# utility functions
function(u_include_header_only_boost SUBDIR_NAME)
    if(Boost_FOUND)
        message("Including Boost Headers ...")
        target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS})
    endif()
endfunction()

function(u_include_and_link_compiled_boost SUBDIR_NAME BOOST_COMPONENT)
    if(Boost_FOUND)
        message("Including Boost Headers ...")
        target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS}) # ? try to check if this is actually needed for compiled
        message("Linking Boost Libraries ...")
        target_link_libraries(${SUBDIR_NAME} PUBLIC ${BOOST_COMPONENT})
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

qt_generate_deploy_app_script(
    TARGET ${PROJECT_NAME} OUTPUT_SCRIPT deploy_script NO_TRANSLATIONS
) # create deploy script

install(SCRIPT ${deploy_script}) # run deploy script

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
if (TARGET FCContextMenuHandler)
    add_dependencies(install_local FCContextMenuHandler)
endif()

# Note: Previous 'reinstall' target removed; use 'install_local' and package from ./install
