

#Creacion de nuevo usuario para borrado del antiguo usuario
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
#Script para limpiar y ocultar Recomendaciones de Inicio
```
Write-Host "Limpiando Caché de Recomendaciones y Jump Lists..." -ForegroundColor Cyan

# 1. Limpiar el historial de Destinos Automáticos y Personalizados (Jump Lists y Recomendaciones de Inicio)
$Destinations = @(
    "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*",
    "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations\*"
)
Remove-Item -Path $Destinations -Force -ErrorAction SilentlyContinue

# 2. Limpiar la base de datos de Actividad de Windows (Windows Timeline / Caché de Actividad)
$ActivityCache = "$env:LOCALAPPDATA\ConnectedDevicesPlatform\*\*"
Remove-Item -Path $ActivityCache -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Desactivando el rastreo de archivos recientes en el Registro..." -ForegroundColor Cyan

# 3. Desactivar que Windows siga rastreando y mostrando estos archivos en Inicio
$ExplorerKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# Ocultar documentos y archivos recientes en Inicio y Explorador
Set-ItemProperty -Path $ExplorerKey -Name "Start_TrackDocs" -Value 0 -ErrorAction SilentlyContinue

# Ocultar programas o aplicaciones abiertas/instaladas recientemente
Set-ItemProperty -Path $ExplorerKey -Name "Start_TrackProgs" -Value 0 -ErrorAction SilentlyContinue

Write-Host "Reiniciando el Explorador de Windows para aplicar los cambios..." -ForegroundColor Yellow

# 4. Reiniciar el explorador para que el menú Inicio se actualice de inmediato
Stop-Process -Name explorer -Force
```

# Definir las aplicaciones y las versiones de Office (16.0 es Office 365/2019/2016, 15.0 es 2013, etc.)
```
$OfficeApps = @("Word", "Excel", "PowerPoint")
$OfficeVersions = @("16.0", "15.0", "14.0", "12.0") 

Write-Host "Iniciando limpieza de registros de Office..." -ForegroundColor Cyan

foreach ($Version in $OfficeVersions) {
    foreach ($App in $OfficeApps) {
        # Rutas comunes donde Office guarda el historial
        $MRUPaths = @(
            "HKCU:\Software\Microsoft\Office\$Version\$App\User MRU",
            "HKCU:\Software\Microsoft\Office\$Version\$App\File MRU",
            "HKCU:\Software\Microsoft\Office\$Version\$App\Place MRU",
            "HKCU:\Software\Microsoft\Office\$Version\$App\Reading Locations"
        )

        foreach ($Path in $MRUPaths) {
            if (Test-Path $Path) {
                # Se elimina la carpeta del registro completa, Office la volverá a crear vacía cuando se abra
                Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Limpiado: $App (Versión $Version)" -ForegroundColor Green
            }
        }
    }
}

Write-Host "Limpieza de Office completada." -ForegroundColor Cyan
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
#regedit cleanup
```

```

#network cleanup
```
Write-Host "Iniciando limpieza de configuraciones de red..." -ForegroundColor Cyan

# 1. Eliminar todos los perfiles de redes Wi-Fi guardados (Nombres y Contraseñas)
Write-Host "Borrando redes Wi-Fi conocidas..." -ForegroundColor Yellow
netsh wlan delete profile name=* i=*

# 2. Eliminar todas las conexiones VPN configuradas por el usuario
Write-Host "Borrando conexiones VPN..." -ForegroundColor Yellow
Get-VpnConnection -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-VpnConnection -Name $_.Name -Force -ErrorAction SilentlyContinue
    Write-Host "VPN eliminada: $($_.Name)" -ForegroundColor Green
}

# 3. Desconectar y olvidar unidades de red mapeadas (Carpetas compartidas de la empresa)
Write-Host "Borrando unidades de red y conexiones a servidores..." -ForegroundColor Yellow
Get-SmbMapping -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-SmbMapping -LocalPath $_.LocalPath -Force -UpdateProfile -ErrorAction SilentlyContinue
    Write-Host "Unidad de red desconectada: $($_.LocalPath)" -ForegroundColor Green
}

# Alternativa clásica por si quedan conexiones persistentes (SMB) en caché
net use * /delete /y | Out-Null

Write-Host "Limpieza de redes completada." -ForegroundColor Green
```



# Sobrescribe todo el espacio libre del disco C:
```
cipher /w:C
```
