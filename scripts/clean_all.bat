@echo off
chcp 65001 >nul
setlocal

rem 工程根目录 = 本脚本所在目录的上一级（scripts/ 的父目录）
rem 这样无论从根目录执行 scripts\clean_all.bat，还是进入 scripts 后执行 .\clean_all.bat，
rem 都能正确定位到工程根目录。
set "ROOT_DIR=%~dp0.."

echo ======================================
echo  一键清理: build bin lib install packages
echo ======================================

if exist "%ROOT_DIR%\build"    rmdir /s /q "%ROOT_DIR%\build"
if exist "%ROOT_DIR%\bin"      rmdir /s /q "%ROOT_DIR%\bin"
if exist "%ROOT_DIR%\lib"      rmdir /s /q "%ROOT_DIR%\lib"
if exist "%ROOT_DIR%\install"  rmdir /s /q "%ROOT_DIR%\install"
if exist "%ROOT_DIR%\packages" rmdir /s /q "%ROOT_DIR%\packages"

echo.
echo ✅ 清理完成！

rem 交互式终端下暂停，CI / 脚本调用时（stdin 非终端）直接退出
if not defined CI pause