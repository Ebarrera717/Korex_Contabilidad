import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { buildExogenaXml } from '@/lib/xml-exogena-builder';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const formatNumber = searchParams.get('format') || '1001';
        const fiscalYear = parseInt(searchParams.get('year') || String(new Date().getFullYear()));
        const companyId = parseInt(searchParams.get('companyId') || '1');
        const numEnvio = parseInt(searchParams.get('numEnvio') || '1');

        // Obtener datos de la empresa
        const companyRes = await executeQuery(
            `SELECT "documentNumber", "verificationDigit", "businessName" FROM public."Company" WHERE id = $1`,
            [companyId]
        );

        if (companyRes.rows.length === 0) {
            return NextResponse.json({ success: false, error: 'Empresa no encontrada' }, { status: 404 });
        }

        const company = companyRes.rows[0];

        // Obtener datos del formato correspondiente
        let fnName = 'fnGenerarFormatoExogena1001';
        let version = '10';

        switch (formatNumber) {
            case '1007':
                fnName = 'fnGenerarFormatoExogena1007';
                version = '9';
                break;
            case '1008':
                fnName = 'fnGenerarFormatoExogena1008';
                version = '8';
                break;
            case '1009':
                fnName = 'fnGenerarFormatoExogena1009';
                version = '8';
                break;
            case '1001':
            default:
                fnName = 'fnGenerarFormatoExogena1001';
                version = '10';
                break;
        }

        const dataRes = await executeQuery(`SELECT * FROM public."${fnName}"($1, $2)`, [companyId, fiscalYear]);
        const rows = dataRes.rows;

        // Construir XML para prevalidador DIAN
        const xmlContent = buildExogenaXml({
            formato: formatNumber,
            version,
            numEnvio,
            anoGravable: fiscalYear,
            nitInformante: company.documentNumber,
            dvInformante: company.verificationDigit,
            razonSocialInformante: company.businessName
        }, rows);

        return new NextResponse(xmlContent, {
            status: 200,
            headers: {
                'Content-Type': 'application/xml; charset=ISO-8859-1',
                'Content-Disposition': `attachment; filename="Dian_Exogena_${formatNumber}_v${version}_${fiscalYear}.xml"`
            }
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
