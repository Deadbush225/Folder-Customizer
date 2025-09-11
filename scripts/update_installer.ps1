# Start-Process -FilePath binarycreator.exe -ArgumentList ( "-n -c config/config.xml -p packages .\FolderCustomizerSetup-x64.exe") -NoNewWindow -Wait

# Ensure ./install exists by invoking the CMake convenience target
if (Test-Path ./build) {
	try {
		cmake --build ./build --target install_local --config Release | Out-Null
	} catch {}
}

# Resolve version from manifest.json if available
$version = ""
if (Test-Path ./manifest.json) {
	try {
		$json = Get-Content ./manifest.json | ConvertFrom-Json
		$version = $json.version
	} catch {}
}

$args = "./installer.iss"
if ($version) { $args = "/DMyAppVersion=$version $args" }

Start-Process "ISCC.exe" -ArgumentList $args -NoNewWindow -Wait

if (!(Test-Path ./windows-installer)) { New-Item -ItemType Directory -Path ./windows-installer | Out-Null }
Get-ChildItem -Path . -Filter "FolderCustomizerSetup-x64.exe" | ForEach-Object { Move-Item $_.FullName ./windows-installer/ -Force }

Get-ChildItem ./windows-installer -Filter "FolderCustomizerSetup-x64.exe" | Get-FileHash | Format-List
