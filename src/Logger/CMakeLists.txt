set(SUBDIR_NAME Logger)

add_library(${SUBDIR_NAME} OBJECT ${CMAKE_CURRENT_SOURCE_DIR}/logger.cpp)

target_link_libraries(${SUBDIR_NAME} PRIVATE Qt6::Core)

u_include_header_only_boost(${SUBDIR_NAME})