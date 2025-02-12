set(SUBDIR_NAME Core)

add_library(${SUBDIR_NAME} OBJECT ${CMAKE_CURRENT_SOURCE_DIR}/registry.cpp)

target_include_directories(${SUBDIR_NAME} PUBLIC ../../../Include/Core)
target_link_libraries(${SUBDIR_NAME} PRIVATE Qt6::Core)

if(Boost_FOUND)
    message("Boost Found...")
    target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS})
    target_link_libraries(${SUBDIR_NAME} PUBLIC Boost::program_options)
    # target_link_libraries(${PROJECT_NAME} PUBLIC Boost::boost)
endif()