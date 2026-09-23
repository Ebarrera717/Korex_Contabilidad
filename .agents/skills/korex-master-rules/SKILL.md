---
name: korex-master-rules
description: Skill Maestro de Korex para desarrollo multibase, aislamiento absoluto de motores, protección inviolable del .env, independencia total entre Setup y Actualizador, prevención de contaminación de pruebas y garantía de no regresión en PostgreSQL y SQL Server.
---

# SKILL MAESTRO – KOREX (ID: 74163)
## DESARROLLO, INSTALACIÓN, ACTUALIZACIÓN, AISLAMIENTO, PRUEBAS, SEGURIDAD Y MANTENIMIENTO (POSTGRESQL + SQL SERVER)

---

## 1. OBJETIVO GENERAL
Korex soporta oficialmente dos motores de base de datos:
1. **PostgreSQL**
2. **SQL Server**

Ambos motores deben mantenerse funcionales. Todo desarrollo futuro debe diseñarse, implementarse y validarse para ambos motores.
**NINGÚN DESARROLLO SE CONSIDERA TERMINADO SI SOLAMENTE FUNCIONA EN UNO DE LOS DOS MOTORES.**

---

## 2. REGLA MAESTRA DE MULTIBASE
Todo cambio debe analizar y validar ambos motores:
* Tablas, campos, tipos de datos, PKs, FKs, constraints, índices, vistas.
* Stored Procedures, funciones, triggers, migraciones.
* Consultas, transacciones, Backend, API, Frontend.
* Reportes, exportaciones, integraciones, jobs, procesos automáticos.
* Instaladores, actualizadores, diagnósticos, optimizaciones y correcciones.

---

## 3. REGLA CRÍTICA DE AISLAMIENTO (INVIOLABLE)

### SI KOREX OPERA EN SQL SERVER:
TODO debe ejecutarse EXCLUSIVAMENTE en SQL Server.
**QUEDA ESTRICTAMENTE PROHIBIDO:**
* Conectar a PostgreSQL.
* Consultar, modificar o crear tablas en PostgreSQL.
* Ejecutar SPs, funciones, migraciones o índices en PostgreSQL.
* Sincronizar información con PostgreSQL.

### SI KOREX OPERA EN POSTGRESQL:
TODO debe ejecutarse EXCLUSIVAMENTE en PostgreSQL.
**QUEDA ESTRICTAMENTE PROHIBIDO:**
* Conectar a SQL Server.
* Consultar, modificar o crear tablas en SQL Server.
* Ejecutar SPs, funciones, migraciones o índices en SQL Server.
* Sincronizar información con SQL Server.

---

## 4. PROHIBICIÓN DE CONEXIONES OCULTAS Y FALLBACKS DE MOTOR
La aplicación NO puede mantener conexiones ocultas al motor contrario.
NO debe existir:
* Conexión automática secundaria.
* Fallback hacia otro motor.
* Sincronización o replicación automática entre motores.
* Consulta de validación al motor contrario.
* Migración automática al motor contrario.

---

## 5. REGLA CRÍTICA DEL ARCHIVO `.env` (SETUP vs ACTUALIZADOR)

### EN EL PROCESO DE SETUP (`GenerarSetup.bat` / `GenerarSetupSqlServer.bat`):
1. **El `.env` se CREA DESDE CERO** utilizando única y exclusivamente los datos solicitados en la instalación del cliente.
2. **PROHIBICIÓN ABSOLUTA DE TRANSPORTAR EL `.env` DE PRUEBAS/DESARROLLO**:
   * Queda estrictamente prohibido copiar, empaquetar o incluir archivos `.env` reales o de desarrollo en `RELEASE_KOREX`, instaladores o archivos `.iss`.
   * En `deploy/Generar_Empaquetado.ps1`, el archivo `.env` DEBE ser explícitamente excluido y eliminado de `RELEASE_KOREX`.
   * En los scripts de Inno Setup (`.iss`), la sección `[Files]` DEBE excluir expresamente `*.env` y `*.env.*`.
   * El instalador jamás heredará variables del ambiente de desarrollo (ej. `ZEUSAGENCIAS10`, `Korex_Pruebas`, `192.168.80.26`).

### EN EL PROCESO DE ACTUALIZACIÓN (`GenerarActualizador.bat` / `GenerarActualizadorSqlServer.bat`):
1. **EL ACTUALIZADOR CONSERVA EL `.env` EXISTENTE DEL CLIENTE AL 100%**:
   * Queda estrictamente prohibido sobrescribir, reemplazar, regenerar, eliminar, renombrar o sustituir el `.env` existente del cliente.
   * El actualizador NO puede cambiar servidor, puerto, base de datos, motor, usuario ni credenciales.
2. **SI EL ACTUALIZADOR NO ENCUENTRA EL `.env` EXISTENTE**:
   * El actualizador **SE DETIENE INMEDIATAMENTE** e informa:
     `ERROR CRÍTICO: No se encontró el archivo .env de la instalación existente. La actualización no puede continuar sin la configuración previa del cliente.`
   * Queda estrictamente prohibido inventar o recurrir a valores predeterminados (`localhost`, `sa`, `postgres`, `Korex`, etc.).
3. **VALIDACIÓN DE INTEGRIDAD HASH PRE Y POST ACTUALIZACIÓN**:
   * Se genera un hash SHA-256 del `.env` antes de la actualización y se valida que tras la actualización el archivo conserve intactas las credenciales y conexiones del cliente.

---

## 6. CUATRO PROCESOS DE DESPLIEGUE TOTALMENTE INDEPENDIENTES

| Proceso | Archivo Batch | Script PowerShell | Script Inno Setup | Motor Destino | Manejo de `.env` |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Setup PostgreSQL** | `GenerarSetup.bat` | `Setup_Korex_Silent.ps1` | `Korex.iss` | PostgreSQL | Genera `.env` desde cero |
| **Actualizador PostgreSQL** | `GenerarActualizador.bat` | `Update_Korex.ps1` | `Korex_Update.iss` | PostgreSQL | Preserva `.env` existente |
| **Setup SQL Server** | `GenerarSetupSqlServer.bat` | `Setup_Korex_SQLServer_Silent.ps1` | `Korex_SQLServer.iss` | SQL Server | Genera `.env` desde cero |
| **Actualizador SQL Server** | `GenerarActualizadorSqlServer.bat` | `Update_Korex_SQLServer.ps1` | `Korex_SQLServer_Update.iss` | SQL Server | Preserva `.env` existente |

---

## 7. PROTOCOLO DE NO REGRESIÓN Y PROTECCIÓN DE CORRECCIONES
1. Toda corrección debe acompañarse de su prueba automatizada en la suite multibase (`node scripts/validate_full_suite.js`).
2. Ningún desarrollo puede eliminar, degradar o romper correcciones previas de producción.
3. Antes de dar por concluida cualquier tarea, se debe ejecutar la suite de 8 capas de validación y certificar 100% de coincidencia funcional.
