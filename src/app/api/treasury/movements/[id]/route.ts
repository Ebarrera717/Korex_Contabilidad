import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    try {
        const { id: idStr } = await params;
        const id = parseInt(idStr, 10);

        if (isNaN(id)) {
            return NextResponse.json({ success: false, message: 'ID inválido' }, { status: 400 });
        }

        let movement: any = null;

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            const res = await pool.request().query(`
                SELECT 
                    tm.[id], tm.[companyId], tm.[movementType], tm.[documentTypeId],
                    dt.[code] AS [documentTypeCode], dt.[name] AS [documentTypeName],
                    tm.[consecutiveNumber], tm.[entryNumber], tm.[movementDate],
                    tm.[bankAccountId], b.[name] AS [bankName], ba.[accountNumber] AS [bankAccountNumber],
                    tm.[cashBoxId], cb.[name] AS [cashBoxName],
                    tm.[thirdPartyId], tp.[documentNumber] AS [thirdPartyDoc], tp.[fullName] AS [thirdPartyName],
                    tm.[concept], tm.[paymentMethod], tm.[checkNumber], tm.[totalAmount],
                    tm.[status], tm.[journalEntryId], tm.[createdById], u.[name] AS [createdByName],
                    tm.[createdAt]
                FROM dbo.[TreasuryMovement] tm
                INNER JOIN dbo.[DocumentType] dt ON tm.[documentTypeId] = dt.[id]
                LEFT JOIN dbo.[BankAccount] ba ON tm.[bankAccountId] = ba.[id]
                LEFT JOIN dbo.[Bank] b ON ba.[bankId] = b.[id]
                LEFT JOIN dbo.[CashBox] cb ON tm.[cashBoxId] = cb.[id]
                LEFT JOIN dbo.[ThirdParty] tp ON tm.[thirdPartyId] = tp.[id]
                LEFT JOIN dbo.[User] u ON tm.[createdById] = u.[id]
                WHERE tm.[id] = ${id}
            `);
            movement = res.recordset[0] || null;
        } else {
            const rows = await executePostgresQuery(
                'SELECT * FROM public."fnTesoreriaMovimientosListar"() WHERE id = $1',
                [id]
            );
            movement = rows[0] || null;
        }

        if (!movement) {
            return NextResponse.json({ success: false, message: 'Movimiento no encontrado' }, { status: 404 });
        }

        return NextResponse.json({ success: true, data: movement });
    } catch (err: any) {
        console.error('[API_TREASURY_MOV_DETAIL_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
