1. Forzar la aparición del cuadro "Otro usuario"
~~~
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "dontdisplaylastusername" -Value 1
~~~

2. Habilitar el Cambio Rápido de Usuario
~~~
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "HideFastUserSwitching" -Value 0
~~~

