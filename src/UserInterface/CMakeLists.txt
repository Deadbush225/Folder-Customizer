set(SUBDIR_NAME UserInterface)

# Remove GLOB_RECURSE for headers - they shouldn't be in add_library sources
add_library(${SUBDIR_NAME} OBJECT
    ${CMAKE_CURRENT_SOURCE_DIR}/subclass.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/window.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/cli.cpp
)

target_include_directories(${SUBDIR_NAME} PRIVATE ${PROJECT_SOURCE_DIR}/Include)
target_link_libraries(${SUBDIR_NAME} PRIVATE Customizer Qt6::Widgets Qt6::Core)

# Make sure Boost headers are visible on Windows (vcpkg or Chocolatey layouts)
if(WIN32)
    if(DEFINED BOOST_ROOT)
        if(EXISTS "${BOOST_ROOT}/include/boost")
            target_include_directories(${SUBDIR_NAME} PRIVATE "${BOOST_ROOT}/include")
        endif()

        if(EXISTS "${BOOST_ROOT}/boost")
            target_include_directories(${SUBDIR_NAME} PRIVATE "${BOOST_ROOT}")
        endif()
    endif()

    if(DEFINED ENV{VCPKG_INSTALLATION_ROOT})
        set(_VCPKG_INC "$ENV{VCPKG_INSTALLATION_ROOT}/installed/x64-windows/include")

        if(EXISTS "${_VCPKG_INC}/boost")
            target_include_directories(${SUBDIR_NAME} PRIVATE "${_VCPKG_INC}")
        endif()
    endif()
endif()

if(BOOST_AVAILABLE)
    target_compile_definitions(${SUBDIR_NAME} PRIVATE HAVE_BOOST_PROGRAM_OPTIONS=1)
    u_include_and_link_compiled_boost(${SUBDIR_NAME} program_options)
else()
    target_compile_definitions(${SUBDIR_NAME} PRIVATE HAVE_BOOST_PROGRAM_OPTIONS=0)
endif()
