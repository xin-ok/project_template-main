set(app_name shared_lib)

add_library(${app_name}
SHARED
    pch.h
    ${app_name}_export.h
    ${app_name}.h
    ${app_name}.cc
)

target_precompile_headers(${app_name} 
PRIVATE 
    pch.h
)

target_compile_definitions(${app_name}
PRIVATE
    SHAREDLIB_EXPORT
)

set_target_properties(${app_name} PROPERTIES FOLDER ${CMAKE_PROJECT_NAME})

install(TARGETS ${app_name}
    EXPORT ${export_name}Targets 
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(FILES pch.h ${app_name}.h ${app_name}_export.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${app_name}
)

if(WIN32)
    install(FILES $<TARGET_PDB_FILE:${app_name}>
        DESTINATION ${CMAKE_INSTALL_BINDIR}
        CONFIGURATIONS Debug
        OPTIONAL
    )
endif()
