$FirstThreeOctets = "10.32.1"

# 1. Creamos un grupo de hilos (Runspace Pool) para lanzar pings en paralelo real
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, 50)
$RunspacePool.Open()
$Tasks = @()

# 2. Bloque de código que ejecutará cada hilo (.NET Nativo)
$ScriptBlock = {
    param($IP)
    $Ping = New-Object System.Net.NetworkInformation.Ping
    try {
        $Reply = $Ping.Send($IP, 200)
        if ($Reply.Status -eq "Success") {
            try {
                $HostName = [System.Net.Dns]::GetHostEntry($IP).HostName
                return [PSCustomObject]@{ IP = $IP; HostName = $HostName }
            } catch {
                return [PSCustomObject]@{ IP = $IP; HostName = "<No se pudo resolver>" }
            }
        }
    } catch { return $null }
}

# 3. Lanzamos los 254 hilos al mismo tiempo
1..254 | ForEach-Object {
    $IP = "$FirstThreeOctets.$_"
    $PowerShell = [powershell]::Create().AddScript($ScriptBlock).AddArgument($IP)
    $PowerShell.RunspacePool = $RunspacePool
    $Tasks += [PSCustomObject]@{
        Pipe   = $PowerShell
        Handle = $PowerShell.BeginInvoke()
    }
}

# 4. Control de avance por línea de comando usando limpiado de pantalla
$Characters = "|", "/", "-", "\"
$Counter = 0

while ($Tasks.Handle.IsCompleted -contains $false) {
    $Completed = ($Tasks.Handle | Where-Object { $_.IsCompleted -eq $true }).Count
    $Percent = [math]::Round(($Completed / 254) * 100)
    $Char = $Characters[$Counter % 4]
    
    # Limpiamos el Host para forzar a la terminal a reescribir desde arriba
    Clear-Host
    
    # Escribimos el estatus de manera limpia en la línea de comandos
    Write-Host "Iniciando escaneo ultra rápido..." -ForegroundColor Cyan
    Write-Host "Escaneando red $FirstThreeOctets.0/24... [$Char] $Percent% ($Completed/254)" -ForegroundColor Yellow
    
    $Counter++
    Start-Sleep -Milliseconds 100
}

# 5. Limpieza final antes de entregar los datos
Clear-Host

# 6. Recolectamos resultados de la memoria RAM
$Results = foreach ($Task in $Tasks) {
    $Task.Pipe.EndInvoke($Task.Handle)
    $Task.Pipe.Dispose()
}
$RunspacePool.Close()

# 7. Imprimimos resultados finales ordenados por IP
Write-Host "--- ESCANEO COMPLETADO ---" -ForegroundColor Cyan
$ActiveHosts = $Results | Where-Object { $_ -ne $null } | Sort-Object {[version]$_.IP}

if ($ActiveHosts) {
    $ActiveHosts | ForEach-Object {
        Write-Host "[ONLINE] $($_.IP) - $($_.HostName)" -ForegroundColor Green
    }
} else {
    Write-Host "No se encontraron equipos activos en el segmento $FirstThreeOctets.0/24." -ForegroundColor Yellow
}

# =========================================================================
# FUNCIÓN DE EXPORTACIÓN A CSV (
# =========================================================================
# if ($ActiveHosts) {
#     # Define la ruta y el nombre del archivo (incluye fecha y hora para no sobreescribir)
#     $Fecha = Get-Date -Format "yyyy-MM-dd_HH-mm"
#     $RutaArchivo = "$PSScriptRoot\Escaneo_$($FirstThreeOctets)_$Fecha.csv"
#     
#     # Exporta los resultados limpios a un archivo CSV compatible con Excel
#     $ActiveHosts | Export-Csv -Path $RutaArchivo -NoTypeInformation -Encoding UTF8 -Delimiter ","
#     
#     Write-Host "`n[INFO] Resultados exportados correctamente en: $RutaArchivo" -ForegroundColor Cyan
# }
# =========================================================================
