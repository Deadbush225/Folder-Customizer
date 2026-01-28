cmake_minimum_required(VERSION 3.16)

set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)

# Set policies for modern CMake behavior
if(POLICY CMP0167)
    cmake_policy(SET CMP0167 NEW)
endif()

if(POLICY CMP0128)
    cmake_policy(SET CMP0128 NEW)
endif()

if(POLICY CMP0177)
    cmake_policy(SET CMP0177 NEW)
endif()

cmake_policy(SET CMP0144 NEW) # Case-insensitive

# Set default build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release")
endif()

# Allow disabling Qt deploy script generation
option(ENABLE_QT_DEPLOY_SCRIPT "Generate and run Qt deploy script during install" ON)

# Initialize project
project(FolderCustomizer VERSION 0.1.0)
set(PROJECT_NAME FolderCustomizer)
set(PROJECT_SOURCE ${CMAKE_SOURCE_DIR}/src)
message("\nPROJECT SOURCE: " ${PROJECT_SOURCE})

# Global C++ standard settings
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Platform-specific definitions
if(WIN32)
    add_compile_definitions(WIN32_LEAN_AND_MEAN NOMINMAX)
endif()

# Qt and Boost build system settings
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Load configuration modules from cmake folder
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/config/BoostConfig.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/config/QtConfig.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/utilities/BoostUtilities.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/utilities/InstallConfiguration.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/utilities/PostBuildOptimization.cmake)

message(STATUS "Using toolchain file: ${CMAKE_TOOLCHAIN_FILE}")

# Include project headers - now using target-specific includes instead of global

add_subdirectory(src/Core)
add_subdirectory(src/Logger)
add_subdirectory(src/Customizer)
add_subdirectory(src/Utils)
add_subdirectory(src/UserInterface)

# Windows-only shell extension
if(WIN32)
    add_subdirectory(src/context-menu)
endif()

# Application executable and icon
set(SOURCE_FILES ${PROJECT_SOURCE}/main.cpp)
set(app_icon_resource_windows "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Folder Customizer.rc")

add_executable(${PROJECT_NAME} ${SOURCE_FILES}
    ${app_icon_resource_windows}
    Icons/resource.qrc)

# Add target-specific include directory
target_include_directories(${PROJECT_NAME} PRIVATE ${PROJECT_SOURCE_DIR}/Include)

# Hide console window in non-Debug builds
if(WIN32 AND NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    set_target_properties(${PROJECT_NAME} PROPERTIES WIN32_EXECUTABLE ON)
endif()

set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "FolderCustomizer")

install(TARGETS ${PROJECT_NAME} 
    DESTINATION ${CMAKE_INSTALL_BINDIR}
    COMPONENT Application
)

# Link libraries
target_link_libraries(${PROJECT_NAME} PRIVATE Core Logger Utils Customizer UserInterface Qt6::Widgets Qt6::Core)

# Link Boost program_options if available
if(BOOST_AVAILABLE)
    if(TARGET Boost::program_options)
        target_link_libraries(${PROJECT_NAME} PRIVATE Boost::program_options)
        message(STATUS "Linking with Boost::program_options target")
    elseif(MINGW)
        target_link_libraries(${PROJECT_NAME} PRIVATE ${Boost_LIBRARIES})
        message(STATUS "Linking with system Boost libraries: ${Boost_LIBRARIES}")
    else()
        target_link_libraries(${PROJECT_NAME} PRIVATE "boost_program_options")
    endif()
    
    target_compile_definitions(${PROJECT_NAME} PRIVATE HAVE_BOOST_PROGRAM_OPTIONS=1)
else()
    target_compile_definitions(${PROJECT_NAME} PRIVATE HAVE_BOOST_PROGRAM_OPTIONS=0)
endif()

# Install main executable
install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_BINDIR})

# eUpdater integration
set(FC_HOME_PAGE "https://github.com/Deadbush225/folder-customizer")
set(FC_PACKAGE_ID "folder-customizer")

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/integration/eUpdaterIntegration.cmake")

# Enhanced Qt deployment
if(ENABLE_QT_DEPLOY_SCRIPT)
    if(WIN32)
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deployment/EnhancedQtDeploy.cmake")
            include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/deployment/EnhancedQtDeploy.cmake")
            deploy_qt_enhanced(${PROJECT_NAME})
        else()
            message(FATAL_ERROR "EnhancedQtDeploy.cmake not found")
        endif()

        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deployment/PruneInstall.cmake")
            install(SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deployment/PruneInstall.cmake")
        else()
            message(FATAL_ERROR "PruneInstall.cmake not found")
        endif()
    else()
        message(STATUS "Skipping Qt deploy script on this platform")
    endif()
else()
    message(STATUS "Qt deploy script generation disabled")
endif()

# MinGW runtime and Boost DLL deployment
if(WIN32 AND MINGW)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/deployment/MinGWDeploy.cmake")
        include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/deployment/MinGWDeploy.cmake")
        deploy_mingw_and_boost(${PROJECT_NAME})
    else()
        message(WARNING "MinGWDeploy.cmake not found - MinGW runtime DLLs may be missing")
    endif()
endif()

# Setup install_local target with post-build optimization
setup_install_local_target(${PROJECT_NAME})
add_context_menu_dependency(${PROJECT_NAME})
