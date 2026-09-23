const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rootDir = path.join(__dirname, '..');
const envPath = path.join(rootDir, '.env');
const envExamplePath = path.join(rootDir, '.env.example');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function ask(question, defaultValue) {
    return new Promise((resolve) => {
        const promptText = defaultValue ? `${question} [${defaultValue}]: ` : `${question}: `;
        rl.question(promptText, (answer) => {
            resolve(answer.trim() || defaultValue || '');
        });
    });
}

async function runWizard() {
    console.log('\n================================================================');
    console.log('   KOREX_CONTABILIDAD - ASISTENTE DE CONFIGURACION (.env)');
    console.log('================================================================\n');
    console.log('Este asistente te ayudara a configurar la conexion a base de datos');
    console.log('y parametros del sistema de forma rapida y segura.\n');

    // 1. Seleccion de Motor
    console.log('1. SELECCION DE MOTOR DE BASE DE DATOS');
    console.log('   [1] PostgreSQL (Recomendado para instalaciones locales)');
    console.log('   [2] SQL Server (Recomendado para servidores de produccion)');
    const motorChoice = await ask('Seleccione el motor [1 o 2]', '1');
    const provider = motorChoice === '2' ? 'sqlserver' : 'postgresql';

    let pgHost = 'localhost';
    let pgPort = '5432';
    let pgDb = 'Korex_contabilidad_pg';
    let pgUser = 'postgres';
    let pgPass = 'zzeusagencias';

    let ssHost = 'localhost';
    let ssPort = '1433';
    let ssDb = 'Korex_Contabilidad_sql';
    let ssUser = 'zeusagencias';
    let ssPass = 'zzeusagencias';

    if (provider === 'postgresql') {
        console.log('\n2. PARAMETROS DE CONEXION POSTGRESQL');
        pgHost = await ask('Servidor / IP de PostgreSQL', 'localhost');
        pgPort = await ask('Puerto de PostgreSQL', '5432');
        pgDb = await ask('Nombre de la Base de Datos', 'Korex_contabilidad_pg');
        pgUser = await ask('Usuario de PostgreSQL', 'postgres');
        pgPass = await ask('Contrasena de PostgreSQL', 'zzeusagencias');
    } else {
        console.log('\n2. PARAMETROS DE CONEXION SQL SERVER');
        ssHost = await ask('Servidor / Instancia de SQL Server', 'localhost');
        ssPort = await ask('Puerto de SQL Server', '1433');
        ssDb = await ask('Nombre de la Base de Datos', 'Korex_Contabilidad_sql');
        ssUser = await ask('Usuario de SQL Server', 'zeusagencias');
        ssPass = await ask('Contrasena de SQL Server', 'zzeusagencias');
    }

    // 3. Parametros Web
    console.log('\n3. PARAMETROS DEL SERVIDOR WEB');
    const port = await ask('Puerto de la Aplicacion Web', '3002');
    const appSecret = await ask('Clave Secreta de la Aplicacion (APP_SECRET)', 'korex-contabilidad-secret-key-2026-colombia');

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

# Seguridad y Cifrado
APP_SECRET="${appSecret}"
`;

    fs.writeFileSync(envPath, envContent, 'utf8');
    fs.writeFileSync(envExamplePath, envContent, 'utf8');

    console.log('\n================================================================');
    console.log('   ✅ ARCHIVO .env CREADO Y CONFIGURADO EXITOSAMENTE');
    console.log('================================================================');
    console.log(`   - Motor Activo: ${provider.toUpperCase()}`);
    console.log(`   - Base de Datos: ${provider === 'sqlserver' ? ssDb : pgDb}`);
    console.log(`   - Puerto Web: http://localhost:${port}`);
    console.log('================================================================\n');

    rl.close();
}

runWizard().catch(err => {
    console.error('Error configurando .env:', err);
    rl.close();
    process.exit(1);
});
