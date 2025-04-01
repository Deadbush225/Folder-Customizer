# Define the file path and the current version
$filePaths = @(
    # "./config/config.xml",
    # "./packages/com.mainprogram/meta/package.xml"
    "./installer.iss",
    "./Updater/updater.iss"
)

# Read the version from a JSON file
$jsonFilePath = "./manifest.json"
$jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json
$currentVersion = $jsonContent.version

foreach ($filePath in $filePaths) {
    Write-Host $filePath
    # Read the file content
    $fileContent = Get-Content -Path $filePath -Raw
    
    # Replace the version between <Version> tags
    $updatedContent = $fileContent -replace 'MyAppVersion ".*"', 'MyAppVersion "$currentVersion"'
    
    # Write the updated content back to the file
    Set-Content -Path $filePath -Value $updatedContent
}
    
Write-Host "Version updated to $currentVersion"