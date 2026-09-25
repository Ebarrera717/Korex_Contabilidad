@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0"

echo ===============================================================================
echo        GENERADOR OFICIAL DE CLAVES DE LICENCIA - KOREX CONTABILIDAD
echo ===============================================================================
echo.

node scripts\generar-licencia.js

echo.
pause
