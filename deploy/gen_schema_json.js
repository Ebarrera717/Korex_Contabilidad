const fs = require('fs');
const path = require('path');

async function generateSchemaAndUpdaters() {
    console.log('\n================================================================');
    console.log('   KOREX_CONTABILIDAD - GENERADOR DE SCHEMA Y ACTUALIZADORES');
    console.log('================================================================\n');

    const rootDir = path.join(__dirname, '..');
    const deployDir = path.join(rootDir, 'deploy');
    if (!fs.existsSync(deployDir)) {
        fs.mkdirSync(deployDir, { recursive: true });
    }

    // 1. Consolidar Actualizador.sql (PostgreSQL)
    console.log('[1/4] Consolidando Actualizador.sql (PostgreSQL)...');
    let pgScript = `-- ============================================================================\n`;
    pgScript += `-- KOREX_CONTABILIDAD - SCRIPT CONSOLIDADO DE ACTUALIZACION (POSTGRESQL)\n`;
    pgScript += `-- GENERADO AUTOMATICAMENTE: ${new Date().toISOString()}\n`;
    pgScript += `-- ============================================================================\n\n`;

    // Tablas DDL
    const tableDir = path.join(rootDir, 'SQL', 'Table');
    if (fs.existsSync(tableDir)) {
        const tableFiles = fs.readdirSync(tableDir).filter(f => f.endsWith('.sql')).sort();
        for (const file of tableFiles) {
            pgScript += `-- --- TABLA: ${file} ---\n`;
            pgScript += fs.readFileSync(path.join(tableDir, file), 'utf8') + '\n\n';
        }
    }

    // Datos Semillas
    const dataDir = path.join(rootDir, 'SQL', 'Data');
    if (fs.existsSync(dataDir)) {
        const dataFiles = fs.readdirSync(dataDir).filter(f => f.endsWith('.sql')).sort();
        for (const file of dataFiles) {
            pgScript += `-- --- SEMILLAS: ${file} ---\n`;
            pgScript += fs.readFileSync(path.join(dataDir, file), 'utf8') + '\n\n';
        }
    }

    // Funciones
    const fnDir = path.join(rootDir, 'SQL', 'Function');
    if (fs.existsSync(fnDir)) {
        const fnFiles = fs.readdirSync(fnDir).filter(f => f.endsWith('.sql')).sort();
        for (const file of fnFiles) {
            pgScript += `-- --- FUNCION: ${file} ---\n`;
            pgScript += fs.readFileSync(path.join(fnDir, file), 'utf8') + '\n\n';
        }
    }

    // Procedimientos
    const spDir = path.join(rootDir, 'SQL', 'Procedure');
    if (fs.existsSync(spDir)) {
        const spFiles = fs.readdirSync(spDir).filter(f => f.endsWith('.sql')).sort();
        for (const file of spFiles) {
            pgScript += `-- --- PROCEDIMIENTO: ${file} ---\n`;
            pgScript += fs.readFileSync(path.join(spDir, file), 'utf8') + '\n\n';
        }
    }

    fs.writeFileSync(path.join(deployDir, 'Actualizador.sql'), pgScript, 'utf8');
    console.log('   ✅ Actualizador.sql generado con éxito.');

    // 2. Consolidar ActualizadorSERVER.sql (SQL Server)
    console.log('[2/4] Consolidando ActualizadorSERVER.sql (SQL Server)...');
    let sqlServerScript = `-- ============================================================================\n`;
    sqlServerScript += `-- KOREX_CONTABILIDAD - SCRIPT CONSOLIDADO DE ACTUALIZACION (SQL SERVER)\n`;
    sqlServerScript += `-- GENERADO AUTOMATICAMENTE: ${new Date().toISOString()}\n`;
    sqlServerScript += `-- ============================================================================\n\n`;

    const sqlServerDir = path.join(rootDir, 'SQL', 'SqlServer');
    if (fs.existsSync(sqlServerDir)) {
        const ssFiles = fs.readdirSync(sqlServerDir).filter(f => f.endsWith('.sql')).sort();
        for (const file of ssFiles) {
            sqlServerScript += `-- --- OBJETO T-SQL: ${file} ---\n`;
            sqlServerScript += fs.readFileSync(path.join(sqlServerDir, file), 'utf8') + '\n\n';
        }
    }

    fs.writeFileSync(path.join(deployDir, 'ActualizadorSERVER.sql'), sqlServerScript, 'utf8');
    console.log('   ✅ ActualizadorSERVER.sql generado con éxito.');

    // 3. Generar schema_metadata.json
    console.log('[3/4] Generando schema_metadata.json...');
    const metadata = {
        system: 'Korex_Contabilidad',
        version: '1.0.0',
        buildDate: new Date().toISOString(),
        databases: {
            postgresql: {
                tables: fs.existsSync(tableDir) ? fs.readdirSync(tableDir).filter(f => f.endsWith('.sql')).length : 0,
                procedures: fs.existsSync(spDir) ? fs.readdirSync(spDir).filter(f => f.endsWith('.sql')).length : 0,
                functions: fs.existsSync(fnDir) ? fs.readdirSync(fnDir).filter(f => f.endsWith('.sql')).length : 0
            },
            sqlserver: {
                files: fs.existsSync(sqlServerDir) ? fs.readdirSync(sqlServerDir).filter(f => f.endsWith('.sql')).length : 0
            }
        }
    };
    fs.writeFileSync(path.join(deployDir, 'schema_metadata.json'), JSON.stringify(metadata, null, 2), 'utf8');
    console.log('   ✅ schema_metadata.json generado con éxito.');

    console.log('\n[4/4] ✅ Proceso de consolidación finalizado.\n');
}

generateSchemaAndUpdaters().catch(err => {
    console.error('Error generando schema y actualizadores:', err);
    process.exit(1);
});
