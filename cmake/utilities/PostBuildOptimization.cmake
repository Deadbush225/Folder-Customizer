# Post-build optimization utilities
# Handles binary stripping and UPX compression for reduced binary size

# Install local target configuration
function(setup_install_local_target PROJECT_NAME)
    if(WIN32)
        set(INSTALL_LOCAL_DIR "${CMAKE_SOURCE_DIR}/dist/windows")
    else()
        set(INSTALL_LOCAL_DIR "${CMAKE_SOURCE_DIR}/dist/linux")
    endif()

    add_custom_target(install_local
        # Incremental install: Do NOT wipe the directory
        COMMAND ${CMAKE_COMMAND} -E make_directory "${INSTALL_LOCAL_DIR}"
        COMMAND ${CMAKE_COMMAND} --install "${CMAKE_BINARY_DIR}" --config $<IF:$<BOOL:$<CONFIG>>,$<CONFIG>,Release> --prefix "${INSTALL_LOCAL_DIR}"
        USES_TERMINAL
        COMMENT "Build + local install to ${INSTALL_LOCAL_DIR} (Incremental)"
    )

    add_dependencies(install_local ${PROJECT_NAME})

    # Add stripping and UPX compression for reduced size
    if(UNIX)
        find_program(STRIP_EXECUTABLE strip)

        if(STRIP_EXECUTABLE)
            add_custom_command(TARGET install_local POST_BUILD
                COMMAND find "${INSTALL_LOCAL_DIR}" -type f \( -name "FolderCustomizer" -o -name "eUpdater" -o -name "*.so*" \) -print -exec ${STRIP_EXECUTABLE} --strip-unneeded {} \\
                \;
                COMMENT "Stripping debug symbols from binaries and libraries"
                VERBATIM
            )
        endif()

        find_program(UPX_EXECUTABLE upx)

        if(UPX_EXECUTABLE)
            add_custom_command(TARGET install_local POST_BUILD
                COMMAND "${UPX_EXECUTABLE}" --best "${INSTALL_LOCAL_DIR}/${CMAKE_INSTALL_BINDIR}/FolderCustomizer"
                COMMENT "Compressing binaries with UPX"
                VERBATIM
            )
        endif()
    elseif(MINGW)
        find_program(STRIP_EXECUTABLE strip)

        if(STRIP_EXECUTABLE)
            add_custom_command(TARGET install_local POST_BUILD
                COMMAND ${STRIP_EXECUTABLE} --strip-unneeded "${INSTALL_LOCAL_DIR}/${CMAKE_INSTALL_BINDIR}/*.exe" 2>nul || echo "Strip completed"
                COMMENT "Stripping debug symbols from Windows binaries (MinGW)"
            )
        endif()

        find_program(UPX_EXECUTABLE upx)

        if(UPX_EXECUTABLE)
            add_custom_command(TARGET install_local POST_BUILD
                COMMAND ${UPX_EXECUTABLE} --best "${INSTALL_LOCAL_DIR}/${CMAKE_INSTALL_BINDIR}/*.exe" 2>nul || echo "UPX completed"
                COMMENT "Compressing Windows binaries with UPX (MinGW)"
            )
        endif()
    endif()
endfunction()

# Add context menu handler as dependency if available
macro(add_context_menu_dependency TARGET_NAME)
    if(TARGET FCContextMenuHandler)
        add_dependencies(install_local FCContextMenuHandler)
    endif()
endmacro()

message(STATUS "Post-build optimization utilities loaded")
