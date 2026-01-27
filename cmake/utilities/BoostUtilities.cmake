# Boost linking and header inclusion utilities
# Provides functions to link and include Boost libraries in targets
# Functions: u_include_header_only_boost(), u_include_and_link_compiled_boost()

# Include Boost headers only (for header-only components)
function(u_include_header_only_boost SUBDIR_NAME)
    if(BOOST_AVAILABLE)
        message("Including Boost Headers for ${SUBDIR_NAME}...")

        if(WIN32 AND DEFINED BOOST_ROOT)
            if(EXISTS "${BOOST_ROOT}/include/boost")
                target_include_directories(${SUBDIR_NAME} PRIVATE "${BOOST_ROOT}/include")
            endif()

            if(EXISTS "${BOOST_ROOT}/boost")
                target_include_directories(${SUBDIR_NAME} PRIVATE "${BOOST_ROOT}")
            endif()
        else()
            target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS})
        endif()
    endif()
endfunction()

# Include Boost headers and link compiled Boost libraries
function(u_include_and_link_compiled_boost SUBDIR_NAME BOOST_COMPONENT)
    if(BOOST_AVAILABLE)
        message("Linking Boost ${BOOST_COMPONENT} for ${SUBDIR_NAME}...")

        if(WIN32 AND DEFINED BOOST_ROOT AND NOT MINGW)
            # Custom Boost build (MSVC)
            if(EXISTS "${BOOST_ROOT}/include/boost")
                target_include_directories(${SUBDIR_NAME} PRIVATE "${BOOST_ROOT}/include")
            endif()

            if(EXISTS "${BOOST_ROOT}/boost")
                target_include_directories(${SUBDIR_NAME} PRIVATE "${BOOST_ROOT}")
            endif()

            target_link_libraries(${SUBDIR_NAME} PUBLIC "boost_${BOOST_COMPONENT}")
        else()
            # System Boost (Linux or MinGW)
            if(DEFINED Boost_INCLUDE_DIRS)
                target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS})
            endif()

            if(TARGET Boost::${BOOST_COMPONENT})
                target_link_libraries(${SUBDIR_NAME} PUBLIC Boost::${BOOST_COMPONENT})
            elseif(TARGET ${BOOST_COMPONENT})
                target_link_libraries(${SUBDIR_NAME} PUBLIC ${BOOST_COMPONENT})
            else()
                # Try linking with library name directly
                target_link_libraries(${SUBDIR_NAME} PUBLIC "boost_${BOOST_COMPONENT}")
            endif()
        endif()
    endif()
endfunction()

# Link Boost program_options to a target (convenience wrapper)
function(u_link_boost_program_options TARGET_NAME)
    u_include_and_link_compiled_boost(${TARGET_NAME} "program_options")
endfunction()

message(STATUS "Boost utilities loaded")
