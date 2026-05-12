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
~~~
Get-AppxPackage | Select-Object Name, PackageFullName
~~~
