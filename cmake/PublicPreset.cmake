set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS true)

message(STATUS "Latest supported C++ standard: ${CMAKE_CXX_STANDARD_LATEST}")
set(CMAKE_CXX_STANDARD ${CMAKE_CXX_STANDARD_LATEST})
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_DEBUG_POSTFIX "d")
set(CMAKE_CONFIGURATION_TYPES "${CMAKE_BUILD_TYPE}" CACHE STRING "" FORCE)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${PROJECT_SOURCE_DIR}/bin/Release)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ${PROJECT_SOURCE_DIR}/bin/Debug)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE ${PROJECT_SOURCE_DIR}/lib/Release)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG ${PROJECT_SOURCE_DIR}/lib/Debug)

if(WIN32)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE ${PROJECT_SOURCE_DIR}/bin/Release)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG ${PROJECT_SOURCE_DIR}/bin/Debug)
    add_compile_options(
        /utf-8                    # 跨平台开发时建议统一为 utf-8 编码格式
        /W4                       # 警告级别 4
        /WX                       # 将警告视为错误
        /permissive-              # 严格遵循标准，禁用非标准扩展
        /Zc:__cplusplus           # 使 __cplusplus 宏报告正确的 C++ 标准版本
        /Zc:preprocessor          # 使用符合标准的新预处理器
        /Zc:inline                # 移除未使用的内联函数（影响编译/链接时间）
        /Gy                       # 启用函数级链接（影响链接时间）
        /MP                       # 多进程编译，加速构建
        $<$<CONFIG:Debug>:/sdl>   # 启用安全开发生命周期检查（缓冲区溢出等）
        $<$<CONFIG:Debug>:/Oy->   # 保留帧指针
    )
else()
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE ${PROJECT_SOURCE_DIR}/lib/Release)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG ${PROJECT_SOURCE_DIR}/lib/Debug)
    add_compile_options(
        -Werror                   # 开启警告视为错误
        -Wall                     # 开启大部分常见警告
        -Wextra                   # 开启额外警告
        -Wpedantic                # 严格遵循C++标准，不使用GNU扩展
        -Wold-style-cast          # 警告C风格的强制类型转换
        -Woverloaded-virtual      # 警告虚函数重载问题 
        -Wpointer-arith           # 警告指针算术运算
        -Wshadow                  # 警告变量或函数被隐藏 
        -Wwrite-strings           # 警告不安全的字符串常量赋值 
        -march=native             # 为当前机器的CPU架构生成最优指令，但会牺牲可移植性
        -fPIC                     # 生成位置无关代码，对动态库 (.so) 是必需的
        $<$<CONFIG:Debug>:-g3>    # 生成最详细的调试信息（包括宏定义、局部变量等）
        $<$<CONFIG:Debug>:-fno-omit-frame-pointer>     # 保留帧指针，获得更好的堆栈跟踪
        $<$<CONFIG:Debug>:-fno-optimize-sibling-calls> # 禁用尾调用优化，保持完整堆栈
    )
endif()

set(MSVC_DEBUGGER_DIR "${PROJECT_SOURCE_DIR}/bin/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>")

message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")

option(ENABLE_RELEASE_DEBUG_INFO "Enable debug info in Release mode" OFF)
option(DISABLE_RELEASE_OPTIMIZATION "Disable optimization in Release mode" OFF)
option(ENABLE_FSANITIZE_ADDRESS "Enable AddressSanitizer (memory error detection)" OFF)
if(MSVC)
    set(ENABLE_FSANITIZE_UNDEFINED OFF CACHE INTERNAL "Not supported on this platform")
    set(ENABLE_FSANITIZE_THREAD OFF CACHE INTERNAL "Not supported on this platform")
else()
    option(ENABLE_FSANITIZE_UNDEFINED "Enable UndefinedBehaviorSanitizer (UB detection)" OFF)
    option(ENABLE_FSANITIZE_THREAD "Enable ThreadSanitizer (data race detection)" OFF)
endif()

if(ENABLE_RELEASE_DEBUG_INFO)
    message(STATUS "# Enable debug info in Release mode")
    if(MSVC)
        add_compile_options(/Zi)
        add_link_options(/DEBUG)
    else()
        add_compile_options(
            -g3 
        )
    endif()
endif()

if(DISABLE_RELEASE_OPTIMIZATION)
    message(STATUS "# Disable optimization in Release mode")
    if(MSVC)
        add_compile_options(
            /Od 
            /Ob0 
            /Oy-
        )
    else()
        add_compile_options(
            -O0
            -fno-omit-frame-pointer
            -fno-optimize-sibling-calls
        )
    endif()
endif()

if(ENABLE_FSANITIZE_ADDRESS)
    message(STATUS "# AddressSanitizer is ENABLED (detects: buffer overflow, use-after-free, memory leaks)")
    if(MSVC)
        add_compile_options(/fsanitize=address)
    else()
        add_compile_options(
            -fsanitize=address
            -fsanitize-address-use-after-scope
        )
        add_link_options(-fsanitize=address)
    endif()
endif()


if(ENABLE_FSANITIZE_UNDEFINED)
    message(STATUS "# UndefinedBehaviorSanitizer is ENABLED (detects: integer overflow, null pointer deref, alignment errors, etc.)")
    if(MSVC)
        message(WARNING "UndefinedBehaviorSanitizer is not supported by MSVC. "
                        "Use ClangCL or switch to Linux for this feature.")
    else()
        add_compile_options(
            -fsanitize=undefined
            -fsanitize=float-divide-by-zero     
        )
        add_link_options(-fsanitize=undefined)
        # 可选：将未定义行为转换为运行时陷阱（立即崩溃）
        # add_compile_options(-fsanitize-undefined-trap-on-error)
    endif()
endif()


if(ENABLE_FSANITIZE_THREAD)
    message(STATUS "# ThreadSanitizer is ENABLED (detects: data races, lock ordering issues)")
    if(MSVC)
        message(WARNING "ThreadSanitizer is not supported by MSVC. "
                        "Use ClangCL or switch to Linux for this feature.")
    else()
        add_compile_options(
            -fsanitize=thread
        )
        add_link_options(-fsanitize=thread)
    endif()
endif()

include_directories(${PROJECT_SOURCE_DIR})
find_package(Threads REQUIRED)

# Windows下，当文件被锁定或占用时，该目标生成会执行失败
add_custom_target(clean_all_binary
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${PROJECT_SOURCE_DIR}/bin"
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${PROJECT_SOURCE_DIR}/lib"
    COMMENT "Removing Bin and lib directories"
)

set(UTILITY_FILES
    ${PROJECT_SOURCE_DIR}/cmake/PublicPreset.cmake
    ${PROJECT_SOURCE_DIR}/cmake/PrivatePreset.cmake
    ${PROJECT_SOURCE_DIR}/README.md
    ${PROJECT_SOURCE_DIR}/.clang-format
    ${PROJECT_SOURCE_DIR}/.gitignore
    ${PROJECT_SOURCE_DIR}/CMakeLists.txt
)

add_custom_target(utilities
    COMMENT "utilities files and scripts"
)

target_sources(utilities PRIVATE ${UTILITY_FILES})

set_target_properties(clean_all_binary utilities PROPERTIES FOLDER "tools")