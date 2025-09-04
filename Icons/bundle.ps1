# combines (32, 48, 256) and 16 icons

$tones = "Dark", "Light", "Normal"

$colors = "Red", "Violet", "Pink", "Lemon", "Green", "Orange", "Gray", "Black", "Azure", "Blue", "Brown", "White"

$currentDir = Get-Location

foreach ($tone in $tones) {
    foreach ($color in $colors) {
        Start-Process -FilePath "./icobundl.exe" -ArgumentList "-o ./$($tone)/$($color).ico ./$($tone)/ICO/$($color).ico ./$($tone)/ICO/$($color)-16.ico"
    }
}

Set-Location $currentDir