1. Forzar la aparición del cuadro "Otro usuario"
~~~powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "dontdisplaylastusername" -Value 1
~~~

2. Habilitar el Cambio Rápido de Usuario
~~~powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "HideFastUserSwitching" -Value 0
~~~

3. Obtener programas instalados:
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
For PowerShell 5.1 (Get-Package): Returns a concise table including packages installed via PackageManagement and traditional programs.
~~~powershell
Get-Package | Select-Object Name, Version, ProviderName
~~~
For Windows Store/UWP Apps (Get-AppxPackage): Specifically lists modern "Metro" or Store apps.
~~~powershell
Get-AppxPackage | Select-Object Name, PackageFullName
~~~

Get driver info
~~~powershell
Get-NetAdapter
Get-NetAdapterAdvancedProperty -Name "Ethernet" | Select-Object DisplayName, RegistryKeyword
~~~


https://github.com/chall32/LDWin
https://github.com/chall32/LDWin.git

Step 1: Create the LLDP Registry Key and Property
~~~powershell
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -Name "LLDP" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLDP" -Name "AdvertiseHostInformation" -Value 1 -PropertyType DWORD -Force
~~~

Step 2: Configure and Start the LLDP Service
~~~powershell
Set-Service -Name "lldpsvc" -StartupType manual
Start-Service -Name "lldpsvc"
~~~

Step 3: Restart the Network Adapter
~~~powershell
Restart-NetAdapter -Name "Ethernet" -Confirm:$false
~~~


Sesiones activas de usuario
~~~powershell
query user
~~~

Scan all local drives for any file with "video" in the name:
~~~powershell
Get-ChildItem -Path "C:\" -Filter "*video*" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
~~~

Scan all local drives for any file with ".exe" in the name (date included):
~~~powershell
Get-ChildItem -Path "C:\" -Filter "*.exe*" -File -Recurse -ErrorAction SilentlyContinue | Select-Object FullName, LastWriteTime | Sort-Object LastWriteTime -Descending
~~~

This targets the 64-bit and 32-bit system registration paths. Note that some programs do not supply an absolute InstallDate to the registry.
~~~powershell
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
Where-Object {$_.DisplayName} | 
Select-Object DisplayName, DisplayVersion, InstallDate | 
Sort-Object InstallDate -Descending
~~~

Event Log Method (Most Accurate for Dates)
~~~powershell
Get-WinEvent -ProviderName msiinstaller | 
Where-Object {$_.Id -eq 1033} | 
Select-Object TimeCreated, Message | 
Format-Table -Wrap
~~~

View Recently Modified or Created Files
~~~powershell
Get-ChildItem -Path "C:\" -Recurse -File -ErrorAction SilentlyContinue | 
Sort-Object LastWriteTime -Descending | 
Select-Object Name, LastWriteTime, FullName -First 20
~~~


Find Files Created (Instead of Modified) Recently
~~~powershell
Get-ChildItem -Path "C:\" -Recurse -File | 
Sort-Object CreationTime -Descending | 
Select-Object Name, CreationTime, FullName -First 20
~~~

Check for Malicious Persistence (Startup & Tasks)
~~~powershell
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | Format-Table -AutoSize
~~~

List Hidden Active Tasks:
~~~powershell
Get-ScheduledTask | Get-ScheduledTaskInfo | Sort-Object LastRunTime -Descending | Select-Object TaskName, LastRunTime | Out-GridView
~~~

Find Processes Running from Unexpected Folders
~~~powershell
Get-Process | Select-Object Name, Id, @{Name="Path"; Expression={$_.Path}} | Where-Object {$_.Path -ne $null} | Sort-Object Name
~~~

Compress a folder to .zip
~~~powershell
Compress-Archive -Path "C:\" -DestinationPath "C:\output.zip"
~~~

Adicion de ruta a variables de entorno
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

Certificados instalados
~~~powershell
Get-ChildItem -Path Cert:\LocalMachine -Recurse
~~~

Buscar un certificado específico por su nombre (Subject):
~~~powershell
Get-ChildItem -Path Cert:\LocalMachine -Recurse | Where-Object { $_.Subject -like "*NombreDelCertificado*" }
~~~

Quitar un certificado
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
Disable GPS
~~~powershell
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 0
Stop-Service -Name "lfsvc" -Force

~~~
Enable GPS
~~~powershell
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 1
Start-Service -Name "lfsvc"
~~~

Window message response
~~~PowerShell
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




