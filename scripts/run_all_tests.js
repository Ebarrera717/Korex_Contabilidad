const { execSync } = require('child_process');
const path = require('path');

const testScripts = [
    { phase: 'Fase 2 - Maestros Contables', script: 'test_phase2_masters.js' },
    { phase: 'Fase 3 - Núcleo Contable y Comprobantes', script: 'test_phase3_accounting.js' },
    { phase: 'Fase 4 - Tesorería y Bancos', script: 'test_phase4_treasury.js' },
    { phase: 'Fase 5 - Cartera y Proveedores', script: 'test_phase5_receivables_payables.js' },
    { phase: 'Fase 6 - Activos Fijos y Depreciación', script: 'test_phase6_fixed_assets.js' },
    { phase: 'Fase 7 - Reportes Financieros y DIAN', script: 'test_phase7_reports_dian.js' },
    { phase: 'Fase 8 - Integraciones e Interfaces', script: 'test_phase8_integrations.js' },
    { phase: 'Fase 9 - Empaquetado e Instaladores', script: 'test_phase9_packaging.js' },
    { phase: 'Validación Integral de Suite', script: 'validate_full_suite.js' }
];

console.log('\n================================================================');
console.log('   KOREX_CONTABILIDAD - EJECUTOR MAESTRO DE CERTIFICACION (FASE 10)');
console.log('================================================================\n');

const summary = [];
const scriptsDir = __dirname;

for (const item of testScripts) {
    const scriptPath = path.join(scriptsDir, item.script);
    process.stdout.write(`Ejecutando ${item.phase} (${item.script})... `);
    try {
        const output = execSync(`node "${scriptPath}"`, { encoding: 'utf8', stdio: 'pipe' });
        const passed = output.includes('VALIDADA EXITOSAMENTE') || output.includes('Suite completa ejecutada exitosamente') || output.includes('100%');
        if (passed) {
            console.log('✅ APROBADO');
            summary.push({ Fase: item.phase, Script: item.script, Estado: '✅ OK', Detalle: '100% Pruebas Aprobadas' });
        } else {
            console.log('⚠️ AVISO');
            summary.push({ Fase: item.phase, Script: item.script, Estado: '⚠️ AVISO', Detalle: 'Ejecución con observaciones' });
        }
    } catch (err) {
        console.log('❌ FALLO');
        summary.push({ Fase: item.phase, Script: item.script, Estado: '❌ FALLO', Detalle: err.message });
    }
}

console.log('\n================================================================');
console.log('   RESUMEN GENERAL DE CERTIFICACION KOREX_CONTABILIDAD');
console.log('================================================================\n');

console.table(summary);

const allOk = summary.every(s => s.Estado === '✅ OK');
if (allOk) {
    console.log('\n>>> 🏆 PROYECTO KOREX_CONTABILIDAD CERTIFICADO EXITOSAMENTE AL 100% <<<\n');
} else {
    console.error('\n>>> ❌ EXISTEN PRUEBAS QUE NO SUPERARON LA CERTIFICACIÓN <<<\n');
    process.exit(1);
}
