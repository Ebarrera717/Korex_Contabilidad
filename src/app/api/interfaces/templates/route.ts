import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const category = searchParams.get('category');

        let query = `SELECT "id", "code", "name", "category", "formatType", "mappingConfig", "isActive", "createdAt" 
                     FROM public."DataInterfaceTemplate" 
                     WHERE "isActive" = true`;
        const params: any[] = [];

        if (category) {
            params.push(category);
            query += ` AND "category" = $1`;
        }

        query += ` ORDER BY "category" ASC, "name" ASC;`;

        const result = await executeQuery(query, params);
        return NextResponse.json({ success: true, count: result.rows.length, data: result.rows });
    } catch (error: any) {
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
