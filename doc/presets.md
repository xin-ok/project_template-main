# CMakePresets.json 详解

`CMakePresets.json` 由 `cmake/GeneratePresets.cmake` 自动生成，定义了完整的构建生命周期，覆盖 **配置 → 构建 → 测试 → 打包 → 工作流** 五个阶段。

## 命名规则

自动生成的 Preset 名称格式如下（GCC 使用 `-dumpfullversion` 获取完整版本号，如 `14.2.0`）：

| 平台 | 配置 Preset 名称 | 说明 |
|------|-----------------|------|
| Linux GCC | `gcc_{版本}-debug` / `gcc_{版本}-release` | 如 `gcc_14.2.0-debug` |
| Linux Clang | `clang_{版本}-debug` / `clang_{版本}-release` | 如 `clang_20.1.0-debug` |
| Windows MSVC | `msvc{主版本}-debug` / `msvc{主版本}-release` | 如 `msvc17-debug` |
| Windows Clang | `clang_{版本}-debug` / `clang_{版本}-release` | 独立安装的 Clang |
| Windows MinGW | `gcc_{版本}-debug` / `gcc_{版本}-release` | MinGW GCC |

其他 Preset 类型基于配置 Preset 名称派生：

| Preset 类型 | 命名格式 | 示例 |
|------------|---------|------|
| buildPreset | `{配置名称}` | `gcc_14.2.0-debug` |
| testPreset | `ctest-{配置名称}` | `ctest-gcc_14.2.0-debug` |
| packagePreset | `cpack-{配置名称}` | `cpack-gcc_14.2.0-debug` |
| workflowPreset | `workflow-{配置名称}` | `workflow-gcc_14.2.0-debug` |

## 各阶段 Preset

### 配置 Preset（configurePresets）

定义生成器、编译器、构建类型和输出目录。所有编译器均分 Debug/Release 各一个 Preset，通过 `CMAKE_BUILD_TYPE` 指定构建类型。

- **MSVC / Clang-cl**：Visual Studio 多配置生成器，同时设置 `CMAKE_BUILD_TYPE` 和 buildPreset 中的 `configuration` 字段
- **独立 Clang / GCC**：单配置生成器（Ninja / Unix Makefiles），仅通过 `CMAKE_BUILD_TYPE` 控制

### 构建 Preset（buildPresets）

关联到对应的配置 Preset。

- **MSVC / Clang-cl**：额外带 `"configuration"` 字段（多配置生成器需要它识别 Debug/Release）
- **独立 Clang / GCC**：直接引用 configurePreset 名称

### 测试 Preset（testPresets）

关联配置 Preset，用于运行 CTest。

### 打包 Preset（packagePresets）

关联配置 Preset，用于 CPack 打包。

- **Linux**：打包为 `.tar.gz`，输出到 `packages/`
- **Windows**：打包为 `.zip`，输出到 `packages/`

### 工作流 Preset（workflowPresets）

将 **配置 → 构建 → 测试 → 打包** 串联成一条命令：

```bash
cmake --workflow --preset workflow-gcc_14.2.0-debug
```

等价于依次执行：

```bash
cmake --preset gcc_14.2.0-debug
cmake --build --preset gcc_14.2.0-debug
ctest --preset ctest-gcc_14.2.0-debug
cpack --preset cpack-gcc_14.2.0-debug
```

## Preset 层级关系

```
CMakePresets.json
├── configurePresets          # 配置 Preset（编译器、生成器、构建类型）
├── buildPresets              # 构建 Preset（关联配置 Preset）
├── testPresets               # 测试 Preset（关联配置 Preset）
├── packagePresets            # 打包 Preset（关联配置 Preset）
└── workflowPresets           # 工作流 Preset（串联多个 Preset）
```

> 实际生成的名称取决于环境中检测到的编译器类型和版本。
