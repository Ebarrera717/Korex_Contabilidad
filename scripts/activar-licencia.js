const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Cargar variables de entorno de .env
const envCandidates = [
    path.join(__dirname, '..', '.env'),
    path.join(__dirname, '.env'),
    path.join(process.cwd(), '.env')
];

let provider = 'postgres';
let pgDbUrl = 'postgresql://postgres:zzeusagencias@localhost:5432/Korex_contabilidad_pg?schema=public';
let sqlServerUrl = '';
let secretKey = 'Korex_Master_License_Secret_Key_2026_Secure';

for (const envPath of envCandidates) {
    if (fs.existsSync(envPath)) {
        try {
            const envContent = fs.readFileSync(envPath, 'utf8');
            envContent.split(/\r?\n/).forEach(line => {
                const parts = line.split('=');
                if (parts.length >= 2) {
                    const key = parts[0].trim();
                    const val = parts.slice(1).join('=').trim().replace(/^["']|["']$/g, '');
                    if (key === 'DATABASE_PROVIDER') provider = val.toLowerCase();
                    if (key === 'DATABASE_URL_POSTGRES') pgDbUrl = val;
                    if (key === 'DATABASE_URL_SQLSERVER') sqlServerUrl = val;
                    if (key === 'DATABASE_URL') {
                        if (val.startsWith('sqlserver://')) sqlServerUrl = val;
                        else if (val.startsWith('postgresql://') || val.startsWith('postgres://')) pgDbUrl = val;
                    }
                    if (key === 'LICENSE_SECRET') secretKey = val;
                }
            });
        } catch (e) {}
    }
}

function verifyKey(licenseKey) {
    if (!licenseKey) return { isValid: false, error: 'Clave vacía' };
    const parts = licenseKey.trim().split('.');
    if (parts.length !== 3 || parts[0] !== 'KOR1') {
        return { isValid: false, error: 'Formato de clave no reconocido (debe iniciar por KOR1...)' };
    }

    const [, payloadBase64, signature] = parts;
    const expectedSignature = crypto.createHmac('sha256', secretKey).update(payloadBase64).digest('hex');

    if (signature !== expectedSignature) {
        return { isValid: false, error: 'La firma de la clave es inválida o fue alterada.' };
    }

    try {
        const decoded = JSON.parse(Buffer.from(payloadBase64, 'base64url').toString('utf8'));
        return { isValid: true, payload: { client: decoded.c, nit: decoded.n, exp: decoded.e } };
    } catch (e) {
        return { isValid: false, error: 'Error al descifrar el contenido del token.' };
    }
}

async function activarLicencia(licenseKey, inputClientName, inputNit) {
    const verification = verifyKey(licenseKey);
    if (!verification.isValid) {
        console.error(`\n❌ ERROR DE ACTIVACIÓN: ${verification.error}\n`);
        process.exit(1);
    }

    const { client: payloadClient, nit: payloadNit, exp } = verification.payload;
    const finalClient = (inputClientName && inputClientName.trim()) || payloadClient.trim();
    const finalNit = (inputNit && inputNit.trim()) || payloadNit.trim();

    console.log('\n================================================================');
    console.log('       ACTIVACIÓN DE LICENCIA KOREX CONTABILIDAD                ');
    console.log('================================================================');
    console.log(`Empresa    : ${finalClient}`);
    console.log(`NIT        : ${finalNit}`);
    console.log(`Nueva Fecha: ${exp}`);
    console.log('----------------------------------------------------------------');

    // 1. Activar en PostgreSQL si está disponible
    try {
        const { Client } = require('pg');
        const pgClient = new Client({ connectionString: pgDbUrl });
        await pgClient.connect();
        await pgClient.query(`
            INSERT INTO public."SystemParameter" (code, name, value) 
            VALUES ('LICENSE_KEY', 'Clave de Licencia del Sistema', $1),
                   ('LICENSE_EXPIRATION_DATE', 'Fecha de Expiración de Licencia', $2),
                   ('COMPANY_NAME', 'Nombre o Razón Social de la Empresa', $3),
                   ('COMPANY_NIT', 'NIT de la Empresa', $4)
            ON CONFLICT (code) DO UPDATE SET value = EXCLUDED.value
        `, [licenseKey.trim(), exp, finalClient, finalNit]);
        await pgClient.end();
        console.log('✅ Licencia guardada exitosamente en PostgreSQL (Korex_contabilidad_pg).');
    } catch (err) {
        console.warn('⚠️ Nota PostgreSQL:', err.message);
    }

    // 2. Activar en SQL Server si está configurado
    if (sqlServerUrl) {
        try {
            const mssql = require('mssql');
            const pool = await mssql.connect(sqlServerUrl);
            const upsertParam = async (code, name, val) => {
                await pool.request()
                    .input('code', code)
                    .input('name', name)
                    .input('val', val)
                    .query(`
                        IF EXISTS (SELECT 1 FROM dbo.[SystemParameter] WHERE [code] = @code)
                            UPDATE dbo.[SystemParameter] SET [value] = @val, [name] = @name WHERE [code] = @code;
                        ELSE
                            INSERT INTO dbo.[SystemParameter] ([code], [name], [value]) VALUES (@code, @name, @val);
                    `);
            };
            await upsertParam('LICENSE_KEY', 'Clave de Licencia del Sistema', licenseKey.trim());
            await upsertParam('LICENSE_EXPIRATION_DATE', 'Fecha de Expiración de Licencia', exp);
            await upsertParam('COMPANY_NAME', 'Nombre o Razón Social de la Empresa', finalClient);
            await upsertParam('COMPANY_NIT', 'NIT de la Empresa', finalNit);
            await pool.close();
            console.log('✅ Licencia guardada exitosamente en SQL Server (Korex_Contabilidad_sql).');
        } catch (err) {
            console.warn('⚠️ Nota SQL Server:', err.message);
        }
    }

    console.log('================================================================\n');
}

async function runInteractive() {
    const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
    });

    const ask = (q) => new Promise(res => readline.question(q, ans => res(ans.trim())));

    let currentClient = 'EMPRESA DEMO CONTABLE S.A.S.';
    let currentNit = '900123456-8';

    console.log('\n================================================================');
    console.log('       ACTIVACIÓN DE LICENCIA KOREX CONTABILIDAD                ');
    console.log('================================================================\n');

    let clientInput = await ask(`Empresa / Razón Social [${currentClient}]: `);
    if (!clientInput) clientInput = currentClient;

    let nitInput = await ask(`Cédula o NIT [${currentNit}]: `);
    if (!nitInput) nitInput = currentNit;

    let keyInput = await ask('Pegue la Clave de Licencia completa (KOR1...): ');

    readline.close();
    await activarLicencia(keyInput, clientInput, nitInput);
}

const args = process.argv.slice(2);
if (args.length >= 1) {
    activarLicencia(args[0], args[1], args[2]);
} else {
    runInteractive();
}
