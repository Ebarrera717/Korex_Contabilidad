import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const year = new Date().getFullYear();
        const startDate = searchParams.get('startDate') || `${year}-01-01T00:00:00.000Z`;
        const endDate = searchParams.get('endDate') || `${year}-12-31T23:59:59.999Z`;
        const level = parseInt(searchParams.get('level') || '5', 10);

        const result = await executeQuery(
            'SELECT * FROM public."fnReporteBalancePrueba"($1, $2, $3, $4)',
            [companyId, startDate, endDate, level]
        );

        const accounts = result.rows || result;
        let totalPeriodDebit = 0;
        let totalPeriodCredit = 0;

        accounts.forEach((acc: any) => {
            if (acc.level === 1) {
                totalPeriodDebit += parseFloat(acc.periodDebit || 0);
                totalPeriodCredit += parseFloat(acc.periodCredit || 0);
            }
        });

        return NextResponse.json({
            success: true,
            data: accounts,
            summary: {
                totalPeriodDebit,
                totalPeriodCredit,
                isBalanced: Math.abs(totalPeriodDebit - totalPeriodCredit) < 0.01
            }
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
