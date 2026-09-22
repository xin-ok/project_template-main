#!/usr/bin/env python3
"""
合并 install 目录下的所有预设构建产物，并打包为 zip。

将 install/ 下的每个子目录（如 msvc18-debug、msvc18-release）内容
合并到一个临时目录，再打成 zip 包。

用法:
    python package_install.py                       # 包名自动带时间戳
    python package_install.py ProjectTemplate-1.0.0-win64
"""

import shutil
import sys
import tempfile
import zipfile
from datetime import datetime
from pathlib import Path


def main() -> int:
    # ---------- 确定包名 ----------
    package_name = sys.argv[1] if len(sys.argv) > 1 else ""
    if not package_name.strip():
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        package_name = f"ProjectTemplate-install-{stamp}"

    # 去掉可能手动带上的 .zip 后缀
    if package_name.lower().endswith(".zip"):
        package_name = package_name[:-4]

    # ---------- 目录准备 ----------
    root_dir    = Path(__file__).resolve().parent
    install_dir = root_dir / "install"
    output_dir  = root_dir / "packages"

    # ---------- 校验 install 目录 ----------
    if not install_dir.is_dir():
        print(f"错误：未找到 install 目录：{install_dir}")
        return 1

    sub_dirs = [d for d in install_dir.iterdir() if d.is_dir()]
    if not sub_dirs:
        print("错误：install 目录下没有任何子目录可合并")
        return 1

    print("======================================")
    print("  合并 install 并打包 zip")
    print("======================================")

    output_dir.mkdir(parents=True, exist_ok=True)

    # ---------- 用临时目录做 staging ----------
    staging = Path(tempfile.mkdtemp(prefix="nspkg_"))
    try:
        # ---------- 逐个合并子目录 ----------
        for d in sub_dirs:
            print(f"合并目录：{d.name}")
            # dirs_exist_ok=True 允许覆盖已存在文件，等价 Copy-Item -Force
            shutil.copytree(d, staging, dirs_exist_ok=True)

        # ---------- 打 zip ----------
        zip_path = output_dir / f"{package_name}.zip"
        if zip_path.exists():
            zip_path.unlink()

        top_items = list(staging.iterdir())

        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
            for item in staging.rglob("*"):
                if item.is_file():
                    # arcname 相对 staging，避免把 staging 这层目录名写进去
                    zf.write(item, item.relative_to(staging))

        print()
        print(f"打包完成：{zip_path}")
        print("包内顶层内容：")
        for item in top_items:
            print(f"  - {item.name}")

    finally:
        # ---------- 清理临时目录 ----------
        if staging.exists():
            shutil.rmtree(staging, ignore_errors=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())