<#
.SYNOPSIS
    Script de Auditoría Forense y Triage Consolidado.
    Recopila: Información de sistema, red, persistencia, ejecución (Prefetch), 
    eventos críticos y extracción de Hives del registro.
#>

# 1. Configuración de Entorno y Rutas
$hostName = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$reportPath = Join-Path $env:USERPROFILE "Desktop\Auditoria_Full_$hostName"
$hivesPath = Join-Path $reportPath "Registro_Hives"

# Crear directorios
New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
New-Item -ItemType Directory -Path $hivesPath -Force | Out-Null

Write-Host "--- INICIANDO AUDITORÍA INTEGRAL: $hostName ---" -ForegroundColor Cyan

# 2. Información General y Usuarios
Write-Host "[+] Recolectando System Info y Usuarios..."
Get-ComputerInfo | Out-File "$reportPath\1_Sistema.txt"
Get-LocalUser | Select-Object * | Export-Csv -Path "$reportPath\1_Usuarios_Locales.csv" -NoTypeInformation
Get-LocalGroupMember -Group "Administrators" | Out-File "$reportPath\1_Admins_Locales.txt"

# 3. Conexiones, Red y SMB
Write-Host "[+] Analizando Red y Recursos Compartidos..."
Get-NetTCPConnection | Export-Csv -Path "$reportPath\2_Conexiones_Red.csv" -NoTypeInformation
Get-DnsClientCache | Export-Csv -Path "$reportPath\2_Cache_DNS.csv" -NoTypeInformation
Get-SmbShare | Out-File "$reportPath\2_SMB_Shares.txt"

# 4. Historial de USB y Dispositivos Extraíbles
Write-Host "[+] Extrayendo historial de USBSTOR del Registro..."
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*" -ErrorAction SilentlyContinue | 
    Select-Object FriendlyName, PSChildName | Out-File "$reportPath\3_Historial_USB.txt"

# 5. Evidencia de Ejecución (Prefetch) y Persistencia
Write-Host "[+] Analizando ejecución (Prefetch) y Autoruns..."
Get-ChildItem -Path "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue | 
    Select-Object Name, LastWriteTime | Export-Csv -Path "$reportPath\4_Prefetch_Exec.csv" -NoTypeInformation

$runKeys = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Run", "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run")
foreach ($key in $runKeys) {
    Get-ItemProperty -Path $key -ErrorAction SilentlyContinue | Out-File "$reportPath\4_Persistencia.txt" -Append
}
Get-ScheduledTask | Where-Object {$_.State -ne "Disabled"} | Export-Csv -Path "$reportPath\4_Tareas_Programadas.csv" -NoTypeInformation

# 6. Eventos Críticos de Seguridad (Últimos 14 días)
Write-Host "[+] Buscando eventos de interés (Logons, Nuevos Servicios, Limpieza)..."
$Events = Get-WinEvent -FilterHashtable @{
    LogName = 'Security', 'System'
    Id = 1102, 4624, 4625, 7045, 4720 # 4720: Usuario creado
    StartTime = (Get-Date).AddDays(-14)
} -ErrorAction SilentlyContinue
$Events | Select-Object TimeCreated, Id, Message | Export-Csv -Path "$reportPath\5_Eventos_Seguridad.csv" -NoTypeInformation

# 7. EXTRACCIÓN DE HIVES (NTUSER.DAT y System Hives)
# Usamos 'reg save' para volcar las colmenas que están en uso.
Write-Host "[!] Extrayendo colmenas del Registro (SAM, SYSTEM, SOFTWARE, NTUSER)..." -ForegroundColor Yellow

try {
    reg save HKLM\SAM "$hivesPath\SAM.hiv" /y | Out-Null
    reg save HKLM\SYSTEM "$hivesPath\SYSTEM.hiv" /y | Out-Null
    reg save HKLM\SOFTWARE "$hivesPath\SOFTWARE.hiv" /y | Out-Null
    reg save HKCU "$hivesPath\NTUSER.hiv" /y | Out-Null
    Write-Host "[OK] Hives exportados exitosamente a la carpeta Registro_Hives." -ForegroundColor Green
} catch {
    Write-Host "[ERROR] No se pudieron exportar los Hives. ¿Ejecutaste como Administrador?" -ForegroundColor Red
}

# 8. Archivos Sospechosos / Modificados
Write-Host "[+] Buscando archivos modificados recientemente en carpetas críticas..."
$targetPaths = @("$env:TEMP", "C:\Users\Public", "$env:AppData")
foreach ($path in $targetPaths) {
    Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-5) } |
    Select-Object FullName, LastWriteTime, Length | 
    Export-Csv -Path "$reportPath\6_Archivos_Recientes.csv" -NoTypeInformation -Append
}

Write-Host "`n[!] AUDITORÍA FINALIZADA." -ForegroundColor Green
Write-Host "Carpeta de resultados: $reportPath"
