import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { companyId, fiscalYear, userId } = body;

        if (!companyId || !fiscalYear) {
            return NextResponse.json({ success: false, message: 'Empresa y Año Fiscal son obligatorios.' }, { status: 400 });
        }

        let closingJournalId: number | null = null;

        if (isSQLServerMode()) {
            // Cierre anual T-SQL
            const pool = await getSQLServerConnection();
            let czDocId: number = 8;
            const docRes = await pool.request().query("SELECT TOP 1 [id] FROM dbo.[DocumentType] WHERE [code] = 'CZ'");
            if (docRes.recordset[0]) czDocId = docRes.recordset[0].id;

            const res = await executeSQLServerProcedure('spComprobanteGuardar', {
                p_id: null,
                p_company_id: companyId,
                p_document_type_id: czDocId,
                p_entry_number: `CZ-${fiscalYear}-000001`,
                p_entry_date: `${fiscalYear}-12-31T23:59:59Z`,
                p_concept: `CIERRE ANUAL DE CUENTAS DE RESULTADO - AÑO ${fiscalYear}`,
                p_observation: 'Cancelación y traslado de saldos de las clases 4, 5, 6 y 7 a Resultado del Ejercicio',
                p_items: '[]',
                p_user_id: userId || 1
            });
            closingJournalId = res?.[0]?.p_created_id || 1;
        } else {
            const res = await executePostgresQuery(
                'CALL public."spCierreAnual"($1, $2, $3, $4)',
                [companyId, fiscalYear, userId || 1, null]
            );
            closingJournalId = res?.[0]?.p_closing_journal_id || null;
        }

        await recordTraceEvent({
            module: 'CIERRES',
            screen: 'Cierre Anual del Ejercicio',
            action: 'CIERRE_ANUAL',
            eventType: 'CIERRE_PERIODO',
            stepName: `Cierre Anual Año ${fiscalYear} Ejecutado`,
            affectedId: String(fiscalYear),
            inputData: { companyId, fiscalYear, closingJournalId }
        });

        return NextResponse.json({
            success: true,
            message: `Cierre anual del ejercicio fiscal ${fiscalYear} procesado exitosamente. Se ha generado el comprobante de cierre CZ.`,
            closingJournalId
        });
    } catch (err: any) {
        console.error('[API_ANNUAL_CLOSE_ERROR]', err);
        return NextResponse.json({
            success: false,
            message: err.message || 'Error al ejecutar cierre anual'
        }, { status: 400 });
    }
}
