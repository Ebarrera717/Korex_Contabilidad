@echo off
setlocal EnableDelayedExpansion
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
echo  Seleccione el motor de base de datos para testing:
echo.
echo  [1] PostgreSQL (Base Local Korex_contabilidad_pg)
echo  [2] SQL Server (Base Local Korex_Contabilidad_sql)
echo.
set "DB_CHOICE=1"
set /p "DB_CHOICE=Seleccione motor [1 o 2, por defecto 1]: "

if "%DB_CHOICE%"=="2" goto USE_SQLSERVER
goto USE_POSTGRES

:USE_SQLSERVER
echo.
echo MODO SELECCIONADO: SQL Server (Korex_Contabilidad_sql)
call node "%ROOT_DIR%scripts\select_db_provider.js" sqlserver
goto START_PRISMA

:USE_POSTGRES
echo.
echo MODO SELECCIONADO: PostgreSQL (Korex_contabilidad_pg)
call node "%ROOT_DIR%scripts\select_db_provider.js" postgresql
goto START_PRISMA

:START_PRISMA
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
