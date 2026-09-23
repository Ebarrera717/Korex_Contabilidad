const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');
const baseDatosDir = path.join(rootDir, 'BaseDatos');
const deployDir = path.join(rootDir, 'deploy');

if (!fs.existsSync(baseDatosDir)) {
    fs.mkdirSync(baseDatosDir, { recursive: true });
}

console.log('\n================================================================');
console.log('   KOREX_CONTABILIDAD - GENERADOR DE ARCHIVOS DE BASE EN BLANCO');
console.log('================================================================\n');

// 1. Asegurar que los actualizadores estén actualizados
require(path.join(deployDir, 'gen_schema_json.js'));

// 2. Copiar archivos maestros a BaseDatos/
const pgSrc = path.join(deployDir, 'Actualizador.sql');
const pgDest = path.join(baseDatosDir, 'Korex_contabilidad_pg_BLANCO.sql');

if (fs.existsSync(pgSrc)) {
    fs.copyFileSync(pgSrc, pgDest);
    console.log('   ✅ Archivo de restauración PostgreSQL generado:');
    console.log(`      -> BaseDatos/Korex_contabilidad_pg_BLANCO.sql (${(fs.statSync(pgDest).size / 1024).toFixed(1)} KB)`);
}

const ssSrc = path.join(deployDir, 'ActualizadorSERVER.sql');
const ssDest = path.join(baseDatosDir, 'Korex_Contabilidad_sql_BLANCO.sql');

if (fs.existsSync(ssSrc)) {
    fs.copyFileSync(ssSrc, ssDest);
    console.log('   ✅ Archivo de restauración SQL Server generado:');
    console.log(`      -> BaseDatos/Korex_Contabilidad_sql_BLANCO.sql (${(fs.statSync(ssDest).size / 1024).toFixed(1)} KB)`);
}

// 3. Crear archivo README explicativo
const readmeContent = `# Archivos de Restauración - Base de Datos en Blanco

Este directorio contiene los scripts y respaldos maestros para restaurar la base de datos de **Korex_Contabilidad** en estado limpio e inicial.

---

## Archivos Disponibles

1. **PostgreSQL**:
   - Archivo: \`Korex_contabilidad_pg_BLANCO.sql\`
   - Base de datos destino: \`Korex_contabilidad_pg\`
   - Cómo restaurar:
     - **Opción A (Automática)**: Ejecutar \`inicializar-bd-blanco.bat\` en la raíz del proyecto.
     - **Opción B (pgAdmin / psql)**:
       \`\`\`bash
       psql -U postgres -d Korex_contabilidad_pg -f BaseDatos/Korex_contabilidad_pg_BLANCO.sql
       \`\`\`

2. **SQL Server**:
   - Archivo: \`Korex_Contabilidad_sql_BLANCO.sql\`
   - Base de datos destino: \`Korex_Contabilidad_sql\`
   - Cómo restaurar:
     - **Opción A (Automática)**: Ejecutar \`inicializar-bd-blanco.bat\` y seleccionar la opción 2.
     - **Opción B (SSMS / sqlcmd)**:
       \`\`\`bash
       sqlcmd -S localhost -d Korex_Contabilidad_sql -i BaseDatos/Korex_Contabilidad_sql_BLANCO.sql
       \`\`\`

---

## Contenido Inicial de la Base en Blanco
- Esquema DDL completo de tablas NIIF (43 modelos).
- 40 Procedimientos Almacenados transaccionales.
- 41 Funciones SQL de consulta, libros oficiales y medios magnéticos DIAN.
- Catálogo oficial del Plan Único de Cuentas (PUC) de 5 niveles.
- Tipos de Documentos Contables (CC, CI, CE, FV, FC, NC, ND, DP, CZ).
- Formatos de Medios Magnéticos DIAN (1001, 1007, 1008, 1009).
- Empresa Demo: *EMPRESA DEMO CONTABLE S.A.S.*
- Usuario Administrador Inicial:
  - **Email:** \`admin@korex.com.co\`
  - **Contraseña:** \`Admin123*\`
`;

fs.writeFileSync(path.join(baseDatosDir, 'README.md'), readmeContent, 'utf8');
console.log('   ✅ README.md de instrucciones generado en BaseDatos/.');

console.log('\n>>> 🏆 ARCHIVOS DE BASE EN BLANCO PREPARADOS EXITOSAMENTE <<<\n');
