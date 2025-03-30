Start-Process -FilePath binarycreator.exe -ArgumentList ( "-n -c config/config.xml -p packages .\FolderCustomizerSetup-x64.exe") -NoNewWindow -Wait

Get-FileHash "./FolderCustomizerSetup-x64.exe" | Format-List
