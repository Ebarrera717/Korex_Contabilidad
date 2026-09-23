import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function POST(request: NextRequest) {
    const startTime = Date.now();
    let endpointCode = 'UNKNOWN';
    let eventType = 'UNKNOWN';
    let body: any = null;

    try {
        body = await request.json();
        endpointCode = body.endpointCode || request.headers.get('x-endpoint-code') || 'EXTERNAL_ERP';
        eventType = body.eventType || 'COMPROBANTE_SYNC';

        const { companyId, entries, autoPost, userId } = body;

        if (!companyId || !entries || !Array.isArray(entries)) {
            const errorMsg = 'El payload debe contener companyId y entries (array)';
            const durationMs = Date.now() - startTime;

            await executeQuery(
                `CALL public."spIntegrationTransactionRegistrar"($1, 'INBOUND', $2, $3::jsonb, $4::jsonb, 400, $5, 'ERROR', $6, NULL)`,
                [endpointCode, eventType, JSON.stringify(body), JSON.stringify({ error: errorMsg }), durationMs, errorMsg]
            );

            return NextResponse.json({ success: false, error: errorMsg }, { status: 400 });
        }

        // Ejecutar ingesta de comprobantes
        const importRes = await executeQuery(
            `CALL public."spBatchImportComprobantes"($1, $2::jsonb, $3, $4, NULL, NULL, NULL, NULL)`,
            [companyId, JSON.stringify(entries), autoPost !== false, userId || 1]
        );

        const totalRows = importRes.rows[0]?.p_total_rows || entries.length;
        const successRows = importRes.rows[0]?.p_success_rows || 0;
        const failedRows = importRes.rows[0]?.p_failed_rows || 0;
        const errors = importRes.rows[0]?.p_errors || [];

        const responsePayload = {
            success: failedRows === 0,
            totalRows,
            successRows,
            failedRows,
            errors
        };

        const durationMs = Date.now() - startTime;
        const txStatus = failedRows === 0 ? 'SUCCESS' : (successRows > 0 ? 'PARTIAL' : 'ERROR');

        const txRes = await executeQuery(
            `CALL public."spIntegrationTransactionRegistrar"($1, 'INBOUND', $2, $3::jsonb, $4::jsonb, 200, $5, $6, $7, NULL)`,
            [endpointCode, eventType, JSON.stringify(body), JSON.stringify(responsePayload), durationMs, txStatus, failedRows > 0 ? 'Errores en comprobantes' : null]
        );

        return NextResponse.json({
            ...responsePayload,
            txCode: txRes.rows[0]?.p_tx_code
        });
    } catch (error: any) {
        const durationMs = Date.now() - startTime;
        await executeQuery(
            `CALL public."spIntegrationTransactionRegistrar"($1, 'INBOUND', $2, $3::jsonb, $4::jsonb, 500, $5, 'ERROR', $6, NULL)`,
            [endpointCode, eventType, JSON.stringify(body || {}), JSON.stringify({ error: error.message }), durationMs, error.message]
        );

        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
