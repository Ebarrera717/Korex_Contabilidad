# Archivos de Restauración y Respaldos - Base de Datos en Blanco

Este directorio contiene los archivos maestros para restaurar la base de datos de **Korex_Contabilidad** en estado inicial y limpio.

---

## 1. Archivos Disponibles en `BaseDatos/`

| Tipo | Archivo | Motor | Uso |
|---|---|---|---|
| **Respaldo Nativo (.BAK)** | `Korex_Contabilidad_sql_BLANCO.bak` | SQL Server | **Restauración nativa directa** en SSMS o script |
| **Script DDL (.SQL)** | `Korex_Contabilidad_sql_BLANCO.sql` | SQL Server | Creación y ejecución de scripts T-SQL |
| **Script DDL (.SQL)** | `Korex_contabilidad_pg_BLANCO.sql` | PostgreSQL | Restauración en pgAdmin o psql |

---

## 2. Métodos de Restauración para SQL Server (.BAK)

### Opción A: Restauración Automática con 1 Clic (Recomendada)
Haz doble clic en el archivo raíz:
👉 [`Restaurar_SQLServer_Bak.bat`](../Restaurar_SQLServer_Bak.bat)
*(Cierra conexiones existentes, restaura el `.bak` con `REPLACE` y deja la base en modo multiusuario).*

### Opción B: Restaurar desde SQL Server Management Studio (SSMS)
1. Abre **SSMS** y conéctate a tu servidor local.
2. Clic derecho en **Databases** ➔ **Restore Database...**
3. Selecciona **Device** ➔ Clic en `...` ➔ **Add** ➔ Selecciona:
   `F:\Proyectos\Korex_Contabilidad\BaseDatos\Korex_Contabilidad_sql_BLANCO.bak`
4. En **Destination Database**, escribe: `Korex_Contabilidad_sql`
5. En la pestaña **Options**, marca:
   - ✅ *Overwrite the existing database (WITH REPLACE)*
   - ✅ *Close existing connections to destination database*
6. Clic en **OK**.

### Opción C: Comando T-SQL directo
```sql
USE master;
ALTER DATABASE [Korex_Contabilidad_sql] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

RESTORE DATABASE [Korex_Contabilidad_sql]
FROM DISK = 'F:\Proyectos\Korex_Contabilidad\BaseDatos\Korex_Contabilidad_sql_BLANCO.bak'
WITH REPLACE, STATS = 10;

ALTER DATABASE [Korex_Contabilidad_sql] SET MULTI_USER;
```

---

## 3. Contenido Maestro en la Base en Blanco
- **43 Modelos y Tablas DDL** bajo estándares NIIF.
- **40 Procedimientos Almacenados (SPs)** transaccionales.
- **41 Funciones SQL (FNs)** de balance, libros oficiales y medios magnéticos.
- **Plan Único de Cuentas (PUC)** de 5 niveles para Colombia.
- **Tipos de Documentos**: `CC`, `CI`, `CE`, `FV`, `FC`, `NC`, `ND`, `DP`, `CZ`.
- **Información Exógena DIAN**: Formatos `1001`, `1007`, `1008`, `1009`.
- **Empresa Demo**: *EMPRESA DEMO CONTABLE S.A.S.*
- **Usuario Administrador**: `admin@korex.com.co` / `Admin123*`
