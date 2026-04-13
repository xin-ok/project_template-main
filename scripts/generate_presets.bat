@echo off
chcp 65001 >nul
setlocal

rem 工程根目录 = 本脚本所在目录的上一级（scripts/ 的父目录）
rem 这样无论从根目录执行 scripts\generate_presets.bat，还是进入 scripts 后执行 .\generate_presets.bat，
rem 都能正确定位到 cmake/GeneratePresets.cmake。
set "ROOT_DIR=%~dp0.."

echo ======================================
echo  生成 CMakePresets.json
echo ======================================

cmake -P "%ROOT_DIR%\cmake\GeneratePresets.cmake"
if errorlevel 1 (
    echo.
    echo ❌ 生成失败！
    pause
    exit /b 1
)

echo.
echo ✅ 生成完成！
pause
