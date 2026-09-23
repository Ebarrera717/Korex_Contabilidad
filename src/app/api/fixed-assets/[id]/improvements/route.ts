import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { logTraceability } from '@/lib/traceability';

export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const startTime = Date.now();
    try {
        const { id } = await params;
        const assetId = parseInt(id, 10);
        const body = await request.json();
        const {
            description,
            amount,
            additionalMonths = 0,
            accountCounterpartId,
            createdById = 1
        } = body;

        if (!description || !amount || !accountCounterpartId) {
            return NextResponse.json({
                success: false,
                message: 'Faltan parámetros obligatorios: description, amount, accountCounterpartId'
            }, { status: 400 });
        }

        const result = await executeQuery(
            `CALL public."spActivoFijoMejoraRegistrar"($1, $2, $3, $4, $5, $6, NULL, NULL)`,
            [assetId, description, amount, additionalMonths, accountCounterpartId, createdById]
        );

        const out = result.rows ? result.rows[0] : result;

        await logTraceability({
            code: `TRC-MEJ-AF-${Date.now()}`,
            module: 'ACTIVOS_FIJOS',
            action: 'MEJORA_CAPITALIZABLE',
            eventType: 'TRANSACCIONAL',
            stepName: 'spActivoFijoMejoraRegistrar',
            spName: 'spActivoFijoMejoraRegistrar',
            endpoint: `/api/fixed-assets/${assetId}/improvements`,
            durationMs: Date.now() - startTime,
            status: 'SUCCESS',
            inputData: body,
            outputData: out
        });

        return NextResponse.json({
            success: true,
            message: 'Mejora capitalizable registrada y contabilizada con éxito',
            data: out
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
