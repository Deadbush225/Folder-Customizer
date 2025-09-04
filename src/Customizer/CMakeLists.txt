set(SUBDIR_NAME Customizer)

add_library(${SUBDIR_NAME} OBJECT
    ${CMAKE_CURRENT_SOURCE_DIR}/icon_refresher.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/tagger.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/folderCustomizer.cpp)

target_link_libraries(${SUBDIR_NAME} PRIVATE Qt6::Core)
