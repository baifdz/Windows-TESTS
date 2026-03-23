<#
.SYNOPSIS
    Herramienta de Auditoría Forense Consolidada y Detección de Amenazas.
    Incluye: Info de Sistema, Red, Persistencia, Prefetch, Hives de Registro
    y Análisis de Procesos/Malware.
#>

$hostName = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$reportPath = Join-Path $env:USERPROFILE "Desktop\Auditoria_Full_$hostName"
$hivesPath = Join-Path $reportPath "Registro_Hives"

# Crear directorios
New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
New-Item -ItemType Directory -Path $hivesPath -Force | Out-Null

Write-Host "--- INICIANDO AUDITORÍA INTEGRAL Y BUSQUEDA DE AMENAZAS ---" -ForegroundColor Cyan

# 1. SEGURIDAD Y PROCESOS (Hunting)
Write-Host "[+] Analizando procesos y software de seguridad..." -ForegroundColor Yellow
$securityProducts = "msmpeng|cb.exe|s1service|csagent|cybereason|fireeye|traps|carbonblack"
$processes = Get-Process | Select-Object Id, ProcessName, Path, @{Name="Company"; Expression={$_.MainModule.FileVersionInfo.CompanyName}}, @{Name="Description"; Expression={$_.MainModule.FileVersionInfo.FileDescription}}

# Identificar Software de Seguridad
$processes | Where-Object { $_.ProcessName -match $securityProducts } | Export-Csv -Path "$reportPath\0_Seguridad_Detectada.csv" -NoTypeInformation

# Identificar Procesos Sospechosos (Sin Firma/Compañía o en carpetas TEMP)
$processes | Where-Object { ([string]::IsNullOrEmpty($_.Company)) -or ($_.Path -match "Temp|Users\\Public|AppData") } | 
    Export-Csv -Path "$reportPath\0_Procesos_Sospechosos.csv" -NoTypeInformation

# 2. INFORMACIÓN GENERAL Y USUARIOS
Write-Host "[+] Recolectando System Info y Usuarios..."
Get-ComputerInfo | Out-File "$reportPath\1_Sistema.txt"
Get-LocalUser | Select-Object * | Export-Csv -Path "$reportPath\1_Usuarios_Locales.csv" -NoTypeInformation
Get-LocalGroupMember -Group "Administrators" | Out-File "$reportPath\1_Admins_Locales.txt"

# 3. RED Y CONEXIONES
Write-Host "[+] Analizando Red y Cache DNS..."
Get-NetTCPConnection | Export-Csv -Path "$reportPath\2_Conexiones_Red.csv" -NoTypeInformation
Get-DnsClientCache | Export-Csv -Path "$reportPath\2_Cache_DNS.csv" -NoTypeInformation
Get-SmbShare | Out-File "$reportPath\2_SMB_Shares.txt"

# 4. ARTEFACTOS DE EJECUCIÓN (PREFETCH) Y USB
Write-Host "[+] Extrayendo Prefetch y Historial USB..."
Get-ChildItem -Path "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue | 
    Select-Object Name, LastWriteTime | Export-Csv -Path "$reportPath\3_Prefetch_Exec.csv" -NoTypeInformation
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*" -ErrorAction SilentlyContinue | 
    Select-Object FriendlyName, PSChildName | Out-File "$reportPath\3_Historial_USB.txt"

# 5. PERSISTENCIA (Autoruns y Tareas)
Write-Host "[+] Verificando mecanismos de persistencia..."
$runKeys = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Run", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run")
foreach ($key in $runKeys) { Get-ItemProperty -Path $key -ErrorAction SilentlyContinue | Out-File "$reportPath\4_Persistencia_Reg.txt" -Append }
Get-ScheduledTask | Where-Object {$_.State -ne "Disabled"} | Export-Csv -Path "$reportPath\4_Tareas_Programadas.csv" -NoTypeInformation

# 6. EXTRACCIÓN DE HIVES (SAM, SYSTEM, SOFTWARE, NTUSER)
Write-Host "[!] Exportando Hives del Registro (Binarios)..." -ForegroundColor Magenta
reg save HKLM\SAM "$hivesPath\SAM.hiv" /y | Out-Null
reg save HKLM\SYSTEM "$hivesPath\SYSTEM.hiv" /y | Out-Null
reg save HKLM\SOFTWARE "$hivesPath\SOFTWARE.hiv" /y | Out-Null
reg save HKCU "$hivesPath\NTUSER.hiv" /y | Out-Null

# 7. FORENSICS DE ARCHIVOS Y HASHING
Write-Host "[+] Calculando Hashes de archivos recientes en rutas críticas..." -ForegroundColor Yellow
$targetPaths = @("$env:TEMP", "C:\Users\Public", "$env:AppData\Roaming")
foreach ($path in $targetPaths) {
    Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) } |
    ForEach-Object {
        [PSCustomObject]@{
            FileName = $_.FullName
            LastWriteTime = $_.LastWriteTime
            SHA256 = (Get-FileHash -Path $_.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        }
    } | Export-Csv -Path "$reportPath\5_Hashes_Archivos_Recientes.csv" -NoTypeInformation -Append
}

# 8. EVENTOS DE SEGURIDAD
Write-Host "[+] Extrayendo Logs de Seguridad..."
$Events = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=1102,4624,4625,7045; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue
$Events | Select-Object TimeCreated, Id, Message | Export-Csv -Path "$reportPath\6_Eventos_Seguridad.csv" -NoTypeInformation

Write-Host "`n[!] AUDITORÍA COMPLETADA EXITOSAMENTE." -ForegroundColor Green
Write-Host "Resultados en: $reportPath"
