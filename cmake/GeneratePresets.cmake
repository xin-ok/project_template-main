# ============================================================================
#  GeneratePresets.cmake
#  自动检测当前环境并生成 CMakePresets.json
#
#  用法: cmake -P cmake/GeneratePresets.cmake
# ============================================================================

cmake_minimum_required(VERSION 3.10)

# ---- 辅助函数 ----

# 获取编译器完整版本号（如 14.2.0）
# GCC 用 -dumpfullversion，Clang 用 -dumpversion
function(get_compiler_version compiler_path var_name)
    if(compiler_path)
        # 先尝试 -dumpfullversion（GCC 7+ 支持，返回完整版本如 14.2.0）
        execute_process(
            COMMAND ${compiler_path} -dumpfullversion
            OUTPUT_VARIABLE version_full
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )
        if(version_full)
            set(${var_name} "${version_full}" PARENT_SCOPE)
        else()
            # 如果不支持（如 Clang），回退到 -dumpversion
            execute_process(
                COMMAND ${compiler_path} -dumpversion
                OUTPUT_VARIABLE version_raw
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_QUIET
            )
            set(${var_name} "${version_raw}" PARENT_SCOPE)
        endif()
    else()
        set(${var_name} "unknown" PARENT_SCOPE)
    endif()
endfunction()

# 获取 Ninja 路径（跨平台通用，优先 Ninja，找不到则回退到 Unix Makefiles）
function(find_ninja var_name)
    find_program(NINJA_PATH ninja)
    if(NINJA_PATH)
        set(${var_name} "Ninja" PARENT_SCOPE)
    else()
        set(${var_name} "" PARENT_SCOPE)
    endif()
endfunction()

# 生成编译器标识字符串（用于 preset 名称）
function(make_compiler_id compiler_type compiler_path var_name)
    if(compiler_path)
        get_compiler_version("${compiler_path}" ver)
        string(TOLOWER "${compiler_type}" type_lower)
        set(${var_name} "${type_lower}_${ver}" PARENT_SCOPE)
    else()
        set(${var_name} "" PARENT_SCOPE)
    endif()
endfunction()

# ---- Windows: 通过 vswhere 检测所有 Visual Studio 版本 ----

function(detect_all_visual_studio)
    # 查找 vswhere
    find_program(VSWHERE_PATH vswhere)
    if(NOT VSWHERE_PATH)
        # vswhere 通常不在 PATH 中，尝试常见安装路径
        set(VSWHERE_PATH "C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe")
        if(NOT EXISTS "${VSWHERE_PATH}")
            set(VSWHERE_PATH "")
        endif()
    endif()

    if(NOT VSWHERE_PATH)
        message(STATUS "  vswhere 未找到，无法检测 Visual Studio")
        return()
    endif()

    # 使用 -property 分别获取每个属性（按行对应）
    # 先获取安装路径列表
    execute_process(
        COMMAND "${VSWHERE_PATH}" -sort -products *
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64
            -property installationPath
        OUTPUT_VARIABLE VS_PATHS_RAW
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )

    if(NOT VS_PATHS_RAW)
        message(STATUS "  vswhere 未找到包含 C++ 工具链的 Visual Studio 安装")
        return()
    endif()

    # 获取产品线版本（如 2022）
    execute_process(
        COMMAND "${VSWHERE_PATH}" -sort -products *
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64
            -property catalog_productLineVersion
        OUTPUT_VARIABLE VS_YEARS_RAW
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )

    # 获取产品线标识（如 Dev17）
    execute_process(
        COMMAND "${VSWHERE_PATH}" -sort -products *
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64
            -property catalog_productLine
        OUTPUT_VARIABLE VS_LINES_RAW
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )

    # 按行分割
    string(REPLACE "\r\n" ";" VS_PATHS "${VS_PATHS_RAW}")
    string(REPLACE "\n" ";" VS_PATHS "${VS_PATHS}")
    string(REPLACE "\r\n" ";" VS_YEARS "${VS_YEARS_RAW}")
    string(REPLACE "\n" ";" VS_YEARS "${VS_YEARS}")
    string(REPLACE "\r\n" ";" VS_LINES "${VS_LINES_RAW}")
    string(REPLACE "\n" ";" VS_LINES "${VS_LINES}")

    set(VS_LIST "")
    set(idx 0)
    list(LENGTH VS_PATHS total_count)

    while(idx LESS total_count)
        list(GET VS_PATHS ${idx} VS_PATH)
        list(GET VS_YEARS ${idx} VS_YEAR)
        list(GET VS_LINES ${idx} VS_PRODUCT_LINE)

        string(STRIP "${VS_PATH}" VS_PATH)
        string(STRIP "${VS_YEAR}" VS_YEAR)
        string(STRIP "${VS_PRODUCT_LINE}" VS_PRODUCT_LINE)

        # 跳过空行
        if(NOT VS_PATH OR NOT VS_YEAR OR NOT VS_PRODUCT_LINE)
            math(EXPR idx "${idx} + 1")
            continue()
        endif()

        # 统一将路径中的反斜杠替换为正斜杠
        string(REPLACE "\\" "/" VS_PATH "${VS_PATH}")

        # 从 Dev17 中提取主版本号 17
        string(REGEX REPLACE "Dev" "" VS_VERSION_MAJOR "${VS_PRODUCT_LINE}")

        # 校验 VS_YEAR 是否为合法的 4 位年份
        # 某些 VS 预览版（如 Dev18 / VS 2026）的 catalog_productLineVersion
        # 可能返回主版本号 "18" 而非年份 "2026"，需要做回退推导
        string(REGEX MATCH "^[0-9]{4}$" _valid_year "${VS_YEAR}")
        if(NOT _valid_year)
            # 根据主版本号推导发布年份（基于已知 VS 版本映射）
            if(VS_VERSION_MAJOR EQUAL 18)
                set(VS_YEAR "2026")
            elseif(VS_VERSION_MAJOR EQUAL 17)
                set(VS_YEAR "2022")
            elseif(VS_VERSION_MAJOR EQUAL 16)
                set(VS_YEAR "2019")
            elseif(VS_VERSION_MAJOR EQUAL 15)
                set(VS_YEAR "2017")
            elseif(VS_VERSION_MAJOR EQUAL 14)
                set(VS_YEAR "2015")
            else()
                # 未知版本：用主版本号作为年份（尽力而为）
                set(VS_YEAR "20${VS_VERSION_MAJOR}")
            endif()
        endif()

        # 生成 CMake 生成器名称
        set(GENERATOR "Visual Studio ${VS_VERSION_MAJOR} ${VS_YEAR}")

        # 查找 cl.exe
        file(GLOB MSVC_TOOLSET_DIRS "${VS_PATH}/VC/Tools/MSVC/*")
        list(SORT MSVC_TOOLSET_DIRS)
        list(REVERSE MSVC_TOOLSET_DIRS)

        set(CL_PATH "")
        foreach(TOOLSET_DIR IN LISTS MSVC_TOOLSET_DIRS)
            set(TEST_CL "${TOOLSET_DIR}/bin/Hostx64/x64/cl.exe")
            if(EXISTS "${TEST_CL}")
                set(CL_PATH "${TEST_CL}")
                break()
            endif()
        endforeach()

        if(CL_PATH)
            # 格式: type|vs_year|vs_major|install_path|compiler_path
            set(vs_entry "msvc|${VS_YEAR}|${VS_VERSION_MAJOR}|${VS_PATH}|${CL_PATH}")
            list(APPEND VS_LIST "${vs_entry}")

            # 检测 VS 自带的 Clang-cl
            set(CLANGCL_PATH "${VS_PATH}/VC/Tools/Llvm/bin/clang-cl.exe")
            if(EXISTS "${CLANGCL_PATH}")
                set(clangcl_entry "clang-cl|${VS_YEAR}|${VS_VERSION_MAJOR}|${VS_PATH}|${CLANGCL_PATH}")
                list(APPEND VS_LIST "${clangcl_entry}")
            endif()
        endif()

        math(EXPR idx "${idx} + 1")
    endwhile()

    if(VS_LIST)
        set(VS_LIST "${VS_LIST}" PARENT_SCOPE)
    endif()
endfunction()

# ---- Windows: 从 PATH 检测独立安装的编译器 ----

function(detect_path_compilers)
    set(PATH_COMPILERS "")

    # 检测独立安装的 Clang（非 VS 自带的）
    find_program(CLANG_C_COMPILER clang)
    find_program(CLANG_CXX_COMPILER clang++)
    if(CLANG_C_COMPILER)
        make_compiler_id("clang" "${CLANG_C_COMPILER}" clang_id)
        set(entry "clang|${CLANG_C_COMPILER}|${CLANG_CXX_COMPILER}|${clang_id}")
        list(APPEND PATH_COMPILERS "${entry}")
    endif()

    # 检测 MinGW GCC
    find_program(GCC_C_COMPILER gcc)
    find_program(GCC_CXX_COMPILER g++)
    if(GCC_C_COMPILER)
        make_compiler_id("gcc" "${GCC_C_COMPILER}" gcc_id)
        set(entry "gcc|${GCC_C_COMPILER}|${GCC_CXX_COMPILER}|${gcc_id}")
        list(APPEND PATH_COMPILERS "${entry}")
    endif()

    if(PATH_COMPILERS)
        set(PATH_COMPILERS "${PATH_COMPILERS}" PARENT_SCOPE)
    endif()
endfunction()

# ---- 检测环境 ----

message(STATUS "=== 检测环境 ===")

# 操作系统
string(TOLOWER "${CMAKE_HOST_SYSTEM_NAME}" HOST_OS)
message(STATUS "  操作系统: ${CMAKE_HOST_SYSTEM_NAME}")
message(STATUS "")

# ---- 检测构建工具和编译器 ----

# COMPILERS 列表格式: {type, c_path, cxx_path, id, generator, vs_year}
# type: msvc | clang-cl | clang | gcc
# generator: Visual Studio 17 2022 | Ninja | Unix Makefiles
set(COMPILERS "")

if(WIN32)
    # Windows: 通过 vswhere 检测所有 Visual Studio 版本
    detect_all_visual_studio()

    if(VS_LIST)
        foreach(vs_entry IN LISTS VS_LIST)
            # 解析 vs_entry: type|vs_year|vs_major|install_path|compiler_path
            string(REPLACE "|" ";" vs_fields "${vs_entry}")
            list(GET vs_fields 0 entry_type)
            list(GET vs_fields 1 vs_year)
            list(GET vs_fields 2 vs_major)
            list(GET vs_fields 3 vs_install_path)
            list(GET vs_fields 4 compiler_path)

            if(entry_type STREQUAL "msvc")
                set(generator "Visual Studio ${vs_major} ${vs_year}")
                set(preset_name "msvc${vs_major}")

                # msvc: C 和 C++ 都用 cl.exe
                list(APPEND COMPILERS "msvc")
                list(APPEND COMPILERS "${compiler_path}")
                list(APPEND COMPILERS "${compiler_path}")
                list(APPEND COMPILERS "${preset_name}")
                list(APPEND COMPILERS "${generator}")
                list(APPEND COMPILERS "${vs_year}")

            elseif(entry_type STREQUAL "clang-cl")
                set(generator "Visual Studio ${vs_major} ${vs_year}")
                set(preset_name "clang-cl${vs_major}")

                # clang-cl: C 和 C++ 都用 clang-cl.exe
                list(APPEND COMPILERS "clang-cl")
                list(APPEND COMPILERS "${compiler_path}")
                list(APPEND COMPILERS "${compiler_path}")
                list(APPEND COMPILERS "${preset_name}")
                list(APPEND COMPILERS "${generator}")
                list(APPEND COMPILERS "${vs_year}")
            endif()
        endforeach()
    endif()

    # 从 PATH 检测独立安装的编译器
    detect_path_compilers()

    if(PATH_COMPILERS)
        # 先确定构建工具（所有 PATH 编译器共用同一个生成器）
        find_ninja(GENERATOR)
        if(NOT GENERATOR)
            set(GENERATOR "Unix Makefiles")
        endif()

        foreach(pc_entry IN LISTS PATH_COMPILERS)
            string(REPLACE "|" ";" pc_fields "${pc_entry}")
            list(GET pc_fields 0 pc_type)
            list(GET pc_fields 1 pc_c_path)
            list(GET pc_fields 2 pc_cxx_path)
            list(GET pc_fields 3 pc_id)

            if(pc_type STREQUAL "clang")
                list(APPEND COMPILERS "clang")
                list(APPEND COMPILERS "${pc_c_path}")
                list(APPEND COMPILERS "${pc_cxx_path}")
                list(APPEND COMPILERS "${pc_id}")
                list(APPEND COMPILERS "${GENERATOR}")
                list(APPEND COMPILERS "")

            elseif(pc_type STREQUAL "gcc")
                list(APPEND COMPILERS "gcc")
                list(APPEND COMPILERS "${pc_c_path}")
                list(APPEND COMPILERS "${pc_cxx_path}")
                list(APPEND COMPILERS "${pc_id}")
                list(APPEND COMPILERS "${GENERATOR}")
                list(APPEND COMPILERS "")
            endif()
        endforeach()
    endif()

    # 如果没有检测到任何编译器
    if(NOT COMPILERS)
        # 尝试从 PATH 中找 cl（兼容开发者命令提示符环境）
        find_program(MSVC_C_COMPILER cl)
        find_program(MSVC_CXX_COMPILER cl)
        if(MSVC_C_COMPILER)
            set(GENERATOR "Visual Studio 17 2022")
            list(APPEND COMPILERS "msvc")
            list(APPEND COMPILERS "${MSVC_C_COMPILER}")
            list(APPEND COMPILERS "${MSVC_CXX_COMPILER}")
            list(APPEND COMPILERS "msvc")
            list(APPEND COMPILERS "${GENERATOR}")
            list(APPEND COMPILERS "")
        endif()
    endif()
else()
    # Linux: 检测构建工具
    find_ninja(GENERATOR)
    if(NOT GENERATOR)
        set(GENERATOR "Unix Makefiles")
    endif()

    # Linux: 检测 GCC
    find_program(GCC_C_COMPILER gcc)
    find_program(GCC_CXX_COMPILER g++)
    if(GCC_C_COMPILER)
        make_compiler_id("gcc" "${GCC_C_COMPILER}" gcc_id)
        list(APPEND COMPILERS "gcc")
        list(APPEND COMPILERS "${GCC_C_COMPILER}")
        list(APPEND COMPILERS "${GCC_CXX_COMPILER}")
        list(APPEND COMPILERS "${gcc_id}")
        list(APPEND COMPILERS "${GENERATOR}")
        list(APPEND COMPILERS "")
    endif()

    # Linux: 检测 Clang
    find_program(CLANG_C_COMPILER clang)
    find_program(CLANG_CXX_COMPILER clang++)
    if(CLANG_C_COMPILER)
        make_compiler_id("clang" "${CLANG_C_COMPILER}" clang_id)
        list(APPEND COMPILERS "clang")
        list(APPEND COMPILERS "${CLANG_C_COMPILER}")
        list(APPEND COMPILERS "${CLANG_CXX_COMPILER}")
        list(APPEND COMPILERS "${clang_id}")
        list(APPEND COMPILERS "${GENERATOR}")
        list(APPEND COMPILERS "")
    endif()
endif()

if(NOT COMPILERS)
    message(FATAL_ERROR "未检测到任何支持的编译器！")
endif()

# ---- 打印检测结果（每个编译器独立显示）----

# COMPILERS 列表格式: {type, c_path, cxx_path, id, generator, vs_year}
# 每 6 个元素一组
set(idx 0)
list(LENGTH COMPILERS total_len)
while(idx LESS total_len)
    list(GET COMPILERS ${idx} comp_type)
    math(EXPR idx "${idx} + 1")
    list(GET COMPILERS ${idx} comp_c_path)
    math(EXPR idx "${idx} + 1")
    list(GET COMPILERS ${idx} comp_cxx_path)
    math(EXPR idx "${idx} + 1")
    list(GET COMPILERS ${idx} comp_id)
    math(EXPR idx "${idx} + 1")
    list(GET COMPILERS ${idx} comp_generator)
    math(EXPR idx "${idx} + 1")
    list(GET COMPILERS ${idx} comp_vs_year)
    math(EXPR idx "${idx} + 1")

    if(comp_type STREQUAL "msvc")
        message(STATUS "  发现: MSVC (Visual Studio ${comp_vs_year})")
        message(STATUS "    编译器路径: ${comp_c_path}")
        message(STATUS "    构建工具: ${comp_generator}")
    elseif(comp_type STREQUAL "clang-cl")
        message(STATUS "  发现: Clang-cl (VS ${comp_vs_year})")
        message(STATUS "    编译器路径: ${comp_c_path}")
        message(STATUS "    构建工具: ${comp_generator}")
    elseif(comp_type STREQUAL "clang")
        message(STATUS "  发现: Clang ${comp_id}")
        message(STATUS "    编译器路径: ${comp_c_path}")
        message(STATUS "    构建工具: ${comp_generator}")
    elseif(comp_type STREQUAL "gcc")
        message(STATUS "  发现: GCC ${comp_id}")
        message(STATUS "    编译器路径: ${comp_c_path}")
        message(STATUS "    构建工具: ${comp_generator}")
    endif()
    message(STATUS "")
endwhile()

# ---- 生成 CMakePresets.json ----

message(STATUS "=== 生成 CMakePresets.json ===")

# 开始构建 JSON
set(JSON "{\n")
set(JSON "${JSON}    \"version\": 8,\n")

# ---- configurePresets ----
set(JSON "${JSON}    \"configurePresets\": [\n")

set(PRESET_NAMES "")       # 存储所有 preset 名称
set(has_first_config FALSE)

# COMPILERS 列表格式: {type, c_path, cxx_path, id, generator, vs_year}
# 每 6 个元素一组
set(idx 0)
list(LENGTH COMPILERS total_len)
while(idx LESS total_len)
    list(GET COMPILERS ${idx} comp_type)
    math(EXPR idx "${idx} + 1")
    list(GET COMPILERS ${idx} comp_c_path)
    math(EXPR idx "${idx} + 1")
    list(GET COMPILERS ${idx} comp_cxx_path)
    math(EXPR idx "${idx} + 1")
    list(GET COMPILERS ${idx} comp_id)
    math(EXPR idx "${idx} + 1")
    list(GET COMPILERS ${idx} comp_generator)
    math(EXPR idx "${idx} + 1")
    list(GET COMPILERS ${idx} comp_vs_year)
    math(EXPR idx "${idx} + 1")

    # 根据编译器类型和平台生成 configurePreset
    if(comp_type STREQUAL "msvc")
        # MSVC: 仅 Windows，多配置生成器，分 Debug/Release
        if(comp_vs_year)
            set(base_display "MSVC (Visual Studio ${comp_vs_year}) - amd64")
        else()
            set(base_display "MSVC (Visual Studio) - amd64")
        endif()
        set(desc "${comp_generator} (x64)")

        foreach(build_type "Debug" "Release")
            if(has_first_config)
                set(JSON "${JSON},\n")
            endif()
            set(has_first_config TRUE)

            string(TOLOWER "${build_type}" build_type_lower)
            set(preset_name "${comp_id}-${build_type_lower}")

            set(JSON "${JSON}        {\n")
            set(JSON "${JSON}            \"name\": \"${preset_name}\",\n")
            set(JSON "${JSON}            \"displayName\": \"${base_display} ${build_type}\",\n")
            set(JSON "${JSON}            \"description\": \"${desc} (${build_type})\",\n")
            set(JSON "${JSON}            \"generator\": \"${comp_generator}\",\n")
            set(JSON "${JSON}            \"toolset\": \"host=x64\",\n")
            set(JSON "${JSON}            \"architecture\": \"x64\",\n")
            set(JSON "${JSON}            \"binaryDir\": \"\${sourceDir}/build/\${presetName}\",\n")
            set(JSON "${JSON}            \"cacheVariables\": {\n")
            set(JSON "${JSON}                \"CMAKE_INSTALL_PREFIX\": \"\${sourceDir}/install/\${presetName}\",\n")
            set(JSON "${JSON}                \"CMAKE_C_COMPILER\": \"${comp_c_path}\",\n")
            set(JSON "${JSON}                \"CMAKE_CXX_COMPILER\": \"${comp_cxx_path}\",\n")
            set(JSON "${JSON}                \"CMAKE_BUILD_TYPE\": \"${build_type}\"\n")
            set(JSON "${JSON}            },\n")
            set(JSON "${JSON}            \"condition\": {\n")
            set(JSON "${JSON}                \"type\": \"equals\",\n")
            set(JSON "${JSON}                \"lhs\": \"\${hostSystemName}\",\n")
            set(JSON "${JSON}                \"rhs\": \"Windows\"\n")
            set(JSON "${JSON}            }\n")
            set(JSON "${JSON}        }")
            list(APPEND PRESET_NAMES "${preset_name}")
        endforeach()

    elseif(comp_type STREQUAL "clang-cl")
        # Clang-cl: 仅 Windows，多配置生成器，分 Debug/Release
        if(comp_vs_year)
            set(base_display "Clang-cl (VS ${comp_vs_year}) - amd64")
        else()
            set(base_display "Clang-cl - amd64")
        endif()
        set(desc "Clang-cl with ${comp_generator} (x64)")

        foreach(build_type "Debug" "Release")
            if(has_first_config)
                set(JSON "${JSON},\n")
            endif()
            set(has_first_config TRUE)

            string(TOLOWER "${build_type}" build_type_lower)
            set(preset_name "${comp_id}-${build_type_lower}")

            set(JSON "${JSON}        {\n")
            set(JSON "${JSON}            \"name\": \"${preset_name}\",\n")
            set(JSON "${JSON}            \"displayName\": \"${base_display} ${build_type}\",\n")
            set(JSON "${JSON}            \"description\": \"${desc} (${build_type})\",\n")
            set(JSON "${JSON}            \"generator\": \"${comp_generator}\",\n")
            set(JSON "${JSON}            \"toolset\": \"host=x64\",\n")
            set(JSON "${JSON}            \"architecture\": \"x64\",\n")
            set(JSON "${JSON}            \"binaryDir\": \"\${sourceDir}/build/\${presetName}\",\n")
            set(JSON "${JSON}            \"cacheVariables\": {\n")
            set(JSON "${JSON}                \"CMAKE_INSTALL_PREFIX\": \"\${sourceDir}/install/\${presetName}\",\n")
            set(JSON "${JSON}                \"CMAKE_C_COMPILER\": \"${comp_c_path}\",\n")
            set(JSON "${JSON}                \"CMAKE_CXX_COMPILER\": \"${comp_cxx_path}\",\n")
            set(JSON "${JSON}                \"CMAKE_BUILD_TYPE\": \"${build_type}\"\n")
            set(JSON "${JSON}            },\n")
            set(JSON "${JSON}            \"condition\": {\n")
            set(JSON "${JSON}                \"type\": \"equals\",\n")
            set(JSON "${JSON}                \"lhs\": \"\${hostSystemName}\",\n")
            set(JSON "${JSON}                \"rhs\": \"Windows\"\n")
            set(JSON "${JSON}            }\n")
            set(JSON "${JSON}        }")
            list(APPEND PRESET_NAMES "${preset_name}")
        endforeach()

    elseif(comp_type STREQUAL "clang" OR comp_type STREQUAL "gcc")
        # 独立 Clang/GCC: 跨平台（Windows/Linux），单配置生成器
        # 需要为 Debug/Release 各生成一个 preset
        if(WIN32)
            set(arch_suffix "amd64")
            if(comp_type STREQUAL "clang")
                set(base_display "Clang ${comp_id} - ${arch_suffix}")
            else()
                set(base_display "GCC ${comp_id} - ${arch_suffix} (MinGW)")
            endif()
            set(condition_os "Windows")
        else()
            set(arch_suffix "x86_64-linux-gnu")
            if(comp_type STREQUAL "clang")
                set(base_display "Clang ${comp_id} - ${arch_suffix}")
            else()
                set(base_display "GCC ${comp_id} - ${arch_suffix}")
            endif()
            set(condition_os "Linux")
        endif()
        set(desc "${comp_type} with ${comp_generator}")

        foreach(build_type "Debug" "Release")
            if(has_first_config)
                set(JSON "${JSON},\n")
            endif()
            set(has_first_config TRUE)

            string(TOLOWER "${build_type}" build_type_lower)
            set(single_preset_name "${comp_id}-${build_type_lower}")

            set(JSON "${JSON}        {\n")
            set(JSON "${JSON}            \"name\": \"${single_preset_name}\",\n")
            set(JSON "${JSON}            \"displayName\": \"${base_display} ${build_type}\",\n")
            set(JSON "${JSON}            \"description\": \"${desc} (${build_type})\",\n")
            set(JSON "${JSON}            \"generator\": \"${comp_generator}\",\n")
            set(JSON "${JSON}            \"binaryDir\": \"\${sourceDir}/build/\${presetName}\",\n")
            set(JSON "${JSON}            \"cacheVariables\": {\n")
            set(JSON "${JSON}                \"CMAKE_INSTALL_PREFIX\": \"\${sourceDir}/install/\${presetName}\",\n")
            set(JSON "${JSON}                \"CMAKE_C_COMPILER\": \"${comp_c_path}\",\n")
            set(JSON "${JSON}                \"CMAKE_CXX_COMPILER\": \"${comp_cxx_path}\",\n")
            set(JSON "${JSON}                \"CMAKE_BUILD_TYPE\": \"${build_type}\"\n")
            set(JSON "${JSON}            },\n")
            set(JSON "${JSON}            \"condition\": {\n")
            set(JSON "${JSON}                \"type\": \"equals\",\n")
            set(JSON "${JSON}                \"lhs\": \"\${hostSystemName}\",\n")
            set(JSON "${JSON}                \"rhs\": \"${condition_os}\"\n")
            set(JSON "${JSON}            }\n")
            set(JSON "${JSON}        }")

            list(APPEND PRESET_NAMES "${single_preset_name}")
        endforeach()
    endif()
endwhile()

set(JSON "${JSON}\n    ],\n")

# ---- buildPresets ----
set(JSON "${JSON}    \"buildPresets\": [\n")
set(has_first_build FALSE)

# 所有 preset 名称都包含 -debug 或 -release 后缀
# MSVC/clang-cl 需要额外带 "configuration"（Visual Studio 多配置生成器需要）
# 独立 Clang/GCC 不需要 "configuration"（单配置生成器，由 CMAKE_BUILD_TYPE 控制）
foreach(preset_name IN LISTS PRESET_NAMES)
    # 检查是否为 MSVC 或 clang-cl 风格（多配置生成器）
    string(REGEX MATCH "^(msvc|clang-cl)" is_msvc_style "${preset_name}")

    if(has_first_build)
        set(JSON "${JSON},\n")
    endif()
    set(has_first_build TRUE)

    if(is_msvc_style)
        # MSVC/clang-cl: 从 preset 名提取配置 (debug -> Debug, release -> Release)
        string(REGEX REPLACE ".*-(debug|release)$" "\\1" config_lower "${preset_name}")
        string(SUBSTRING "${config_lower}" 0 1 first_char)
        string(TOUPPER "${first_char}" first_char_upper)
        string(SUBSTRING "${config_lower}" 1 -1 rest)
        set(config_name "${first_char_upper}${rest}")

        set(JSON "${JSON}        {\n")
        set(JSON "${JSON}            \"name\": \"${preset_name}\",\n")
        set(JSON "${JSON}            \"configurePreset\": \"${preset_name}\",\n")
        set(JSON "${JSON}            \"configuration\": \"${config_name}\"\n")
        set(JSON "${JSON}        }")
    else()
        # 单配置生成器（独立 Clang/GCC）：直接引用 configurePreset，不需要 configuration
        set(JSON "${JSON}        {\n")
        set(JSON "${JSON}            \"name\": \"${preset_name}\",\n")
        set(JSON "${JSON}            \"configurePreset\": \"${preset_name}\"\n")
        set(JSON "${JSON}        }")
    endif()
endforeach()

set(JSON "${JSON}\n    ],\n")

# ---- testPresets ----
set(JSON "${JSON}    \"testPresets\": [\n")
set(has_first_test FALSE)

foreach(preset_name IN LISTS PRESET_NAMES)
    # 检查是否为 MSVC 或 clang-cl 风格（多配置生成器）
    string(REGEX MATCH "^(msvc|clang-cl)" is_msvc_style "${preset_name}")

    if(has_first_test)
        set(JSON "${JSON},\n")
    endif()
    set(has_first_test TRUE)

    if(is_msvc_style)
        # MSVC/clang-cl: 从 preset 名提取配置并带上 configuration
        string(REGEX REPLACE ".*-(debug|release)$" "\\1" config_lower "${preset_name}")
        string(SUBSTRING "${config_lower}" 0 1 first_char)
        string(TOUPPER "${first_char}" first_char_upper)
        string(SUBSTRING "${config_lower}" 1 -1 rest)
        set(config_name "${first_char_upper}${rest}")

        set(JSON "${JSON}        {\n")
        set(JSON "${JSON}            \"name\": \"ctest-${preset_name}\",\n")
        set(JSON "${JSON}            \"configurePreset\": \"${preset_name}\",\n")
        set(JSON "${JSON}            \"configuration\": \"${config_name}\"\n")
        set(JSON "${JSON}        }")
    else()
        # 单配置生成器（独立 Clang/GCC）：直接引用 configurePreset
        set(JSON "${JSON}        {\n")
        set(JSON "${JSON}            \"name\": \"ctest-${preset_name}\",\n")
        set(JSON "${JSON}            \"configurePreset\": \"${preset_name}\"\n")
        set(JSON "${JSON}        }")
    endif()
endforeach()

set(JSON "${JSON}\n    ],\n")

# ---- packagePresets ----
set(JSON "${JSON}    \"packagePresets\": [\n")
set(has_first_pkg FALSE)

foreach(preset_name IN LISTS PRESET_NAMES)
    if(has_first_pkg)
        set(JSON "${JSON},\n")
    endif()
    set(has_first_pkg TRUE)
    set(JSON "${JSON}        {\n")
    set(JSON "${JSON}            \"name\": \"cpack-${preset_name}\",\n")
    set(JSON "${JSON}            \"configurePreset\": \"${preset_name}\"\n")
    set(JSON "${JSON}        }")
endforeach()

set(JSON "${JSON}\n    ],\n")

# ---- workflowPresets ----
set(JSON "${JSON}    \"workflowPresets\": [\n")
set(has_first_wf FALSE)

# 所有 preset 名称都包含 -debug 或 -release 后缀，每个 preset 对应一个 workflow
foreach(preset_name IN LISTS PRESET_NAMES)
    if(has_first_wf)
        set(JSON "${JSON},\n")
    endif()
    set(has_first_wf TRUE)

    set(JSON "${JSON}        {\n")
    set(JSON "${JSON}            \"name\": \"workflow-${preset_name}\",\n")
    set(JSON "${JSON}            \"steps\": [\n")
    set(JSON "${JSON}                { \"type\": \"configure\", \"name\": \"${preset_name}\" },\n")
    set(JSON "${JSON}                { \"type\": \"build\", \"name\": \"${preset_name}\" },\n")
    set(JSON "${JSON}                { \"type\": \"test\", \"name\": \"ctest-${preset_name}\" },\n")
    set(JSON "${JSON}                { \"type\": \"package\", \"name\": \"cpack-${preset_name}\" }\n")
    set(JSON "${JSON}            ]\n")
    set(JSON "${JSON}        }")
endforeach()

set(JSON "${JSON}\n    ]\n")
set(JSON "${JSON}}\n")

# ---- 写入文件 ----

set(OUTPUT_FILE "${CMAKE_CURRENT_LIST_DIR}/../CMakePresets.json")
file(WRITE "${OUTPUT_FILE}" "${JSON}")
message(STATUS "✅ 已生成: ${OUTPUT_FILE}")
message(STATUS "")
message(STATUS "可用 Preset 列表:")
message(STATUS "")

foreach(preset_name IN LISTS PRESET_NAMES)
    # 检查是否为 MSVC 或 clang-cl 风格（多配置生成器）
    string(REGEX MATCH "^(msvc|clang-cl)" is_msvc_style "${preset_name}")

    message(STATUS "  ── ${preset_name} ──")
    message(STATUS "  configure: cmake --preset ${preset_name}")
    message(STATUS "  build:     cmake --build --preset ${preset_name}")
    message(STATUS "  test:      ctest --preset ctest-${preset_name}")

    if(is_msvc_style)
        # MSVC/clang-cl: install 需要 --config
        string(REGEX REPLACE ".*-(debug|release)$" "\\1" config_lower "${preset_name}")
        string(SUBSTRING "${config_lower}" 0 1 first_char)
        string(TOUPPER "${first_char}" first_char_upper)
        string(SUBSTRING "${config_lower}" 1 -1 rest)
        set(config_name "${first_char_upper}${rest}")
        message(STATUS "  install:   cmake --install build/${preset_name} --config ${config_name}")
    else()
        message(STATUS "  install:   cmake --install build/${preset_name}")
    endif()

    message(STATUS "  package:   cpack --preset cpack-${preset_name}")
    message(STATUS "  workflow:  cmake --workflow --preset workflow-${preset_name}")
    message(STATUS "")
endforeach()
