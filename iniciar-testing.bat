@echo off
setlocal EnableDelayedExpansion
chcp 65001 > nul
cd /d "%~dp0"
set "ROOT_DIR=%~dp0"
title Korex_Contabilidad - Servidor de Testing y Desarrollo

if not exist "%ROOT_DIR%package.json" (
  echo [ERROR] No se encontro package.json en el directorio actual.
  pause
  exit /b 1
)

echo ================================================================
echo      KOREX_CONTABILIDAD - ENTORNO DE TESTING Y DESARROLLO
echo ================================================================
echo.
echo  [1] Continuar con la configuracion actual de .env (Recomendado)
echo  [2] Activar SQL Server (Sin alterar credenciales de .env)
echo  [3] Activar PostgreSQL (Sin alterar credenciales de .env)
echo  [4] Abrir Asistente de Configuracion (.env)
echo.
set "DB_CHOICE=1"
set /p "DB_CHOICE=Seleccione una opcion [1-4, por defecto 1]: "

if "%DB_CHOICE%"=="2" goto SWITCH_SQLSERVER
if "%DB_CHOICE%"=="3" goto SWITCH_POSTGRES
if "%DB_CHOICE%"=="4" goto OPEN_CONFIG
goto START_CURRENT

:SWITCH_SQLSERVER
echo.
echo Cambiando motor a SQL Server...
call node "%ROOT_DIR%scripts\select_db_provider.js" sqlserver
goto START_CURRENT

:SWITCH_POSTGRES
echo.
echo Cambiando motor a PostgreSQL...
call node "%ROOT_DIR%scripts\select_db_provider.js" postgresql
goto START_CURRENT

:OPEN_CONFIG
call "%ROOT_DIR%Configurar_Env.bat"
goto START_CURRENT

:START_CURRENT
echo.
echo [1/3] Consolidando esquemas y actualizadores...
call node "%ROOT_DIR%deploy\gen_schema_json.js"

echo.
echo [2/3] Generando cliente Prisma...
if exist "%ROOT_DIR%node_modules\prisma\build\index.js" (
    call node "%ROOT_DIR%node_modules\prisma\build\index.js" generate
) else (
    call npx prisma generate
)

echo.
echo [3/3] Ejecutando suite rapida de verificacion de integridad...
call node "%ROOT_DIR%scripts\validate_full_suite.js"

echo.
echo ================================================================
echo  INICIANDO SERVIDOR EN PUERTO 3002...
echo  URL: http://localhost:3002
echo ================================================================
echo.

call npm run dev -- -p 3002

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo [ERROR] El servidor finalizo con codigo %ERRORLEVEL%.
  pause
)
