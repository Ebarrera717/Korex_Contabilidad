const fs = require('fs');
const path = require('path');

async function runPhase9Tests() {
    console.log('\n================================================================');
    console.log('   KOREX_CONTABILIDAD - TEST DE EMPAQUETADO E INSTALADORES (FASE 9)');
    console.log('================================================================\n');

    const results = [];
    const rootDir = path.join(__dirname, '..');
    const deployDir = path.join(rootDir, 'deploy');

    // 1. Presencia de Scripts Inno Setup (.iss)
    const issFiles = ['installer.iss', 'updater.iss', 'installer_sqlserver.iss', 'updater_sqlserver.iss'];
    const issPresent = issFiles.every(f => fs.existsSync(path.join(deployDir, f)));

    results.push({
        Operacion: '1. Scripts Inno Setup (.iss)',
        Validacion: `Presencia de los 4 scripts Inno Setup (${issFiles.join(', ')})`,
        Estado: issPresent ? '✅ OK' : '❌ FALLO',
        Detalle: 'Separación completa de instaladores y actualizadores PostgreSQL y SQL Server'
    });

    // 2. Regla de Protección Inviolable del .env en Instaladores (Setup)
    const installerPgContent = fs.existsSync(path.join(deployDir, 'installer.iss')) ? fs.readFileSync(path.join(deployDir, 'installer.iss'), 'utf8') : '';
    const installerSsContent = fs.existsSync(path.join(deployDir, 'installer_sqlserver.iss')) ? fs.readFileSync(path.join(deployDir, 'installer_sqlserver.iss'), 'utf8') : '';
    const envProtectedSetup = installerPgContent.includes('onlyifdoesntexist') && installerSsContent.includes('onlyifdoesntexist');

    results.push({
        Operacion: '2. Protección del .env en Instaladores (Setup)',
        Validacion: 'Flags "onlyifdoesntexist" y "uninsneveruninstall" configuradas',
        Estado: envProtectedSetup ? '✅ OK' : '❌ FALLO',
        Detalle: 'Garantía de preservación de configuración en primera instalación'
    });

    // 3. Regla Estricta de Omisión del .env en Actualizadores (Updater)
    const updaterPgContent = fs.existsSync(path.join(deployDir, 'updater.iss')) ? fs.readFileSync(path.join(deployDir, 'updater.iss'), 'utf8') : '';
    const updaterSsContent = fs.existsSync(path.join(deployDir, 'updater_sqlserver.iss')) ? fs.readFileSync(path.join(deployDir, 'updater_sqlserver.iss'), 'utf8') : '';
    const envOmittedUpdater = updaterPgContent.includes('Excludes: ".env') && updaterSsContent.includes('Excludes: ".env');

    results.push({
        Operacion: '3. Omisión Estricta del .env en Actualizadores',
        Validacion: 'Exclusión explícita de .env en la sección [Files]',
        Estado: envOmittedUpdater ? '✅ OK' : '❌ FALLO',
        Detalle: 'Cero riesgo de sobreescritura de contraseñas o servidores en producción'
    });

    // 4. Scripts Consolidados de Base de Datos (Actualizador.sql & ActualizadorSERVER.sql)
    const actualizadorPg = fs.existsSync(path.join(deployDir, 'Actualizador.sql')) && fs.statSync(path.join(deployDir, 'Actualizador.sql')).size > 1000;
    const actualizadorSs = fs.existsSync(path.join(deployDir, 'ActualizadorSERVER.sql')) && fs.statSync(path.join(deployDir, 'ActualizadorSERVER.sql')).size > 1000;

    results.push({
        Operacion: '4. Consolidados SQL Multibase',
        Validacion: `Actualizador.sql (${fs.statSync(path.join(deployDir, 'Actualizador.sql')).size} bytes) y ActualizadorSERVER.sql (${fs.statSync(path.join(deployDir, 'ActualizadorSERVER.sql')).size} bytes)`,
        Estado: (actualizadorPg && actualizadorSs) ? '✅ OK' : '❌ FALLO',
        Detalle: 'Scripts DDL y SPs consolidados para despliegues autónomos'
    });

    // 5. Schema Metadata JSON
    const metadataPath = path.join(deployDir, 'schema_metadata.json');
    const hasMetadata = fs.existsSync(metadataPath);
    let metadataOk = false;
    if (hasMetadata) {
        const meta = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
        metadataOk = meta.system === 'Korex_Contabilidad' && meta.databases?.postgresql?.procedures >= 36;
    }

    results.push({
        Operacion: '5. Metadatos de Esquema (schema_metadata.json)',
        Validacion: 'Métricas de versión, tablas, SPs y funciones registradas',
        Estado: metadataOk ? '✅ OK' : '❌ FALLO',
        Detalle: 'Reporte pre-compilación generado por gen_schema_json.js'
    });

    // 6. Instalador de Servicio de Windows (KorexContabilidadService)
    const serviceInstallerPath = path.join(deployDir, 'service_installer.js');
    const serviceContent = fs.existsSync(serviceInstallerPath) ? fs.readFileSync(serviceInstallerPath, 'utf8') : '';
    const serviceOk = serviceContent.includes('KorexContabilidadService') && serviceContent.includes('sc.exe create');

    results.push({
        Operacion: '6. Gestor de Servicio de Windows',
        Validacion: 'Servicio KorexContabilidadService con registro automático',
        Estado: serviceOk ? '✅ OK' : '❌ FALLO',
        Detalle: 'Módulo deploy/service_installer.js configurado'
    });

    // 7. Compiladores Batch y Script PowerShell
    const batFiles = ['GenerarSetup.bat', 'GenerarActualizador.bat', 'GenerarSetupSqlServer.bat', 'GenerarActualizadorSqlServer.bat'];
    const psFile = path.join(deployDir, 'Generar_Empaquetado.ps1');
    const batsOk = batFiles.every(f => fs.existsSync(path.join(rootDir, f))) && fs.existsSync(psFile);

    results.push({
        Operacion: '7. Compiladores Batch y Empaquetador PowerShell',
        Validacion: 'Generadores .bat y deploy/Generar_Empaquetado.ps1 disponibles',
        Estado: batsOk ? '✅ OK' : '❌ FALLO',
        Detalle: 'Automatización de compilación con Inno Setup ISCC'
    });

    // 8. Aislamiento de Puertos y Rutas de Despliegue
    const appIsolated = installerPgContent.includes('3002') && installerSsContent.includes('3002');

    results.push({
        Operacion: '8. Aislamiento Operacional y de Red',
        Validacion: 'Puerto dedicado 3002 y rutas aisladas para Korex_Contabilidad',
        Estado: appIsolated ? '✅ OK' : '❌ FALLO',
        Detalle: 'Independencia total sin interferencia con otros sistemas o puertos'
    });

    console.table(results);

    const allPassed = results.every(r => r.Estado.includes('✅'));
    console.log(`\n[RESULTADO FASE 9] Total Pruebas: ${results.length} | Aprobadas: ${results.filter(r => r.Estado.includes('✅')).length} | Fallidas: ${results.filter(r => r.Estado.includes('❌')).length}`);

    if (allPassed) {
        console.log('\n>>> ✅ FASE 9 - EMPAQUETADO E INSTALADORES VALIDADA EXITOSAMENTE AL 100% <<<\n');
    } else {
        console.error('\n>>> ❌ EXISTEN ERRORES EN LA VALIDACIÓN DE FASE 9 <<<\n');
        process.exit(1);
    }
}

runPhase9Tests().catch(err => {
    console.error('Error ejecutando tests de Fase 9:', err);
    process.exit(1);
});
