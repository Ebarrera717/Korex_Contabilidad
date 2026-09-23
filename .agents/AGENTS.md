# Reglas de Codificación y Desarrollo - Proyecto Korex_Contabilidad

Este documento contiene las directrices, estándares y reglas maestras del proyecto para guiar la asistencia en programación, desarrollo de base de datos y despliegue del sistema **Korex_Contabilidad** (Contabilidad General para Colombia).

---

## 1. Regla Suprema de Independencia del Proyecto

- **INDEPENDENCIA TOTAL Y AISLAMIENTO DE PROYECTO**: Korex_Contabilidad es un sistema completamente independiente de cualquier otro proyecto (incluyendo AgenciasNew).
  - Base de datos independiente: PostgreSQL local (`Korex_contabilidad_pg`) y SQL Server producción (`Korex_Contabilidad_sql`).
  - Archivo `.env` independiente.
  - Instaladores y actualizadores propios.
  - Tablas, Procedimientos Almacenados, Funciones y esquemas exclusivos.
  - Queda estrictamente PROHIBIDO modificar, consultar, alterar o conectarse a bases de datos o archivos de otros proyectos.

---

## 2. Reglas de Base de Datos y Lógica Contable

- **REGLA METODOLÓGICA DE CREACIÓN Y DISEÑO DE SKILLS**: Toda nueva Skill o actualización de Skill **DEBE redactarse como un principio de arquitectura universal, patrón abstracto de solución o regla de diseño reutilizable**, evitando limitar las instrucciones a casos de prueba puntuales o valores del momento.
- **REGLA MAESTRA DE CONTROL DE REGRESIONES Y PROTECCIÓN DE CORRECCIONES (`correcciones-permanencia-proteccion`)**: *"Ninguna corrección, funcionalidad, configuración, SP, tabla, parámetro, proceso, interfaz o comportamiento que ya haya sido validado en Korex puede perderse, sobrescribirse, eliminarse, alterarse o degradarse en desarrollos posteriores. Principio obligatorio: TODO LO QUE SE CORRIGE, SE PROTEGE ACUMULATIVAMENTE."*
- **REGLA DE ORO DE DESARROLLO MULTIBASE (PostgreSQL + SQL Server)**: *"PostgreSQL y SQL Server son plataformas oficialmente soportadas. Todo cambio futuro debe diseñarse, implementarse y validarse para ambas desde el inicio. Ningún desarrollo se considera terminado si solo funciona en uno de los dos motores."*
- **REGLA ABSOLUTA DE AISLAMIENTO DE MOTORES (UN MOTOR ACTIVO = UNA ÚNICA INFRAESTRUCTURA)**: *"PostgreSQL y SQL Server son infraestructuras independientes. Cuando el sistema opera en un motor seleccionado (`isSQLServerMode()`), el 100% de las operaciones, transacciones, SPs, importaciones, CRUDs, consultas y reportes DEBEN ejecutarse exclusivamente en ese motor."*
- **REGLA PRIMORDIAL DE ARQUITECTURA (Lógica Database-First)**: Todo proceso contable, balance, cálculo de retenciones, liquidación, contabilización, cierre de período, validación o mutación de datos en Korex_Contabilidad **DEBE realizarse obligatoria y prioritariamente a través de Procedimientos Almacenados (SPs), Funciones SQL y Tablas de Base de Datos**.
- **REGLA CONTABLE FUNDAMENTAL: PARTIDA DOBLE ESTRICTA**:
  - Todo comprobante contable contabilizado debe estar estrictamente cuadrado:
  $$\sum \text{Débitos} = \sum \text{Créditos}$$
  - La verificación de partida doble debe ejecutarse a nivel de Stored Procedure (`spComprobanteContabilizar`) antes de efectuar commit en la transacción.
  - No se permite asentar comprobantes descuadrados.
- **PRECISIÓN DECIMAL Y FINANCIERA COLOMBIANA**:
  - Todos los montos contables (débito, crédito, base gravable, saldo acumulado) DEBEN definirse como `NUMERIC(18,4)` en PostgreSQL y `DECIMAL(18,4)` en SQL Server.
- **INMUTABILIDAD DE PERÍODOS CERRADOS**:
  - Los períodos fiscales cerrados no pueden recibir inserciones, modificaciones ni eliminaciones de asientos contables. La reapertura de un período es un proceso restringido que requiere rol administrativo y genera registro de auditoría.

---

## 3. Reglas de Seguridad y Cifrado

- **Cifrado de Credenciales (`security.ts`)**: Todas las cadenas de conexión con contraseñas en `.env` deben almacenarse cifradas con el estándar AES-256-CBC en formato `ENC(iv_hex:ciphertext_hex)`.
- **Contraseñas de Usuarios (`bcryptjs`)**: Toda contraseña de usuario se almacena mediante hash salteado irreversible Bcrypt (mínimo 10 rondas).
- **Protección Inviolable del `.env`**: Ningún instalador o actualizador podrá sobrescribir, reemplazar o alterar el archivo `.env` del cliente.

---

## 4. Reglas de Next.js, Frontend y UI

- **Puerto del Servidor**: El servidor local de desarrollo y producción de Next.js se arranca por defecto en el puerto **`3001`**.
- **Prisma ORM**: Al modificar tablas o esquemas, ejecutar `npx prisma db pull` y `npx prisma generate` para mantener sincronizados los modelos tipados.
- **Estandarización de UI (Tailwind CSS v4 & Lucide React)**: Cumplir con la armonía de colores, modales estandarizados, tokens de espaciado y tipografía definidos en el Skill `ui-design-harmony`.
- **Manual Operativo Interactivo**: Mantener actualizado el manual en `src/data/manual/modules.ts` con cada funcionalidad agregada.

---

## 5. Regla de Registro Estricto de Maestros (`TAB_CONFIG`)

- Todo maestro contable (Empresa, PUC, Terceros, Centros de Costo, Tipos de Documento, Consecutivos, Períodos) debe registrarse en el diccionario fuertemente tipado `TAB_CONFIG` siguiendo el Skill `master-creation` en 6 capas completas.
