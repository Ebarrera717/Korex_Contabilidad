/**
 * KOREX_CONTABILIDAD - Generador de XML Oficial para Prevalidador DIAN
 * Soporte para Formatos de Medios Magnéticos: 1001, 1007, 1008, 1009
 */

export interface ExogenaXmlHeader {
    formato: string;
    version: string;
    numEnvio: number;
    anoGravable: number;
    nitInformante: string;
    dvInformante?: string;
    razonSocialInformante: string;
    fechaEnvio?: string;
}

export function buildExogenaXml(header: ExogenaXmlHeader, rows: Record<string, any>[]): string {
    const fecha = header.fechaEnvio || new Date().toISOString().split('T')[0];
    const totalRegistros = rows.length;

    let xml = `<?xml version="1.0" encoding="ISO-8859-1"?>\n`;
    xml += `<masiva xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n`;
    xml += `  <Cabecera>\n`;
    xml += `    <Formato>${header.formato}</Formato>\n`;
    xml += `    <Version>${header.version}</Version>\n`;
    xml += `    <NumEnvio>${header.numEnvio}</NumEnvio>\n`;
    xml += `    <FecEnvio>${fecha}</FecEnvio>\n`;
    xml += `    <FecInicial>${header.anoGravable}-01-01</FecInicial>\n`;
    xml += `    <FecFinal>${header.anoGravable}-12-31</FecFinal>\n`;
    xml += `    <ValorTotal>0</ValorTotal>\n`;
    xml += `    <CantReg>${totalRegistros}</CantReg>\n`;
    xml += `    <Nit>${header.nitInformante}</Nit>\n`;
    if (header.dvInformante) {
        xml += `    <Dv>${header.dvInformante}</Dv>\n`;
    }
    xml += `  </Cabecera>\n`;

    const tagItem = `f${header.formato}`;

    for (const row of rows) {
        xml += `  <${tagItem}>\n`;
        for (const [key, val] of Object.entries(row)) {
            if (val !== undefined && val !== null) {
                const escapedVal = String(val)
                    .replace(/&/g, '&amp;')
                    .replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;')
                    .replace(/"/g, '&quot;')
                    .replace(/'/g, '&apos;');
                xml += `    <${key}>${escapedVal}</${key}>\n`;
            }
        }
        xml += `  </${tagItem}>\n`;
    }

    xml += `</masiva>\n`;
    return xml;
}
