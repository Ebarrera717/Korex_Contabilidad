import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    try {
        const { id: idStr } = await params;
        const id = parseInt(idStr, 10);
        const body = await req.json().catch(() => ({}));
        const userId = body.userId || 1;

        if (isNaN(id)) {
            return NextResponse.json({ success: false, message: 'ID de comprobante inválido' }, { status: 400 });
        }

        if (isSQLServerMode()) {
            await executeSQLServerProcedure('spComprobanteContabilizar', {
                p_journal_id: id,
                p_user_id: userId
            });
        } else {
            await executePostgresQuery(
                'CALL public."spComprobanteContabilizar"($1, $2)',
                [id, userId]
            );
        }

        await recordTraceEvent({
            module: 'CONTABILIDAD',
            screen: 'Comprobantes',
            action: 'CONTABILIZAR',
            eventType: 'CONTABILIZACION',
            stepName: 'Comprobante Contabilizado con Partida Doble',
            affectedId: String(id),
            inputData: { journalId: id, userId }
        });

        return NextResponse.json({
            success: true,
            message: 'Comprobante formalmente asentado y contabilizado con éxito (Partida Doble verificada).'
        });
    } catch (err: any) {
        console.error('[API_JOURNAL_POSTING_ERROR]', err);
        return NextResponse.json({
            success: false,
            message: err.message || 'Error al contabilizar comprobante'
        }, { status: 400 });
    }
}
