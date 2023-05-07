$Answer = "true"

While (-not ($Answer -eq "x")) {
    $Process = Start-Process -FilePath pwsh -ArgumentList ".\build.ps1" -WindowStyle "Maximized" -PassThru
    $Answer = Read-Host "Please enter to [re]start, x to exit"
    try {
        # Stop-Process -Id $Process.Id -Force
        # Stop-Process -Name "WindowsTerminal" -Force
        # $ProcessIds = Get-CimInstance -Class Win32_Process -Filter "Name = 'WindowsTerminal.exe'"
        # foreach ($currentItemName in $ProcessIds) {
        #     <# $currentItemName is the current item #>
        #     $currentItemName.
        #     $Process.SessionId
        #     # if ($currentItemName.Id == $Process.Id) {
        #     # }
        # }
        # $parentProcessID = Get-CimInstance -className win32_process | where-object {$_.ProcessId -eq $Process.Id } | select ParentProcessId
        # $parentProcessID
        $Process.Parent.Id
        $Process.Kill($true)
        # Stop-Process -Id $Process.Parent.Id
        # Stop-Process -Id $Process.Id

        # }
        # Stop-Process -Id $Process.Handle -Force
        # $Process.CloseMainWindow()
    } catch {}
}
