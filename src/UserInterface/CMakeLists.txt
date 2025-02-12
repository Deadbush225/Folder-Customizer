set(SUBDIR_NAME UserInterface)

file(GLOB_RECURSE HEADERS_IN ${CMAKE_SOURCE_DIR}/Include/UserInterface/*.h)

message("${CMAKE_SOURCE_DIR}/Include/UserInterface")
# message("Headers: ${HEADERS_IN}")

add_library(${SUBDIR_NAME} OBJECT
${CMAKE_CURRENT_SOURCE_DIR}/subclass.cpp
${CMAKE_CURRENT_SOURCE_DIR}/window.cpp
${HEADERS_IN}
)

target_link_libraries(${SUBDIR_NAME} PRIVATE Customizer Qt6::Widgets Qt6::Core)
target_include_directories(${SUBDIR_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/Include/UserInterface)

if(Boost_FOUND)
    message("Boost Found...")
    target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS})
    target_link_libraries(${SUBDIR_NAME} PUBLIC Boost::program_options)
    # target_link_libraries(${PROJECT_NAME} PUBLIC Boost::boost)
endif()