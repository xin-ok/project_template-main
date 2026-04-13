set(app_name print_hello)

add_executable(${app_name} ${app_name}.cc)

set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} 
    PROPERTY VS_STARTUP_PROJECT ${app_name}
)

set_target_properties(${app_name} PROPERTIES
    VS_DEBUGGER_WORKING_DIRECTORY ${MSVC_DEBUGGER_DIR} # "$(TargetDir)"
    DEBUG_POSTFIX "d"
)

set_target_properties(${app_name} PROPERTIES FOLDER ${CMAKE_PROJECT_NAME})

add_test(NAME ${app_name}
    COMMAND ${app_name}
    WORKING_DIRECTORY $<TARGET_FILE_DIR:${app_name}>
)

install(TARGETS ${app_name}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
) 

if(WIN32)
    install(FILES $<TARGET_PDB_FILE:${app_name}>
        DESTINATION ${CMAKE_INSTALL_BINDIR}
        CONFIGURATIONS Debug
        OPTIONAL
    )
endif()