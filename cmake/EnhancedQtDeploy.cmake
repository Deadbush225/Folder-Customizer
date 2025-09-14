# Enhanced Qt Deployment with Diagnostics and Fallback
# This script provides comprehensive Qt deployment with multiple detection methods

function(deploy_qt_enhanced PROJECT_NAME)
    if(NOT WIN32)
        message(STATUS "Qt deployment only needed on Windows")
        return()
    endif()

    message(STATUS "=== Enhanced Qt Deployment for ${PROJECT_NAME} ===")

    # Method 1: Try Qt6::qmake approach (current method)
    get_target_property(QT_QMAKE_EXECUTABLE Qt6::qmake IMPORTED_LOCATION)
    set(WINDEPLOYQT_FOUND FALSE)
    set(WINDEPLOYQT_PATH "")

    if(QT_QMAKE_EXECUTABLE)
        get_filename_component(QT_BIN_DIR ${QT_QMAKE_EXECUTABLE} DIRECTORY)
        set(QT_WINDEPLOYQT_CANDIDATE "${QT_BIN_DIR}/windeployqt.exe")

        if(EXISTS ${QT_WINDEPLOYQT_CANDIDATE})
            set(WINDEPLOYQT_FOUND TRUE)
            set(WINDEPLOYQT_PATH ${QT_WINDEPLOYQT_CANDIDATE})
            message(STATUS "✓ Method 1: Found windeployqt via Qt6::qmake: ${WINDEPLOYQT_PATH}")
        else()
            message(STATUS "✗ Method 1: windeployqt not found at: ${QT_WINDEPLOYQT_CANDIDATE}")
        endif()
    else()
        message(STATUS "✗ Method 1: Qt6::qmake target not available")
    endif()

    # Method 2: Try Qt installation directories
    if(NOT WINDEPLOYQT_FOUND)
        message(STATUS "Trying Method 2: Qt installation paths...")

        # Get Qt installation path from any Qt target
        get_target_property(QT_CORE_LOCATION Qt6::Core IMPORTED_LOCATION_RELEASE)

        if(NOT QT_CORE_LOCATION)
            get_target_property(QT_CORE_LOCATION Qt6::Core IMPORTED_LOCATION)
        endif()

        if(QT_CORE_LOCATION)
            get_filename_component(QT_LIB_DIR ${QT_CORE_LOCATION} DIRECTORY)
            get_filename_component(QT_ROOT_DIR ${QT_LIB_DIR} DIRECTORY)
            set(QT_WINDEPLOYQT_CANDIDATE "${QT_ROOT_DIR}/bin/windeployqt.exe")

            if(EXISTS ${QT_WINDEPLOYQT_CANDIDATE})
                set(WINDEPLOYQT_FOUND TRUE)
                set(WINDEPLOYQT_PATH ${QT_WINDEPLOYQT_CANDIDATE})
                message(STATUS "✓ Method 2: Found windeployqt via Qt6::Core: ${WINDEPLOYQT_PATH}")
            else()
                message(STATUS "✗ Method 2: windeployqt not found at: ${QT_WINDEPLOYQT_CANDIDATE}")
            endif()
        endif()
    endif()

    # Method 3: Try PATH search with more extensive hints
    if(NOT WINDEPLOYQT_FOUND)
        message(STATUS "Trying Method 3: Extensive PATH search...")

        find_program(QT_WINDEPLOYQT_SEARCH
            NAMES windeployqt.exe windeployqt
            HINTS
            $ENV{Qt6_DIR}/bin
            $ENV{Qt6_ROOT}/bin
            $ENV{QTDIR}/bin
            $ENV{QT_DIR}/bin
            $ENV{CMAKE_PREFIX_PATH}
            PATHS
            "C:/Qt/6.*/*/bin"
            "C:/Qt6/bin"
            "C:/tools/Qt/6.*/*/bin"
            NO_DEFAULT_PATH
        )

        if(QT_WINDEPLOYQT_SEARCH)
            set(WINDEPLOYQT_FOUND TRUE)
            set(WINDEPLOYQT_PATH ${QT_WINDEPLOYQT_SEARCH})
            message(STATUS "✓ Method 3: Found windeployqt via find_program: ${WINDEPLOYQT_PATH}")
        else()
            message(STATUS "✗ Method 3: windeployqt not found in PATH")
        endif()
    endif()

    # If still not found, try manual Qt DLL deployment
    if(NOT WINDEPLOYQT_FOUND)
        message(WARNING "❌ windeployqt not found anywhere - attempting manual Qt DLL deployment")
        deploy_qt_manual_fallback(${PROJECT_NAME})
        return()
    endif()

    # Deploy Qt with comprehensive error handling
    install(CODE "
        message(STATUS \"=== Qt Deployment Execution ===\")
        message(STATUS \"Using windeployqt: ${WINDEPLOYQT_PATH}\")
        
        # Use CMAKE_INSTALL_PREFIX which may be overridden at install time (e.g., by install_local)
        message(STATUS \"Install prefix: \${CMAKE_INSTALL_PREFIX}\")
        message(STATUS \"Target executable: \${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/${PROJECT_NAME}.exe\")
        
        # Verify executable exists before deployment
        if(NOT EXISTS \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/${PROJECT_NAME}.exe\")
            message(FATAL_ERROR \"Target executable not found: \${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/${PROJECT_NAME}.exe\")
        endif()
        
        # Run windeployqt with comprehensive logging
        execute_process(
            COMMAND \"${WINDEPLOYQT_PATH}\" 
                --release 
                --no-translations 
                --no-system-d3d-compiler 
                --no-opengl-sw 
                --no-compiler-runtime
                --verbose 2
                --dir \"\${CMAKE_INSTALL_PREFIX}\" 
                \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/${PROJECT_NAME}.exe\"
            WORKING_DIRECTORY \"\${CMAKE_INSTALL_PREFIX}\"
            RESULT_VARIABLE DEPLOY_RESULT
            OUTPUT_VARIABLE DEPLOY_OUTPUT
            ERROR_VARIABLE DEPLOY_ERROR
            TIMEOUT 300
        )
        
        message(STATUS \"=== Deployment Results ===\")
        message(STATUS \"Result code: \${DEPLOY_RESULT}\")
        
        if(DEPLOY_OUTPUT)
            message(STATUS \"Output: \${DEPLOY_OUTPUT}\")
        endif()
        
        if(DEPLOY_ERROR)
            message(STATUS \"Error output: \${DEPLOY_ERROR}\")
        endif()
        
        if(NOT DEPLOY_RESULT EQUAL 0)
            message(FATAL_ERROR \"❌ Qt deployment failed with code \${DEPLOY_RESULT}\")
        endif()
        
        # Verify Qt DLLs were actually deployed
        file(GLOB QT_DLLS \"\${CMAKE_INSTALL_PREFIX}/Qt6*.dll\" \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/Qt6*.dll\")
        list(LENGTH QT_DLLS QT_DLL_COUNT)
        
        if(QT_DLL_COUNT EQUAL 0)
            message(FATAL_ERROR \"❌ No Qt DLLs found after deployment - deployment may have failed silently\")
        else()
            message(STATUS \"✓ Qt deployment successful - found \${QT_DLL_COUNT} Qt DLLs\")
            foreach(dll IN LISTS QT_DLLS)
                message(STATUS \"  - \${dll}\")
            endforeach()
        endif()
    ")
endfunction()

# Fallback manual Qt DLL deployment
function(deploy_qt_manual_fallback PROJECT_NAME)
    message(STATUS "Attempting manual Qt DLL deployment...")

    install(CODE "
        # Find Qt DLLs from the Qt installation
        get_target_property(QT_CORE_LOCATION Qt6::Core IMPORTED_LOCATION_RELEASE)
        if(NOT QT_CORE_LOCATION)
            get_target_property(QT_CORE_LOCATION Qt6::Core IMPORTED_LOCATION)
        endif()
        
        if(QT_CORE_LOCATION)
            get_filename_component(QT_DLL_DIR \${QT_CORE_LOCATION} DIRECTORY)
            
            # Copy essential Qt DLLs manually
            set(ESSENTIAL_QT_DLLS
                Qt6Core.dll
                Qt6Gui.dll  
                Qt6Widgets.dll
            )
            
            set(COPIED_COUNT 0)
            foreach(dll_name IN LISTS ESSENTIAL_QT_DLLS)
                set(dll_path \"\${QT_DLL_DIR}/\${dll_name}\")
                if(EXISTS \"\${dll_path}\")
                    file(COPY \"\${dll_path}\" DESTINATION \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}\")
                    message(STATUS \"✓ Copied \${dll_name}\")
                    math(EXPR COPIED_COUNT \"\${COPIED_COUNT} + 1\")
                else()
                    message(STATUS \"✗ Not found: \${dll_path}\")
                endif()
            endforeach()
            
            if(COPIED_COUNT GREATER 0)
                message(STATUS \"✓ Manual Qt deployment completed - copied \${COPIED_COUNT} DLLs\")
            else()
                message(FATAL_ERROR \"❌ Manual Qt deployment failed - no DLLs found\")
            endif()
        else()
            message(FATAL_ERROR \"❌ Cannot locate Qt installation for manual deployment\")
        endif()
    ")
endfunction()
