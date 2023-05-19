
$colors = "Red", "Violet", "Pink", "Lemon", "Green", "Orange", "Gray", "Black", "Azure", "Blue", "Brown"

foreach ($color in $colors) {
    Start-Process -FilePath "./icobundl.exe" -ArgumentList "-o FIN-$($color).ico $($color).ico $($color)-16.ico"
}