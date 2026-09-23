import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const year = new Date().getFullYear();
        const startDate = searchParams.get('startDate') || `${year}-01-01T00:00:00.000Z`;
        const endDate = searchParams.get('endDate') || `${year}-12-31T23:59:59.999Z`;

        const result = await executeQuery(
            'SELECT * FROM public."fnReporteLibroDiario"($1, $2, $3)',
            [companyId, startDate, endDate]
        );

        return NextResponse.json({ success: true, data: result.rows || result });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
