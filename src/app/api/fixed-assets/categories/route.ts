import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET() {
    try {
        const result = await executeQuery('SELECT * FROM public."fnActivosFijosCategoriasListar"()');
        return NextResponse.json({ success: true, data: result.rows || result });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}

export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const {
            id = null,
            code,
            name,
            defaultUsefulLifeMonths = 60,
            accountAssetId,
            accountAccumDeprId,
            accountExpenseDeprId,
            isActive = true
        } = body;

        if (!code || !name || !accountAssetId || !accountAccumDeprId || !accountExpenseDeprId) {
            return NextResponse.json({
                success: false,
                message: 'Faltan parámetros obligatorios: code, name, accountAssetId, accountAccumDeprId, accountExpenseDeprId'
            }, { status: 400 });
        }

        const result = await executeQuery(
            `CALL public."spActivoFijoCategoriaGuardar"($1, $2, $3, $4, $5, $6, $7, $8, NULL)`,
            [id, code, name, defaultUsefulLifeMonths, accountAssetId, accountAccumDeprId, accountExpenseDeprId, isActive]
        );

        return NextResponse.json({
            success: true,
            message: 'Categoría de activo fijo guardada exitosamente',
            data: result.rows ? result.rows[0] : result
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
