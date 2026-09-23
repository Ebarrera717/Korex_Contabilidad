import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const year = parseInt(searchParams.get('year') || new Date().getFullYear().toString(), 10);
        const period = parseInt(searchParams.get('period') || '1', 10); // 1 = Bimestre 1 (Ene-Feb)

        const result = await executeQuery(
            'SELECT * FROM public."fnReporteDeclaracionIva"($1, $2, $3)',
            [companyId, year, period]
        );

        const rows = result.rows || result;
        let totalIvaGenerado = 0;
        let totalIvaDescontable = 0;

        rows.forEach((r: any) => {
            if (r.conceptCode === 'IVA_GEN_19') totalIvaGenerado += parseFloat(r.taxAmount || 0);
            if (r.conceptCode === 'IVA_DESC_COMPRAS') totalIvaDescontable += parseFloat(r.taxAmount || 0);
        });

        const saldoPagar = totalIvaGenerado - totalIvaDescontable;

        return NextResponse.json({
            success: true,
            form: 'FORMULARIO_300',
            year,
            period,
            data: rows,
            summary: {
                totalIvaGenerado,
                totalIvaDescontable,
                saldoPagar: saldoPagar > 0 ? saldoPagar : 0,
                saldoFavor: saldoPagar < 0 ? Math.abs(saldoPagar) : 0
            }
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
