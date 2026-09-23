import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        const { searchParams } = new URL(req.url);
        const companyIdStr = searchParams.get('companyId');
        const companyId = companyIdStr ? parseInt(companyIdStr, 10) : null;
        const type = searchParams.get('type') || null; // 'INGRESO', 'EGRESO', 'TRANSFERENCIA'
        const startDate = searchParams.get('startDate') || null;
        const endDate = searchParams.get('endDate') || null;
        const bankAccountIdStr = searchParams.get('bankAccountId');
        const bankAccountId = bankAccountIdStr ? parseInt(bankAccountIdStr, 10) : null;
        const cashBoxIdStr = searchParams.get('cashBoxId');
        const cashBoxId = cashBoxIdStr ? parseInt(cashBoxIdStr, 10) : null;
        const status = searchParams.get('status') || null;
        const search = searchParams.get('search') || null;

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            let query = `
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
                WHERE 1=1
            `;
            if (companyId) query += ` AND tm.[companyId] = ${companyId}`;
            if (type) query += ` AND tm.[movementType] = '${type}'`;
            if (startDate) query += ` AND tm.[movementDate] >= '${startDate}'`;
            if (endDate) query += ` AND tm.[movementDate] <= '${endDate}'`;
            if (bankAccountId) query += ` AND tm.[bankAccountId] = ${bankAccountId}`;
            if (cashBoxId) query += ` AND tm.[cashBoxId] = ${cashBoxId}`;
            if (status) query += ` AND tm.[status] = '${status}'`;
            if (search) query += ` AND (tm.[entryNumber] LIKE '%${search}%' OR tm.[concept] LIKE '%${search}%' OR tp.[fullName] LIKE '%${search}%')`;
            query += ` ORDER BY tm.[movementDate] DESC, tm.[id] DESC`;

            const res = await pool.request().query(query);
            return NextResponse.json({ success: true, data: res.recordset || [] });
        }

        const data = await executePostgresQuery(
            'SELECT * FROM public."fnTesoreriaMovimientosListar"($1, $2, $3, $4, $5, $6, $7, $8)',
            [companyId, type, startDate, endDate, bankAccountId, cashBoxId, status, search]
        );
        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        console.error('[API_TREASURY_MOV_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const {
            movementType, companyId, movementDate, bankAccountId, cashBoxId,
            targetBankAccountId, targetCashBoxId, thirdPartyId, concept,
            paymentMethod, checkNumber, totalAmount,
            counterpartAccountId, debitAccountId, withholdingAmount, withholdingAccountId,
            costCenterId, userId
        } = body;

        if (!movementType || !companyId || !movementDate || !concept || !totalAmount) {
            return NextResponse.json({ success: false, message: 'Tipo, Empresa, Fecha, Concepto y Monto son obligatorios.' }, { status: 400 });
        }

        let movementId: number | null = null;
        let journalId: number | null = null;

        if (movementType === 'INGRESO') {
            if (isSQLServerMode()) {
                const res = await executeSQLServerProcedure('spTesoreriaIngresoCrear', {
                    p_company_id: companyId,
                    p_movement_date: movementDate,
                    p_bank_account_id: bankAccountId || null,
                    p_cash_box_id: cashBoxId || null,
                    p_third_party_id: thirdPartyId || null,
                    p_concept: concept,
                    p_payment_method: paymentMethod || 'TRANSFERENCIA',
                    p_check_number: checkNumber || null,
                    p_total_amount: totalAmount,
                    p_counterpart_account_id: counterpartAccountId,
                    p_cost_center_id: costCenterId || null,
                    p_user_id: userId || 1
                });
                movementId = res?.[0]?.p_movement_id || null;
                journalId = res?.[0]?.p_journal_id || null;
            } else {
                const res = await executePostgresQuery(
                    'CALL public."spTesoreriaIngresoCrear"($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)',
                    [
                        companyId, movementDate, bankAccountId || null, cashBoxId || null, thirdPartyId || null,
                        concept, paymentMethod || 'TRANSFERENCIA', checkNumber || null, totalAmount,
                        counterpartAccountId, costCenterId || null, userId || 1, null, null
                    ]
                );
                movementId = res?.[0]?.p_movement_id || null;
                journalId = res?.[0]?.p_journal_id || null;
            }
        } else if (movementType === 'EGRESO') {
            if (isSQLServerMode()) {
                const res = await executeSQLServerProcedure('spTesoreriaEgresoCrear', {
                    p_company_id: companyId,
                    p_movement_date: movementDate,
                    p_bank_account_id: bankAccountId || null,
                    p_cash_box_id: cashBoxId || null,
                    p_third_party_id: thirdPartyId || null,
                    p_concept: concept,
                    p_payment_method: paymentMethod || 'TRANSFERENCIA',
                    p_check_number: checkNumber || null,
                    p_total_amount: totalAmount,
                    p_debit_account_id: debitAccountId,
                    p_withholding_amount: withholdingAmount || 0,
                    p_withholding_account_id: withholdingAccountId || null,
                    p_cost_center_id: costCenterId || null,
                    p_user_id: userId || 1
                });
                movementId = res?.[0]?.p_movement_id || null;
                journalId = res?.[0]?.p_journal_id || null;
            } else {
                const res = await executePostgresQuery(
                    'CALL public."spTesoreriaEgresoCrear"($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)',
                    [
                        companyId, movementDate, bankAccountId || null, cashBoxId || null, thirdPartyId || null,
                        concept, paymentMethod || 'TRANSFERENCIA', checkNumber || null, totalAmount,
                        debitAccountId, withholdingAmount || 0, withholdingAccountId || null,
                        costCenterId || null, userId || 1, null, null
                    ]
                );
                movementId = res?.[0]?.p_movement_id || null;
                journalId = res?.[0]?.p_journal_id || null;
            }
        } else if (movementType === 'TRANSFERENCIA') {
            if (isSQLServerMode()) {
                const res = await executeSQLServerProcedure('spTesoreriaTransferenciaCrear', {
                    p_company_id: companyId,
                    p_movement_date: movementDate,
                    p_source_bank_id: bankAccountId || null,
                    p_source_cash_id: cashBoxId || null,
                    p_target_bank_id: targetBankAccountId || null,
                    p_target_cash_id: targetCashBoxId || null,
                    p_concept: concept,
                    p_total_amount: totalAmount,
                    p_user_id: userId || 1
                });
                movementId = res?.[0]?.p_movement_id || null;
                journalId = res?.[0]?.p_journal_id || null;
            } else {
                const res = await executePostgresQuery(
                    'CALL public."spTesoreriaTransferenciaCrear"($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)',
                    [
                        companyId, movementDate, bankAccountId || null, cashBoxId || null,
                        targetBankAccountId || null, targetCashBoxId || null,
                        concept, totalAmount, userId || 1, null, null
                    ]
                );
                movementId = res?.[0]?.p_movement_id || null;
                journalId = res?.[0]?.p_journal_id || null;
            }
        }

        await recordTraceEvent({
            module: 'TESORERIA',
            screen: 'Movimientos de Tesorería',
            action: movementType,
            eventType: 'CONTABILIZACION',
            stepName: `Movimiento de Tesorería ${movementType} Registrado`,
            affectedId: String(movementId),
            inputData: body
        });

        return NextResponse.json({
            success: true,
            message: `Movimiento de tesorería (${movementType}) registrado y contabilizado automáticamente.`,
            movementId,
            journalId
        });
    } catch (err: any) {
        console.error('[API_TREASURY_MOV_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
