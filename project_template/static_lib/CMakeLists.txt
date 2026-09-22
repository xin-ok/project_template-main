add_library(static_lib
STATIC
    static_lib.h
    static_lib.cc
)

target_include_directories(static_lib
PRIVATE
    ${PROJECT_SOURCE_DIR}/project_template
)

set_target_properties(static_lib PROPERTIES FOLDER "project_template")

install(TARGETS static_lib
    EXPORT ${export_name}Targets 
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(FILES static_lib.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/static_lib
)
