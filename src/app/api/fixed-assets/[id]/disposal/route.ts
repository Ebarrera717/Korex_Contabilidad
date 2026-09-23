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
            disposalType = 'BAJA_OBSOLESCENCIA', // 'BAJA_OBSOLESCENCIA', 'VENTA', 'DONACION', 'PERDIDA'
            salePrice = 0,
            accountSaleIncomeId = null,
            reason = 'Baja de activo fijo',
            createdById = 1
        } = body;

        const result = await executeQuery(
            `CALL public."spActivoFijoBajaRegistrar"($1, $2, $3, $4, $5, $6, NULL, NULL, NULL)`,
            [assetId, disposalType, salePrice, accountSaleIncomeId, reason, createdById]
        );

        const out = result.rows ? result.rows[0] : result;

        await logTraceability({
            code: `TRC-BAJA-AF-${Date.now()}`,
            module: 'ACTIVOS_FIJOS',
            action: 'BAJA_ENAJENACION',
            eventType: 'TRANSACCIONAL',
            stepName: 'spActivoFijoBajaRegistrar',
            spName: 'spActivoFijoBajaRegistrar',
            endpoint: `/api/fixed-assets/${assetId}/disposal`,
            durationMs: Date.now() - startTime,
            status: 'SUCCESS',
            inputData: body,
            outputData: out
        });

        return NextResponse.json({
            success: true,
            message: 'Baja / venta de activo fijo registrada y contabilizada correctamente',
            data: out
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
