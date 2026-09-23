const fs = require('fs');
const path = require('path');

const provider = (process.argv[2] || 'postgresql').toLowerCase().trim();
const envPath = path.join(__dirname, '..', '.env');

const pgConn = 'postgresql://postgres:zzeusagencias@localhost:5432/Korex_contabilidad_pg?schema=public';
const sqlConn = 'sqlserver://localhost:1433;database=Korex_Contabilidad_sql;user=sa;password=zzeusagencias;encrypt=false;trustServerCertificate=true';

let envLines = [];

if (provider === 'sqlserver') {
    envLines = [
        `DATABASE_PROVIDER="sqlserver"`,
        `DATABASE_URL="${sqlConn}"`,
        `DATABASE_URL_SQLSERVER="${sqlConn}"`,
        `DATABASE_URL_POSTGRES="${pgConn}"`,
        `PORT="3002"`,
        `NEXT_PUBLIC_APP_PORT="3002"`,
        `NEXT_PUBLIC_APP_NAME="Korex_Contabilidad"`,
        `NEXT_PUBLIC_APP_VERSION="1.0.0"`,
        `APP_SECRET="korex-contabilidad-secret-key-2026-colombia"`
    ];
    console.log('✅ Configuración .env actualizada a: SQL Server (Korex_Contabilidad_sql)');
} else {
    envLines = [
        `DATABASE_PROVIDER="postgresql"`,
        `DATABASE_URL="${pgConn}"`,
        `DATABASE_URL_POSTGRES="${pgConn}"`,
        `DATABASE_URL_SQLSERVER="${sqlConn}"`,
        `PORT="3002"`,
        `NEXT_PUBLIC_APP_PORT="3002"`,
        `NEXT_PUBLIC_APP_NAME="Korex_Contabilidad"`,
        `NEXT_PUBLIC_APP_VERSION="1.0.0"`,
        `APP_SECRET="korex-contabilidad-secret-key-2026-colombia"`
    ];
    console.log('✅ Configuración .env actualizada a: PostgreSQL (Korex_contabilidad_pg)');
}

fs.writeFileSync(envPath, envLines.join('\n') + '\n', 'utf8');
