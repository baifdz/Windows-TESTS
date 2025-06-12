@echo off
setlocal enabledelayedexpansion

:: URL que deseas abrir
set "URL=https://www.google.com"

:: Rutas comunes donde Chrome suele estar instalado
set "COMMON_PATHS[0]=C:\Program Files\Google\Chrome\Application\chrome.exe"
set "COMMON_PATHS[1]=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

:: Variable para almacenar la ruta de Chrome si se encuentra
set "CHROME_PATH="

:: Verificar rutas comunes
for /L %%i in (0,1,1) do (
    call set "P=!COMMON_PATHS[%%i]!"
    if exist "!P!" (
        set "CHROME_PATH=!P!"
        goto found
    )
)

:: Si no se encuentra en rutas comunes, buscar en todo el disco C:
echo Buscando chrome.exe en todo el disco C: (esto puede tardar unos momentos)...
for /r "C:\" %%f in (chrome.exe) do (
    set "CHROME_PATH=%%f"
    goto found
)

echo Chrome no fue encontrado en el sistema.
pause
exit /b

:found
echo Chrome encontrado en: "%CHROME_PATH%"
start "" "%CHROME_PATH%" %URL%
exit /b
