cmake_minimum_required(VERSION 3.16)

if(POLICY CMP0167)
    cmake_policy(SET CMP0167 NEW)
endif()

set(Boost_ROOT D:/Dev/boost_1_87_0/stage)
set(CMAKE_PREFIX_PATH ${Boost_ROOT})

set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/packages/com.foldercustomizer/data)

project(FolderCustomizer VERSION 0.1.0)
set(PROJECT_NAME FolderCustomizer)
set(PROJECT_SOURCE ${CMAKE_SOURCE_DIR}/src)
message("\nPROJECT SOURCE: " ${PROJECT_SOURCE})

# Turn on automatic invocation of the MOC, UIC & RCC
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# set(Boost_USE_STATIC_LIBS OFF)
find_package(Qt6 REQUIRED COMPONENTS Widgets Core)
qt_standard_project_setup()
find_package(Boost REQUIRED COMPONENTS program_options)

# utility functions
function(u_include_header_only_boost SUBDIR_NAME)
    if(Boost_FOUND)
        message("Including Boost Headers ...")
        target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS})
    endif()
endfunction()

function(u_include_and_link_compiled_boost SUBDIR_NAME BOOST_COMPONENT)
    if(Boost_FOUND)
        message("Including Boost Headers ...")
        target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS}) # ? try to check if this is actually needed for compiled
        message("Linking Boost Libraries ...")
        target_link_libraries(${SUBDIR_NAME} PUBLIC ${BOOST_COMPONENT})
    endif()
endfunction()

include_directories(${PROJECT_SOURCE_DIR}/Include)

add_subdirectory(src/Core)
add_subdirectory(src/Logger)
add_subdirectory(src/Customizer)
add_subdirectory(src/Utils)
add_subdirectory(src/UserInterface)

add_subdirectory(src/context-menu)

set(SOURCE_FILES ${PROJECT_SOURCE}/main.cpp)

# binary's icon
set(app_icon_resource_windows "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Folder Customizer.rc")

add_executable(${PROJECT_NAME} ${SOURCE_FILES}
    ${app_icon_resource_windows}
    Icons/resource.qrc)

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    message("Removing Console...\n")
    set_property(TARGET ${PROJECT_NAME} PROPERTY WIN32_EXECUTABLE true)
endif()

set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "FolderCustomizer")

target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)

target_link_libraries(${PROJECT_NAME} PRIVATE Core Logger Utils Customizer UserInterface Qt6::Widgets Qt6::Core)

# installer
install(TARGETS ${PROJECT_NAME} BUNDLE DESTINATION . RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}) # move the executable

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/Icons DESTINATION ${CMAKE_INSTALL_BINDIR}) # move directory

# Move DLL to the installation folder
install(TARGETS FCContextMenuHandler DESTINATION ${CMAKE_INSTALL_BINDIR})

qt_generate_deploy_app_script(
    TARGET ${PROJECT_NAME} OUTPUT_SCRIPT deploy_script NO_TRANSLATIONS
) # create deploy script

install(SCRIPT ${deploy_script}) # run deploy script
