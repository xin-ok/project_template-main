add_subdirectory(project_test)
add_subdirectory(static_lib)
add_subdirectory(shared_lib)
add_subdirectory(project_lib_test)

#===================== export ======================
install(EXPORT ${export_name}Targets
    FILE ${export_name}Targets.cmake
    NAMESPACE ${export_name}::                 
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${export_name}
)

configure_package_config_file(
    ${PROJECT_SOURCE_DIR}/cmake/${export_name}Config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/${export_name}Config.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${export_name}
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${export_name}Config.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${export_name}
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/${export_name}ConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${export_name}ConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${export_name}
)
