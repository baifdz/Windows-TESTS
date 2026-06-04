#Antes de usar este codigo sobre una red tener en cuenta que puede hacer que algunas alertas de IDS/EDR/antivirus/etc marquen un trafico inusual ya que hace que escanee toda una red en busqueda de archvivos en carpetas compartidas (net view)

# --- Configuración del Usuario ---
$red = "192.168.1." # Primeros 3 octetos
$rangoInicio = 1
$rangoFin = 254
$extensions = ".txt", ".pdf", ".docx", ".xlsx", ".config", ".sql", ".ps1", ".exe", ".bat"
$csvPath = ".\Reporte_Maestro_Red_$($red)csv" 
# ---------------------------------

$resultadosTotales = @()
$ping = New-Object System.Net.NetworkInformation.Ping

Write-Host "`n[*] Iniciando Auditoría Profunda: $red$rangoInicio al $red$rangoFin" -ForegroundColor Magenta
Write-Host "[!] ADVERTENCIA: Este proceso es intrusivo y puede tardar." -ForegroundColor DarkYellow

for ($i = $rangoInicio; $i -le $rangoFin; $i++) {
    $ip = "$red$i"
    
    try {
        # 1. Barrido de red rápido
        $respuestaPing = $ping.Send($ip, 1000)
        
        if ($respuestaPing.Status -eq 'Success') {
            Write-Host "`n=========================================" -ForegroundColor Cyan
            Write-Host "[+] Host Activo: $ip" -ForegroundColor Cyan
            Write-Host "=========================================" -ForegroundColor Cyan
            
            # 2. Resolución de Hostname
            try { $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName } 
            catch { $hostname = "Desconocido" }

            # 3. Obtención de Dominio y Sistema Operativo
            $dominio = "Desconocido"
            $so = "Desconocido (RPC Bloqueado)"
            try {
                $wmiComp = Get-CimInstance Win32_ComputerSystem -ComputerName $ip -ErrorAction Stop
                $wmiOS = Get-CimInstance Win32_OperatingSystem -ComputerName $ip -ErrorAction Stop
                
                $dominio = $wmiComp.Domain
                $so = $wmiOS.Caption
            } catch { } 

            Write-Host "    [i] Hostname : $hostname" -ForegroundColor DarkCyan
            Write-Host "    [i] OS/Dom   : $so | $dominio" -ForegroundColor DarkCyan

            # 4. Descubrimiento de Carpetas
            $shares = net view \\$ip 2>$null | Where-Object { $_ -match "Disco|Disk" } | ForEach-Object {
                if ($_ -match "^(.*?)\s+(?:Disco|Disk)") { $matches[1].Trim() }
            } | Select-Object -Unique 

            if (-not $shares) {
                Write-Host "    [-] No se detectaron carpetas compartidas." -ForegroundColor Gray
                continue
            }

            Write-Host "    [!] Carpetas detectadas: $($shares.Count)" -ForegroundColor Yellow
            
            foreach ($share in $shares) {
                if ($share -match "C\$|ADMIN\$|IPC\$") { continue }

                $rutaUNC = "\\$ip\$share"
                Write-Host "`n      -> Explorando: $rutaUNC" -ForegroundColor Blue
                
                # 5. Verificación de Acceso
                $accesoCarpeta = "NO"
                try {
                    if (Test-Path $rutaUNC -ErrorAction Stop) { $accesoCarpeta = "SI" }
                } catch { }

                if ($accesoCarpeta -eq "NO") {
                    Write-Host "         [x] Acceso denegado a la raíz de la carpeta." -ForegroundColor Red
                    $resultadosTotales += [PSCustomObject]@{
                        IP = $ip; Hostname = $hostname; Dominio = $dominio; SO = $so
                        Carpeta = $share; Acceso_Raiz = "NO"; Archivo = "N/A"; Ruta = "N/A"
                        Extension = "N/A"; TamanoMB = 0; Modificacion = "N/A"
                    }
                    continue
                }

                # 6. Enumeración de Archivos
                $archivosEncontrados = 0
                $currentFiles = Get-ChildItem -Path "$rutaUNC\*" -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
                    $extensions -contains $_.Extension.ToLower()
                }

                if ($currentFiles) {
                    foreach ($file in $currentFiles) {
                        $resultadosTotales += [PSCustomObject]@{
                            IP           = $ip
                            Hostname     = $hostname
                            Dominio      = $dominio
                            SO           = $so
                            Carpeta      = $share
                            Acceso_Raiz  = "SI"
                            Archivo      = $file.Name
                            Ruta         = $file.FullName
                            Extension    = $file.Extension.ToLower()
                            TamanoMB     = [math]::Round(($file.Length / 1MB), 2)
                            Modificacion = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                        }
                        $archivosEncontrados++
                    }
                    Write-Host "         [+] $archivosEncontrados archivos de interés extraídos." -ForegroundColor Green
                } else {
                    Write-Host "         [i] Accesible, pero 0 archivos coinciden con las extensiones." -ForegroundColor DarkYellow
                    $resultadosTotales += [PSCustomObject]@{
                        IP = $ip; Hostname = $hostname; Dominio = $dominio; SO = $so
                        Carpeta = $share; Acceso_Raiz = "SI"; Archivo = "VACIO/SIN COINCIDENCIAS"; Ruta = "N/A"
                        Extension = "N/A"; TamanoMB = 0; Modificacion = "N/A"
                    }
                }
            }
        } else {
            Write-Progress -Activity "Barrido de Red" -Status "IP $ip apagada" -PercentComplete (($i / $rangoFin) * 100)
        }
    } catch {
        # Continuar en caso de error crítico de red
    }
}

# ==============================================================================
# GENERACIÓN DE REPORTE
# ==============================================================================
Write-Host "`n==================================================" -ForegroundColor White
Write-Host "                         RESUMEN                " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor White

if ($resultadosTotales.Count -gt 0) {

    $soloArchivos = $resultadosTotales | Where-Object { $_.Extension -ne "N/A" }
    
    if ($soloArchivos.Count -gt 0) {
        $resumenExt = $soloArchivos | Group-Object -Property Extension | Sort-Object Count -Descending
        
        Write-Host "Archivos por extensión:" -ForegroundColor Yellow
        foreach ($grupo in $resumenExt) {
            Write-Host "  $($grupo.Count) `t`t $($grupo.Name)" -ForegroundColor White
        }
    }

    $equiposVulnerables = ($resultadosTotales | Select-Object -Property IP -Unique).Count
    Write-Host "--------------------------------------------------" -ForegroundColor White
    Write-Host "Equipos con compartidos detectados : $equiposVulnerables" -ForegroundColor Green
    Write-Host "Total de archivos de interés       : $($soloArchivos.Count)" -ForegroundColor Green
    
    $resultadosTotales | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`n[+] Reporte CSV maestro guardado en: $csvPath" -ForegroundColor Cyan
} else {
    Write-Host "No se encontraron recursos ni archivos." -ForegroundColor Yellow
}
Write-Host "==================================================" -ForegroundColor White
