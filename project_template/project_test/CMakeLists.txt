add_executable(project_test project_test.cc)

set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} 
    PROPERTY VS_STARTUP_PROJECT project_test
)

set_target_properties(project_test PROPERTIES
    VS_DEBUGGER_WORKING_DIRECTORY ${MSVC_DEBUGGER_DIR} # "$(TargetDir)"
    DEBUG_POSTFIX "d"
)

set_target_properties(project_test PROPERTIES FOLDER "project_template")

add_test(NAME project_test
    COMMAND project_test
    WORKING_DIRECTORY $<TARGET_FILE_DIR:project_test>
)

install(TARGETS project_test
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
) 

if(WIN32)
    install(FILES $<TARGET_PDB_FILE:project_test>
        DESTINATION ${CMAKE_INSTALL_BINDIR}
        CONFIGURATIONS Debug
        OPTIONAL
    )
endif()