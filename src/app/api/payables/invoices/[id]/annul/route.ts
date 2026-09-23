import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { logTraceability } from '@/lib/traceability';

export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const startTime = Date.now();
    try {
        const { id } = await params;
        const invoiceId = parseInt(id, 10);
        const body = await request.json();
        const { reason = 'Anulación de factura de compra', userId = 1 } = body;

        await executeQuery(
            `CALL public."spFacturaCompraAnular"($1, $2, $3)`,
            [invoiceId, reason, userId]
        );

        await logTraceability({
            code: `TRC-ANUL-FC-${Date.now()}`,
            module: 'PROVEEDORES',
            action: 'ANULAR_FACTURA_COMPRA',
            eventType: 'TRANSACCIONAL',
            stepName: 'spFacturaCompraAnular',
            spName: 'spFacturaCompraAnular',
            endpoint: `/api/payables/invoices/${invoiceId}/annul`,
            durationMs: Date.now() - startTime,
            status: 'SUCCESS',
            inputData: { invoiceId, reason, userId }
        });

        return NextResponse.json({ success: true, message: 'Factura de compra anulada exitosamente' });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
