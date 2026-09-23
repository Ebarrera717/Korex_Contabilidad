@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set "ROOT_DIR=%~dp0"

echo ================================================================
echo    KOREX_CONTABILIDAD - INICIALIZADOR DE BASE DE DATOS EN BLANCO
echo ================================================================
echo.
echo  Este script crea la base de datos desde cero con:
echo   - Esquema completo de tablas DDL NIIF
echo   - Procedimientos Almacenados transaccionales (SPs)
echo   - Funciones SQL de balance, libros y reportes DIAN
echo   - Catalogo base de Plan Unico de Cuentas (PUC) de 5 niveles
echo   - Tipos de Documento oficiales (CC, CI, CE, FV, FC, NC, ND, DP, CZ)
echo   - Formatos de Informacion Exogena DIAN (1001, 1007, 1008, 1009)
echo   - Usuario Administrador por defecto (admin@korex.com.co / Admin123*)
echo.
echo  Seleccione el motor de base de datos a inicializar:
echo.
echo  [1] PostgreSQL (Korex_contabilidad_pg)
echo  [2] SQL Server (Korex_Contabilidad_sql)
echo  [3] Ambos Motores (PostgreSQL + SQL Server)
echo.
set "INIT_CHOICE=1"
set /p "INIT_CHOICE=Seleccione opcion [1, 2 o 3, por defecto 1]: "

if "%INIT_CHOICE%"=="2" goto INIT_SQLSERVER
if "%INIT_CHOICE%"=="3" goto INIT_BOTH
goto INIT_POSTGRES

:INIT_POSTGRES
echo.
echo [1/1] Inicializando base de datos en PostgreSQL...
call node "%ROOT_DIR%scripts\init_blank_database.js" postgresql
goto FINISH

:INIT_SQLSERVER
echo.
echo [1/1] Inicializando base de datos en SQL Server...
call node "%ROOT_DIR%scripts\init_blank_database.js" sqlserver
goto FINISH

:INIT_BOTH
echo.
echo [1/2] Inicializando base de datos en PostgreSQL...
call node "%ROOT_DIR%scripts\init_blank_database.js" postgresql
echo.
echo [2/2] Inicializando base de datos en SQL Server...
call node "%ROOT_DIR%scripts\init_blank_database.js" sqlserver
goto FINISH

:FINISH
echo.
echo Sincronizando cliente Prisma...
if exist "%ROOT_DIR%node_modules\prisma\build\index.js" (
    call node "%ROOT_DIR%node_modules\prisma\build\index.js" generate
) else (
    call npx prisma generate
)

echo.
echo ================================================================
echo  INICIALIZACION COMPLETADA CON EXITO.
echo ================================================================
echo.
pause
