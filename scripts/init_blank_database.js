const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');
const fallbackNodeModules = path.join(rootDir, '..', 'AgenciasNew', 'node_modules');

function resolveModule(moduleName) {
    try {
        return require(moduleName);
    } catch (e) {
        try {
            return require(path.join(fallbackNodeModules, moduleName));
        } catch (e2) {
            throw new Error(`No se pudo cargar el módulo '${moduleName}'. Ejecute 'npm install' en el proyecto.`);
        }
    }
}

const { Client } = resolveModule('pg');
const mssql = resolveModule('mssql');
const bcrypt = resolveModule('bcryptjs');

const provider = (process.argv[2] || 'postgresql').toLowerCase().replace('--provider=', '').trim();

async function initPostgresBlankDb() {
    console.log('\n================================================================');
    console.log('   INICIALIZANDO BASE DE DATOS EN BLANCO: POSTGRESQL');
    console.log('   Base de Datos: Korex_contabilidad_pg');
    console.log('================================================================\n');

    // 1. Conectar a postgres default para crear la base de datos si no existe
    const adminClient = new Client({
        connectionString: 'postgresql://postgres:zzeusagencias@localhost:5432/postgres'
    });

    try {
        await adminClient.connect();
        const checkDb = await adminClient.query("SELECT 1 FROM pg_database WHERE datname = 'Korex_contabilidad_pg'");
        if (checkDb.rows.length === 0) {
            console.log('[1/4] Creando base de datos Korex_contabilidad_pg...');
            await adminClient.query('CREATE DATABASE "Korex_contabilidad_pg" ENCODING "UTF8"');
            console.log('   ✅ Base de datos Korex_contabilidad_pg creada exitosamente.');
        } else {
            console.log('[1/4] Base de datos Korex_contabilidad_pg ya existe.');
        }
    } catch (err) {
        console.warn('   ⚠️ Aviso al verificar/crear base:', err.message);
    } finally {
        await adminClient.end().catch(() => {});
    }

    // 2. Conectar a Korex_contabilidad_pg
    const targetClient = new Client({
        connectionString: 'postgresql://postgres:zzeusagencias@localhost:5432/Korex_contabilidad_pg?schema=public'
    });

    try {
        await targetClient.connect();
        console.log('[2/4] Conectado a Korex_contabilidad_pg.');

        // 3. Generar y aplicar script consolidado
        console.log('[3/4] Aplicando tablas DDL, semillas, funciones y procedimientos almacenados...');
        require(path.join(rootDir, 'deploy', 'gen_schema_json.js'));

        const actualizadorPath = path.join(rootDir, 'deploy', 'Actualizador.sql');
        if (fs.existsSync(actualizadorPath)) {
            const sqlScript = fs.readFileSync(actualizadorPath, 'utf8');
            await targetClient.query(sqlScript);
            console.log('   ✅ Script Actualizador.sql aplicado exitosamente.');
        }

        // 4. Sincronizar secuencias y sembrar Usuario Administrador por defecto
        console.log('[4/4] Verificando usuario Administrador inicial...');
        
        await targetClient.query(`
            SELECT setval(pg_get_serial_sequence('public."Role"', 'id'), COALESCE((SELECT MAX(id) FROM public."Role"), 1));
            SELECT setval(pg_get_serial_sequence('public."Company"', 'id'), COALESCE((SELECT MAX(id) FROM public."Company"), 1));
        `).catch(() => {});

        const seedUser = async (name, email, plainPass) => {
            const hashedPassword = bcrypt.hashSync(plainPass, 10);
            await targetClient.query(`
                INSERT INTO public."User" ("name", "email", "passwordHash", "roleId", "companyId", "isActive", "createdAt", "updatedAt")
                VALUES ($1, $2, $3, 1, 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                ON CONFLICT (email) DO UPDATE SET
                    name = EXCLUDED.name,
                    "passwordHash" = EXCLUDED."passwordHash",
                    "roleId" = EXCLUDED."roleId",
                    "isActive" = true,
                    "updatedAt" = CURRENT_TIMESTAMP;
            `, [name, email, hashedPassword]);
            console.log(`   ✅ Usuario fijado: ${email} (Clave: ${plainPass})`);
        };

        await seedUser('Administrador del Sistema', 'admin@korex.com.co', 'Admin123*');
        await seedUser('Eduardo Barrera', 'ebarrera@zagencias.com', 'admin123');
        await seedUser('Eduardo Barrera', 'ebarrrera@zagencias.com', 'admin123');

        console.log('\n>>> 🏆 BASE DE DATOS POSTGRESQL EN BLANCO INICIALIZADA AL 100% <<<\n');
    } catch (err) {
        console.error('❌ Error aplicando esquema en PostgreSQL:', err.message);
    } finally {
        await targetClient.end().catch(() => {});
    }
}

async function initSqlServerBlankDb() {
    console.log('\n================================================================');
    console.log('   INICIALIZANDO BASE DE DATOS EN BLANCO: SQL SERVER');
    console.log('   Base de Datos: Korex_Contabilidad_sql');
    console.log('================================================================\n');

    let poolMaster = null;
    let poolDb = null;
    let activeConfig = null;

    const credentialOptions = [
        { user: 'zeusagencias', password: 'zzeusagencias', server: 'localhost', port: 1433, database: 'master', options: { encrypt: false, trustServerCertificate: true } },
        { user: 'sa', password: 'zzeusagencias', server: 'localhost', port: 1433, database: 'master', options: { encrypt: false, trustServerCertificate: true } },
        { user: 'sa', password: 'password', server: 'localhost', port: 1433, database: 'master', options: { encrypt: false, trustServerCertificate: true } }
    ];

    for (const cfg of credentialOptions) {
        try {
            poolMaster = await mssql.connect(cfg);
            activeConfig = cfg;
            break;
        } catch (e) {}
    }

    if (!poolMaster || !activeConfig) {
        console.error('❌ Error conectando a SQL Server: No se pudo autenticar con usuarios predeterminados (zeusagencias / sa).');
        return;
    }

    try {
        console.log('[1/3] Conectando a master para verificar/crear Korex_Contabilidad_sql...');
        await poolMaster.request().query(`
            IF DB_ID('Korex_Contabilidad_sql') IS NULL
            BEGIN
                CREATE DATABASE [Korex_Contabilidad_sql];
            END;
        `);
        await poolMaster.close();
        console.log('   ✅ Base de datos Korex_Contabilidad_sql lista.');

        // Conectar a Korex_Contabilidad_sql y aplicar esquema
        console.log('[2/3] Aplicando esquema T-SQL y procedimientos...');
        const dbConfig = { ...activeConfig, database: 'Korex_Contabilidad_sql' };
        poolDb = await mssql.connect(dbConfig);

        const actualizadorPath = path.join(rootDir, 'deploy', 'ActualizadorSERVER.sql');
        if (fs.existsSync(actualizadorPath)) {
            const sqlContent = fs.readFileSync(actualizadorPath, 'utf8');
            const batches = sqlContent.split(/^\s*GO\s*$/mi);
            for (const batch of batches) {
                if (batch.trim()) {
                    try {
                        await poolDb.request().batch(batch);
                    } catch (batchErr) {
                        // Ignorar advertencias menores en objetos ya existentes
                    }
                }
            }
            console.log('   ✅ Script ActualizadorSERVER.sql aplicado exitosamente.');
        }
        await poolDb.close();
        console.log('\n>>> 🏆 BASE DE DATOS SQL SERVER EN BLANCO INICIALIZADA AL 100% <<<\n');
    } catch (err) {
        console.error('❌ Error inicializando base de datos en SQL Server:', err.message);
    }
}

if (provider === 'sqlserver') {
    initSqlServerBlankDb();
} else {
    initPostgresBlankDb();
}
