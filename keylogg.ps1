# Example of reading direct input sequentially and saving it to a file
#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
# Run this via: powershell.exe -WindowStyle Hidden -File script.ps1


$ScriptContent = @'
# Define the absolute path to the system Temp directory
$LogPath = "C:\Windows\Temp\input_mapping.txt"

# Processing loop for direct console input
while ($true) {
    if ([System.Console]::KeyAvailable) {
        $KeyInfo = [System.Console]::ReadKey($true)
        $Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        "[ $Timestamp ] Mapped Key: $($KeyInfo.Key)" | Out-File -FilePath $LogPath -Append
    }
    Start-Sleep -Milliseconds 100
}
'@

# Save the script file directly inside Windows\Temp
$ScriptContent | Out-File -FilePath "C:\Windows\Temp\script.ps1" -Encoding utf8


#Validate the file
#Get-ChildItem .\script.ps1

#Run the file
#powershell.exe -WindowStyle Hidden -File "C:\Windows\Temp\script.ps1"


#Stop it
#Stop-Process -Name "powershell" -Force

#Remove it
#Clear-Content -Path "C:\Windows\Temp\input_mapping.txt"
#Remove-Item -Path "C:\Windows\Temp\script.ps1" -Force

#Overrides execution permissions to run it and keep it on process
#run powershell.exe -ExecutionPolicy Bypass -File "C:\Windows\Temp\script.ps1"




# Start a clean, system-supported log of all console activity
Start-Transcript -Path "C:\Windows\Temp\admin_audit_log.txt" -NoClobber

# [Put any other administrative tools or automation commands here]

# Stop the log when finished
Stop-Transcript
