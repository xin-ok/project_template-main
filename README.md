# C++ CMake 工程模板

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![CMake](https://img.shields.io/badge/CMake-3.14+-green.svg)](https://cmake.org)
[![C++](https://img.shields.io/badge/C%2B%2B-23-blue.svg)](https://en.cppreference.com/w/cpp/23)
[![CI](https://github.com/xin-ok/project_template-main/actions/workflows/ci.yml/badge.svg)](https://github.com/xin-ok/project_template-main/actions/workflows/ci.yml)

一个开箱即用的现代 C++ 跨平台工程模板。**一条命令改好工程名**，直接开始写业务代码。

支持 Windows（MSVC / Clang / MinGW）与 Linux（GCC / Clang），内置测试、基准测试、打包、安装导出、CI。

---

## 30 秒上手

```bash
# 1. 克隆模板
git clone https://github.com/xin-ok/project_template-main.git MyProject
cd MyProject

# 2. 改工程名（自动替换所有引用 + 生成 CMakePresets.json）
python scripts/init_project.py MyProject

# 3. 构建
cmake --preset msvc17-debug          # Windows（名称以 cmake --list-presets 为准）
cmake --build --preset msvc17-debug --parallel 8

# 4. 运行
./bin/Debug/print_hellod.exe
```

> 第 2 步会清理构建产物、替换 `project()` / `export_name` / 示例代码中的工程名、重命名导出配置文件，并自动生成 `CMakePresets.json`。
> 想先看看会改什么？加 `--dry-run`。

---

## 这个模板给你什么

| 能力 | 说明 |
|---|---|
| 🎯 **一键初始化** | `init_project.py` 改工程名，无需手动搜索替换 |
| 🔧 **Presets 自动生成** | 探测本机所有编译器，生成 `CMakePresets.json`，无需手写 |
| 🌍 **跨平台跨编译器** | MSVC / Clang-cl / Clang / GCC，Windows + Linux |
| ✅ **严格告警** | `/W4 /WX`、`-Wall -Wextra -Werror`，强制干净代码 |
| 🧪 **单元测试** | GoogleTest + GoogleMock，`gtest_discover_tests` 按用例注册 |
| 📊 **基准测试** | Google Benchmark，可选开关 |
| 📦 **打包** | CPack 产出 `.zip` / `.tar.gz` |
| 📚 **安装与导出** | 生成 `find_package` 可用的 CMake 包 |
| 🛡️ **Sanitizer** | ASan / UBSan / TSan 一键开关 |
| ⚡ **预编译头** | 加速编译 |
| 🔁 **Workflow Preset** | 配置 → 构建 → 测试 → 打包，一条命令 |
| 🤖 **CI 就绪** | GitHub Actions：Windows + Linux × Debug/Release 全流程 |
| 🖥️ **IDE 友好** | VS Code CMake Tools、Visual Studio 开箱可用 |

---

## 目录结构

```
.
├── CMakeLists.txt          # 顶层入口（改工程名只需改这里）
├── cmake/                  # 构建配置模块
│   ├── PublicPreset.cmake  #   编译选项、输出目录、通用开关
│   ├── PrivatePreset.cmake #   项目私有编译选项
│   ├── CPackPreset.cmake   #   打包配置
│   ├── Export.cmake        #   安装与 find_package 导出
│   └── GeneratePresets.cmake # 自动生成 CMakePresets.json
├── src/                    # 你的源码（目录名固定，不随工程名变化）
│   ├── static_lib/         #   静态库示例
│   ├── shared_lib/         #   动态库示例（含 PCH）
│   └── print_hello/        #   可执行文件示例
├── tests/                  # 单元测试（BUILD_TESTS=ON 时构建）
├── benchmarks/             # 基准测试（BUILD_BENCHMARKS=ON 时构建）
├── examples/               # 使用示例（含独立 find_package 用法）
├── scripts/                # 辅助脚本
│   ├── init_project.py     #   工程初始化
│   ├── generate_presets.*  #   生成 CMakePresets.json
│   ├── clean_all.*         #   清理构建产物
│   └── package_install.py  #   合并 install 并打包
├── docs/                   # 详细文档
├── thirdparty/             # 本地第三方依赖
├── bin/ lib/               # 构建产物（自动生成）
└── packages/               # 打包产物（自动生成）
```

---

## 常用命令

### 生成 / 查看 Presets

```bash
./scripts/generate_presets.sh     # Linux
scripts\generate_presets.bat      # Windows

cmake --list-presets              # 查看所有可用 preset
```

### 构建

```bash
cmake --preset <preset>                        # 配置
cmake --build --preset <preset> --parallel 8   # 构建
```

### 测试

```bash
# 先开启测试开关
cmake --preset <preset> -DBUILD_TESTS=ON
cmake --build --preset <preset> --parallel 8

# 运行
ctest --preset ctest-<preset>                  # 全部
ctest --preset ctest-<preset> -R AddTest       # 按名称过滤
```

> `gtest_discover_tests` 在**构建后**枚举用例，所以必须先构建再 `ctest`。
> 直接 `ctest` 时需带 `-C Debug`（多配置生成器），用 preset 则自动带上。

### 基准测试

```bash
cmake --preset <preset> -DBUILD_BENCHMARKS=ON
cmake --build --preset <preset> --parallel 8
./bin/Debug/bench_mathd --benchmark_min_time=0.1s
```

### 安装 / 打包

```bash
cmake --install build/<preset> --config Debug   # 安装到 install/<preset>
cpack --preset cpack-<preset>                   # 打包到 packages/
```

### 一条命令走完全流程

```bash
cmake --workflow --preset workflow-<preset>
```

---

## 构建选项

| 选项 | 默认 | 说明 |
|---|---|---|
| `BUILD_TESTS` | `OFF` | 构建 `tests/`，自动拉取 GoogleTest |
| `BUILD_BENCHMARKS` | `OFF` | 构建 `benchmarks/`，自动拉取 Google Benchmark |
| `ENABLE_RELEASE_DEBUG_INFO` | `OFF` | Release 保留调试信息 |
| `DISABLE_RELEASE_OPTIMIZATION` | `OFF` | Release 禁用优化 |
| `ENABLE_FSANITIZE_ADDRESS` | `OFF` | AddressSanitizer |
| `ENABLE_FSANITIZE_UNDEFINED` | `OFF` | UBSan（MSVC 不支持） |
| `ENABLE_FSANITIZE_THREAD` | `OFF` | TSan（MSVC 不支持） |
| `GIT_PROXY` | 空 | 拉取依赖时使用的 git 代理 |

用法：

```bash
cmake --preset <preset> -DBUILD_TESTS=ON -DENABLE_FSANITIZE_ADDRESS=ON
```

### 依赖代理

`FetchContent` 拉取第三方库时如需代理：

```bash
cmake --preset <preset> -DGIT_PROXY=socks5h://127.0.0.1:10808
```

> 建议用 `socks5h://`（DNS 也走代理），避免域名解析失败。

---

## 在别的工程里使用本模板的库

模板会导出标准 CMake 包，其他工程可以直接 `find_package`：

```cmake
find_package(MyProject REQUIRED)

add_executable(app main.cc)
target_link_libraries(app PRIVATE MyProject::MyProject)
```

完整示例见 [`examples/lib_test/CMakeLists.install.txt`](./examples/lib_test/CMakeLists.install.txt)。

---

## 自定义

### 改工程名

```bash
python scripts/init_project.py MyProject
```

| 选项 | 说明 |
|---|---|
| `--dry-run` | 只打印将要做的改动，不落盘 |
| `--force` | 跳过「已初始化」检查 |
| `--no-presets` | 不自动生成 `CMakePresets.json` |
| `--keep-build` | 不清理构建产物 |

> 脚本只能运行一次。若模板已被初始化，需加 `--force` 才会继续。

### 改版本号

编辑 `CMakeLists.txt`：

```cmake
project(MyProject VERSION 1.0.0)   # ← 改这里
```

### 改打包信息

编辑 `cmake/CPackPreset.cmake`：

```cmake
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "MyApplication")
set(CPACK_PACKAGE_VENDOR "MyCompany")
```

### 加自己的库 / 可执行文件

1. 在 `src/` 下新建目录，参考 `src/static_lib/CMakeLists.txt`
2. 在 `src/CMakeLists.txt` 里 `add_subdirectory(你的目录)`
3. 如需导出给外部使用，把目标加进 `target_link_libraries(${export_name} INTERFACE ...)`

---

## 常见问题

**Q: `cmake --list-presets` 是空的？**
先运行 `scripts/generate_presets.bat`（Windows）或 `./scripts/generate_presets.sh`（Linux）。

**Q: `ctest` 显示 "No tests were found"？**
两个原因：① 没加 `-DBUILD_TESTS=ON`；② 没先构建（`gtest_discover_tests` 需要构建后枚举用例）。

**Q: 拉取 GoogleTest / Benchmark 卡住？**
配置代理：`-DGIT_PROXY=socks5h://127.0.0.1:10808`。

---

## 文档

- [Preset 详解](./docs/presets.md) — 命名规则、各阶段 Preset 说明
- [编译选项](./docs/build-options.md) — Debug/Release、Sanitizer、格式化、清理

---

## 许可证

[MIT License](./LICENSE)
