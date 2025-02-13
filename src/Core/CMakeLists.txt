set(SUBDIR_NAME Core)

add_library(${SUBDIR_NAME} OBJECT ${CMAKE_CURRENT_SOURCE_DIR}/registry.cpp)

target_link_libraries(${SUBDIR_NAME} PRIVATE Qt6::Core)
