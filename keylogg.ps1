# Example of reading direct input sequentially and saving it to a file
# Run this via: powershell.exe -WindowStyle Hidden -File script.ps1

$LogPath = "$PSScriptRoot\input_mapping.txt"

# This loop processes input directed to the process
while ($true) {
    if ([System.Console]::KeyAvailable) {
        $KeyInfo = [System.Console]::ReadKey($true)
        $Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        
        # Format and save the mapped key data
        "[ $Timestamp ] Mapped Key: $($KeyInfo.Key)" | Out-File -FilePath $LogPath -Append
    }
    Start-Sleep -Milliseconds 100  # Prevents 100% CPU usage
}
