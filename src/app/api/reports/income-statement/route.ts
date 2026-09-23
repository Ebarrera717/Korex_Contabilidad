import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const year = new Date().getFullYear();
        const startDate = searchParams.get('startDate') || `${year}-01-01T00:00:00.000Z`;
        const endDate = searchParams.get('endDate') || `${year}-12-31T23:59:59.999Z`;
        const level = parseInt(searchParams.get('level') || '3', 10);

        const result = await executeQuery(
            'SELECT * FROM public."fnReporteEstadoResultados"($1, $2, $3, $4)',
            [companyId, startDate, endDate, level]
        );

        const accounts = result.rows || result;
        let totalIngresos = 0;
        let totalGastos = 0;
        let totalCostosVentas = 0;
        let totalCostosProduccion = 0;

        accounts.forEach((acc: any) => {
            if (acc.category === 'INGRESOS' && acc.level === 1) totalIngresos += parseFloat(acc.netAmount || 0);
            if (acc.category === 'GASTOS' && acc.level === 1) totalGastos += parseFloat(acc.netAmount || 0);
            if (acc.category === 'COSTOS_VENTAS' && acc.level === 1) totalCostosVentas += parseFloat(acc.netAmount || 0);
            if (acc.category === 'COSTOS_PRODUCCION' && acc.level === 1) totalCostosProduccion += parseFloat(acc.netAmount || 0);
        });

        const utilidadBruta = totalIngresos - (totalCostosVentas + totalCostosProduccion);
        const utilidadOperacional = utilidadBruta - totalGastos;

        return NextResponse.json({
            success: true,
            data: accounts,
            summary: {
                totalIngresos,
                totalCostosVentas,
                totalCostosProduccion,
                utilidadBruta,
                totalGastos,
                utilidadOperacional
            }
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
