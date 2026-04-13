include_directories(${PROJECT_SOURCE_DIR}/src)

add_subdirectory(print_hello)
add_subdirectory(shared_lib)
add_subdirectory(static_lib)


add_library(${export_name} INTERFACE)

add_library(${export_name}::${export_name} ALIAS ${export_name})

target_link_libraries(${export_name}
INTERFACE
    shared_lib
    static_lib
)

target_include_directories(${export_name} INTERFACE
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

install(TARGETS ${export_name}
    EXPORT ${export_name}Targets
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

set_target_properties(${export_name} PROPERTIES FOLDER ${CMAKE_PROJECT_NAME})