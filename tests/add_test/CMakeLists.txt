set(app_name add_test)

add_executable(${app_name} ${app_name}.cc)

set_target_properties(${app_name} PROPERTIES
    VS_DEBUGGER_WORKING_DIRECTORY ${MSVC_DEBUGGER_DIR}
    DEBUG_POSTFIX "d"
)

set_target_properties(${app_name} PROPERTIES FOLDER tests)

add_test(NAME ${app_name}
    COMMAND ${app_name}
    WORKING_DIRECTORY $<TARGET_FILE_DIR:${app_name}>
)

target_link_libraries(${app_name} 
PRIVATE 
    gtest 
    gtest_main
    gmock
    gmock_main
)

gtest_discover_tests(${app_name}
    WORKING_DIRECTORY $<TARGET_FILE_DIR:${app_name}>
)

