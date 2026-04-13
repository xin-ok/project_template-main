set(app_name bench_math)

add_executable(${app_name} ${app_name}.cc)

set_target_properties(${app_name} PROPERTIES
    VS_DEBUGGER_WORKING_DIRECTORY ${MSVC_DEBUGGER_DIR}
    DEBUG_POSTFIX "d"
)

set_target_properties(${app_name} PROPERTIES FOLDER benchmarks)

target_link_libraries(${app_name} 
PRIVATE 
    benchmark::benchmark
)



