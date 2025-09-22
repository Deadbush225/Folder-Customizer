# PruneInstall.cmake: Remove optional/duplicate DLLs and plugins, keep only /bin/ versions

# Helper to remove all files matching a glob
function(_rm_glob_bin_only pattern)
    file(GLOB _tmp ${pattern})

    foreach(_file IN LISTS _tmp)
        if(NOT _file MATCHES "/bin/")
            message(STATUS "Removing duplicate or non-bin: ${_file}")
            file(REMOVE "${_file}")
        endif()
    endforeach()
endfunction()

# Remove all DLLs and plugins outside /bin/
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/Qt6*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/lib*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/icudt*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/icuin*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/icuuc*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/d3dcompiler*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/D3DCompiler*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/dxcompiler*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/dxil*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/api-ms-*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/msvcp140*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/vcruntime140*.dll")
_rm_glob_bin_only("${CMAKE_INSTALL_PREFIX}/concrt140.dll")

# Remove unwanted plugin subfolders inside /bin/
file(GLOB _bin_plugin_dirs "${CMAKE_INSTALL_PREFIX}/bin/*")

foreach(_dir IN LISTS _bin_plugin_dirs)
    if(IS_DIRECTORY "${_dir}")
        if(_dir MATCHES "imageformats|bearer|networkinformation|sqldrivers|multimedia|qmltooling|quick|scenegraph|translations|generic|tls")
            message(STATUS "Removing plugin dir in bin: ${_dir}")
            file(REMOVE_RECURSE "${_dir}")
        endif()
    endif()
endforeach()

# Remove image format plugins we don't use (keep png and ico)
file(GLOB _img_unneeded_bin
    "${CMAKE_INSTALL_PREFIX}/bin/imageformats/qgif*.dll"
    "${CMAKE_INSTALL_PREFIX}/bin/imageformats/qjpeg*.dll"
    "${CMAKE_INSTALL_PREFIX}/bin/imageformats/qsvg*.dll"
)

if(_img_unneeded_bin)
    foreach(_file IN LISTS _img_unneeded_bin)
        message(STATUS "Removing image plugin: ${_file}")
        file(REMOVE "${_file}")
    endforeach()
endif()

# Remove Boost DLLs outside /bin/ and keep only needed in /bin/
file(GLOB _boost_dlls_bin "${CMAKE_INSTALL_PREFIX}/bin/*boost*.dll")
set(_needed_boost "program_options")

foreach(_dll IN LISTS _boost_dlls_bin)
    get_filename_component(_dll_name "${_dll}" NAME_WE)

    if(NOT _dll_name MATCHES ".*boost.*${_needed_boost}.*")
        message(STATUS "Removing unneeded Boost DLL: ${_dll}")
        file(REMOVE "${_dll}")
    endif()
endforeach()

message(STATUS "PruneInstall.cmake completed (bin-only, no duplicates, minimal Qt/Boost)")
