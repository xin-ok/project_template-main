set(CPACK_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")
set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
set(CPACK_PACKAGE_VERSION "${PROJECT_VERSION}")

# ============================================================
#  👇 自定义打包信息
# ============================================================
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "MyApplication")
set(CPACK_PACKAGE_VENDOR "MyCompany")
# ============================================================

if(CMAKE_BUILD_TYPE)
    set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_NAME}-${CMAKE_BUILD_TYPE}")
else()
    set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CMAKE_SYSTEM_NAME}")
endif()

if(WIN32)
    set(CPACK_GENERATOR "ZIP")
else()
    set(CPACK_GENERATOR "TGZ")
endif()
set(CPACK_OUTPUT_FILE_PREFIX "${PROJECT_SOURCE_DIR}/packages")

include(CPack)