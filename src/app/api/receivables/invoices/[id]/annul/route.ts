import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { logTraceability } from '@/lib/traceability';

export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const startTime = Date.now();
    try {
        const { id } = await params;
        const invoiceId = parseInt(id, 10);
        const body = await request.json();
        const { reason = 'Anulación de factura de venta', userId = 1 } = body;

        await executeQuery(
            `CALL public."spFacturaVentaAnular"($1, $2, $3)`,
            [invoiceId, reason, userId]
        );

        await logTraceability({
            code: `TRC-ANUL-FV-${Date.now()}`,
            module: 'CARTERA',
            action: 'ANULAR_FACTURA_VENTA',
            eventType: 'TRANSACCIONAL',
            stepName: 'spFacturaVentaAnular',
            spName: 'spFacturaVentaAnular',
            endpoint: `/api/receivables/invoices/${invoiceId}/annul`,
            durationMs: Date.now() - startTime,
            status: 'SUCCESS',
            inputData: { invoiceId, reason, userId }
        });

        return NextResponse.json({ success: true, message: 'Factura de venta anulada exitosamente' });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
