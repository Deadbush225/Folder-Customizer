cmake_minimum_required(VERSION 3.16)

project(FolderCustomizer VERSION 0.1.0)

# file(GLOB_RECURSE HELPER_FILES "/src/HELPER/*.cpp")
# file(GLOB_RECURSE INCLUDE_FILES "*.h")

# Find includes in the build directories
set(CMAKE_INCLUDE_CURRENT_DIR ON)

# Turn on automatic invocation of the MOC, UIC & RCC
set(CMAKE_AUTOMOC ON)
# set(CMAKE_AUTOUIC ON)
# set(CMAKE_AUTORCC ON)

set(Boost_USE_STATIC_LIBS OFF)

set(PROJECT_NAME FolderCustomizer)

find_package(Qt6 REQUIRED COMPONENTS Widgets)
find_package(Qt6 REQUIRED COMPONENTS Core)

# set(Boost_INCLUDE_DIRS, )

find_package(Boost 1.81.0)
# find_package(Boost 1.81.0 COMPONENTS format)

qt_standard_project_setup()

file(GLOB_RECURSE WINDOW "Window/*.cpp")
file(GLOB_RECURSE CUSTOMIZER "Customizer/*.cpp")
file(GLOB_RECURSE LOGGER "Logger/*.cpp")
file(GLOB_RECURSE REGISTRY "Registry/*.cpp")

set(SOURCE_FILES
${WINDOW}
${CUSTOMIZER}
${LOGGER}
${REGISTRY}
main.cpp
)

# add_executable(PrintingRates main.cpp DashboardWidget.cpp)
#---
message(${CMAKE_CURRENT_SOURCE_DIR})
set(app_icon_resource_windows "${CMAKE_CURRENT_SOURCE_DIR}/Icons/Folder Customizer.rc")
add_executable(${PROJECT_NAME} ${SOURCE_FILES} ${app_icon_resource_windows}
    "Icons/resource.qrc")

if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set_property(TARGET ${PROJECT_NAME} PROPERTY WIN32_EXECUTABLE true)
endif()

set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "Folder Customizer")

# set(INSTALLER_SOURCE_FILES "../Installer/installer.cpp")
# add_executable(Installer ${INSTALLER_SOURCE_FILES})
# include_directories("src/Utils" "Utils/")

# target_include_directories(${PROJECT_NAME} PRIVATE "src/Utils/")
# add_executable(Testsd ${SOURCE_FILES})
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)

target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Widgets)
target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Core)

if(Boost_FOUND)
    message("Boost Found...")
    target_include_directories(${PROJECT_NAME} PRIVATE ${Boost_INCLUDE_DIRS})
    target_link_libraries(${PROJECT_NAME} PUBLIC ${Boost_LIBRARIES})
    # target_link_libraries(${PROJECT_NAME} PUBLIC Boost::boost)
endif()

# target_compile_features(Installer PRIVATE cxx_std_20)

# target_link_libraries(Installer PRIVATE Qt6::Widgets)
# target_link_libraries(Installer PRIVATE Qt6::Core)

# target_link_libraries(Testsd PRIVATE Qt6::Widgets)
# target_link_libraries(Testsd PRIVATE Qt6::Core)

# set(CPACK_PROJECT_NAME ${PROJECT_NAME})
# set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})
# include(CPack)
