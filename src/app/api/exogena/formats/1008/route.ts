import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const year = parseInt(searchParams.get('year') || (new Date().getFullYear() - 1).toString(), 10);

        const result = await executeQuery(
            'SELECT * FROM public."fnGenerarFormatoExogena1008"($1, $2)',
            [companyId, year]
        );

        return NextResponse.json({
            success: true,
            format: '1008',
            version: '8',
            year,
            recordsCount: (result.rows || result).length,
            data: result.rows || result
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
