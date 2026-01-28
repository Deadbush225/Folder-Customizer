#!/usr/bin/env pwsh
param(
    [string]$QtPath = "F:\Dev\Qt\6.7.3\mingw_64",
    [string]$BoostPath = "F:\Dev\boost_1_86_0\stage\",
    [switch]$SkipBuild,
    [switch]$Publish
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$projectRoot = Split-Path $scriptDir -Parent

Set-Location $projectRoot

# Read Version from manifest.json
$manifestPath = Join-Path $projectRoot "manifest.json"
if (-not (Test-Path $manifestPath)) {
    Write-Error "manifest.json not found!"
}
$manifest = Get-Content $manifestPath | ConvertFrom-Json
$version = $manifest.VERSION
Write-Host "Detected Version: $version" -ForegroundColor Cyan

# 1. Configure and Build
if (-not $SkipBuild) {
    Write-Host "Configuring CMake..." -ForegroundColor Cyan
    & cmake -S . -B .\build\build-windows\ -G Ninja `
        -DCMAKE_PREFIX_PATH="$QtPath" `
        -DBoost_ROOT="$BoostPath"

    Write-Host "Building project..." -ForegroundColor Cyan
    & cmake --build .\build\build-windows\ --target install_local
} else {
    Write-Host "Skipping build steps..." -ForegroundColor Yellow
}

# 2. Build Installer
Write-Host "Building Installer..." -ForegroundColor Cyan
$installerScript = "installer.iss"
$outputDir = "release-assets"

# Try to find ISCC
$iscc = Get-Command "ISCC" -ErrorAction SilentlyContinue
if (-not $iscc) {
    $possiblePaths = @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe"
    )
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $iscc = $path
            break
        }
    }
}

if (-not $iscc) {
    Write-Error "ISCC (Inno Setup Compiler) not found. Please add it to PATH or install it."
}

# Run ISCC
# We define MyAppVersion to match manifest version
& $iscc "/DMyAppVersion=$version" $installerScript

# Expected Installer Path
# .iss defines OutputBaseFilename={#MyPackageId}-{#MyAppVersion}
# MyPackageId default is "folder-customizer"
$installerName = "folder-customizer-$version.exe" 
$installerPath = Join-Path $projectRoot "$outputDir\$installerName"

if (-not (Test-Path $installerPath)) {
    Write-Error "Installer was not found at expected path: $installerPath"
}

Write-Host "Installer created at: $installerPath" -ForegroundColor Green

# 3. Release
if ($Publish) {
    Write-Host "Invoking eRelease..." -ForegroundColor Cyan
    $eReleaseScript = Join-Path $scriptDir "eRelease/eRelease.ps1"
    
    # Pass the installer as an asset
    if (Test-Path $eReleaseScript) {
        & $eReleaseScript
    } else {
        Write-Error "eRelease script not found at $eReleaseScript"
    }
} else {
    Write-Host "Skipping release (use -Publish to release)" -ForegroundColor Yellow
}
