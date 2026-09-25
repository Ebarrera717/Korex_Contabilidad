@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0"

echo ===============================================================================
echo            KOREX VALIDATOR - VALIDACIÓN AUTOMÁTICA OBLIGATORIA
echo ===============================================================================
echo.
echo Seleccione el motor de base de datos a validar:
echo   [1] PostgreSQL Local (Korex_contabilidad_pg)
echo   [2] SQL Server (Korex_Contabilidad_sql)
echo   [3] Ambos Motores (Validacion Multibase Completa)
echo.
set /p engineOpt="Seleccione una opcion [1-3] (Default: 3): "

if "%engineOpt%"=="1" (
    set "ENGINE=postgres"
) else if "%engineOpt%"=="2" (
    set "ENGINE=sqlserver"
) else (
    set "ENGINE=all"
)

echo.
echo Ejecutando KorexValidator para motor: !ENGINE!...
echo.
node scripts\korex_validator.js --engine=!ENGINE! --phase=manual

if errorlevel 1 (
    echo.
    echo ===============================================================================
    echo   [NO GO] VALIDACIÓN FALLIDA - SE ENCONTRARON INCONSISTENCIAS CRITICAS
    echo ===============================================================================
    echo.
    pause
    exit /b 1
) else (
    echo.
    echo ===============================================================================
    echo   [GO] VALIDACIÓN EXITOSA - PROYECTO LISTO PARA PRODUCCION / EMPAQUETADO
    echo ===============================================================================
    echo.
    pause
    exit /b 0
)
