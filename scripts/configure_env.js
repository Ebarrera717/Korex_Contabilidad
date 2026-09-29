const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rootDir = path.join(__dirname, '..');
const envPath = path.join(rootDir, '.env');
const envExamplePath = path.join(rootDir, '.env.example');

// Leer variables actuales si existen
let currentEnv = {
    DATABASE_PROVIDER: 'postgresql',
    DATABASE_URL: 'postgresql://postgres:zzeusagencias@localhost:5432/Korex_contabilidad_pg?schema=public',
    DATABASE_URL_POSTGRES: 'postgresql://postgres:zzeusagencias@localhost:5432/Korex_contabilidad_pg?schema=public',
    DATABASE_URL_SQLSERVER: 'sqlserver://localhost:1433;database=Korex_Contabilidad_sql;user=zeusagencias;password=zzeusagencias;encrypt=false;trustServerCertificate=true',
    PORT: '3002',
    NEXT_PUBLIC_APP_PORT: '3002',
    NEXT_PUBLIC_APP_NAME: 'Korex_Contabilidad',
    NEXT_PUBLIC_APP_VERSION: '1.0.0',
    APP_SECRET: 'korex-contabilidad-secret-key-2026-colombia',
    LICENSE_SECRET: 'Korex_Master_License_Secret_Key_2026_Secure'
};

if (fs.existsSync(envPath)) {
    try {
        const lines = fs.readFileSync(envPath, 'utf8').split(/\r?\n/);
        for (const line of lines) {
            const trimmed = line.trim();
            if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
                const eqIdx = trimmed.indexOf('=');
                const key = trimmed.slice(0, eqIdx).trim();
                const val = trimmed.slice(eqIdx + 1).trim().replace(/^["']|["']$/g, '');
                currentEnv[key] = val;
            }
        }
    } catch (e) {}
}

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function ask(question, defaultValue) {
    return new Promise((resolve) => {
        const promptText = defaultValue !== undefined && defaultValue !== '' ? `${question} [${defaultValue}]: ` : `${question}: `;
        rl.question(promptText, (answer) => {
            resolve(answer.trim() || defaultValue || '');
        });
    });
}

// Probar conexión a Postgres
async function testPostgresConnection(url) {
    try {
        const { Client } = require('pg');
        const client = new Client({ connectionString: url });
        await client.connect();
        const res = await client.query('SELECT current_database() as db, version() as v');
        await client.end();
        return { success: true, db: res.rows[0]?.db };
    } catch (err) {
        return { success: false, error: err.message };
    }
}

// Probar conexión a SQL Server
async function testSQLServerConnection(url) {
    try {
        const mssql = require('mssql');
        let clean = url.replace(/^(sqlserver|mssql):\/\//i, '');
        let hostPortPart = clean.split(';')[0];
        let host = hostPortPart.split(':')[0] || '127.0.0.1';
        let portStr = hostPortPart.split(':')[1] || '';
        let instanceName = undefined;
        if (host.includes('\\')) {
            const parts = host.split('\\');
            host = parts[0];
            instanceName = parts[1];
        }
        let database = 'Korex_Contabilidad_sql';
        let user = 'zeusagencias';
        let password = 'zzeusagencias';

        const params = clean.split(';');
        for (const p of params) {
            const eqIdx = p.indexOf('=');
            if (eqIdx > 0) {
                const key = p.substring(0, eqIdx).trim().toLowerCase();
                const val = decodeURIComponent(p.substring(eqIdx + 1).trim());
                if (key === 'database') database = val;
                else if (key === 'user' || key === 'user id' || key === 'uid') user = val;
                else if (key === 'password' || key === 'pwd') password = val;
                else if (key === 'instance' || key === 'instancename') instanceName = val;
                else if (key === 'port') portStr = val;
            }
        }

        const config = {
            server: host,
            user,
            password,
            database,
            options: {
                encrypt: false,
                trustServerCertificate: true,
                connectTimeout: 7000
            },
            connectionTimeout: 7000
        };

        if (instanceName) config.options.instanceName = instanceName;
        else if (portStr) config.port = parseInt(portStr, 10);

        const pool = await mssql.connect(config);
        const res = await pool.request().query('SELECT DB_NAME() as db');
        await pool.close();
        return { success: true, db: res.recordset[0]?.db };
    } catch (err) {
        return { success: false, error: err.message };
    }
}

async function runWizard() {
    console.log('\n================================================================');
    console.log('   KOREX_CONTABILIDAD - ASISTENTE DE CONFIGURACION (.env)       ');
    console.log('================================================================\n');

    console.log(`Configuracion actual detectada:`);
    console.log(`  - Motor activo     : ${currentEnv.DATABASE_PROVIDER.toUpperCase()}`);
    console.log(`  - Puerto web       : ${currentEnv.PORT}`);
    console.log(`  - BD PostgreSQL    : ${currentEnv.DATABASE_URL_POSTGRES}`);
    console.log(`  - BD SQL Server    : ${currentEnv.DATABASE_URL_SQLSERVER}`);
    console.log('----------------------------------------------------------------\n');

    console.log('Seleccione una accion:');
    console.log('  [1] Usar PostgreSQL como motor principal (Recomendado / Local)');
    console.log('  [2] Usar SQL Server como motor principal (Produccion)');
    console.log('  [3] Configurar parametros de conexion detallados');
    console.log('  [4] Probar conexiones de base de datos actuales');
    console.log('  [5] Salir sin cambios');
    console.log('');

    const action = await ask('Opcion [1-5]', '1');

    if (action === '5') {
        console.log('\nOperacion cancelada por el usuario.\n');
        rl.close();
        return;
    }

    if (action === '4') {
        console.log('\n--- Probando conexion PostgreSQL ---');
        const pgTest = await testPostgresConnection(currentEnv.DATABASE_URL_POSTGRES);
        if (pgTest.success) console.log(`  ✅ PostgreSQL CONECTADO: Base de datos [${pgTest.db}]`);
        else console.log(`  ❌ PostgreSQL ERROR: ${pgTest.error}`);

        console.log('\n--- Probando conexion SQL Server ---');
        const ssTest = await testSQLServerConnection(currentEnv.DATABASE_URL_SQLSERVER);
        if (ssTest.success) console.log(`  ✅ SQL Server CONECTADO: Base de datos [${ssTest.db}]`);
        else console.log(`  ❌ SQL Server ERROR: ${ssTest.error}`);

        console.log('\n----------------------------------------------------------------\n');
        rl.close();
        return;
    }

    let provider = currentEnv.DATABASE_PROVIDER;
    let ssUrl = currentEnv.DATABASE_URL_SQLSERVER;
    let pgUrl = currentEnv.DATABASE_URL_POSTGRES;
    let port = currentEnv.PORT || '3002';
    let appSecret = currentEnv.APP_SECRET || 'korex-contabilidad-secret-key-2026-colombia';
    let licSecret = currentEnv.LICENSE_SECRET || 'Korex_Master_License_Secret_Key_2026_Secure';

    if (action === '1') {
        provider = 'postgresql';
    } else if (action === '2') {
        provider = 'sqlserver';
    } else if (action === '3') {
        console.log('\n1. SELECCION DE MOTOR ACTIVO');
        console.log('   [1] PostgreSQL');
        console.log('   [2] SQL Server');
        const mChoice = await ask('Motor activo [1 o 2]', provider === 'postgresql' ? '1' : '2');
        provider = mChoice === '2' ? 'sqlserver' : 'postgresql';

        console.log('\n2. PARAMETROS DE POSTGRESQL');
        const pgHost = await ask('Host / IP PostgreSQL', 'localhost');
        const pgPort = await ask('Puerto PostgreSQL', '5432');
        const pgDb = await ask('Base de Datos PostgreSQL', 'Korex_contabilidad_pg');
        const pgUser = await ask('Usuario PostgreSQL', 'postgres');
        const pgPass = await ask('Contrasena PostgreSQL', 'zzeusagencias');
        pgUrl = `postgresql://${pgUser}:${encodeURIComponent(pgPass)}@${pgHost}:${pgPort}/${pgDb}?schema=public`;

        console.log('\n3. PARAMETROS DE SQL SERVER');
        const ssHost = await ask('Servidor / Host / Instancia SQL Server', 'localhost');
        const ssPort = await ask('Puerto SQL Server', '1433');
        const ssDb = await ask('Base de Datos SQL Server', 'Korex_Contabilidad_sql');
        const ssUser = await ask('Usuario SQL Server', 'zeusagencias');
        const ssPass = await ask('Contrasena SQL Server', 'zzeusagencias');
        ssUrl = `sqlserver://${ssHost}:${ssPort};database=${ssDb};user=${ssUser};password=${ssPass};encrypt=false;trustServerCertificate=true`;

        console.log('\n4. PARAMETROS DE SERVIDOR WEB');
        port = await ask('Puerto HTTP de Next.js', port);
    }

    const activeUrl = provider === 'sqlserver' ? ssUrl : pgUrl;

    // Probar conexión antes de guardar
    console.log(`\nValidando conexion con motor seleccionado (${provider.toUpperCase()})...`);
    if (provider === 'sqlserver') {
        const testRes = await testSQLServerConnection(ssUrl);
        if (testRes.success) {
            console.log(`  ✅ SQL Server: Conexion exitosa a [${testRes.db}]`);
        } else {
            console.log(`  ⚠️ Advertencia SQL Server: ${testRes.error}`);
        }
    } else {
        const testRes = await testPostgresConnection(pgUrl);
        if (testRes.success) {
            console.log(`  ✅ PostgreSQL: Conexion exitosa a [${testRes.db}]`);
        } else {
            console.log(`  ⚠️ Advertencia PostgreSQL: ${testRes.error}`);
        }
    }

    const envContent = `# ============================================================================
# KOREX_CONTABILIDAD - CONFIGURACION OFICIAL DEL SISTEMA
# Generado el: ${new Date().toISOString()}
# ============================================================================

# Motor de Base de Datos Activo (postgresql o sqlserver)
DATABASE_PROVIDER="${provider}"

# Cadena de Conexion Activa
DATABASE_URL="${activeUrl}"

# Cadenas Especificas por Motor
DATABASE_URL_POSTGRES="${pgUrl}"
DATABASE_URL_SQLSERVER="${ssUrl}"

# Configuracion del Servidor Web
PORT="${port}"
NEXT_PUBLIC_APP_PORT="${port}"
NEXT_PUBLIC_APP_NAME="Korex_Contabilidad"
NEXT_PUBLIC_APP_VERSION="1.0.0"

# Seguridad y Licenciamiento
APP_SECRET="${appSecret}"
LICENSE_SECRET="${licSecret}"
`;

    fs.writeFileSync(envPath, envContent, 'utf8');
    fs.writeFileSync(envExamplePath, envContent, 'utf8');

    console.log('\n================================================================');
    console.log('   ✅ ARCHIVO .env ACTUALIZADO CORRECTAMENTE');
    console.log('================================================================');
    console.log(`   - Motor activo : ${provider.toUpperCase()}`);
    console.log(`   - URL activa   : ${activeUrl}`);
    console.log(`   - Puerto       : http://localhost:${port}`);
    console.log('================================================================\n');

    rl.close();
}

runWizard().catch(err => {
    console.error('Error configurando .env:', err);
    rl.close();
    process.exit(1);
});
