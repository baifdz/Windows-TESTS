'''Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log } -Force'''

Este comando hará lo siguiente:

Get-EventLog -LogName *: Obtiene todos los registros de eventos en el sistema.

ForEach-Object: Para cada registro de eventos encontrado, ejecuta el siguiente comando.

Clear-EventLog -LogName $_.Log: Limpia los registros de eventos del log que se está procesando.

Este comando eliminará los registros de todos los logs de eventos del sistema, incluyendo los de aplicación, seguridad, y otros.


'''Start-Process powershell -ArgumentList "-Command Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log }" -Verb RunAs'''

Detener el servicio de eventos:
Puedes detener el servicio que maneja el visor de eventos con el siguiente comando en PowerShell:
'''Stop-Service -Name EventLog'''

Esto detendrá el servicio y efectivamente desactivará el visor de eventos. Aunque puedes seguir viendo los registros antiguos, no se registrarán nuevos eventos mientras el servicio esté detenido.

Reiniciar el servicio de eventos:
Para reactivar el visor de eventos, simplemente reinicia el servicio con este comando:

Start-Service -Name EventLog
