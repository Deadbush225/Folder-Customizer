set(SUBDIR_NAME Logger)


add_library(${SUBDIR_NAME} STATIC ${CMAKE_CURRENT_SOURCE_DIR}/logger.cpp)

target_link_libraries(${SUBDIR_NAME} PRIVATE Qt6::Core)
target_include_directories(${SUBDIR_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/Include/Logger)

if(Boost_FOUND)
    message("Boost Found...")
    target_include_directories(${SUBDIR_NAME} PRIVATE ${Boost_INCLUDE_DIRS})
    target_link_libraries(${SUBDIR_NAME} PUBLIC ${Boost_LIBRARIES})
    # target_link_libraries(${PROJECT_NAME} PUBLIC Boost::boost)
endif()