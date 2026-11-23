# PowerShell — Comandos de Administración y Diagnóstico de Windows


Claro. Aquí tienes únicamente el índice, manteniendo la numeración de los mismos comandos:


# Índice — PowerShell: Administración y Diagnóstico de Windows

1. [Forzar la aparición del cuadro "Otro usuario"](#1-forzar-la-aparición-del-cuadro-otro-usuario)
2. [Habilitar el Cambio Rápido de Usuario](#2-habilitar-el-cambio-rápido-de-usuario)
3. [Obtener programas instalados](#3-obtener-programas-instalados)
4. [Versión de Windows](#4-versión-de-windows)
5. [Desinstalar una aplicación específica](#5-desinstalar-una-aplicación-específica)
6. [Get driver info](#6-get-driver-info)
7. [LDWin](#7-ldwin)
8. [Sesiones activas de usuario](#8-sesiones-activas-de-usuario)
9. [Buscar archivos que contengan "video" en el nombre](#9-buscar-archivos-que-contengan-video-en-el-nombre)
10. [Buscar archivos .exe](#10-buscar-archivos-exe)
11. [Programas instalados y fecha de instalación](#11-programas-instalados-y-fecha-de-instalación)
12. [Event Log Method (Most Accurate for Dates)](#12-event-log-method-most-accurate-for-dates)
13. [View Recently Modified or Created Files](#13-view-recently-modified-or-created-files)
14. [Find Files Created (Instead of Modified) Recently](#14-find-files-created-instead-of-modified-recently)
15. [Check for Malicious Persistence (Startup & Tasks)](#15-check-for-malicious-persistence-startup--tasks)
16. [List Hidden Active Tasks](#16-list-hidden-active-tasks)
17. [Find Processes Running from Unexpected Folders](#17-find-processes-running-from-unexpected-folders)
18. [Compress a folder to .zip](#18-compress-a-folder-to-zip)
19. [Adición de ruta a variables de entorno](#19-adición-de-ruta-a-variables-de-entorno)
20. [Certificados instalados](#20-certificados-instalados)
21. [Disable GPS](#21-disable-gps)
22. [Enable GPS](#22-enable-gps)
23. [Window message response](#23-window-message-response)
24. [Procesos Vinculados a Apps](#24-procesos-vinculados-a-apps)
25. [Procesos con más consumo de RAM](#25-procesos-con-más-consumo-de-ram)
26. [Quitar Permisos de Administrador](#26-quitar-permisos-de-administrador)
27. [Pop Up with timer](#27-pop-up-with-timer)
28. [Show network adapters interfaces](#28-show-network-adapters-interfaces)
29. [Disable Network Adapter](#29-disable-network-adapter)
30. [Enable Network Adapter](#30-enable-network-adapter)
31. [List letter disks](#31-list-letter-disks)
32. [Ask for a web request (universal command for text)](#32-ask-for-a-web-request-universal-command-for-text)
33. [Ask for a web request (universal command for download)](#33-ask-for-a-web-request-universal-command-for-download)


## 1. Forzar la aparición del cuadro "Otro usuario"

~~~powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "dontdisplaylastusername" -Value 1
~~~

## 2. Habilitar el Cambio Rápido de Usuario

~~~powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "HideFastUserSwitching" -Value 0
~~~

## 3. Obtener programas instalados

~~~powershell
$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

Get-ItemProperty $RegistryPaths | 
    Where-Object { $_.DisplayName -ne $null } | 
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | 
    Sort-Object DisplayName
~~~

### PowerShell 5.1 (Get-Package)

Returns a concise table including packages installed via PackageManagement and traditional programs.

~~~powershell
Get-Package | Select-Object Name, Version, ProviderName
~~~

### Windows Store/UWP Apps (Get-AppxPackage)

Specifically lists modern "Metro" or Store apps.

~~~powershell
Get-AppxPackage | Select-Object Name, PackageFullName
~~~

## 4. Versión de Windows

~~~powershell
$Ver = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'; "Windows Version: $($Ver.DisplayVersion) (Build $($Ver.CurrentBuildNumber).$($Ver.UBR))"
~~~

## 5. Desinstalar una aplicación específica

Para desinstalar una aplicación específica, se usa el comando con su nombre completo (PackageFullName):

~~~powershell
Get-AppxPackage *programa* | Remove-AppxPackage
~~~

~~~powershell
Uninstall-Package -Name "programa"
~~~

## 6. Get driver info

~~~powershell
Get-NetAdapter
Get-NetAdapterAdvancedProperty -Name "Ethernet" | Select-Object DisplayName, RegistryKeyword
~~~

## 7. LDWin

https://github.com/chall32/LDWin

https://github.com/chall32/LDWin.git

### Step 1: Create the LLDP Registry Key and Property

~~~powershell
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "LLDP" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLDP" -Name "AdvertiseHostInformation" -Value 1 -PropertyType DWORD -Force
~~~

### Step 2: Configure and Start the LLDP Service

~~~powershell
Set-Service -Name "lldpsvc" -StartupType manual
Start-Service -Name "lldpsvc"
~~~

### Step 3: Restart the Network Adapter

~~~powershell
Restart-NetAdapter -Name "Ethernet" -Confirm:$false
~~~

## 8. Sesiones activas de usuario

~~~powershell
query user
~~~

## 9. Buscar archivos que contengan "video" en el nombre

Scan all local drives for any file with "video" in the name:

~~~powershell
Get-ChildItem -Path "C:\" -Filter "*video*" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
~~~
~~~powershell
Get-ChildItem -Path "C:\" -Filter "*video*" -File -Recurse -ErrorAction SilentlyContinue | Select-Object FullName, LastWriteTime, CreationTime, LastAccessTime
~~~


## 10. Buscar archivos .exe

Scan all local drives for any file with ".exe" in the name (date included):

~~~powershell
Get-ChildItem -Path "C:\" -Filter "*.exe*" -File -Recurse -ErrorAction SilentlyContinue | Select-Object FullName, LastWriteTime | Sort-Object LastWriteTime -Descending
~~~

## 11. Programas instalados y fecha de instalación

This targets the 64-bit and 32-bit system registration paths. Note that some programs do not supply an absolute InstallDate to the registry.

~~~powershell
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
Where-Object {$_.DisplayName} | 
Select-Object DisplayName, DisplayVersion, InstallDate | 
Sort-Object InstallDate -Descending
~~~

## 12. Event Log Method (Most Accurate for Dates)

~~~powershell
Get-WinEvent -ProviderName msiinstaller | 
Where-Object {$_.Id -eq 1033} | 
Select-Object TimeCreated, Message | 
Format-Table -Wrap
~~~

## 13. View Recently Modified or Created Files

~~~powershell
Get-ChildItem -Path "C:\" -Recurse -File -ErrorAction SilentlyContinue | 
Sort-Object LastWriteTime -Descending | 
Select-Object Name, LastWriteTime, FullName -First 20
~~~

## 14. Find Files Created (Instead of Modified) Recently

~~~powershell
Get-ChildItem -Path "C:\" -Recurse -File | 
Sort-Object CreationTime -Descending | 
Select-Object Name, CreationTime, FullName -First 20
~~~

## 15. Check for Malicious Persistence (Startup & Tasks)

~~~powershell
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | Format-Table -AutoSize
~~~

## 16. List Hidden Active Tasks

~~~powershell
Get-ScheduledTask | Get-ScheduledTaskInfo | Sort-Object LastRunTime -Descending | Select-Object TaskName, LastRunTime | Out-GridView
~~~

## 17. Find Processes Running from Unexpected Folders

~~~powershell
Get-Process | Select-Object Name, Id, @{Name="Path"; Expression={$_.Path}} | Where-Object {$_.Path -ne $null} | Sort-Object Name
~~~

## 18. Compress a folder to .zip

~~~powershell
Compress-Archive -Path "C:\" -DestinationPath "C:\output.zip"
~~~

## 19. Adición de ruta a variables de entorno

~~~powershell
# 1. Definir la ruta del programa
$ruta = "C:\Program Files\<program.exe>"
# 2. Añadir al PATH Global (Para todos los usuarios de la maquina)
$oldPathMachine = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($oldPathMachine -notlike "*$ruta*") {
    [Environment]::SetEnvironmentVariable("Path", "$oldPathMachine;$ruta", "Machine")
}
# 3. Añadir al PATH del Usuario Actual
$oldPathUser = [Environment]::GetEnvironmentVariable("Path", "User")
if ($oldPathUser -notlike "*$ruta*") {
    [Environment]::SetEnvironmentVariable("Path", "$oldPathUser;$ruta", "User")
}
~~~

## 20. Certificados instalados

~~~powershell
Get-ChildItem -Path Cert:\LocalMachine -Recurse
~~~

### Buscar un certificado específico por su nombre (Subject)

~~~powershell
Get-ChildItem -Path Cert:\LocalMachine -Recurse | Where-Object { $_.Subject -like "*NombreDelCertificado*" }
~~~

### Quitar un certificado

~~~powershell
Get-ChildItem -Path Cert:\CurrentUser -Recurse | 
    Where-Object { $_.Thumbprint -eq "<thumbprint>" } | 
    Remove-Item -Verbose
~~~

~~~powershell
Get-ChildItem -Path Cert:\LocalMachine -Recurse | 
    Where-Object { $_.Thumbprint -eq "<thumbprint>" } | 
    Remove-Item -Verbose
~~~

### Instalar certificado

~~~powershell
Import-Certificate -FilePath "C:\TuCertificado.cer" -CertStoreLocation Cert:\LocalMachine\Root
~~~~

## 21. Disable GPS

~~~powershell
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 0
Stop-Service -Name "lfsvc" -Force

~~~

## 22. Enable GPS

~~~powershell
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 1
Start-Service -Name "lfsvc"
~~~

## 23. Window message response

~~~powershell
$objeto = New-Object -ComObject WScript.Shell
$respuesta = $objeto.Popup("¿Puedes asistir a la reunión hoy?", 0, "Pregunta", 4 + 32)

if ($respuesta -eq 6) { 
    $voto = "SI." 
} else { 
    $voto = "NO." 
}

# Este comando devolvera la ventana flotante con la respuesta
msg * /server:<IP or HOSTNAME> "El usuario $env:USERNAME respondio: $voto"
~~~

## 24. Procesos Vinculados a Apps

~~~powershell
Get-Process | Where-Object {$_.Name -match "AnyViewer|IISExpress|java|netbeans|sap"} | Select-Object Name, Id, @{Name="RAM (MB)";Expression={[math]::round(($_.WorkingSet / 1MB),2)}} | Sort-Object "RAM (MB)" -Descending
~~~

## 25. Procesos con más consumo de RAM

~~~powershell
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 -Property Name, Id, @{Name="RAM (MB)";Expression={[math]::round(($_.WorkingSet / 1MB),2)}}
~~~

## 26. Quitar Permisos de Administrador

~~~powershell
Remove-LocalGroupMember -Group "Administradores" -Member "Usuario"
~~~

### Validar Permisos

~~~powershell
Get-LocalGroupMember -Group "Administradores"
~~~

## 27. Pop Up with timer

~~~powershell
$wsh.Popup("This window will close automatically in 5 seconds.", 5, "Timed Notification", 0)
~~~

## 28. Show network adapters interfaces

~~~powershell
Get-NetAdapter -IncludeHidden
~~~

## 29. Disable Network Adapter

~~~powershell
Disable-NetAdapter -Name "Ethernet" -Confirm:$false
~~~

## 30. Enable Network Adapter

~~~powershell
Enable-NetAdapter -Name "Ethernet" -Confirm:$false
~~~

## 31. List letter disks

~~~powershell
Get-PSDrive -PSProvider FileSystem
~~~

## 32. Ask for a web request (universal command for text)

~~~powershell
$webclient = New-Object System.Net.WebClient
$webclient.DownloadString("https://ifconfig.me")
~~~

## 33. Ask for a web request (universal command for download)

~~~powershell
$webclient = New-Object System.Net.WebClient
$webclient.DownloadFile("https://ifconfig.me")
~~~

## List Directories
~~~powershell
Get-ChildItem
~~~
## Find text in a file 
~~~powershell
Select-String -path c:\users \*.txt -pattern password
~~~

## Ping sweep in 10.1.2.0/24
~~~powershell
1..255 | % {echo "10.1.2.$_"; ping -n 1 -2 100 10.1.2.$_ | SelectString ttl}
~~~

## Port Scan 
~~~powershell
1..1024 | % {echo ((new-object Net.Sockets.TcpClient).Connect ("10.1.2.3",$_)) "Port $_ is Open"} 2>$null
~~~




