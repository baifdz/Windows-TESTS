# --- Configuración del Usuario ---
$red = "10.32.1." # Los primeros 3 octetos de la red
$rangoInicio = 1
$rangoFin = 254
$csvPath = ".\Auditoria_Red_$($red)csv" 
# ---------------------------------

$resultados = @()

Write-Host "`n[*] Iniciando escaneo de red en el rango: $red$rangoInicio al $red$rangoFin" -ForegroundColor Magenta
Write-Host "[*] Esto puede tomar varios minutos dependiendo de la red..." -ForegroundColor DarkGray

$ping = New-Object System.Net.NetworkInformation.Ping

for ($i = $rangoInicio; $i -le $rangoFin; $i++) {
    $ip = "$red$i"
    
    try {
        # 1. Ping rápido (1000 milisegundos = 1 segundo de timeout)
        $respuestaPing = $ping.Send($ip, 1000)
        
        if ($respuestaPing.Status -eq 'Success') {
            Write-Host "`n[+] Host Activo: $ip" -ForegroundColor Cyan
            
            # 2. Intentar resolver el Hostname
            try {
                $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName
            } catch {
                $hostname = "Desconocido"
            }

            # 3. Intentar resolver Grupo de Trabajo / Dominio mediante WMI
            try {
                $cimSession = New-CimSessionOption -Protocol Dcom
                $dominio = (Get-CimInstance Win32_ComputerSystem -ComputerName $ip -ErrorAction Stop).Domain
            } catch {
                $dominio = "Desconocido (Firewall/RPC bloqueado)"
            }

            Write-Host "    Hostname: $hostname | Grupo/Dominio: $dominio" -ForegroundColor DarkCyan

            # 4. Buscar carpetas compartidas
            $shares = net view \\$ip 2>$null | Where-Object { $_ -match "Disco|Disk" } | ForEach-Object {
                if ($_ -match "^(.*?)\s+(?:Disco|Disk)") {
                    $matches[1].Trim() 
                }
            } | Select-Object -Unique 

            if ($shares) {
                Write-Host "    [!] Carpetas compartidas detectadas:" -ForegroundColor Yellow
                
                foreach ($share in $shares) {
                    if ($share -match "C\$|ADMIN\$|IPC\$") { continue }

                    $rutaUNC = "\\$ip\$share"
                    $accesible = $false
                    
                    # 5. Probar si el usuario actual tiene permisos de lectura
                    try {
                        if (Test-Path $rutaUNC -ErrorAction Stop) {
                            $accesible = $true
                            Write-Host "      -> $share (Accesible: SÍ)" -ForegroundColor Green
                        } else {
                            Write-Host "      -> $share (Accesible: NO)" -ForegroundColor Red
                        }
                    } catch {
                        Write-Host "      -> $share (Accesible: NO - Permisos denegados)" -ForegroundColor Red
                    }

                    $infoHost = [PSCustomObject]@{
                        IP               = $ip
                        Hostname         = $hostname
                        Dominio_Grupo    = $dominio
                        Carpeta          = $share
                        RutaCompleta     = $rutaUNC
                        Acceso_Lectura   = if ($accesible) { "SI" } else { "NO" }
                    }
                    
                    $resultados += $infoHost
                }
            } else {
                Write-Host "    [-] No se detectaron carpetas compartidas públicas." -ForegroundColor Gray
            }
        } else {
            Write-Progress -Activity "Escaneando Red" -Status "IP $ip apagada o sin respuesta" -PercentComplete (($i / $rangoFin) * 100)
        }
    } catch {
        # Ignorar errores extraños del objeto Ping
    }
}

Write-Host "`n==================================================" -ForegroundColor White
Write-Host "              RESUMEN DE AUDITORÍA                " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor White

if ($resultados.Count -gt 0) {
    $equiposUnicos = ($resultados | Select-Object -Property IP -Unique).Count
    $carpetasAccesibles = ($resultados | Where-Object { $_.Acceso_Lectura -eq "SI" }).Count

    Write-Host "Total de equipos con compartidos: $equiposUnicos" -ForegroundColor Green
    Write-Host "Total de carpetas compartidas   : $($resultados.Count)" -ForegroundColor Yellow
    Write-Host "Carpetas con acceso permitido   : $carpetasAccesibles" -ForegroundColor Red
    
    $resultados | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`n[+] Reporte completo guardado en: $csvPath" -ForegroundColor Cyan
} else {
    Write-Host "No se encontraron equipos con recursos compartidos en este rango." -ForegroundColor Green
}
