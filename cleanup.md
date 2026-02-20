# Desinstalar aplicaciones que no son del sistema (Cuidado: revisa la lista antes)
Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -notmatch "Microsoft" } | ForEach-Object {
    Write-Host "Desinstalando: $($_.Name)"
    $_.Uninstall()
}

# Eliminar aplicaciones de la Microsoft Store para el usuario actual
Get-AppxPackage | Where-Object { $_.IsFramework -eq $false } | Remove-AppxPackage

# Borrar todas las credenciales guardadas (Web y Windows)
cmdkey /list | ForEach-Object { if ($_ -match "Target: (.*)") { cmdkey /delete:$($matches[1]) } }

# Nota: Para desvincular correos de Outlook/Mail, lo más efectivo es borrar la carpeta de perfil:
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Outlook" -Recurse -Force -ErrorAction SilentlyContinue

# Borrar Archivos Temporales y Prefetch
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force
Remove-Item -Path "$env:TEMP\*" -Recurse -Force
Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force

# Limpiar Acceso Rápido e Historial de Explorador
$RecentFiles = "$env:APPDATA\Microsoft\Windows\Recent\*"
Remove-Item -Path $RecentFiles -Recurse -Force

# Limpiar el Visor de Eventos (Logs de sistema sobre qué se ejecutó)
Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log }


$RegistryPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU"
)

foreach ($path in $RegistryPaths) {
    if (Test-Path $path) {
        Remove-ItemProperty -Path $path -Name "*" -ErrorAction SilentlyContinue
    }
}
