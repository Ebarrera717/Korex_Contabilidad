import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { reconciliationId, userId } = body;

        if (!reconciliationId) {
            return NextResponse.json({ success: false, message: 'ID de conciliación obligatorio.' }, { status: 400 });
        }

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            await pool.request().query(`
                UPDATE dbo.[BankReconciliation]
                SET [status] = 'CLOSED', [closedAt] = GETDATE(), [closedById] = ${userId || 1}, [updatedAt] = GETDATE()
                WHERE [id] = ${reconciliationId}
            `);
        } else {
            await executePostgresQuery(
                'CALL public."spConciliacionBancariaCerrar"($1, $2)',
                [reconciliationId, userId || 1]
            );
        }

        await recordTraceEvent({
            module: 'TESORERIA',
            screen: 'Conciliación Bancaria',
            action: 'CERRAR_CONCILIACION',
            eventType: 'UPDATE',
            stepName: 'Conciliación Bancaria Cerrada Formalmente',
            affectedId: String(reconciliationId),
            inputData: body
        });

        return NextResponse.json({
            success: true,
            message: 'Conciliación bancaria cerrada formalmente.'
        });
    } catch (err: any) {
        console.error('[API_RECONCILIATION_CLOSE_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
