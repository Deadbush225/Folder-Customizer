# Start-Process -FilePath binarycreator.exe -ArgumentList ( "-n -c config/config.xml -p packages .\FolderCustomizerSetup-x64.exe") -NoNewWindow -Wait

# Ensure ./install exists by invoking the CMake convenience target
if (Test-Path ./build) {
	try {
		cmake --build ./build --target install_local --config Release | Out-Null
	} catch {}
}

# Read values from manifest.json
$manifest = Get-Content -Raw -Path "./manifest.json" | ConvertFrom-Json
$version = "$($manifest.version)".Trim()
$desktopName = "$($manifest.desktop.desktop_name)".Trim()
$packageId = "$($manifest.desktop.package_id)".Trim()
Write-Host "Building installer version $version for $desktopName (package: $packageId)"

# Build the Windows installer with Inno Setup, passing values as defines
Start-Process "ISCC.exe" -ArgumentList @("/DMyAppVersion=$version", "/DMyAppName=`"$desktopName`"", "/DMyPackageId=$packageId", "./installer.iss") -NoNewWindow -Wait

if (!(Test-Path ./windows-installer)) { New-Item -ItemType Directory -Path ./windows-installer | Out-Null }
Get-ChildItem -Path . -Filter "FolderCustomizerSetup-x64.exe" | ForEach-Object { Move-Item $_.FullName ./windows-installer/ -Force }

Get-ChildItem ./windows-installer -Filter "FolderCustomizerSetup-x64.exe" | Get-FileHash | Format-List
