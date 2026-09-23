import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    try {
        const { id: idStr } = await params;
        const id = parseInt(idStr, 10);
        const body = await req.json().catch(() => ({}));
        const reason = body.reason || 'Reversión y ajuste contable inverso';
        const userId = body.userId || 1;

        if (isNaN(id)) {
            return NextResponse.json({ success: false, message: 'ID de comprobante inválido' }, { status: 400 });
        }

        let reverseJournalId: number | null = null;

        if (isSQLServerMode()) {
            const res = await executeSQLServerProcedure('spComprobanteReversar', {
                p_journal_id: id,
                p_reason: reason,
                p_user_id: userId
            });
            reverseJournalId = res?.[0]?.p_reverse_journal_id || null;
        } else {
            const res = await executePostgresQuery(
                'CALL public."spComprobanteReversar"($1, $2, $3, $4)',
                [id, reason, userId, null]
            );
            reverseJournalId = res?.[0]?.p_reverse_journal_id || null;
        }

        await recordTraceEvent({
            module: 'CONTABILIDAD',
            screen: 'Comprobantes',
            action: 'REVERSAR',
            eventType: 'CONTABILIZACION',
            stepName: 'Comprobante Reversado Automáticamente',
            affectedId: String(reverseJournalId || id),
            inputData: { originalJournalId: id, reverseJournalId, reason, userId }
        });

        return NextResponse.json({
            success: true,
            message: 'Comprobante reversado exitosamente. Se ha generado un nuevo comprobante inverso contabilizado.',
            reverseJournalId
        });
    } catch (err: any) {
        console.error('[API_JOURNAL_REVERSE_ERROR]', err);
        return NextResponse.json({
            success: false,
            message: err.message || 'Error al reversar comprobante'
        }, { status: 400 });
    }
}
