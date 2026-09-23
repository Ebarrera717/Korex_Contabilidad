import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { logTraceability } from '@/lib/traceability';

export async function POST(request: NextRequest) {
    const startTime = Date.now();
    try {
        const body = await request.json();
        const {
            payableInvoiceId,
            payableInstallmentId = null,
            treasuryMovementId = null,
            advancePaymentId = null,
            creditNoteId = null,
            amount,
            discountAmount = 0,
            observations = 'Cruce de Proveedores'
        } = body;

        if (!payableInvoiceId || !amount) {
            return NextResponse.json({
                success: false,
                message: 'Faltan parámetros obligatorios: payableInvoiceId, amount'
            }, { status: 400 });
        }

        const result = await executeQuery(
            `CALL public."spProveedorEgresoCruzar"($1, $2, $3, $4, $5, $6, $7, $8, NULL, NULL, NULL)`,
            [
                payableInvoiceId, payableInstallmentId, treasuryMovementId,
                advancePaymentId, creditNoteId, amount, discountAmount, observations
            ]
        );

        const out = result.rows ? result.rows[0] : result;

        await logTraceability({
            code: `TRC-CRUCE-CXP-${Date.now()}`,
            module: 'PROVEEDORES',
            action: 'CRUCE_PROVEEDORES',
            eventType: 'TRANSACCIONAL',
            stepName: 'spProveedorEgresoCruzar',
            spName: 'spProveedorEgresoCruzar',
            endpoint: '/api/payables/cross',
            durationMs: Date.now() - startTime,
            status: 'SUCCESS',
            inputData: body,
            outputData: out
        });

        return NextResponse.json({
            success: true,
            message: 'Cruce de cuenta por pagar aplicado con éxito',
            data: out
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
