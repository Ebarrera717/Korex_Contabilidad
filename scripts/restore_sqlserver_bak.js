const mssql = require('mssql');
const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');
const bakFilePath = path.join(rootDir, 'BaseDatos', 'Korex_Contabilidad_sql_BLANCO.bak');

async function restoreBak() {
    console.log('\n================================================================');
    console.log('   RESTAURANDO BASE DE DATOS SQL SERVER DESDE ARCHIVO .BAK');
    console.log('   Archivo: ' + bakFilePath);
    console.log('   Destino: Korex_Contabilidad_sql');
    console.log('================================================================\n');

    if (!fs.existsSync(bakFilePath)) {
        console.error('❌ Archivo .bak no encontrado en ' + bakFilePath);
        process.exit(1);
    }

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
        console.log('[1/3] Cerrando conexiones activas a Korex_Contabilidad_sql...');
        await pool.request().query(`
            IF DB_ID('Korex_Contabilidad_sql') IS NOT NULL
            BEGIN
                ALTER DATABASE [Korex_Contabilidad_sql] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
            END;
        `).catch(() => {});

        console.log('[2/3] Restaurando base de datos con REPLACE...');
        const restoreQuery = `
            RESTORE DATABASE [Korex_Contabilidad_sql]
            FROM DISK = '${bakFilePath.replace(/'/g, "''")}'
            WITH REPLACE, STATS = 10;
        `;
        await pool.request().query(restoreQuery);

        console.log('[3/3] Restableciendo modo MULTI_USER...');
        await pool.request().query(`
            ALTER DATABASE [Korex_Contabilidad_sql] SET MULTI_USER;
        `);

        await pool.close();
        console.log('\n>>> 🏆 BASE DE DATOS RESTAURADA EXITOSAMENTE DESDE EL .BAK <<<\n');
    } catch (err) {
        console.error('❌ Error restaurando archivo .BAK:', err.message);
        process.exit(1);
    }
}

restoreBak();
