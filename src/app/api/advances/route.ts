import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { logTraceability } from '@/lib/traceability';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const advanceType = searchParams.get('advanceType') || null;
        const thirdPartyId = searchParams.get('thirdPartyId') ? parseInt(searchParams.get('thirdPartyId')!, 10) : null;
        const status = searchParams.get('status') || null;

        const result = await executeQuery(
            'SELECT * FROM public."fnAnticiposListar"($1, $2, $3, $4)',
            [companyId, advanceType, thirdPartyId, status]
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
            advanceType, // 'CLIENTE', 'PROVEEDOR'
            thirdPartyId,
            treasuryMovementId = null,
            amount,
            concept,
            createdById = 1
        } = body;

        if (!advanceType || !thirdPartyId || !amount || !concept) {
            return NextResponse.json({
                success: false,
                message: 'Faltan parámetros obligatorios: advanceType, thirdPartyId, amount, concept'
            }, { status: 400 });
        }

        const result = await executeQuery(
            `CALL public."spAnticipoRegistrar"($1, $2, $3, $4, $5, $6, $7, NULL)`,
            [companyId, advanceType, thirdPartyId, treasuryMovementId, amount, concept, createdById]
        );

        const out = result.rows ? result.rows[0] : result;

        await logTraceability({
            code: `TRC-ANT-${Date.now()}`,
            module: 'ANTICIPOS',
            action: 'REGISTRAR_ANTICIPO',
            eventType: 'TRANSACCIONAL',
            stepName: 'spAnticipoRegistrar',
            spName: 'spAnticipoRegistrar',
            endpoint: '/api/advances',
            durationMs: Date.now() - startTime,
            status: 'SUCCESS',
            inputData: body,
            outputData: out
        });

        return NextResponse.json({
            success: true,
            message: `Anticipo de ${advanceType} registrado correctamente`,
            data: out
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
