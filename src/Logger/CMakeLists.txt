set(SUBDIR_NAME Logger)

add_library(${SUBDIR_NAME} OBJECT ${CMAKE_CURRENT_SOURCE_DIR}/logger.cpp)

target_link_libraries(${SUBDIR_NAME} PRIVATE Qt6::Core)
target_include_directories(${SUBDIR_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/Include/Logger)

target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS})
message(${Boost_INCLUDE_DIRS})