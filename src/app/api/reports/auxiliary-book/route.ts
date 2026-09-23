import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const accountId = searchParams.get('accountId') ? parseInt(searchParams.get('accountId')!, 10) : null;
        const year = new Date().getFullYear();
        const startDate = searchParams.get('startDate') || `${year}-01-01T00:00:00.000Z`;
        const endDate = searchParams.get('endDate') || `${year}-12-31T23:59:59.999Z`;
        const thirdPartyId = searchParams.get('thirdPartyId') ? parseInt(searchParams.get('thirdPartyId')!, 10) : null;

        if (!accountId) {
            return NextResponse.json({ success: false, message: 'Se requiere el parámetro accountId' }, { status: 400 });
        }

        const result = await executeQuery(
            'SELECT * FROM public."fnReporteLibroAuxiliar"($1, $2, $3, $4, $5)',
            [companyId, accountId, startDate, endDate, thirdPartyId]
        );

        return NextResponse.json({ success: true, data: result.rows || result });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
