import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            const res = await pool.request().query(`
                SELECT 
                    t.[id], t.[code], t.[name], t.[type], t.[ratePercentage], t.[minimumBaseAmount],
                    t.[accountDebitId], ad.[code] AS [accountDebitCode], ad.[name] AS [accountDebitName],
                    t.[accountCreditId], ac.[code] AS [accountCreditCode], ac.[name] AS [accountCreditName],
                    t.[isActive]
                FROM dbo.[TaxConcept] t
                LEFT JOIN dbo.[Account] ad ON t.[accountDebitId] = ad.[id]
                LEFT JOIN dbo.[Account] ac ON t.[accountCreditId] = ac.[id]
                ORDER BY t.[code] ASC
            `);
            return NextResponse.json({ success: true, data: res.recordset || [] });
        }

        const data = await executePostgresQuery('SELECT * FROM public."fnTaxConceptListar"()');
        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        console.error('[API_TAXES_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const {
            id, code, name, type, ratePercentage, minimumBaseAmount,
            accountDebitId, accountCreditId, isActive
        } = body;

        if (!code || !name || !type) {
            return NextResponse.json({ success: false, message: 'Código, Nombre y Tipo de Impuesto son obligatorios.' }, { status: 400 });
        }

        if (isSQLServerMode()) {
            await executeSQLServerProcedure('spTaxConceptGuardar', {
                p_id: id || null,
                p_code: code,
                p_name: name,
                p_type: type,
                p_rate: ratePercentage || 0,
                p_min_base: minimumBaseAmount || 0,
                p_debit_account_id: accountDebitId || null,
                p_credit_account_id: accountCreditId || null,
                p_is_active: isActive !== undefined ? (isActive ? 1 : 0) : 1
            });
        } else {
            await executePostgresQuery(
                'CALL public."spTaxConceptGuardar"($1, $2, $3, $4, $5, $6, $7, $8, $9)',
                [
                    id || null, code, name, type, ratePercentage || 0, minimumBaseAmount || 0,
                    accountDebitId || null, accountCreditId || null, isActive !== undefined ? isActive : true
                ]
            );
        }

        await recordTraceEvent({
            module: 'IMPUESTOS',
            screen: 'Impuestos y Retenciones',
            action: id ? 'UPDATE' : 'INSERT',
            eventType: id ? 'UPDATE' : 'INSERT',
            stepName: id ? 'Impuesto Actualizado' : 'Impuesto Creado',
            affectedId: code,
            inputData: body
        });

        return NextResponse.json({ success: true, message: 'Impuesto o concepto tributario guardado exitosamente.' });
    } catch (err: any) {
        console.error('[API_TAXES_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
