# Boost configuration and detection
# Handles both Windows custom builds and system Boost on Linux/MinGW
# Exports: BOOST_AVAILABLE, Boost_INCLUDE_DIRS, Boost_LIBRARIES

# Force use of FindBoost module instead of BoostConfig for better compatibility
set(Boost_NO_BOOST_CMAKE ON)
set(Boost_NO_SYSTEM_PATHS OFF)

# Configure Boost based on compiler and platform
if(MINGW)
    # Always use FindBoost module for MinGW (most Boost builds don't have CMake config files)
    if(DEFINED Boost_ROOT AND NOT Boost_ROOT STREQUAL "")
        message(STATUS "MinGW with custom Boost_ROOT: ${Boost_ROOT}")
        # Set Boost hints for FindBoost module
        set(BOOST_ROOT ${Boost_ROOT})
        set(BOOST_INCLUDEDIR ${Boost_ROOT})
        set(BOOST_LIBRARYDIR ${Boost_ROOT}/stage/lib)
    else()
        message(STATUS "MinGW detected - using system Boost")
    endif()
    # Ensure FindBoost module is used (redundant but explicit)
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

# Prefer static libs for distribution packages to avoid version conflicts
if(MINGW)
    set(Boost_USE_STATIC_LIBS ON)
    # set(Boost_USE_STATIC_RUNTIME ON)
    message(STATUS "MinGW: Forcing static Boost linking")
elseif(NOT WIN32)
    set(Boost_USE_STATIC_LIBS ON)
endif()

# Try to find Boost first
find_package(Boost REQUIRED COMPONENTS program_options)

# set BOOST_AVAILABLE to TRUE IF BOOST ROOT IS DEFINED AND program_options IS FOUND
if(DEFINED Boost_FOUND AND Boost_FOUND)
    set(BOOST_AVAILABLE TRUE)
    message(STATUS "Boost found: ${Boost_INCLUDE_DIRS}, Libraries: ${Boost_LIBRARIES}")
else()
    set(BOOST_AVAILABLE FALSE)
    message(WARNING "Boost not found or program_options component missing")
endif()

# Expose Boost availability to all targets as a macro
if(BOOST_AVAILABLE)
    add_compile_definitions(HAVE_BOOST_PROGRAM_OPTIONS=1)
else()
    add_compile_definitions(HAVE_BOOST_PROGRAM_OPTIONS=0)
endif()

message(STATUS "Boost configuration complete: BOOST_AVAILABLE=${BOOST_AVAILABLE}")
