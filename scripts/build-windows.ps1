# Build script for Windows builds
param (
    [switch]$Debug,
    [switch]$Clean,
    [switch]$Install,
    [switch]$Package,
    [int]$Jobs = 4
)

# Helper functions for colored output
function Write-ColoredOutput {
    param (
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    $originalColor = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $host.UI.RawUI.ForegroundColor = $originalColor
}

function Write-Info {
    param ([string]$Message)
    Write-ColoredOutput "[INFO] $Message" -ForegroundColor "Cyan"
}

function Write-Success {
    param ([string]$Message)
    Write-ColoredOutput "[SUCCESS] $Message" -ForegroundColor "Green"
}

function Write-Warning {
    param ([string]$Message)
    Write-ColoredOutput "[WARNING] $Message" -ForegroundColor "Yellow"
}

function Write-Error {
    param ([string]$Message)
    Write-ColoredOutput "[ERROR] $Message" -ForegroundColor "Red"
}

# Set up paths
$ScriptPath = $PSScriptRoot
$ProjectRoot = (Get-Item $ScriptPath).Parent.FullName
$BuildDir = Join-Path $ProjectRoot "build\build-windows"

# Ensure build directory exists
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

# Determine build type
$BuildType = "Release"
if ($Debug) {
    $BuildType = "Debug"
}

# Clean if requested
if ($Clean) {
    Write-Info "Cleaning build directory..."
    Get-ChildItem -Path $BuildDir -Recurse | Remove-Item -Recurse -Force
}

# Configure
Write-Info "Configuring with CMake (BUILD_TYPE=$BuildType)..."
Push-Location $ProjectRoot
cmake -B $BuildDir -G "Ninja" -DCMAKE_BUILD_TYPE=$BuildType -DCMAKE_INSTALL_PREFIX="$ProjectRoot\install"
if ($LASTEXITCODE -ne 0) {
    Write-Error "CMake configuration failed"
    exit 1
}

# Build
Write-Info "Building with $Jobs jobs..."
cmake --build $BuildDir --config $BuildType --parallel $Jobs
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

# Install locally if requested
if ($Install) {
    Write-Info "Installing to $ProjectRoot\install..."
    cmake --build $BuildDir --config $BuildType --target install
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Installation failed"
        exit 1
    }
}

# Create packages if requested
if ($Package) {
    Write-Info "Creating packages..."
    & "$ProjectRoot\scripts\update_installer.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Package creation failed"
        exit 1
    }
}

Write-Success "Build completed successfully!"
Pop-Location
