$currentDir = Get-Location

Get-ChildItem -Directory | ForEach-Object {
    Set-Location -Path $_

    Get-ChildItem -Filter "*.ico" | ForEach-Object {
        $outputFileName = $_.BaseName + ".bmp"
        
        if (-not (Test-Path "BMP")) {
            New-Item -ItemType Directory -Path "BMP"
        }
        
        magick "$($_.FullName)[0]" -depth 8 -define bmp:format=bmp3 -resize 16x16  "BMP3:BMP/$($outputFileName)"
    }
}

Set-Location $currentDir