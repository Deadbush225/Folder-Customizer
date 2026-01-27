# MinGW Runtime DLL Deployment
# Automatically finds and deploys MinGW runtime DLLs (libgcc, libstdc++, libwinpthread)
# and Boost DLLs to the installation directory

function(deploy_mingw_runtime PROJECT_NAME)
    if(NOT WIN32 OR NOT MINGW)
        message(STATUS "MinGW runtime deployment only needed on Windows with MinGW")
        return()
    endif()

    message(STATUS "=== MinGW Runtime DLL Deployment for ${PROJECT_NAME} ===")

    # Search paths for MinGW runtime DLLs
    set(MINGW_SEARCH_PATHS)
    
    # Add compiler binary directory
    get_filename_component(MINGW_BIN_DIR ${CMAKE_CXX_COMPILER} DIRECTORY)
    list(APPEND MINGW_SEARCH_PATHS "${MINGW_BIN_DIR}")
    message(STATUS "MinGW compiler bin directory: ${MINGW_BIN_DIR}")
    
    # Add Qt bin directory (Qt bundles MinGW runtime)
    get_target_property(QT_QMAKE_EXECUTABLE Qt6::qmake IMPORTED_LOCATION)
    if(QT_QMAKE_EXECUTABLE)
        get_filename_component(QT_BIN_DIR ${QT_QMAKE_EXECUTABLE} DIRECTORY)
        list(APPEND MINGW_SEARCH_PATHS "${QT_BIN_DIR}")
        message(STATUS "Qt bin directory: ${QT_BIN_DIR}")
    endif()
    
    # Add common MinGW locations
    list(APPEND MINGW_SEARCH_PATHS
        "C:/msys64/mingw64/bin"
        "C:/mingw64/bin"
    )

    # List of required MinGW runtime DLLs
    set(MINGW_RUNTIME_DLLS
        libgcc_s_seh-1.dll
        libstdc++-6.dll
        libwinpthread-1.dll
    )

    # Find and install each DLL
    set(DLLS_TO_INSTALL)
    foreach(dll_name IN LISTS MINGW_RUNTIME_DLLS)
        set(dll_found FALSE)
        
        foreach(search_path IN LISTS MINGW_SEARCH_PATHS)
            set(dll_path "${search_path}/${dll_name}")
            if(EXISTS "${dll_path}")
                file(TO_CMAKE_PATH "${dll_path}" dll_path_normalized)
                list(APPEND DLLS_TO_INSTALL "${dll_path_normalized}")
                message(STATUS "✓ Found ${dll_name} at ${search_path}")
                set(dll_found TRUE)
                break()
            endif()
        endforeach()
        
        if(NOT dll_found)
            message(WARNING "✗ Not found: ${dll_name}")
        endif()
    endforeach()

    # Install MinGW runtime DLLs
    if(DLLS_TO_INSTALL)
        list(REMOVE_DUPLICATES DLLS_TO_INSTALL)
        list(LENGTH DLLS_TO_INSTALL dll_count)
        install(FILES ${DLLS_TO_INSTALL} DESTINATION ${CMAKE_INSTALL_BINDIR})
        message(STATUS "Will install ${dll_count} MinGW runtime DLLs to ${CMAKE_INSTALL_BINDIR}")
    else()
        message(WARNING "No MinGW runtime DLLs found for deployment")
    endif()
endfunction()

function(deploy_boost_runtime)
    if(NOT WIN32)
        message(STATUS "Boost DLL deployment only needed on Windows")
        return()
    endif()

    # Check if Boost is statically linked
    if(Boost_USE_STATIC_LIBS)
        message(STATUS "Using static Boost linking - no DLL deployment needed")
        return()
    endif()

    message(STATUS "=== Boost DLL Deployment ===")

    # Search paths for Boost DLLs
    set(BOOST_SEARCH_PATHS)

    # Add Boost library directories if available
    if(Boost_LIBRARY_DIRS)
        list(APPEND BOOST_SEARCH_PATHS ${Boost_LIBRARY_DIRS})
    endif()

    # Add BOOST_ROOT paths
    if(BOOST_ROOT)
        list(APPEND BOOST_SEARCH_PATHS
            "${BOOST_ROOT}/lib"
            "${BOOST_ROOT}/stage/lib"
            "${BOOST_ROOT}/bin"
        )
    endif()

    # Add compiler bin directory (MinGW often has Boost DLLs here)
    if(MINGW)
        get_filename_component(MINGW_BIN_DIR ${CMAKE_CXX_COMPILER} DIRECTORY)
        list(APPEND BOOST_SEARCH_PATHS "${MINGW_BIN_DIR}")
    endif()

    # Add system paths
    list(APPEND BOOST_SEARCH_PATHS
        "C:/local/boost*/lib*"
        "C:/tools/boost*/lib*"
        "C:/msys64/mingw64/lib"
        "C:/msys64/mingw64/bin"
    )

    # Search for Boost program_options DLL
    set(BOOST_DLLS_TO_INSTALL)
    
    foreach(search_path IN LISTS BOOST_SEARCH_PATHS)
        file(GLOB found_dlls
            "${search_path}/libboost_program_options*.dll"
            "${search_path}/boost_program_options*.dll"
        )

        if(found_dlls)
            foreach(dll IN LISTS found_dlls)
                get_filename_component(dll_name "${dll}" NAME)
                
                # Filter out debug DLLs in release builds
                if(CMAKE_BUILD_TYPE STREQUAL "Release" OR NOT CMAKE_BUILD_TYPE)
                    if(NOT dll_name MATCHES ".*d\\.dll$" AND NOT dll_name MATCHES ".*-gd-.*\\.dll$")
                        list(APPEND BOOST_DLLS_TO_INSTALL "${dll}")
                        message(STATUS "✓ Found Boost program_options DLL: ${dll}")
                    endif()
                else()
                    list(APPEND BOOST_DLLS_TO_INSTALL "${dll}")
                    message(STATUS "✓ Found Boost program_options DLL: ${dll}")
                endif()
            endforeach()
            
            if(BOOST_DLLS_TO_INSTALL)
                break()  # Found what we need, stop searching
            endif()
        endif()
    endforeach()

    # Install Boost DLLs
    if(BOOST_DLLS_TO_INSTALL)
        list(REMOVE_DUPLICATES BOOST_DLLS_TO_INSTALL)
        
        # Normalize paths to forward slashes to avoid escaping issues
        set(BOOST_DLLS_NORMALIZED)
        foreach(dll IN LISTS BOOST_DLLS_TO_INSTALL)
            file(TO_CMAKE_PATH "${dll}" dll_normalized)
            list(APPEND BOOST_DLLS_NORMALIZED "${dll_normalized}")
        endforeach()
        
        install(FILES ${BOOST_DLLS_NORMALIZED} DESTINATION ${CMAKE_INSTALL_BINDIR})
        message(STATUS "Will install Boost DLLs to ${CMAKE_INSTALL_BINDIR}")
    else()
        message(STATUS "No Boost DLLs found - likely using static linking or system Boost")
    endif()
endfunction()

# Combined deployment function
function(deploy_mingw_and_boost PROJECT_NAME)
    deploy_mingw_runtime(${PROJECT_NAME})
    deploy_boost_runtime()
endfunction()

message(STATUS "MinGW deployment utilities loaded")
