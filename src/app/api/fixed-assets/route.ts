import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { logTraceability } from '@/lib/traceability';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const categoryId = searchParams.get('categoryId') ? parseInt(searchParams.get('categoryId')!, 10) : null;
        const status = searchParams.get('status') || null;

        const result = await executeQuery(
            'SELECT * FROM public."fnActivosFijosListar"($1, $2, $3)',
            [companyId, categoryId, status]
        );

        return NextResponse.json({ success: true, data: result.rows || result });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}

export async function POST(request: NextRequest) {
    const startTime = Date.now();
    try {
        const body = await request.json();
        const {
            id = null,
            companyId = 1,
            categoryId,
            code,
            name,
            description = '',
            serialNumber = null,
            purchaseDate = new Date().toISOString(),
            activationDate = new Date().toISOString(),
            acquisitionCost,
            residualValue = 0,
            usefulLifeMonths = 60,
            costCenterId = null,
            responsibleThirdPartyId = null,
            location = '',
            createdById = 1
        } = body;

        if (!categoryId || !code || !name || !acquisitionCost) {
            return NextResponse.json({
                success: false,
                message: 'Faltan parámetros obligatorios: categoryId, code, name, acquisitionCost'
            }, { status: 400 });
        }

        const result = await executeQuery(
            `CALL public."spActivoFijoGuardar"($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, NULL)`,
            [
                id, companyId, categoryId, code, name, description, serialNumber,
                purchaseDate, activationDate, acquisitionCost, residualValue,
                usefulLifeMonths, costCenterId, responsibleThirdPartyId, location, createdById
            ]
        );

        const out = result.rows ? result.rows[0] : result;

        await logTraceability({
            code: `TRC-AF-${Date.now()}`,
            module: 'ACTIVOS_FIJOS',
            action: 'GUARDAR_ACTIVO_FIJO',
            eventType: 'TRANSACCIONAL',
            stepName: 'spActivoFijoGuardar',
            spName: 'spActivoFijoGuardar',
            endpoint: '/api/fixed-assets',
            durationMs: Date.now() - startTime,
            status: 'SUCCESS',
            inputData: body,
            outputData: out
        });

        return NextResponse.json({
            success: true,
            message: 'Activo fijo guardado correctamente',
            data: out
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
