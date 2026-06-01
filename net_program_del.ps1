$HostsAfectados = @(
"1","2","3"
)

foreach ($TargetHost in $HostsAfectados) {
    Write-Host "Procesando eliminación remota en: $TargetHost" -ForegroundColor Cyan
    
    # 1. Matar el proceso si estuviera corriendo en memoria de forma remota
    Get-WmiObject Win32_Process -ComputerName $TargetHost -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "proram.exe" } | ForEach-Object { $_.Terminate() }
    
    # 2. Borrar directamente el archivo de System32 usando la ruta de red administrativa C$
    $TargetFile = "\\$TargetHost\C$\Windows\System32\calc.exe"
    if (Test-Path $TargetFile) {
        Remove-Item -Path $TargetFile -Force -ErrorAction SilentlyContinue
        Write-Host "[?? BORRADO] Archivo eliminado con éxito en $TargetHost" -ForegroundColor Green
    } else {
        Write-Host "[? LIMPIO] El archivo ya no existía en $TargetHost" -ForegroundColor Yellow
    }
}
Write-Host "¡Purga directa completada en la lista de equipos!" -ForegroundColor Green
