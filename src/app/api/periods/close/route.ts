import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { year, month, userId, action } = body; // action: 'CLOSE' o 'REOPEN'

        if (!year || !month) {
            return NextResponse.json({ success: false, message: 'Año y Mes son obligatorios.' }, { status: 400 });
        }

        const isClose = action !== 'REOPEN';

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            if (isClose) {
                // Verificar borradores
                const chk = await pool.request().query(`
                    SELECT COUNT(*) AS [draftCount] FROM dbo.[JournalEntry]
                    WHERE YEAR([entryDate]) = ${year} AND MONTH([entryDate]) = ${month} AND [status] = 'DRAFT'
                `);
                const draftCount = chk.recordset[0]?.draftCount || 0;
                if (draftCount > 0) {
                    return NextResponse.json({
                        success: false,
                        message: `Existen ${draftCount} comprobantes en estado BORRADOR para el período ${year}-${month}. Debe contabilizarlos o anularlos antes de cerrar.`
                    }, { status: 400 });
                }

                await pool.request().query(`
                    UPDATE dbo.[FiscalPeriod] SET [status] = 'CLOSED', [closedAt] = GETDATE(), [closedBy] = ${userId || 1}, [updatedAt] = GETDATE()
                    WHERE [year] = ${year} AND [month] = ${month};
                `);
            } else {
                await pool.request().query(`
                    UPDATE dbo.[FiscalPeriod] SET [status] = 'OPEN', [closedAt] = NULL, [closedBy] = NULL, [updatedAt] = GETDATE()
                    WHERE [year] = ${year} AND [month] = ${month};
                `);
            }
        } else {
            if (isClose) {
                await executePostgresQuery(
                    'CALL public."spPeriodoCerrar"($1, $2, $3)',
                    [year, month, userId || 1]
                );
            } else {
                await executePostgresQuery(
                    'CALL public."spPeriodoReabrir"($1, $2, $3)',
                    [year, month, userId || 1]
                );
            }
        }

        await recordTraceEvent({
            module: 'PERIODOS',
            screen: 'Cierres de Período',
            action: isClose ? 'CIERRE_MENSUAL' : 'REAPERTURA',
            eventType: 'CIERRE_PERIODO',
            stepName: isClose ? `Período Fiscal ${year}-${month} Cerrado` : `Período Fiscal ${year}-${month} Reabierto`,
            affectedId: `${year}-${month}`,
            inputData: body
        });

        return NextResponse.json({
            success: true,
            message: isClose ? `Período ${year}-${month} cerrado satisfactoriamente.` : `Período ${year}-${month} reabierto satisfactoriamente.`
        });
    } catch (err: any) {
        console.error('[API_PERIOD_CLOSE_ERROR]', err);
        return NextResponse.json({
            success: false,
            message: err.message || 'Error al procesar estado del período'
        }, { status: 400 });
    }
}
