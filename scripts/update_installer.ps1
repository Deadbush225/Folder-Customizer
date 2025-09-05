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

# If the install tree used a nested 'bin' directory (./install/bin), flatten it
# so the installer packages files directly under the install root (no {app}\bin).
if (Test-Path ./install/bin) {
	Write-Host "Flattening './install/bin' into './install' for installer packaging"
	try {
		Get-ChildItem -Path ./install/bin -Force | ForEach-Object {
			$source = $_.FullName
			$dest = Join-Path (Resolve-Path ./install).Path $_.Name
			if (Test-Path $dest) {
				Remove-Item -Recurse -Force $dest -ErrorAction SilentlyContinue
			}
			Move-Item -Path $source -Destination $dest -Force
		}
		# remove the empty bin directory
		Remove-Item -Recurse -Force ./install/bin -ErrorAction SilentlyContinue
	} catch {
		Write-Host "Warning: could not flatten install/bin: $_"
	}
}

if (!(Test-Path ./windows-installer)) { New-Item -ItemType Directory -Path ./windows-installer | Out-Null }
Get-ChildItem -Path . -Filter "FolderCustomizerSetup-x64.exe" | ForEach-Object { Move-Item $_.FullName ./windows-installer/ -Force }

Get-ChildItem ./windows-installer -Filter "FolderCustomizerSetup-x64.exe" | Get-FileHash | Format-List
