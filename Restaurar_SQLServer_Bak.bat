@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set "ROOT_DIR=%~dp0"
title Korex_Contabilidad - Restaurar Base de Datos desde .BAK

echo ================================================================
echo   KOREX_CONTABILIDAD - RESTAURAR SQL SERVER DESDE ARCHIVO .BAK
echo ================================================================
echo.
echo  Archivo de Respaldo:
echo   BaseDatos\Korex_Contabilidad_sql_BLANCO.bak
echo.
echo  Base de Datos Destino:
echo   Korex_Contabilidad_sql
echo.
echo  ADVERTENCIA: Esta operacion restaurara la base de datos en estado
echo  limpio original, reemplazando datos de prueba existentes.
echo.
pause

echo.
echo Restaurando respaldo .BAK en SQL Server...
call node "%ROOT_DIR%scripts\restore_sqlserver_bak.js"

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo [ERROR] La restauracion finalizo con errores.
  pause
  exit /b %ERRORLEVEL%
)

echo.
echo ================================================================
echo  RESTAURACION .BAK COMPLETADA CON EXITO.
echo ================================================================
echo.
pause
