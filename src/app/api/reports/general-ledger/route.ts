import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const year = parseInt(searchParams.get('year') || new Date().getFullYear().toString(), 10);
        const month = parseInt(searchParams.get('month') || (new Date().getMonth() + 1).toString(), 10);

        const result = await executeQuery(
            'SELECT * FROM public."fnReporteLibroMayor"($1, $2, $3)',
            [companyId, year, month]
        );

        return NextResponse.json({ success: true, data: result.rows || result });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
