#!/bin/bash
# 工程根目录 = 本脚本所在目录的上一级（scripts/ 的父目录）
# 这样无论从根目录执行 scripts/generate_presets.sh，还是进入 scripts 后执行 ./generate_presets.sh，
# 都能正确定位到 cmake/GeneratePresets.cmake。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "======================================"
echo "  生成 CMakePresets.json"
echo "======================================"

if ! cmake -P "$ROOT_DIR/cmake/GeneratePresets.cmake"; then
    echo ""
    echo "❌ 生成失败！"
    exit 1
fi

echo ""
echo "✅ 生成完成！"
