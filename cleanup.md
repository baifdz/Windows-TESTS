

Creacion de nuevo usuario para borrado del antiguo usuario
```
$Password = Read-Host -AsSecureString "Introduce la contraseña para el nuevo admin"
New-LocalUser -Name "AdminEmpresa" -Password $Password -Description "Administrador de Respaldo"
Add-LocalGroupMember -Group "Administradores" -Member "AdminEmpresa"
```




# Desinstalar aplicaciones que no son del sistema (Cuidado: revisa la lista antes)

```

Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -notmatch "Microsoft" } | ForEach-Object {
    Write-Host "Desinstalando: $($_.Name)"
    $_.Uninstall()
}
```

# Eliminar aplicaciones de la Microsoft Store para el usuario actual
```
Get-AppxPackage | Where-Object { $_.IsFramework -eq $false } | Remove-AppxPackage
```
# Borrar todas las credenciales guardadas (Web y Windows)
```
cmdkey /list | ForEach-Object { if ($_ -match "Target: (.*)") { cmdkey /delete:$($matches[1]) } }
```

# Borra lo que no esté bloqueado sin mostrar errores
```
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
```

# Nota: Para desvincular correos de Outlook/Mail, lo más efectivo es borrar la carpeta de perfil:
```
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Outlook" -Recurse -Force -ErrorAction SilentlyContinue
```
# Borrar Archivos Temporales y Prefetch
```
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force
Remove-Item -Path "$env:TEMP\*" -Recurse -Force
Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force
```
# Limpiar Acceso Rápido e Historial de Explorador
```
$RecentFiles = "$env:APPDATA\Microsoft\Windows\Recent\*"
Remove-Item -Path $RecentFiles -Recurse -Force
```

3. Limpieza de Navegadores (Crucial)
```
$EdgeDir = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"
if (Test-Path $EdgeDir) {
    Remove-Item -Path "$EdgeDir\History" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$EdgeDir\Login Data" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$EdgeDir\Cookies" -Force -ErrorAction SilentlyContinue
}
```

# Limpiar el Visor de Eventos (Logs de sistema sobre qué se ejecutó)
```
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
```

# Sobrescribe todo el espacio libre del disco C:
```
cipher /w:C
```
