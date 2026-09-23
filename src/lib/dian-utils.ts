/**
 * Utilidades Tributarias DIAN - Colombia
 * Archivo: src/lib/dian-utils.ts
 */

// Vector oficial de ponderación de 15 primos según el Estatuto Tributario / DIAN
const DIAN_WEIGHTS = [71, 67, 59, 53, 47, 43, 41, 37, 29, 23, 19, 17, 13, 7, 3];

/**
 * Calcula el Dígito de Verificación (DV) oficial de la DIAN mediante el algoritmo Módulo 11.
 * @param nit String o número con el NIT/Cédula sin puntos, guiones ni DV.
 * @returns Dígito de verificación como string ('0' - '9').
 */
export function calculateVerificationDigit(nit: string | number): string {
    if (!nit) return '';
    const cleanNit = String(nit).replace(/\D/g, '').trim();
    if (cleanNit.length === 0) return '';

    const nitLength = cleanNit.length;
    let sum = 0;

    for (let i = 0; i < nitLength; i++) {
        const digit = parseInt(cleanNit.charAt(nitLength - 1 - i), 10);
        const weight = DIAN_WEIGHTS[DIAN_WEIGHTS.length - 1 - i] || 0;
        sum += digit * weight;
    }

    const mod = sum % 11;
    if (mod === 0) return '0';
    if (mod === 1) return '1';
    return String(11 - mod);
}

/**
 * Formatea un NIT con su Dígito de Verificación y separadores estándar colombianos.
 * Ejemplo: '900123456' -> '900.123.456-8'
 */
export function formatColombianNit(nit: string | number, dv?: string): string {
    if (!nit) return '';
    const cleanNit = String(nit).replace(/\D/g, '').trim();
    if (!cleanNit) return '';

    const calculatedDv = dv !== undefined && dv !== null && dv !== '' ? dv : calculateVerificationDigit(cleanNit);
    
    // Formatear con puntos de miles
    const formattedNum = cleanNit.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
    return calculatedDv ? `${formattedNum}-${calculatedDv}` : formattedNum;
}
