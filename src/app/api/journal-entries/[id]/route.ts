import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import prisma from '@/lib/prisma';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    try {
        const { id: idStr } = await params;
        const id = parseInt(idStr, 10);

        if (isNaN(id)) {
            return NextResponse.json({ success: false, message: 'ID inválido' }, { status: 400 });
        }

        let header: any = null;
        let items: any[] = [];

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            const [rHead, rItems] = await Promise.all([
                pool.request().query(`
                    SELECT 
                        j.[id], j.[companyId], c.[businessName] AS [companyName],
                        j.[documentTypeId], d.[code] AS [documentTypeCode], d.[name] AS [documentTypeName],
                        j.[consecutiveNumber], j.[entryNumber], j.[entryDate],
                        j.[thirdPartyId], t.[documentNumber] AS [thirdPartyDoc], t.[fullName] AS [thirdPartyName],
                        j.[concept], j.[observation], j.[totalDebit], j.[totalCredit],
                        j.[status], j.[createdById], u.[name] AS [createdByName],
                        j.[postedAt], j.[annulledAt], j.[annulmentReason], j.[createdAt]
                    FROM dbo.[JournalEntry] j
                    INNER JOIN dbo.[Company] c ON j.[companyId] = c.[id]
                    INNER JOIN dbo.[DocumentType] d ON j.[documentTypeId] = d.[id]
                    LEFT JOIN dbo.[ThirdParty] t ON j.[thirdPartyId] = t.[id]
                    LEFT JOIN dbo.[User] u ON j.[createdById] = u.[id]
                    WHERE j.[id] = ${id}
                `),
                pool.request().query(`
                    SELECT 
                        ji.[id], ji.[journalEntryId], ji.[accountId], a.[code] AS [accountCode], a.[name] AS [accountName],
                        ji.[thirdPartyId], t.[documentNumber] AS [thirdPartyDoc], t.[fullName] AS [thirdPartyName],
                        ji.[costCenterId], cc.[code] AS [costCenterCode], cc.[name] AS [costCenterName],
                        ji.[debit], ji.[credit], ji.[baseAmount], ji.[description], ji.[documentReference]
                    FROM dbo.[JournalEntryItem] ji
                    INNER JOIN dbo.[Account] a ON ji.[accountId] = a.[id]
                    LEFT JOIN dbo.[ThirdParty] t ON ji.[thirdPartyId] = t.[id]
                    LEFT JOIN dbo.[CostCenter] cc ON ji.[costCenterId] = cc.[id]
                    WHERE ji.[journalEntryId] = ${id}
                    ORDER BY ji.[id] ASC
                `)
            ]);
            header = rHead.recordset[0] || null;
            items = rItems.recordset || [];
        } else {
            const headRows = await executePostgresQuery(
                'SELECT * FROM public."fnComprobanteListar"() WHERE id = $1',
                [id]
            );
            header = headRows[0] || null;
            items = await executePostgresQuery(
                'SELECT * FROM public."fnComprobanteDetalle"($1)',
                [id]
            );
        }

        if (!header) {
            return NextResponse.json({ success: false, message: 'Comprobante no encontrado' }, { status: 404 });
        }

        return NextResponse.json({
            success: true,
            data: {
                ...header,
                items
            }
        });
    } catch (err: any) {
        console.error('[API_JOURNAL_DETAIL_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    try {
        const { id: idStr } = await params;
        const id = parseInt(idStr, 10);

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            const check = await pool.request().query(`SELECT [status] FROM dbo.[JournalEntry] WHERE [id] = ${id}`);
            const status = check.recordset[0]?.status;
            if (status === 'POSTED') {
                return NextResponse.json({ success: false, message: 'No se puede eliminar un comprobante contabilizado. Debe anularlo o reversarlo.' }, { status: 400 });
            }
            await pool.request().query(`DELETE FROM dbo.[JournalEntryItem] WHERE [journalEntryId] = ${id}; DELETE FROM dbo.[JournalEntry] WHERE [id] = ${id};`);
        } else {
            const check = await executePostgresQuery('SELECT status FROM public."JournalEntry" WHERE id = $1', [id]);
            const status = check[0]?.status;
            if (status === 'POSTED') {
                return NextResponse.json({ success: false, message: 'No se puede eliminar un comprobante contabilizado. Debe anularlo o reversarlo.' }, { status: 400 });
            }
            await executePostgresQuery('DELETE FROM public."JournalEntry" WHERE id = $1', [id]);
        }

        await recordTraceEvent({
            module: 'CONTABILIDAD',
            screen: 'Comprobantes',
            action: 'DELETE',
            eventType: 'DELETE',
            stepName: 'Borrador de Comprobante Eliminado',
            affectedId: String(id)
        });

        return NextResponse.json({ success: true, message: 'Comprobante borrador eliminado correctamente.' });
    } catch (err: any) {
        console.error('[API_JOURNAL_DELETE_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
