set(SUBDIR_NAME Utils)

add_library(${SUBDIR_NAME} STATIC ${CMAKE_CURRENT_SOURCE_DIR}/utils.cpp)

target_link_libraries(${SUBDIR_NAME} PRIVATE Qt6::Core)
target_include_directories(${SUBDIR_NAME} PUBLIC ../../../Include/Utils)