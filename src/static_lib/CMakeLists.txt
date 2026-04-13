set(app_name static_lib)

add_library(${app_name}
STATIC
    ${app_name}.h
    ${app_name}.cc
)

set_target_properties(${app_name} PROPERTIES FOLDER ${CMAKE_PROJECT_NAME})

install(TARGETS ${app_name}
    EXPORT ${export_name}Targets 
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(FILES ${app_name}.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${app_name}
)
