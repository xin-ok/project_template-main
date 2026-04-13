cmake_minimum_required(VERSION 3.14)
# ============================================================
#  👇 自定义项目配置
# ============================================================
project(project_template VERSION 1.0.0)
set(export_name project_template)
# ============================================================

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(FetchContent)

include(cmake/PublicPreset.cmake)
include(cmake/PrivatePreset.cmake)
include(cmake/CPackPreset.cmake)
include(cmake/Export.cmake)

enable_testing()

add_subdirectory(examples)
add_subdirectory(src)

if(${BUILD_TESTS})
    # use_thirdparty(googletest) 使用git submodule方式初始化
    FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG        v1.18.0
        GIT_SHALLOW    TRUE
    )
    FetchContent_MakeAvailable(googletest)
    include(GoogleTest)
    add_subdirectory(tests)
endif()

if(${BUILD_BENCHMARKS})
    # use_thirdparty(benchmark)
    # 关闭 benchmark 自带的测试/示例，避免污染 bin/ 并拖慢构建
    set(BENCHMARK_ENABLE_TESTING OFF CACHE BOOL "" FORCE)
    set(BENCHMARK_ENABLE_INSTALL OFF CACHE BOOL "" FORCE)
    set(BENCHMARK_ENABLE_GTEST_TESTS OFF CACHE BOOL "" FORCE)
    FetchContent_Declare(
        googlebenchmark
        GIT_REPOSITORY https://github.com/google/benchmark.git
        GIT_TAG        v1.10.0
    )
    FetchContent_MakeAvailable(googlebenchmark)
    add_subdirectory(benchmarks)
endif()
