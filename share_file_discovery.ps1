# --- Configuración del Usuario ---
$target = "127.0.0.1" #IP a escanear
$extensions = ".txt", ".pdf", ".docx", ".xlsx", ".config", ".sql", ".ps1", ".exe"  #Extension de archivos a buscar en shar
$csvPath = ".\Reporte_Archivos_$target.csv" 
# ---------------------------------

$allFiles = @()

Write-Host "[*] Escaneando recursos compartidos en: $target..." -ForegroundColor Magenta

$shares = net view \\$target | Where-Object { $_ -match "Disco|Disk" } | ForEach-Object {
    if ($_ -match "^(.*?)\s+(?:Disco|Disk)") {
        $matches[1].Trim() 
    }
} | Select-Object -Unique 

if (-not $shares) {
    Write-Host "[!] No se detectaron recursos compartidos accesibles." -ForegroundColor Red
    exit
}

Write-Host "[+] Recursos encontrados: $($shares -join ', ')" -ForegroundColor Gray

foreach ($share in $shares) {
    if ($share -match "C\$|ADMIN\$|IPC\$") { continue }

    $basePath = "\\$target\$share\*" 
    Write-Host "`n[+] Explorando recurso: \\$target\$share" -ForegroundColor Cyan
    
    try {
        $accessErrors = $null 
        
        $currentFiles = Get-ChildItem -Path $basePath -Recurse -File -Force -ErrorAction SilentlyContinue -ErrorVariable accessErrors | Where-Object {
            $extensions -contains $_.Extension
        }
        
        if ($currentFiles) {
            foreach ($file in $currentFiles) {
                Write-Host "    [F] $($file.FullName)" -ForegroundColor Gray
                
                $fileInfo = [PSCustomObject]@{
                    Servidor           = $target
                    Recurso            = $share
                    NombreArchivo      = $file.Name
                    RutaCompleta       = $file.FullName
                    Extension          = $file.Extension.ToLower() # ToLower para agrupar .TXT y .txt igual
                    TamañoMB           = [math]::Round(($file.Length / 1MB), 2)
                    UltimaModificacion = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                }
                
                $allFiles += $fileInfo
            }
        } else {
            Write-Host "    [!] No se encontraron archivos con las extensiones." -ForegroundColor Yellow
        }

        if ($accessErrors) {
            Write-Host "    [?] Nota: Se omitieron subcarpetas por 'Acceso Denegado' (Falta de permisos)." -ForegroundColor DarkYellow
        }

    } catch {
        Write-Host "    [!] Error crítico de red o sintaxis accediendo a $share" -ForegroundColor Red
    }
}

Write-Host "`n==================================================" -ForegroundColor White
Write-Host "              RESUMEN DE BÚSQUEDA                 " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor White

if ($allFiles.Count -gt 0) {
    $resumen = $allFiles | Group-Object -Property Extension | Sort-Object Count -Descending
    
    Write-Host "Cantidad `t Extensión" -ForegroundColor Yellow
    Write-Host "-------- `t ---------" -ForegroundColor Yellow
    
    foreach ($grupo in $resumen) {
        Write-Host "  $($grupo.Count) `t`t $($grupo.Name)" -ForegroundColor White
    }
    
    Write-Host "--------------------------------------------------" -ForegroundColor White
    Write-Host "Total general: $($allFiles.Count) archivos" -ForegroundColor Green
    
    # Exportación CSV
    $allFiles | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "[+] Reporte detallado exportado en: $csvPath" -ForegroundColor Cyan
} else {
    Write-Host "Total general: 0 archivos" -ForegroundColor Green
}
Write-Host "==================================================" -ForegroundColor White
