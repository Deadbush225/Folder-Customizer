set(SUBDIR_NAME UserInterface)

file(GLOB_RECURSE HEADERS_IN ${CMAKE_SOURCE_DIR}/Include/UserInterface/*.h)

add_library(${SUBDIR_NAME} OBJECT
${CMAKE_CURRENT_SOURCE_DIR}/subclass.cpp
${CMAKE_CURRENT_SOURCE_DIR}/window.cpp
${HEADERS_IN}
)

target_link_libraries(${SUBDIR_NAME} PRIVATE Customizer Qt6::Widgets Qt6::Core)
target_include_directories(${SUBDIR_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/Include/UserInterface)

utility_include_and_link_boost(${SUBDIR_NAME})