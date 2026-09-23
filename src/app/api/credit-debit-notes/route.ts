import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { logTraceability } from '@/lib/traceability';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const noteType = searchParams.get('noteType') || null;
        const thirdPartyId = searchParams.get('thirdPartyId') ? parseInt(searchParams.get('thirdPartyId')!, 10) : null;

        const result = await executeQuery(
            'SELECT * FROM public."fnNotasCarteraListar"($1, $2, $3)',
            [companyId, noteType, thirdPartyId]
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
            companyId = 1,
            noteType, // 'NC_CLIENTE', 'ND_CLIENTE', 'NC_PROVEEDOR', 'ND_PROVEEDOR'
            documentTypeId = 4, // NC
            thirdPartyId,
            receivableInvoiceId = null,
            payableInvoiceId = null,
            concept,
            subtotal,
            taxAmount = 0,
            accountConceptId,
            accountCounterpartId,
            createdById = 1,
            observations = ''
        } = body;

        if (!noteType || !thirdPartyId || !concept || !subtotal || !accountConceptId || !accountCounterpartId) {
            return NextResponse.json({
                success: false,
                message: 'Faltan parámetros obligatorios: noteType, thirdPartyId, concept, subtotal, accountConceptId, accountCounterpartId'
            }, { status: 400 });
        }

        const result = await executeQuery(
            `CALL public."spNotaCarteraCrear"($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NULL, NULL, NULL)`,
            [
                companyId, noteType, documentTypeId, thirdPartyId,
                receivableInvoiceId, payableInvoiceId, concept, subtotal,
                taxAmount, accountConceptId, accountCounterpartId, createdById, observations
            ]
        );

        const out = result.rows ? result.rows[0] : result;

        await logTraceability({
            code: `TRC-NOTA-${Date.now()}`,
            module: 'NOTAS_CARTERA',
            action: 'EMITIR_NOTA',
            eventType: 'TRANSACCIONAL',
            stepName: 'spNotaCarteraCrear',
            spName: 'spNotaCarteraCrear',
            endpoint: '/api/credit-debit-notes',
            durationMs: Date.now() - startTime,
            status: 'SUCCESS',
            inputData: body,
            outputData: out
        });

        return NextResponse.json({
            success: true,
            message: `Nota ${noteType} emitida y contabilizada correctamente`,
            data: out
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
