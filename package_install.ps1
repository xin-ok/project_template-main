<#
.SYNOPSIS
    合并 install 目录下的所有预设构建产物，并打包为 zip。

.DESCRIPTION
    将 install/ 下的每个子目录（如 msvc18-debug、msvc18-release）内容
    合并到一个临时目录，再打成 zip 包。

.PARAMETER PackageName
    zip 包名（不含 .zip 后缀）。缺省时使用 ProjectTemplate-install-<时间戳>。

.EXAMPLE
    .\package_install.ps1 ProjectTemplate-1.0.0-win64
#>

param(
    [string]$PackageName = ""
)

$ErrorActionPreference = "Stop"

$RootDir    = $PSScriptRoot
$InstallDir = Join-Path $RootDir "install"
$OutputDir  = Join-Path $RootDir "packages"

# ---------- 确定包名 ----------
if ([string]::IsNullOrWhiteSpace($PackageName)) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $PackageName = "ProjectTemplate-install-$stamp"
}
# 去掉可能手动带上的 .zip 后缀
$PackageName = $PackageName -replace '\.zip$', ''

# ---------- 校验 install 目录 ----------
if (-not (Test-Path $InstallDir)) {
    Write-Host "错误：未找到 install 目录：$InstallDir" -ForegroundColor Red
    exit 1
}

$subDirs = @(Get-ChildItem -Path $InstallDir -Directory)
if ($subDirs.Count -eq 0) {
    Write-Host "错误：install 目录下没有任何子目录可合并" -ForegroundColor Red
    exit 1
}

Write-Host "======================================"
Write-Host "  合并 install 并打包 zip"
Write-Host "======================================"

# ---------- 准备输出目录与临时目录 ----------
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$staging = Join-Path $env:TEMP ("nspkg_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $staging | Out-Null

try {
    # ---------- 逐个合并子目录 ----------
    foreach ($dir in $subDirs) {
        Write-Host "合并目录：$($dir.Name)"
        Copy-Item -Path (Join-Path $dir.FullName "*") -Destination $staging -Recurse -Force
    }

    # ---------- 打 zip ----------
    $zipPath = Join-Path $OutputDir "$PackageName.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }

    $topItems = @(Get-ChildItem -Path $staging)
    Compress-Archive -Path $topItems.FullName -DestinationPath $zipPath

    Write-Host ""
    Write-Host "打包完成：$zipPath" -ForegroundColor Green
    Write-Host "包内顶层内容："
    foreach ($item in $topItems) {
        Write-Host "  - $($item.Name)"
    }
}
finally {
    # ---------- 清理临时目录 ----------
    if (Test-Path $staging) {
        Remove-Item $staging -Recurse -Force
    }
}