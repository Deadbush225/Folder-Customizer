cmake_minimum_required(VERSION 3.10)

set(ContextMenuDll FCContextMenuHandler)

# Set the project name and type
project(${ContextMenuDll} LANGUAGES CXX)

# Specify the target architecture
if(NOT CMAKE_GENERATOR_PLATFORM)
    set(CMAKE_GENERATOR_PLATFORM x64)
endif()

# Add the library
add_library(${ContextMenuDll} SHARED
    dllmain.cpp
    FileContextMenuExt.cpp
    FileContextMenuExt.h
    Reg.h
    Reg.cpp
    ClassFactory.cpp
    ClassFactory.h
    GlobalExportFunctions.def
)

# Set the C++ standard
set_target_properties(${ContextMenuDll} PROPERTIES
    CXX_STANDARD 11
    CXX_STANDARD_REQUIRED YES
    CXX_EXTENSIONS NO
)

# Include directories
include_directories(${ContextMenuDll} PRIVATE ${PROJECT_SOURCE_DIR}/../../Include)

message(${PROJECT_SOURCE_DIR}/../../Include)

# Define UNICODE and _UNICODE to ensure Unicode API is used
target_compile_definitions(${ContextMenuDll} PRIVATE UNICODE _UNICODE)

# Link libraries (if any)
target_link_libraries(${ContextMenuDll} shlwapi shell32 pathcch gdiplus)

# Install the context menu library
install(TARGETS ${ContextMenuDll} DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT Prerequisites)
