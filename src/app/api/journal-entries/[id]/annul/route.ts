import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    try {
        const { id: idStr } = await params;
        const id = parseInt(idStr, 10);
        const body = await req.json().catch(() => ({}));
        const reason = body.reason || 'Anulación solicitada por usuario';
        const userId = body.userId || 1;

        if (isNaN(id)) {
            return NextResponse.json({ success: false, message: 'ID de comprobante inválido' }, { status: 400 });
        }

        if (isSQLServerMode()) {
            await executeSQLServerProcedure('spComprobanteAnular', {
                p_journal_id: id,
                p_reason: reason,
                p_user_id: userId
            });
        } else {
            await executePostgresQuery(
                'CALL public."spComprobanteAnular"($1, $2, $3)',
                [id, reason, userId]
            );
        }

        await recordTraceEvent({
            module: 'CONTABILIDAD',
            screen: 'Comprobantes',
            action: 'ANULAR',
            eventType: 'UPDATE',
            stepName: 'Comprobante Anulado',
            affectedId: String(id),
            inputData: { journalId: id, reason, userId }
        });

        return NextResponse.json({
            success: true,
            message: 'Comprobante anulado exitosamente.'
        });
    } catch (err: any) {
        console.error('[API_JOURNAL_ANNUL_ERROR]', err);
        return NextResponse.json({
            success: false,
            message: err.message || 'Error al anular comprobante'
        }, { status: 400 });
    }
}
