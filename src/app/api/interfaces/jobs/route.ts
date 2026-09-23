import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = searchParams.get('companyId') ? parseInt(searchParams.get('companyId')!) : null;
        const status = searchParams.get('status') || null;
        const interfaceType = searchParams.get('interfaceType') || null;
        const limit = searchParams.get('limit') ? parseInt(searchParams.get('limit')!) : 50;
        const offset = searchParams.get('offset') ? parseInt(searchParams.get('offset')!) : 0;

        const result = await executeQuery(
            `SELECT * FROM public."fnBatchImportJobsListar"($1, $2, $3, $4, $5)`,
            [companyId, status, interfaceType, limit, offset]
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
