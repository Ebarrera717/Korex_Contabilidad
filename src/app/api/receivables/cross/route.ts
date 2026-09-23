import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { logTraceability } from '@/lib/traceability';

export async function POST(request: NextRequest) {
    const startTime = Date.now();
    try {
        const body = await request.json();
        const {
            receivableInvoiceId,
            receivableInstallmentId = null,
            treasuryMovementId = null,
            advancePaymentId = null,
            creditNoteId = null,
            amount,
            discountAmount = 0,
            withholdingAdjustment = 0,
            observations = 'Cruce de Cartera'
        } = body;

        if (!receivableInvoiceId || !amount) {
            return NextResponse.json({
                success: false,
                message: 'Faltan parámetros obligatorios: receivableInvoiceId, amount'
            }, { status: 400 });
        }

        const result = await executeQuery(
            `CALL public."spCarteraReciboCruzar"($1, $2, $3, $4, $5, $6, $7, $8, $9, NULL, NULL, NULL)`,
            [
                receivableInvoiceId, receivableInstallmentId, treasuryMovementId,
                advancePaymentId, creditNoteId, amount, discountAmount,
                withholdingAdjustment, observations
            ]
        );

        const out = result.rows ? result.rows[0] : result;

        await logTraceability({
            code: `TRC-CRUCE-CXC-${Date.now()}`,
            module: 'CARTERA',
            action: 'CRUCE_CARTERA',
            eventType: 'TRANSACCIONAL',
            stepName: 'spCarteraReciboCruzar',
            spName: 'spCarteraReciboCruzar',
            endpoint: '/api/receivables/cross',
            durationMs: Date.now() - startTime,
            status: 'SUCCESS',
            inputData: body,
            outputData: out
        });

        return NextResponse.json({
            success: true,
            message: 'Cruce de cartera aplicado con éxito',
            data: out
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
