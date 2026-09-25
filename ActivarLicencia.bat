@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0"

echo ===============================================================================
echo            ACTIVADOR MANUAL DE LICENCIA - KOREX CONTABILIDAD
echo ===============================================================================
echo.

node scripts\activar-licencia.js

echo.
pause
