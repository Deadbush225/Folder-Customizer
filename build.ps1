# run using run-build.ps1

# cmake -S "./src" -B "./build" -G "Ninja"

$processOptions = @{
    FilePath     = "cmake"
    ArgumentList = "--build `"./build`""
}

$runApp = @{
    FilePath = "./build/FolderCustomizer.exe"
}

$process = Start-Process @processOptions -Wait -NoNewWindow -PassThru # -and (Start-Process @runApp -Wait -NoNewWindow)

if ($process.ExitCode -eq 0) {
    # "running the app ..."
    Clear-Host
    Start-Process @runApp -Wait -NoNewWindow
}

Start-Sleep 30000
# the default terminal must not be windows terminal, use the "host terminal" in the settings of windows terminal