/**
 * KOREX_CONTABILIDAD - Motor de Procesamiento e Ingesta Masiva de Archivos
 * Soporte para mapeo dinámico de columnas, normalización de datos y parsing CSV/JSON
 */

export interface ColumnMapping {
    [targetField: string]: string; // targetField: sourceColumnName
}

export interface ParseResult<T = any> {
    success: boolean;
    totalRows: number;
    rows: T[];
    errors: string[];
}

/**
 * Normaliza y mapea una fila cruda según el mapeo de columnas configurado
 */
export function mapRowToSchema<T = Record<string, any>>(rawRow: Record<string, any>, mapping: ColumnMapping): T {
    const mapped: Record<string, any> = {};
    const normalizedRow: Record<string, any> = {};

    // Normalizar claves del input a mayúsculas y sin espacios
    for (const [k, v] of Object.entries(rawRow)) {
        normalizedRow[k.trim().toUpperCase().replace(/[\s_-]+/g, '_')] = v;
    }

    for (const [targetKey, sourceHeader] of Object.entries(mapping)) {
        const normalizedHeader = sourceHeader.trim().toUpperCase().replace(/[\s_-]+/g, '_');
        if (normalizedRow[normalizedHeader] !== undefined) {
            mapped[targetKey] = normalizedRow[normalizedHeader];
        } else if (rawRow[targetKey] !== undefined) {
            mapped[targetKey] = rawRow[targetKey];
        }
    }

    return mapped as T;
}

/**
 * Parsea contenido CSV a un array de objetos tipados
 */
export function parseCsvContent<T = Record<string, any>>(csvString: string, delimiter: string = ';'): ParseResult<T> {
    const lines = csvString.split(/\r?\n/).filter(line => line.trim().length > 0);
    if (lines.length < 2) {
        return {
            success: false,
            totalRows: 0,
            rows: [],
            errors: ['El archivo no contiene suficientes filas de encabezado y datos']
        };
    }

    const headers = lines[0].split(delimiter).map(h => h.trim().replace(/^["']|["']$/g, ''));
    const rows: T[] = [];
    const errors: string[] = [];

    for (let i = 1; i < lines.length; i++) {
        const line = lines[i];
        const values = line.split(delimiter).map(v => v.trim().replace(/^["']|["']$/g, ''));
        if (values.length === headers.length) {
            const rowObj: Record<string, any> = {};
            headers.forEach((header, idx) => {
                rowObj[header] = values[idx];
            });
            rows.push(rowObj as T);
        } else {
            errors.push(`Línea ${i + 1}: Número de columnas descalzado (${values.length} encontradas, ${headers.length} esperadas)`);
        }
    }

    return {
        success: errors.length === 0,
        totalRows: rows.length,
        rows,
        errors
    };
}
