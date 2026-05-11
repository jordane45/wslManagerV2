# Build portable ZIP for WSL Manager
# Usage: .\scripts\build_portable.ps1
# Output: dist\WSLManager_portable.zip

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path $PSScriptRoot -Parent
$BuildDir    = Join-Path $ProjectRoot 'build\windows\x64\runner\Release'
$DestDir     = Join-Path $ProjectRoot 'dist\WSLManager'
$ZipPath     = Join-Path $ProjectRoot 'dist\WSLManager_portable.zip'

Write-Host '==> flutter build windows --release' -ForegroundColor Cyan
Push-Location $ProjectRoot
flutter build windows --release
Pop-Location

if (-not (Test-Path $BuildDir)) {
    Write-Error "Build directory not found: $BuildDir"
    exit 1
}

# Clean previous dist
if (Test-Path $DestDir) { Remove-Item $DestDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

Write-Host "==> Copying to $DestDir" -ForegroundColor Cyan
Copy-Item -Recurse "$BuildDir\*" $DestDir

# Rename executable to WSLManager.exe
$srcExe  = Join-Path $DestDir 'wsl_manager.exe'
$destExe = Join-Path $DestDir 'WSLManager.exe'
if (Test-Path $srcExe) {
    Rename-Item $srcExe $destExe
    Write-Host "==> Renamed wsl_manager.exe -> WSLManager.exe"
}

# Create portable ZIP
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Write-Host "==> Creating $ZipPath" -ForegroundColor Cyan
Compress-Archive -Path $DestDir -DestinationPath $ZipPath

$SizeMb = [math]::Round((Get-Item $ZipPath).Length / 1MB, 1)
Write-Host "==> Done: $ZipPath ($SizeMb MB)" -ForegroundColor Green
