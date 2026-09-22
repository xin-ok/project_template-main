# project_template

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![CMake](https://img.shields.io/badge/CMake-3.16+-green.svg)

跨平台 C++ CMake 工程模板，一份代码同时支持 Linux（GCC/Clang）与 Windows（MSVC/Clang/MinGW）。

## 特点

- 🌍 **跨平台** — Linux / Windows，多编译器自动适配
- 🎯 **一键 Presets** — 脚本自动探测编译器与环境，生成 `CMakePresets.json`
- ⚙️ **统一构建行为** — 单次只构建一种类型（Debug/Release），消除 MSVC 多配置的不确定性
- ✅ **严格告警** — `-Werror` / `/WX` + 高警告级别，强制干净代码
- 🧪 **CTest 集成** — 构建后直接 `ctest` 跑测试
- 📦 **CPack 打包** — 一条命令产出 `.tar.gz` / `.zip`
- 🔁 **Workflow Preset** — 配置 → 构建 → 测试 → 打包，一条命令走完
- 🛡️ **Sanitizer 可选** — AddressSanitizer / UBSan / ThreadSanitizer 开箱即用
- ⚡ **预编译头** — 加速编译
- 📚 **导出与安装** — 生成可供 `find_package` 复用的 CMake 包
- 🖥️ **VS Code 集成** — 配合 CMake Tools 插件可视化构建、测试、打包

## 快速开始

```bash
# 1. 生成 Presets（自动探测编译器与环境）
./generate_presets.sh        # Linux
generate_presets.bat         # Windows

# 2. 查看可用 Preset
cmake --list-presets

# 3. 构建（名称以 --list-presets 输出为准）
cmake --preset msvc17-debug
cmake --build --preset msvc17-debug

# 4. 测试 / 打包 / 安装
ctest --preset ctest-msvc17-debug
cpack --preset cpack-msvc17-debug
cmake --install build/msvc17-debug --config Debug
```

或一条命令完成全流程：

```bash
cmake --workflow --preset workflow-gcc_14.2.0-debug
```

## 目录结构

```
├── CMakeLists.txt          # 顶层构建入口
├── cmake/                  # 通用构建 / 打包脚本
├── project_template/       # 示例代码（静态库 / 动态库 / 可执行文件 / 测试）
├── doc/                    # 详细文档
├── bin/ lib/               # 构建产物输出目录
├── packages/               # 打包产物
└── thirdparty/             # 第三方依赖
```

## 更多

- [Preset 详解](./doc/presets.md) — 命名规则、各阶段 Preset 说明
- [编译选项](./doc/build-options.md) — Debug/Release、Sanitizer、格式化、清理
