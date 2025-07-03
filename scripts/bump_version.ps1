# Define the file path and the current version
$filePaths = @(
    # "./config/config.xml",
    # "./packages/com.mainprogram/meta/package.xml"
    "./installer.iss"
    # "./Updater/updater.iss"
)

# Read the version from a JSON file
$jsonFilePath = "./manifest.json"
$jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json
$currentVersion = $jsonContent.version

# ━━━━━━━━━━━━━━━━━━━━━━━━━━ Installer.iss ━━━━━━━━━━━━━━━━━━━━━━━━━ #
$fileContent = Get-Content -Path "./installer.iss" -Raw

# Replace the version between <Version> tags
$updatedContent = $fileContent -replace 'MyAppVersion ".*"', "MyAppVersion `"$currentVersion`""

# Write the updated content back to the file
Set-Content -Path "./installer.iss" -Value $updatedContent

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━ updater.cpp ━━━━━━━━━━━━━━━━━━━━━━━━━━ #
$fileContent = Get-Content -Path "./Updater/updater.cpp" -Raw

# Replace the version between <Version> tags
$updatedContent = $fileContent -replace 'appVersion = ".*"', "appVersion = `"$currentVersion`""

# Write the updated content back to the file
Set-Content -Path "./Updater/updater.cpp" -Value $updatedContent


Write-Host "Version updated to $currentVersion"