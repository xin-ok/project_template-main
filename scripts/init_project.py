#!/usr/bin/env python3
"""
工程初始化脚本：把 project_template 模板实例化为指定工程名。

做的事情（按顺序）：
    1. 校验工程名
    2. 检查模板是否已被初始化过（防止二次运行破坏工程）
    3. 清理构建产物 build/ bin/ lib/ install/ packages/
    4. 精确替换各文件中的工程名（白名单，不做全局替换）
    5. 重命名 cmake/project_templateConfig.cmake.in -> cmake/<name>Config.cmake.in
    6. 调用 cmake -P cmake/GeneratePresets.cmake 生成 CMakePresets.json

注意：源码目录固定为 src/，不随工程名变化，因此无需重命名。

用法（在工程根目录执行）:
    python scripts/init_project.py MyProject
    python scripts/init_project.py MyProject --dry-run      # 只打印将要做的改动
    python scripts/init_project.py MyProject --force        # 跳过"已初始化"检查
    python scripts/init_project.py MyProject --no-presets   # 不自动生成 CMakePresets.json
    python scripts/init_project.py MyProject --keep-build   # 不清理构建产物

也可先进入 scripts 目录再执行：
    cd scripts
    python init_project.py MyProject

脚本始终以自身所在目录的上一级作为工程根目录，与当前工作目录无关。
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

# ============================================================
#  控制台编码
# ============================================================
# Windows 下重定向输出时 Python 默认用 GBK，emoji / 中文会抛 UnicodeEncodeError。
# 这里强制 stdout / stderr 使用 UTF-8，无法编码的字符用 '?' 代替而不是崩溃。
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):
        pass

# ============================================================
#  模板常量
# ============================================================

TEMPLATE_NAME = "project_template"

# 源码目录名：固定为 src，不随工程名变化
SRC_DIR = "src"

# 工程名规则：字母开头，只允许字母 / 数字 / 下划线
# 原因：工程名会作为 PROJECT_NAME、导出目标名 <name>Targets、find_package 包名使用，
#       含 '-' '.' 空格等字符会导致 CMake 配置或 find_package 失败。
NAME_PATTERN = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")

# 需要清理的构建产物目录
CLEAN_DIRS = ["build", "bin", "lib", "install", "packages"]

# 需要做文本替换的文件（相对路径 -> [(旧串, 新串模板), ...]）
# 新串模板中的 @NAME@ 会被替换为工程名。
# 注意：这里不用 str.format，因为 CMake 变量 ${PROJECT_SOURCE_DIR} 里的花括号
#       会被 format 当成占位符，导致 KeyError。
NAME_TOKEN = "@NAME@"

TEXT_REPLACEMENTS: dict[str, list[tuple[str, str]]] = {
    "CMakeLists.txt": [
        (f"project({TEMPLATE_NAME} VERSION", f"project({NAME_TOKEN} VERSION"),
        (f"set(export_name {TEMPLATE_NAME})", f"set(export_name {NAME_TOKEN})"),
    ],
    "README.md": [
        (f"# {TEMPLATE_NAME}", f"# {NAME_TOKEN}"),
    ],
    "scripts/package_install.py": [
        (f'f"{TEMPLATE_NAME}-install-{{stamp}}"', f'f"{NAME_TOKEN}-install-{{stamp}}"'),
        (f"python scripts/package_install.py {TEMPLATE_NAME}-1.0.0-win64",
         f"python scripts/package_install.py {NAME_TOKEN}-1.0.0-win64"),
    ],
    # examples/lib_test 直接链接工程内的目标名
    "examples/lib_test/CMakeLists.txt": [
        (f"    {TEMPLATE_NAME}\n", f"    {NAME_TOKEN}\n"),
    ],
    # examples/lib_test 的独立构建版本：find_package + 命名空间目标
    "examples/lib_test/CMakeLists.install.txt": [
        (f"find_package({TEMPLATE_NAME} REQUIRED)",
         f"find_package({NAME_TOKEN} REQUIRED)"),
        (f"{TEMPLATE_NAME}::{TEMPLATE_NAME}", f"{NAME_TOKEN}::{NAME_TOKEN}"),
    ],
}

# 需要重命名的文件（相对路径 -> 新文件名模板）
FILE_RENAMES: dict[str, str] = {
    f"cmake/{TEMPLATE_NAME}Config.cmake.in": f"cmake/{NAME_TOKEN}Config.cmake.in",
}

# 需要重命名的目录（相对路径 -> 新目录名模板）
# 源码目录固定为 src/，不随工程名变化，因此这里为空。
DIR_RENAMES: dict[str, str] = {}


# ============================================================
#  输出辅助
# ============================================================

def info(msg: str) -> None:
    print(f"  {msg}")


def step(msg: str) -> None:
    print(f"\n[{msg}]")


def warn(msg: str) -> None:
    print(f"  ⚠️  {msg}")


def error(msg: str) -> None:
    print(f"  ❌ {msg}", file=sys.stderr)


# ============================================================
#  校验
# ============================================================

def validate_name(name: str) -> str | None:
    """校验工程名，返回错误信息；合法则返回 None。"""
    if not name:
        return "工程名不能为空"
    if not NAME_PATTERN.match(name):
        return (
            f"工程名 '{name}' 不合法。\n"
            "     规则：必须以字母开头，只能包含字母、数字、下划线。\n"
            "     示例：MyProject / my_project / App2"
        )
    if name == TEMPLATE_NAME:
        return f"工程名不能是模板名 '{TEMPLATE_NAME}'，请换一个名字"
    return None


def is_already_initialized(root: Path) -> bool:
    """判断模板是否已被初始化过（顶层 CMakeLists.txt 里已不是模板名）。"""
    top = root / "CMakeLists.txt"
    if not top.is_file():
        return False
    content = top.read_text(encoding="utf-8")
    return f"project({TEMPLATE_NAME} VERSION" not in content


# ============================================================
#  各步骤实现
# ============================================================

def clean_build_artifacts(root: Path, dry_run: bool) -> None:
    step("清理构建产物")
    removed = 0
    for d in CLEAN_DIRS:
        target = root / d
        if target.is_dir():
            info(f"删除 {d}/")
            if not dry_run:
                shutil.rmtree(target, ignore_errors=True)
            removed += 1
    if removed == 0:
        info("没有需要清理的目录")


def apply_text_replacements(root: Path, name: str, dry_run: bool) -> None:
    step("替换文件内容")
    for rel_path, rules in TEXT_REPLACEMENTS.items():
        path = root / rel_path
        if not path.is_file():
            warn(f"跳过（文件不存在）：{rel_path}")
            continue

        content = path.read_text(encoding="utf-8")
        original = content
        hits = 0

        for old, new_tpl in rules:
            new = new_tpl.replace(NAME_TOKEN, name)
            count = content.count(old)
            if count:
                content = content.replace(old, new)
                hits += count
                info(f"{rel_path}: '{old}' -> '{new}'  ({count} 处)")

        if hits == 0:
            warn(f"{rel_path}: 未找到任何待替换内容（可能已初始化过）")
            continue

        if not dry_run and content != original:
            path.write_text(content, encoding="utf-8")


def rename_files(root: Path, name: str, dry_run: bool) -> None:
    step("重命名文件")
    for old_rel, new_tpl in FILE_RENAMES.items():
        old_path = root / old_rel
        new_path = root / new_tpl.replace(NAME_TOKEN, name)

        if not old_path.is_file():
            warn(f"跳过（文件不存在）：{old_rel}")
            continue
        if new_path.exists():
            warn(f"跳过（目标已存在）：{new_path.relative_to(root)}")
            continue

        info(f"{old_rel} -> {new_path.relative_to(root)}")
        if not dry_run:
            old_path.rename(new_path)


def rename_dirs(root: Path, name: str, dry_run: bool) -> None:
    step("重命名目录")
    for old_rel, new_tpl in DIR_RENAMES.items():
        old_path = root / old_rel
        new_path = root / new_tpl.replace(NAME_TOKEN, name)

        if not old_path.is_dir():
            warn(f"跳过（目录不存在）：{old_rel}/")
            continue
        if new_path.exists():
            warn(f"跳过（目标已存在）：{new_path.relative_to(root)}/")
            continue

        info(f"{old_rel}/ -> {new_path.relative_to(root)}/")
        if not dry_run:
            old_path.rename(new_path)


def generate_presets(root: Path, dry_run: bool) -> bool:
    """调用 cmake -P cmake/GeneratePresets.cmake 生成 CMakePresets.json。"""
    step("生成 CMakePresets.json")

    script = root / "cmake" / "GeneratePresets.cmake"
    if not script.is_file():
        warn(f"未找到 {script.relative_to(root)}，跳过")
        return False

    if dry_run:
        info("（dry-run）将执行：cmake -P cmake/GeneratePresets.cmake")
        return True

    cmake = shutil.which("cmake")
    if not cmake:
        warn("未在 PATH 中找到 cmake，请手动运行 scripts/generate_presets.bat 或 scripts/generate_presets.sh")
        return False

    result = subprocess.run(
        [cmake, "-P", str(script)],
        cwd=str(root),
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        warn(f"cmake 执行失败（返回码 {result.returncode}），请手动运行 generate_presets")
        return False

    info("✅ CMakePresets.json 已生成")
    return True


# ============================================================
#  主流程
# ============================================================

def main() -> int:
    parser = argparse.ArgumentParser(
        description="把 project_template 模板实例化为指定工程名",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "示例:\n"
            "  python scripts/init_project.py MyProject\n"
            "  python scripts/init_project.py MyProject --dry-run\n"
        ),
    )
    parser.add_argument("name", help="工程名（字母开头，只含字母/数字/下划线）")
    parser.add_argument("--dry-run", action="store_true", help="只打印将要做的改动，不落盘")
    parser.add_argument("--force", action="store_true", help="跳过'已初始化'检查")
    parser.add_argument("--no-presets", action="store_true", help="不自动生成 CMakePresets.json")
    parser.add_argument("--keep-build", action="store_true", help="不清理构建产物")
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    name = args.name.strip()

    print("======================================")
    print("  工程初始化")
    print("======================================")
    info(f"工程名: {name}")
    info(f"根目录: {root}")
    if args.dry_run:
        info("模式: dry-run（不会修改任何文件）")

    # ---- 1. 校验工程名 ----
    err = validate_name(name)
    if err:
        error(err)
        return 1

    # ---- 2. 检查是否已初始化 ----
    if is_already_initialized(root) and not args.force:
        error(
            "该模板似乎已经被初始化过（顶层 CMakeLists.txt 中已不是 "
            f"project({TEMPLATE_NAME} ...)）。\n"
            "     如果确认要继续，请加 --force 参数。"
        )
        return 1

    # ---- 3. 清理构建产物 ----
    if args.keep_build:
        step("清理构建产物")
        info("已跳过（--keep-build）")
    else:
        clean_build_artifacts(root, args.dry_run)

    # ---- 4. 文本替换（必须先于目录重命名）----
    apply_text_replacements(root, name, args.dry_run)

    # ---- 5. 重命名文件 ----
    rename_files(root, name, args.dry_run)

    # ---- 6. 重命名目录（最后做，避免路径失效）----
    rename_dirs(root, name, args.dry_run)

    # ---- 7. 生成 Presets ----
    if args.no_presets:
        step("生成 CMakePresets.json")
        info("已跳过（--no-presets）")
    else:
        generate_presets(root, args.dry_run)

    # ---- 完成提示 ----
    print()
    print("======================================")
    if args.dry_run:
        print("  ✅ dry-run 完成（未修改任何文件）")
    else:
        print(f"  ✅ 初始化完成：{name}")
    print("======================================")
    print()
    print("后续步骤：")
    print(f"  cmake --list-presets")
    print(f"  cmake --preset <preset-name>")
    print(f"  cmake --build --preset <preset-name>")
    print()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except BrokenPipeError:
        # 输出被管道提前关闭（如 `| Select-String` / `| head`），静默退出
        sys.stderr.close()
        sys.exit(0)
    except KeyboardInterrupt:
        print("\n已取消", file=sys.stderr)
        sys.exit(130)
