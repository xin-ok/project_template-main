add_library(shared_lib
SHARED
    pch.h
    shared_lib_export.h
    shared_lib.h
    shared_lib.cc
)

target_precompile_headers(shared_lib 
PRIVATE 
    pch.h
)

target_include_directories(shared_lib
PRIVATE
    ${PROJECT_SOURCE_DIR}/project_template
)

target_compile_definitions(shared_lib
PRIVATE
    SHAREDLIB_EXPORT
)

set_target_properties(shared_lib PROPERTIES FOLDER "project_template")

install(TARGETS shared_lib
    EXPORT ${export_name}Targets 
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(FILES pch.h shared_lib.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/shared_lib
)

if(WIN32)
    install(FILES $<TARGET_PDB_FILE:shared_lib>
        DESTINATION ${CMAKE_INSTALL_BINDIR}
        CONFIGURATIONS Debug
        OPTIONAL
    )
endif()
