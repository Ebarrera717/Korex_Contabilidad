import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        const { searchParams } = new URL(req.url);
        const companyIdStr = searchParams.get('companyId');
        const companyId = companyIdStr ? parseInt(companyIdStr, 10) : null;

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            let query = `
                SELECT 
                    c.[id], c.[companyId], c.[code], c.[name], c.[accountId],
                    a.[code] AS [accountCode], a.[name] AS [accountName],
                    c.[responsibleUserId], u.[name] AS [responsibleUserName],
                    c.[currency], c.[maxAmount], c.[isActive]
                FROM dbo.[CashBox] c
                INNER JOIN dbo.[Account] a ON c.[accountId] = a.[id]
                LEFT JOIN dbo.[User] u ON c.[responsibleUserId] = u.[id]
                WHERE 1=1
            `;
            if (companyId) query += ` AND c.[companyId] = ${companyId}`;
            query += ` ORDER BY c.[code] ASC`;

            const res = await pool.request().query(query);
            return NextResponse.json({ success: true, data: res.recordset || [] });
        }

        const data = await executePostgresQuery(
            'SELECT * FROM public."fnCajaListar"($1)',
            [companyId]
        );
        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        console.error('[API_CASH_BOX_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { id, companyId, code, name, accountId, responsibleUserId, currency, maxAmount, isActive } = body;

        if (!companyId || !code || !name || !accountId) {
            return NextResponse.json({ success: false, message: 'Empresa, Código, Nombre y Cuenta PUC son obligatorios.' }, { status: 400 });
        }

        if (isSQLServerMode()) {
            await executeSQLServerProcedure('spCajaGuardar', {
                p_id: id || null,
                p_company_id: companyId,
                p_code: code,
                p_name: name,
                p_account_id: accountId,
                p_responsible_user_id: responsibleUserId || null,
                p_currency: currency || 'COP',
                p_max_amount: maxAmount || 0,
                p_is_active: isActive !== undefined ? (isActive ? 1 : 0) : 1
            });
        } else {
            await executePostgresQuery(
                'CALL public."spCajaGuardar"($1, $2, $3, $4, $5, $6, $7, $8, $9)',
                [id || null, companyId, code, name, accountId, responsibleUserId || null, currency || 'COP', maxAmount || 0, isActive !== undefined ? isActive : true]
            );
        }

        await recordTraceEvent({
            module: 'TESORERIA',
            screen: 'Cajas y Fondos Fijos',
            action: id ? 'UPDATE' : 'INSERT',
            eventType: id ? 'UPDATE' : 'INSERT',
            stepName: id ? 'Caja Actualizada' : 'Caja Creada',
            affectedId: code,
            inputData: body
        });

        return NextResponse.json({ success: true, message: 'Caja guardada exitosamente.' });
    } catch (err: any) {
        console.error('[API_CASH_BOX_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
