#!/bin/bash
# 工程根目录 = 本脚本所在目录的上一级（scripts/ 的父目录）
# 这样无论从根目录执行 scripts/clean_all.sh，还是进入 scripts 后执行 ./clean_all.sh，
# 都能正确定位到工程根目录。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

clear
echo "======================================"
echo "  一键清理: build bin lib install packages"
echo "======================================"

# 静默删除目录，不存在也不报错
rm -rf "$ROOT_DIR/build"
rm -rf "$ROOT_DIR/bin"
rm -rf "$ROOT_DIR/lib"
rm -rf "$ROOT_DIR/install"
rm -rf "$ROOT_DIR/packages"

echo ""
echo "✅ 清理完成！"