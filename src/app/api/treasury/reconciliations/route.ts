import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        const { searchParams } = new URL(req.url);
        const bankAccountIdStr = searchParams.get('bankAccountId');
        const bankAccountId = bankAccountIdStr ? parseInt(bankAccountIdStr, 10) : null;
        const yearStr = searchParams.get('year');
        const year = yearStr ? parseInt(yearStr, 10) : new Date().getFullYear();
        const monthStr = searchParams.get('month');
        const month = monthStr ? parseInt(monthStr, 10) : (new Date().getMonth() + 1);

        if (!bankAccountId) {
            return NextResponse.json({ success: false, message: 'Cuenta bancaria requerida' }, { status: 400 });
        }

        let reconciliation: any = null;
        let items: any[] = [];

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            const res = await pool.request().query(`
                SELECT 
                    br.[id], br.[companyId], br.[bankAccountId], b.[name] AS [bankName], ba.[accountNumber],
                    br.[year], br.[month], br.[initialBalance], br.[finalBankStatementBalance],
                    br.[bookBalance], br.[difference], br.[status], br.[closedAt], u.[name] AS [closedByName],
                    br.[observations]
                FROM dbo.[BankReconciliation] br
                INNER JOIN dbo.[BankAccount] ba ON br.[bankAccountId] = ba.[id]
                INNER JOIN dbo.[Bank] b ON ba.[bankId] = b.[id]
                LEFT JOIN dbo.[User] u ON br.[closedById] = u.[id]
                WHERE br.[bankAccountId] = ${bankAccountId} AND br.[year] = ${year} AND br.[month] = ${month}
            `);
            reconciliation = res.recordset[0] || null;

            if (reconciliation) {
                const itemRes = await pool.request().query(`
                    SELECT * FROM dbo.[BankReconciliationItem] WHERE [bankReconciliationId] = ${reconciliation.id} ORDER BY [itemDate] ASC
                `);
                items = itemRes.recordset || [];
            }
        } else {
            const recRows = await executePostgresQuery(
                'SELECT * FROM public."fnConciliacionBancariaConsultar"($1, $2, $3)',
                [bankAccountId, year, month]
            );
            reconciliation = recRows[0] || null;

            if (reconciliation) {
                items = await executePostgresQuery(
                    'SELECT * FROM public."fnConciliacionPartidasListar"($1)',
                    [reconciliation.id]
                );
            }
        }

        return NextResponse.json({
            success: true,
            data: reconciliation ? { ...reconciliation, items } : null
        });
    } catch (err: any) {
        console.error('[API_RECONCILIATION_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { companyId, bankAccountId, year, month, statementBalance, initialBalance, observations, userId } = body;

        if (!companyId || !bankAccountId || !year || !month) {
            return NextResponse.json({ success: false, message: 'Empresa, Cuenta Bancaria, Año y Mes son obligatorios.' }, { status: 400 });
        }

        let reconciliationId: number | null = null;

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            // Calcular saldo en libros
            const acctRes = await pool.request().query(`SELECT [accountId] FROM dbo.[BankAccount] WHERE [id] = ${bankAccountId}`);
            const accountId = acctRes.recordset[0]?.accountId;

            let bookBalance = 0;
            if (accountId) {
                const balRes = await pool.request().query(`
                    SELECT ISNULL(SUM(ji.[debit]) - SUM(ji.[credit]), 0) AS [bookBal]
                    FROM dbo.[JournalEntryItem] ji
                    INNER JOIN dbo.[JournalEntry] j ON ji.[journalEntryId] = j.[id]
                    WHERE ji.[accountId] = ${accountId} AND j.[status] = 'POSTED'
                `);
                bookBalance = balRes.recordset[0]?.bookBal || 0;
            }

            const diff = bookBalance - (statementBalance || 0);

            const q = await pool.request()
                .input('companyId', companyId)
                .input('bankAccountId', bankAccountId)
                .input('year', year)
                .input('month', month)
                .input('initialBalance', initialBalance || 0)
                .input('statementBalance', statementBalance || 0)
                .input('bookBalance', bookBalance)
                .input('difference', diff)
                .input('observations', observations || null)
                .query(`
                    IF EXISTS (SELECT 1 FROM dbo.[BankReconciliation] WHERE [bankAccountId] = @bankAccountId AND [year] = @year AND [month] = @month)
                        UPDATE dbo.[BankReconciliation]
                        SET [initialBalance] = @initialBalance, [finalBankStatementBalance] = @statementBalance, [bookBalance] = @bookBalance, [difference] = @difference, [observations] = @observations, [updatedAt] = GETDATE()
                        WHERE [bankAccountId] = @bankAccountId AND [year] = @year AND [month] = @month;
                    ELSE
                        INSERT INTO dbo.[BankReconciliation] ([companyId], [bankAccountId], [year], [month], [initialBalance], [finalBankStatementBalance], [bookBalance], [difference], [status], [observations], [createdAt], [updatedAt])
                        VALUES (@companyId, @bankAccountId, @year, @month, @initialBalance, @statementBalance, @bookBalance, @difference, 'DRAFT', @observations, GETDATE(), GETDATE());
                    SELECT [id] FROM dbo.[BankReconciliation] WHERE [bankAccountId] = @bankAccountId AND [year] = @year AND [month] = @month;
                `);
            reconciliationId = q.recordset[0]?.id;
        } else {
            const res = await executePostgresQuery(
                'CALL public."spConciliacionBancariaCalcular"($1, $2, $3, $4, $5, $6, $7, $8, $9)',
                [
                    companyId, bankAccountId, year, month,
                    statementBalance || 0, initialBalance || 0,
                    observations || null, userId || 1, null
                ]
            );
            reconciliationId = res?.[0]?.p_reconciliation_id || null;
        }

        await recordTraceEvent({
            module: 'TESORERIA',
            screen: 'Conciliación Bancaria',
            action: 'CALCULAR',
            eventType: 'CONSULTA',
            stepName: `Conciliación Bancaria ${year}-${month} Calculada`,
            affectedId: String(reconciliationId),
            inputData: body
        });

        return NextResponse.json({
            success: true,
            message: 'Conciliación bancaria calculada y actualizada exitosamente.',
            reconciliationId
        });
    } catch (err: any) {
        console.error('[API_RECONCILIATION_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
