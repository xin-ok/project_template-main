cmake_minimum_required(VERSION 3.16)
# ============================================================
#  👇 自定义项目配置
# ============================================================
project(project_template VERSION 1.0.0)
set(export_name ProjectTemplate)
# ============================================================

include(cmake/PublicPreset.cmake)
include(cmake/PrivatePreset.cmake)
include(cmake/CPackPreset.cmake)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
enable_testing()

add_subdirectory(project_template)
