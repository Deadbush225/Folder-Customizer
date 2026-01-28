# Post-build optimization utilities
# Handles binary stripping and UPX compression for reduced binary size

# Install local target configuration
function(setup_install_local_target PROJECT_NAME)
    if(WIN32)
        set(INSTALL_LOCAL_DIR "${CMAKE_SOURCE_DIR}/dist/windows")
    else()
        set(INSTALL_LOCAL_DIR "${CMAKE_SOURCE_DIR}/dist/linux")
    endif()

    if(WIN32)
        add_custom_target(install_local
            COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_LOCAL_DIR}"
            # Install Application (Apps + Manifest) - Always
            COMMAND ${CMAKE_COMMAND} --install "${CMAKE_BINARY_DIR}" --config $<IF:$<BOOL:$<CONFIG>>,$<CONFIG>,Release> --prefix "${INSTALL_LOCAL_DIR}" --component Application
            # Install Prerequisites (DLLs, Icons, Qt) - Only if missing marker
            COMMAND if not exist "${INSTALL_LOCAL_DIR}/bin/Qt6Core.dll" ${CMAKE_COMMAND} --install "${CMAKE_BINARY_DIR}" --config $<IF:$<BOOL:$<CONFIG>>,$<CONFIG>,Release> --prefix "${INSTALL_LOCAL_DIR}" --component Prerequisites
            USES_TERMINAL
            COMMENT "Smart Install: Application (Always) + Prerequisites (Conditional)"
        )
    else()
        add_custom_target(install_local
            COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_LOCAL_DIR}"
            COMMAND ${CMAKE_COMMAND} --install "${CMAKE_BINARY_DIR}" --config $<IF:$<BOOL:$<CONFIG>>,$<CONFIG>,Release> --prefix "${INSTALL_LOCAL_DIR}"
            USES_TERMINAL
            COMMENT "Build + local install to ${INSTALL_LOCAL_DIR}"
        )
    endif()

    add_dependencies(install_local ${PROJECT_NAME})

    # Note: Stripping and UPX compression are intentionally excluded from 'install_local'
    # to support fast incremental builds and debugging. 
    # Use the 'package' or specific 'release' targets for optimized builds.

endfunction()

# Add context menu handler as dependency if available
macro(add_context_menu_dependency TARGET_NAME)
    if(TARGET FCContextMenuHandler)
        add_dependencies(install_local FCContextMenuHandler)
    endif()
endmacro()

message(STATUS "Post-build optimization utilities loaded")
