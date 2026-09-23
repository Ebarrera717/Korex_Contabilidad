import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const year = parseInt(searchParams.get('year') || new Date().getFullYear().toString(), 10);
        const month = parseInt(searchParams.get('month') || (new Date().getMonth() + 1).toString(), 10);

        const result = await executeQuery(
            'SELECT * FROM public."fnReporteDeclaracionRetefuente"($1, $2, $3)',
            [companyId, year, month]
        );

        const rows = result.rows || result;
        let totalRetenciones = 0;
        let totalBase = 0;

        rows.forEach((r: any) => {
            totalBase += parseFloat(r.baseAmount || 0);
            totalRetenciones += parseFloat(r.withholdingAmount || 0);
        });

        return NextResponse.json({
            success: true,
            form: 'FORMULARIO_350',
            year,
            month,
            data: rows,
            summary: {
                totalBase,
                totalRetencionesPagar: totalRetenciones
            }
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
