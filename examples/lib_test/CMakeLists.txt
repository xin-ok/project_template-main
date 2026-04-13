set(app_name lib_test)

add_executable(${app_name} ${app_name}.cc)

target_link_libraries(${app_name}
PRIVATE
    project_template
)

set_target_properties(${app_name} PROPERTIES
    VS_DEBUGGER_WORKING_DIRECTORY ${MSVC_DEBUGGER_DIR}
    DEBUG_POSTFIX "d"
)

set_target_properties(${app_name} PROPERTIES FOLDER examples)

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
else()
    set_target_properties(${app_name} PROPERTIES
        INSTALL_RPATH "$ORIGIN/../lib"
    )
endif()

install(DIRECTORY ./
    DESTINATION example/${app_name}
    PATTERN "CMakeLists.txt"        EXCLUDE
    PATTERN "CMakeLists.install.txt" EXCLUDE)

install(FILES ./CMakeLists.install.txt
    DESTINATION example/${app_name}
    RENAME CMakeLists.txt)
