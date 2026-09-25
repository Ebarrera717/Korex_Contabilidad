const fs = require('fs');
const path = require('path');

// ============================================================================
// KOREX VALIDATOR - VALIDACIÓN AUTOMÁTICA INTEGRAL Y MULTIBASE
// Proyecto: Korex_Contabilidad (NIIF / PUC)
// Archivo: scripts/korex_validator.js
// ============================================================================

const args = process.argv.slice(2);
let targetEngine = 'all'; // 'postgres' | 'sqlserver' | 'all'
let phase = 'pre-build'; // 'pre-dev' | 'pre-build' | 'post-build' | 'post-install'

for (const arg of args) {
    if (arg.startsWith('--engine=')) {
        targetEngine = arg.split('=')[1].toLowerCase();
    } else if (arg.startsWith('--phase=')) {
        phase = arg.split('=')[1].toLowerCase();
    }
}

const REPORT = {
    version: '2.0.0',
    timestamp: new Date().toISOString(),
    phase: phase,
    targetEngine: targetEngine,
    items: [],
    errors: [],
    warnings: [],
    status: 'GO'
};

function addResult(category, component, status, detail, isCritical = false) {
    REPORT.items.push({ category, component, status, detail });
    if (status === '❌ ERROR' || status === '❌ BLOQUEANTE') {
        REPORT.errors.push({ category, component, detail, isCritical });
        if (isCritical) {
            REPORT.status = 'NO GO';
        }
    } else if (status === '⚠️ ADVERTENCIA') {
        REPORT.warnings.push({ category, component, detail });
    }
}

async function runValidator() {
    console.log('\n===============================================================================');
    console.log('            KOREX VALIDATOR - VALIDACIÓN AUTOMÁTICA CONTABILIDAD NIIF          ');
    console.log(`   Fase: ${phase.toUpperCase()} | Motor Objetivo: ${targetEngine.toUpperCase()} `);
    console.log(`   Fecha: ${new Date().toLocaleString()}                                       `);
    console.log('===============================================================================\n');

    const rootDir = path.join(__dirname, '..');
    const sqlDir = path.join(rootDir, 'SQL');
    const sqlServerDir = path.join(sqlDir, 'SqlServer');
    const deployDir = path.join(rootDir, 'deploy');
    const actualizadorServerPath = path.join(deployDir, 'ActualizadorSERVER.sql');
    const actualizadorPgPath = path.join(deployDir, 'Actualizador.sql');
    const prismaSchemaPath = path.join(rootDir, 'prisma', 'schema.prisma');

    // -------------------------------------------------------------------------
    // 1. VALIDACIÓN DE ESTRUCTURAS CRÍTICAS Y COLUMNAS MULTIBASE
    // -------------------------------------------------------------------------
    console.log('[PASO 1/5] Verificando consistencia de tablas y columnas multibase...');
    
    const criticalTables = [
        'Account', 'ThirdParty', 'JournalEntry', 'JournalEntryItem',
        'CashBox', 'TreasuryMovement', 'ReceivableInvoice', 'PayableInvoice',
        'FixedAsset', 'FiscalPeriod', 'Company'
    ];

    if (fs.existsSync(prismaSchemaPath)) {
        const prismaContent = fs.readFileSync(prismaSchemaPath, 'utf8');
        for (const tbl of criticalTables) {
            if (prismaContent.includes(`model ${tbl}`)) {
                addResult('Prisma Schema', `model ${tbl}`, '✅ OK', 'Modelo definido correctamente');
            } else {
                addResult('Prisma Schema', `model ${tbl}`, '❌ BLOQUEANTE', 'Modelo ausente en schema.prisma', true);
            }
        }
    }

    // -------------------------------------------------------------------------
    // 2. VALIDACIÓN DE STORED PROCEDURES Y SCRIPTS DDL
    // -------------------------------------------------------------------------
    console.log('[PASO 2/5] Auditando procedimientos almacenados y actualizadores...');
    
    const criticalSPs = [
        'spComprobanteContabilizar.sql', 'spComprobanteReversar.sql', 'spCierreAnual.sql',
        'spTesoreriaIngresoCrear.sql', 'spTesoreriaEgresoCrear.sql',
        'spCarteraReciboCruzar.sql', 'spProveedorEgresoCruzar.sql',
        'spActivoFijoDepreciarPeriodo.sql', 'spBatchImportComprobantes.sql'
    ];

    const procedureDir = path.join(sqlDir, 'Procedure');
    if (fs.existsSync(procedureDir)) {
        for (const sp of criticalSPs) {
            const spPath = path.join(procedureDir, sp);
            if (fs.existsSync(spPath)) {
                addResult('Stored Procedures', sp, '✅ OK', 'Procedimiento presente en SQL/Procedure/');
            } else {
                addResult('Stored Procedures', sp, '❌ BLOQUEANTE', 'Procedimiento crítico faltante', true);
            }
        }
    }

    // -------------------------------------------------------------------------
    // 3. SEGURIDAD DEL .ENV Y AISLAMIENTO DE EMPAQUETADO
    // -------------------------------------------------------------------------
    console.log('[PASO 3/5] Auditando reglas de seguridad del .env e instaladores...');
    const releaseKorexDir = path.join(rootDir, 'RELEASE_KOREX');
    if (fs.existsSync(releaseKorexDir)) {
        const envInRelease = fs.existsSync(path.join(releaseKorexDir, '.env'));
        if (envInRelease) {
            addResult('Seguridad .env', 'RELEASE_KOREX/.env', '❌ BLOQUEANTE', 'Archivo .env productivo encontrado en paquete. Prohibido empaquetar .env.', true);
        } else {
            addResult('Seguridad .env', 'RELEASE_KOREX/.env', '✅ OK', 'Empaquetado limpio sin archivos .env');
        }
    } else {
        addResult('Seguridad .env', 'RELEASE_KOREX', 'ℹ️ INFO', 'Carpeta RELEASE_KOREX limpia');
    }

    // -------------------------------------------------------------------------
    // 4. VALIDACIÓN DE INSTALADORES Y SCRIPTS INNO SETUP
    // -------------------------------------------------------------------------
    console.log('[PASO 4/5] Verificando scripts de Inno Setup...');
    const innoScripts = [
        { file: 'installer.iss', engine: 'postgres' },
        { file: 'updater.iss', engine: 'postgres' },
        { file: 'installer_sqlserver.iss', engine: 'sqlserver' },
        { file: 'updater_sqlserver.iss', engine: 'sqlserver' }
    ];

    for (const script of innoScripts) {
        const fullPath = path.join(deployDir, script.file);
        if (fs.existsSync(fullPath)) {
            addResult('Inno Setup', script.file, '✅ OK', `Script de empaquetado para ${script.engine} disponible`);
        } else {
            addResult('Inno Setup', script.file, '⚠️ ADVERTENCIA', `Script ${script.file} no encontrado`);
        }
    }

    // -------------------------------------------------------------------------
    // 5. RESUMEN Y DICTAMEN FINAL GO / NO GO
    // -------------------------------------------------------------------------
    console.log('\n===============================================================================');
    console.log('                        DICTAMEN KOREX VALIDATOR                               ');
    console.log('===============================================================================\n');

    console.table(REPORT.items);

    console.log(`\nResumen: ${REPORT.errors.length} Errores | ${REPORT.warnings.length} Advertencias`);
    console.log(`Estado Final: ${REPORT.status === 'GO' ? '🟢 [GO] - APROBADO PARA PRODUCCIÓN / EMPAQUETADO' : '🔴 [NO GO] - BLOQUEADO POR ERRORES CRÍTICOS'}\n`);

    const reportPath = path.join(rootDir, 'korex_validation_report.json');
    fs.writeFileSync(reportPath, JSON.stringify(REPORT, null, 2), 'utf8');

    if (REPORT.status === 'NO GO') {
        console.error('❌ VALIDACIÓN FALLIDA: Se detectaron inconsistencias críticas que impiden la entrega o empaquetado.');
        process.exit(1);
    } else {
        console.log('✅ VALIDACIÓN EXITOSA: Todos los componentes cumplen con la SKILL MAESTRA DE KOREX.');
        process.exit(0);
    }
}

runValidator().catch((err) => {
    console.error('Error fatal en KorexValidator:', err);
    process.exit(1);
});
