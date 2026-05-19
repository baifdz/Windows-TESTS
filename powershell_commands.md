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








