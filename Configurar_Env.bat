@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set "ROOT_DIR=%~dp0"
title Korex_Contabilidad - Asistente de Configuracion (.env)

echo ================================================================
echo    KOREX_CONTABILIDAD - ASISTENTE DE CONFIGURACION (.env)
echo ================================================================
echo.

:: Verificar si node.exe está disponible
where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js no se encuentra en el PATH del sistema.
    echo Por favor instale Node.js o verifique las variables de entorno.
    pause
    exit /b 1
)

call node "%ROOT_DIR%scripts\configure_env.js"

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo [ERROR] La configuracion finalizo con errores.
  pause
  exit /b %ERRORLEVEL%
)

echo.
pause
