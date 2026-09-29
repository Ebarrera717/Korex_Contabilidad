const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rootDir = path.join(__dirname, '..');
const envPath = path.join(rootDir, '.env');
const envExamplePath = path.join(rootDir, '.env.example');

// Leer variables actuales si existen
let rawEnv = {};
if (fs.existsSync(envPath)) {
    try {
        const lines = fs.readFileSync(envPath, 'utf8').split(/\r?\n/);
        for (const line of lines) {
            const trimmed = line.trim();
            if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
                const eqIdx = trimmed.indexOf('=');
                const key = trimmed.slice(0, eqIdx).trim();
                const val = trimmed.slice(eqIdx + 1).trim().replace(/^["']|["']$/g, '');
                rawEnv[key] = val;
            }
        }
    } catch (e) {}
}

function parsePgUrl(url) {
    let user = 'postgres', pass = 'zzeusagencias', host = 'localhost', port = '5432', db = 'Korex_contabilidad_pg';
    if (!url) return { user, pass, host, port, db };
    try {
        const clean = url.replace(/["']/g, '');
        const u = new URL(clean);
        user = decodeURIComponent(u.username || user);
        pass = decodeURIComponent(u.password || pass);
        host = u.hostname || host;
        port = u.port || port;
        db = u.pathname.replace(/^\//, '') || db;
    } catch (e) {}
    return { user, pass, host, port, db };
}

function parseSqlUrl(url) {
    let host = 'localhost', port = '1433', db = 'Korex_Contabilidad_sql', user = 'zeusagencias', pass = 'zzeusagencias';
    if (!url) return { host, port, db, user, pass };
    try {
        let clean = url.replace(/["']/g, '').replace(/^(sqlserver|mssql):\/\//i, '');
        let hostPortPart = clean.split(';')[0];
        if (hostPortPart.includes(':')) {
            host = hostPortPart.split(':')[0] || 'localhost';
            port = hostPortPart.split(':')[1] || '1433';
        } else {
            host = hostPortPart || 'localhost';
        }
        const params = clean.split(';');
        for (const p of params) {
            const eq = p.indexOf('=');
            if (eq > 0) {
                const k = p.slice(0, eq).trim().toLowerCase();
                const v = decodeURIComponent(p.slice(eq + 1).trim());
                if (k === 'database') db = v;
                else if (k === 'user' || k === 'user id' || k === 'uid') user = v;
                else if (k === 'password' || k === 'pwd') pass = v;
                else if (k === 'port') port = v;
            }
        }
    } catch (e) {}
    return { host, port, db, user, pass };
}

let currentProvider = (rawEnv.DATABASE_PROVIDER || 'postgresql').toLowerCase().trim();
let currentPg = parsePgUrl(rawEnv.DATABASE_URL_POSTGRES || rawEnv.DATABASE_URL);
let currentSql = parseSqlUrl(rawEnv.DATABASE_URL_SQLSERVER || rawEnv.DATABASE_URL);
let currentPort = rawEnv.PORT || '3002';
let appSecret = rawEnv.APP_SECRET || 'korex-contabilidad-secret-key-2026-colombia';
let licSecret = rawEnv.LICENSE_SECRET || 'Korex_Master_License_Secret_Key_2026_Secure';

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function ask(question, defaultValue) {
    return new Promise((resolve) => {
        const promptText = defaultValue !== undefined && defaultValue !== '' ? `${question} [${defaultValue}]: ` : `${question}: `;
        rl.question(promptText, (answer) => {
            const res = answer.trim();
            resolve(res !== '' ? res : (defaultValue !== undefined ? defaultValue : ''));
        });
    });
}

// Probar conexión a Postgres
async function testPostgres(host, port, db, user, pass) {
    try {
        const { Client } = require('pg');
        const url = `postgresql://${user}:${encodeURIComponent(pass)}@${host}:${port}/${db}?schema=public`;
        const client = new Client({ connectionString: url, connectionTimeoutMillis: 5000 });
        await client.connect();
        const res = await client.query('SELECT current_database() as db');
        await client.end();
        return { success: true, db: res.rows[0]?.db };
    } catch (err) {
        return { success: false, error: err.message };
    }
}

// Probar conexión a SQL Server
async function testSqlServer(host, port, db, user, pass) {
    try {
        const mssql = require('mssql');
        let instanceName = undefined;
        let finalHost = host;
        if (host.includes('\\')) {
            const parts = host.split('\\');
            finalHost = parts[0];
            instanceName = parts[1];
        }

        const config = {
            server: finalHost,
            user,
            password: pass,
            database: db,
            options: {
                encrypt: false,
                trustServerCertificate: true,
                connectTimeout: 7000
            },
            connectionTimeout: 7000
        };

        if (instanceName) config.options.instanceName = instanceName;
        else if (port) config.port = parseInt(port, 10);

        const pool = await mssql.connect(config);
        const res = await pool.request().query('SELECT DB_NAME() as db');
        await pool.close();
        return { success: true, db: res.recordset[0]?.db };
    } catch (err) {
        return { success: false, error: err.message };
    }
}

function saveEnvFile(provider, pgHost, pgPort, pgDb, pgUser, pgPass, ssHost, ssPort, ssDb, ssUser, ssPass, port) {
    const pgUrl = `postgresql://${pgUser}:${encodeURIComponent(pgPass)}@${pgHost}:${pgPort}/${pgDb}?schema=public`;
    const ssUrl = `sqlserver://${ssHost}:${ssPort};database=${ssDb};user=${ssUser};password=${ssPass};encrypt=false;trustServerCertificate=true`;
    const activeUrl = provider === 'sqlserver' ? ssUrl : pgUrl;

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
    console.log('   🎉 ¡ARCHIVO .env ACTUALIZADO Y GUARDADO EXITOSAMENTE!');
    console.log('================================================================');
    console.log(`   - Motor Activo : ${provider.toUpperCase()}`);
    console.log(`   - Base de Datos: ${provider === 'sqlserver' ? ssDb : pgDb}`);
    console.log(`   - Servidor Host: ${provider === 'sqlserver' ? ssHost : pgHost}`);
    console.log(`   - Puerto HTTP  : http://localhost:${port}`);
    console.log(`   - Archivo      : ${envPath}`);
    console.log('================================================================\n');
}

async function runMenu() {
    console.log('\n================================================================');
    console.log('   KOREX_CONTABILIDAD - ASISTENTE DE CONFIGURACION (.env)       ');
    console.log('================================================================\n');

    console.log(`Configuración actual en .env:`);
    console.log(`  - Motor activo     : ${currentProvider.toUpperCase()}`);
    console.log(`  - Puerto web       : ${currentPort}`);
    console.log(`  - SQL Server       : ${currentSql.user}@${currentSql.host}:${currentSql.port}/${currentSql.db}`);
    console.log(`  - PostgreSQL       : ${currentPg.user}@${currentPg.host}:${currentPg.port}/${currentPg.db}`);
    console.log('----------------------------------------------------------------\n');

    console.log('¿Qué acción desea realizar?');
    console.log('  [1] Activar PostgreSQL como motor principal (Local / Desarrollo)');
    console.log('  [2] Activar SQL Server como motor principal (Producción)');
    console.log('  [3] Configurar datos de conexión paso a paso (Servidor, Usuario, Clave, BD)');
    console.log('  [4] Probar conexiones actuales');
    console.log('  [5] Salir');
    console.log('');

    const choice = await ask('Seleccione una opción [1-5]', '1');

    if (choice === '5') {
        console.log('\nOperación finalizada sin cambios.\n');
        rl.close();
        return;
    }

    if (choice === '1') {
        saveEnvFile('postgresql', currentPg.host, currentPg.port, currentPg.db, currentPg.user, currentPg.pass, currentSql.host, currentSql.port, currentSql.db, currentSql.user, currentSql.pass, currentPort);
        rl.close();
        return;
    }

    if (choice === '2') {
        saveEnvFile('sqlserver', currentPg.host, currentPg.port, currentPg.db, currentPg.user, currentPg.pass, currentSql.host, currentSql.port, currentSql.db, currentSql.user, currentSql.pass, currentPort);
        rl.close();
        return;
    }

    if (choice === '4') {
        console.log('\n--- Probando conexión PostgreSQL ---');
        const pgRes = await testPostgres(currentPg.host, currentPg.port, currentPg.db, currentPg.user, currentPg.pass);
        if (pgRes.success) console.log(`  ✅ PostgreSQL CONECTADO: Base de datos [${pgRes.db}]`);
        else console.log(`  ❌ PostgreSQL ERROR: ${pgRes.error}`);

        console.log('\n--- Probando conexión SQL Server ---');
        const sqlRes = await testSqlServer(currentSql.host, currentSql.port, currentSql.db, currentSql.user, currentSql.pass);
        if (sqlRes.success) console.log(`  ✅ SQL Server CONECTADO: Base de datos [${sqlRes.db}]`);
        else console.log(`  ❌ SQL Server ERROR: ${sqlRes.error}`);

        console.log('\n----------------------------------------------------------------\n');
        rl.close();
        return;
    }

    if (choice === '3') {
        console.log('\n1. SELECCIÓN DEL MOTOR PRINCIPAL:');
        console.log('   [1] PostgreSQL');
        console.log('   [2] SQL Server');
        const mChoice = await ask('Motor activo [1 o 2]', currentProvider === 'sqlserver' ? '2' : '1');
        const selectedProvider = mChoice === '2' ? 'sqlserver' : 'postgresql';

        console.log('\n2. PARÁMETROS DE SQL SERVER:');
        const ssHost = await ask('Servidor / Host / Instancia SQL Server', currentSql.host);
        const ssPort = await ask('Puerto SQL Server', currentSql.port);
        const ssDb = await ask('Base de Datos SQL Server', currentSql.db);
        const ssUser = await ask('Usuario SQL Server', currentSql.user);
        const ssPass = await ask('Contraseña SQL Server', currentSql.pass);

        console.log('\n3. PARÁMETROS DE POSTGRESQL:');
        const pgHost = await ask('Servidor / Host PostgreSQL', currentPg.host);
        const pgPort = await ask('Puerto PostgreSQL', currentPg.port);
        const pgDb = await ask('Base de Datos PostgreSQL', currentPg.db);
        const pgUser = await ask('Usuario PostgreSQL', currentPg.user);
        const pgPass = await ask('Contraseña PostgreSQL', currentPg.pass);

        console.log('\n4. PUERTO HTTP DE LA APLICACIÓN WEB:');
        const port = await ask('Puerto Web', currentPort);

        console.log('\n----------------------------------------------------------------');
        console.log(`Probando conexión con el motor seleccionado (${selectedProvider.toUpperCase()})...`);
        if (selectedProvider === 'sqlserver') {
            const testRes = await testSqlServer(ssHost, ssPort, ssDb, ssUser, ssPass);
            if (testRes.success) console.log(`  ✅ SQL Server: ¡Conexión EXITOSA a [${testRes.db}]!`);
            else console.log(`  ⚠️ Advertencia SQL Server: ${testRes.error}`);
        } else {
            const testRes = await testPostgres(pgHost, pgPort, pgDb, pgUser, pgPass);
            if (testRes.success) console.log(`  ✅ PostgreSQL: ¡Conexión EXITOSA a [${testRes.db}]!`);
            else console.log(`  ⚠️ Advertencia PostgreSQL: ${testRes.error}`);
        }
        console.log('----------------------------------------------------------------\n');

        const confirm = await ask('¿Desea guardar estos cambios en el archivo .env? [S/N]', 'S');
        if (confirm.toUpperCase() === 'S' || confirm.toUpperCase() === 'SI' || confirm.toUpperCase() === 'Y') {
            saveEnvFile(selectedProvider, pgHost, pgPort, pgDb, pgUser, pgPass, ssHost, ssPort, ssDb, ssUser, ssPass, port);
        } else {
            console.log('\n❌ Cambios cancelados. No se modificó el archivo .env.\n');
        }

        rl.close();
    }
}

runMenu().catch(err => {
    console.error('\n❌ Error en el asistente de configuración:', err);
    rl.close();
    process.exit(1);
});
