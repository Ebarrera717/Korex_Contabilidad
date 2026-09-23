@echo off
chcp 65001 > nul
echo ================================================================
echo    KOREX_CONTABILIDAD - COMPILADOR ACTUALIZADOR (SQL SERVER)
echo ================================================================

call powershell.exe -ExecutionPolicy Bypass -File deploy\Generar_Empaquetado.ps1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Falló la preparación del empaquetado.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [COMPILANDO] Generando Korex_Contabilidad_Update_SqlServer.exe con Inno Setup...
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" deploy\updater_sqlserver.iss
) else if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    "C:\Program Files\Inno Setup 6\ISCC.exe" deploy\updater_sqlserver.iss
) else (
    echo [AVISO] Inno Setup 6 no encontrado en rutas por defecto. El script deploy\updater_sqlserver.iss está listo para compilar manualmente.
)

echo.
echo [COMPLETADO] Proceso de generación finalizado.
pause
