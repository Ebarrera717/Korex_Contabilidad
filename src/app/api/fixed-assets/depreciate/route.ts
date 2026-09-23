import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { logTraceability } from '@/lib/traceability';

export async function POST(request: NextRequest) {
    const startTime = Date.now();
    try {
        const body = await request.json();
        const {
            companyId = 1,
            year = new Date().getFullYear(),
            month = new Date().getMonth() + 1,
            createdById = 1
        } = body;

        const result = await executeQuery(
            `CALL public."spActivoFijoDepreciarPeriodo"($1, $2, $3, $4, NULL, NULL, NULL)`,
            [companyId, year, month, createdById]
        );

        const out = result.rows ? result.rows[0] : result;

        await logTraceability({
            code: `TRC-DEPR-${year}-${month}-${Date.now()}`,
            module: 'ACTIVOS_FIJOS',
            action: 'DEPRECIAR_PERIODO',
            eventType: 'TRANSACCIONAL',
            stepName: 'spActivoFijoDepreciarPeriodo',
            spName: 'spActivoFijoDepreciarPeriodo',
            endpoint: '/api/fixed-assets/depreciate',
            durationMs: Date.now() - startTime,
            status: 'SUCCESS',
            inputData: body,
            outputData: out
        });

        return NextResponse.json({
            success: true,
            message: `Depreciación periódica (${year}-${month}) ejecutada y contabilizada correctamente`,
            data: out
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
