import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const cutoffDate = searchParams.get('cutoffDate') || new Date().toISOString();
        const level = parseInt(searchParams.get('level') || '3', 10);

        const result = await executeQuery(
            'SELECT * FROM public."fnReporteBalanceGeneral"($1, $2, $3)',
            [companyId, cutoffDate, level]
        );

        const accounts = result.rows || result;
        let totalActivo = 0;
        let totalPasivo = 0;
        let totalPatrimonio = 0;

        accounts.forEach((acc: any) => {
            if (acc.class === 'ACTIVO' && acc.level === 1) totalActivo += parseFloat(acc.balance || 0);
            if (acc.class === 'PASIVO' && acc.level === 1) totalPasivo += parseFloat(acc.balance || 0);
            if (acc.class === 'PATRIMONIO' && acc.level === 1) totalPatrimonio += parseFloat(acc.balance || 0);
        });

        return NextResponse.json({
            success: true,
            data: accounts,
            summary: {
                totalActivo,
                totalPasivo,
                totalPatrimonio,
                equationBalance: Math.abs(totalActivo - (totalPasivo + totalPatrimonio)) < 0.01
            }
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
