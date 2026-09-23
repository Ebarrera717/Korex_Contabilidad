const mssql = require('mssql');
const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');
const baseDatosDir = path.join(rootDir, 'BaseDatos');
const bakFilePath = path.join(baseDatosDir, 'Korex_Contabilidad_sql_BLANCO.bak');

if (!fs.existsSync(baseDatosDir)) {
    fs.mkdirSync(baseDatosDir, { recursive: true });
}

async function generateBak() {
    console.log('\n================================================================');
    console.log('   GENERANDO BACKUP .BAK DE SQL SERVER');
    console.log('   Base de Datos: Korex_Contabilidad_sql');
    console.log('================================================================\n');

    const credentialOptions = [
        { user: 'zeusagencias', password: 'zzeusagencias', server: 'localhost', port: 1433, database: 'master', options: { encrypt: false, trustServerCertificate: true } },
        { user: 'sa', password: 'zzeusagencias', server: 'localhost', port: 1433, database: 'master', options: { encrypt: false, trustServerCertificate: true } },
        { user: 'sa', password: 'password', server: 'localhost', port: 1433, database: 'master', options: { encrypt: false, trustServerCertificate: true } }
    ];

    let pool = null;
    let activeConfig = null;

    for (const cfg of credentialOptions) {
        try {
            pool = await mssql.connect(cfg);
            activeConfig = cfg;
            break;
        } catch (e) {}
    }

    if (!pool || !activeConfig) {
        console.error('❌ Error conectando a SQL Server: No se pudo autenticar.');
        process.exit(1);
    }

    try {
        // 1. Asegurar que la base de datos esté creada y tenga el esquema
        console.log('[1/3] Verificando base de datos Korex_Contabilidad_sql...');
        await pool.request().query(`
            IF DB_ID('Korex_Contabilidad_sql') IS NULL
            BEGIN
                CREATE DATABASE [Korex_Contabilidad_sql];
            END;
        `);

        // 2. Intentar backup directo a BaseDatos/
        console.log(`[2/3] Generando archivo de respaldo ${bakFilePath}...`);
        
        let tempBakPath = bakFilePath;
        let success = false;

        try {
            const backupQuery = `
                BACKUP DATABASE [Korex_Contabilidad_sql]
                TO DISK = '${bakFilePath.replace(/'/g, "''")}'
                WITH FORMAT, INIT, NAME = N'Korex_Contabilidad_sql_BLANCO-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10;
            `;
            await pool.request().query(backupQuery);
            success = true;
        } catch (directErr) {
            console.warn('   ⚠️ Acceso directo denegado por permisos de servicio SQL. Intentando en directorio temporal de SQL...');
            
            // Probar en C:\Temp\ o ruta de backup de SQL Server
            const tempDir = 'C:\\Temp';
            if (!fs.existsSync(tempDir)) fs.mkdirSync(tempDir, { recursive: true });
            tempBakPath = path.join(tempDir, 'Korex_Contabilidad_sql_BLANCO.bak');

            const backupTempQuery = `
                BACKUP DATABASE [Korex_Contabilidad_sql]
                TO DISK = '${tempBakPath.replace(/'/g, "''")}'
                WITH FORMAT, INIT, NAME = N'Korex_Contabilidad_sql_BLANCO-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10;
            `;
            await pool.request().query(backupTempQuery);

            // Copiar de temp a BaseDatos/
            if (fs.existsSync(tempBakPath)) {
                fs.copyFileSync(tempBakPath, bakFilePath);
                success = true;
            }
        }

        await pool.close();

        if (success && fs.existsSync(bakFilePath)) {
            const sizeMb = (fs.statSync(bakFilePath).size / (1024 * 1024)).toFixed(2);
            console.log(`[3/3] ✅ Archivo .BAK generado exitosamente:`);
            console.log(`      -> ${bakFilePath} (${sizeMb} MB)`);
            console.log('\n>>> 🏆 RESPALDO .BAK LISTO PARA RESTAURAR DIRECTAMENTE <<<\n');
        } else {
            console.error('❌ No se pudo generar el archivo .BAK');
            process.exit(1);
        }

    } catch (err) {
        console.error('❌ Error generando backup en SQL Server:', err.message);
        process.exit(1);
    }
}

generateBak();
