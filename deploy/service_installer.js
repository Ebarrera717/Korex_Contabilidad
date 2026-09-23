/**
 * KOREX_CONTABILIDAD - Instalador y Gestor de Servicio de Windows
 * Manejo de ciclo de vida del servicio KorexContabilidadService con fallback autónomo
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const SERVICE_NAME = 'KorexContabilidadService';
const DISPLAY_NAME = 'Korex Contabilidad General Service';
const DESCRIPTION = 'Servicio principal del sistema Korex_Contabilidad para Colombia';

function installService() {
    console.log(`[SERVICE] Registrando servicio ${SERVICE_NAME}...`);
    try {
        const rootDir = path.resolve(__dirname, '..');
        const nodeExe = process.execPath;
        const serverScript = path.join(rootDir, 'server.js');

        const binPath = `"${nodeExe}" "${serverScript}"`;
        execSync(`sc.exe create "${SERVICE_NAME}" binPath= "${binPath}" start= auto DisplayName= "${DISPLAY_NAME}"`, { stdio: 'inherit' });
        execSync(`sc.exe description "${SERVICE_NAME}" "${DESCRIPTION}"`, { stdio: 'inherit' });
        console.log(`[SERVICE] ✅ Servicio ${SERVICE_NAME} registrado exitosamente.`);
    } catch (err) {
        console.warn(`[SERVICE] ⚠️ No se pudo registrar el servicio de Windows (requiere privilegios de Administrador). Usando modo Task Scheduler / Standalone.`);
    }
}

function uninstallService() {
    console.log(`[SERVICE] Deteniendo y eliminando servicio ${SERVICE_NAME}...`);
    try {
        execSync(`sc.exe stop "${SERVICE_NAME}"`, { stdio: 'ignore' });
    } catch (e) {}
    try {
        execSync(`sc.exe delete "${SERVICE_NAME}"`, { stdio: 'inherit' });
        console.log(`[SERVICE] ✅ Servicio ${SERVICE_NAME} eliminado exitosamente.`);
    } catch (err) {
        console.warn(`[SERVICE] ⚠️ Error al eliminar servicio: ${err.message}`);
    }
}

const action = process.argv[2] || 'install';
if (action === 'install') {
    installService();
} else if (action === 'uninstall') {
    uninstallService();
}
