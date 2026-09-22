# 编译选项

## Debug 模式

- **调试信息**：`-g3`（GCC/Clang）/ `/Zi`（MSVC）— 最详细调试信息
- **优化**：`-O0`（GCC/Clang）/ `/Od`（MSVC）— 禁用优化
- **帧指针**：保留帧指针，获得更好的堆栈回溯
- **后缀**：可执行文件自动添加 `d` 后缀（如 `project1d`）

## Release 模式

- **优化**：默认启用最高优化级别
- **可选**：可通过 CMake 变量开启调试信息或禁用优化

## Sanitizer（可选）

配置时通过 CMake 变量启用：

```bash
# AddressSanitizer（检测内存错误）
cmake --preset gcc_14.2.0-debug -DENABLE_FSANITIZE_ADDRESS=ON

# UndefinedBehaviorSanitizer（检测未定义行为）
cmake --preset gcc_14.2.0-debug -DENABLE_FSANITIZE_UNDEFINED=ON

# ThreadSanitizer（检测数据竞争）
cmake --preset gcc_14.2.0-debug -DENABLE_FSANITIZE_THREAD=ON
```

## 代码格式化

项目参考 Google C++ 风格指南，配置文件为 `.clang-format`。

## 清理构建产物

```bash
# Linux
./clean_all.sh

# Windows
clean_all.bat

# 或使用 CMake 自定义目标
cmake --build build/gcc_14.2.0-debug --target clean_all_binary
```

## 许可证

本项目基于 [MIT License](../LICENSE) 开源。
