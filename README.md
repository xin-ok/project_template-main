# project_template

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![CMake](https://img.shields.io/badge/CMake-3.14+-green.svg)

跨平台 C++ CMake 工程模板，一份代码同时支持 Linux（GCC/Clang）与 Windows（MSVC/Clang/MinGW）。

## 特点

- 🌍 **跨平台** — Linux / Windows，多编译器自动适配
- 🎯 **一键 Presets** — 脚本自动探测编译器与环境，生成 `CMakePresets.json`
- ⚙️ **统一构建行为** — 单次只构建一种类型（Debug/Release），消除 MSVC 多配置的不确定性
- ✅ **严格告警** — `-Werror` / `/WX` + 高警告级别，强制干净代码
- 🧪 **测试框架** — GoogleTest + GoogleMock，`gtest_discover_tests` 按用例注册到 CTest
- 📊 **基准测试** — Google Benchmark，可选开关一键启用
- 📦 **CPack 打包** — 一条命令产出 `.tar.gz` / `.zip`
- 🔁 **Workflow Preset** — 配置 → 构建 → 测试 → 打包，一条命令走完
- 🛡️ **Sanitizer 可选** — AddressSanitizer / UBSan / ThreadSanitizer 开箱即用
- ⚡ **预编译头** — 加速编译
- 📚 **导出与安装** — 生成可供 `find_package` 复用的 CMake 包
- 🔗 **依赖自动拉取** — `FetchContent` 按需下载第三方库，支持代理
- 🖥️ **VS Code 集成** — 配合 CMake Tools 插件可视化构建、测试、打包

## 快速开始

### 0. 初始化工程（从模板创建新工程）

```bash
py scripts/init_project.py MyProject
```

脚本会依次完成：

1. 校验工程名（字母开头，只含字母 / 数字 / 下划线）
2. 清理 `build/` `bin/` `lib/` `install/` `packages/`
3. 替换 `CMakeLists.txt` 中的 `project()` / `export_name`
4. 重命名 `cmake/project_templateConfig.cmake.in` → `cmake/<工程名>Config.cmake.in`
5. 同步更新 `README.md`、`scripts/package_install.py`、`examples/lib_test/*` 中的工程名
6. 自动调用 `cmake -P cmake/GeneratePresets.cmake` 生成 `CMakePresets.json`

> 源码目录固定为 `src/`，不随工程名变化，因此无需重命名。

常用选项：

| 选项 | 说明 |
|------|------|
| `--dry-run` | 只打印将要做的改动，不落盘 |
| `--force` | 跳过「已初始化」检查 |
| `--no-presets` | 不自动生成 `CMakePresets.json` |
| `--keep-build` | 不清理构建产物 |

> 脚本只能运行一次。若模板已被初始化，需加 `--force` 才会继续。

### 1. 生成 Presets（自动探测编译器与环境）

```bash
./scripts/generate_presets.sh        # Linux
scripts\generate_presets.bat         # Windows
```

### 2. 查看可用 Preset

```bash
cmake --list-presets
```

### 3. 构建（名称以 --list-presets 输出为准）

```bash
cmake --preset msvc17-debug
cmake --build --preset msvc17-debug --parallel 8
```

### 4. 测试 / 打包 / 安装

```bash
ctest --preset ctest-msvc17-debug
cpack --preset cpack-msvc17-debug
cmake --install build/msvc17-debug --config Debug
```

或一条命令完成全流程：

```bash
cmake --workflow --preset workflow-gcc_14.2.0-debug
```

## 构建选项

测试与基准测试默认**关闭**，按需开启：

```bash
# 启用单元测试（拉取 GoogleTest / GoogleMock）
cmake --preset msvc17-debug -DBUILD_TESTS=ON

# 启用基准测试（拉取 Google Benchmark）
cmake --preset msvc17-debug -DBUILD_BENCHMARKS=ON

# 两者同时启用
cmake --preset msvc17-debug -DBUILD_TESTS=ON -DBUILD_BENCHMARKS=ON
```

| 选项 | 默认 | 说明 |
|------|------|------|
| `BUILD_TESTS` | `OFF` | 构建 `tests/`，通过 `FetchContent` 拉取 GoogleTest |
| `BUILD_BENCHMARKS` | `OFF` | 构建 `benchmarks/`，通过 `FetchContent` 拉取 Google Benchmark |
| `ENABLE_RELEASE_DEBUG_INFO` | `OFF` | Release 模式保留调试信息 |
| `DISABLE_RELEASE_OPTIMIZATION` | `OFF` | Release 模式禁用优化 |
| `ENABLE_FSANITIZE_ADDRESS` | `OFF` | AddressSanitizer |
| `ENABLE_FSANITIZE_UNDEFINED` | `OFF` | UBSan（MSVC 不支持） |
| `ENABLE_FSANITIZE_THREAD` | `OFF` | TSan（MSVC 不支持） |
| `GIT_PROXY` | 空 | 拉取依赖时使用的 git 代理 |

### 依赖管理

`FetchContent` 拉取第三方库时可指定代理，如：-DGIT_PROXY=socks5://127.0.0.1:10808

```bash
cmake --preset msvc17-debug 
```

### 运行测试

```bash
cmake --build --preset msvc17-debug --parallel 8
ctest --preset ctest-msvc17-debug              # 全部
ctest --preset ctest-msvc17-debug -R AddTest   # 按名称过滤
```

> 直接 `ctest` 时需带 `-C Debug`（多配置生成器），用 preset 则自动带上。

## 目录结构

```
├── scripts/                # 所有辅助脚本（初始化 / 清理 / 生成 Presets / 打包）
│   ├── init_project.py     # 工程初始化（模板 → 新工程）
│   ├── generate_presets.*  # 生成 CMakePresets.json
│   ├── clean_all.*         # 清理构建产物
│   └── package_install.py  # 合并 install 并打包 zip
├── CMakeLists.txt          # 顶层构建入口
├── cmake/                  # 通用构建 / 打包 / 导出脚本
├── src/                    # 源码目录（静态库 / 动态库 / 可执行文件）
├── tests/                  # 单元测试（GoogleTest，BUILD_TESTS=ON 时构建）
├── benchmarks/             # 基准测试（Google Benchmark，BUILD_BENCHMARKS=ON 时构建）
├── examples/               # 使用示例（含独立 find_package 用法）
├── docs/                   # 详细文档
├── tools/                  # 辅助工具
├── bin/ lib/               # 构建产物输出目录
├── packages/               # 打包产物
└── thirdparty/             # 第三方依赖（本地放置）
```

> 所有脚本均以自身所在目录的上一级作为工程根目录，因此从根目录执行
> `scripts/xxx` 或进入 `scripts/` 后执行 `./xxx` 行为完全一致。

## 更多

- [Preset 详解](./docs/presets.md) — 命名规则、各阶段 Preset 说明
- [编译选项](./docs/build-options.md) — Debug/Release、Sanitizer、格式化、清理
