@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set "ROOT_DIR=%~dp0"
title Korex_Contabilidad - Asistente de Configuracion (.env)

echo ================================================================
echo    KOREX_CONTABILIDAD - ASISTENTE DE CONFIGURACION (.env)
echo ================================================================
echo.

call node "%ROOT_DIR%scripts\configure_env.js"

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo [ERROR] La configuracion finalizo con errores.
  pause
  exit /b %ERRORLEVEL%
)

echo.
pause
