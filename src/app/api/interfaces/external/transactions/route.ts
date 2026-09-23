import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const endpointCode = searchParams.get('endpointCode') || null;
        const direction = searchParams.get('direction') || null;
        const status = searchParams.get('status') || null;
        const startDate = searchParams.get('startDate') || null;
        const endDate = searchParams.get('endDate') || null;
        const limit = searchParams.get('limit') ? parseInt(searchParams.get('limit')!) : 50;
        const offset = searchParams.get('offset') ? parseInt(searchParams.get('offset')!) : 0;

        const result = await executeQuery(
            `SELECT * FROM public."fnIntegrationTransactionsListar"($1, $2, $3, $4, $5, $6, $7)`,
            [endpointCode, direction, status, startDate, endDate, limit, offset]
        );

        return NextResponse.json({
            success: true,
            count: result.rows.length,
            data: result.rows
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
