import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            const res = await pool.request().query('SELECT * FROM dbo.[Bank] ORDER BY [name] ASC');
            return NextResponse.json({ success: true, data: res.recordset || [] });
        }

        const data = await executePostgresQuery('SELECT * FROM public."fnBankListar"()');
        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        console.error('[API_BANK_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { id, code, name, nit, phone, contactName, isActive } = body;

        if (!code || !name) {
            return NextResponse.json({ success: false, message: 'Código y Nombre de banco son obligatorios.' }, { status: 400 });
        }

        if (isSQLServerMode()) {
            await executeSQLServerProcedure('spBankGuardar', {
                p_id: id || null,
                p_code: code,
                p_name: name,
                p_nit: nit || null,
                p_phone: phone || null,
                p_contact_name: contactName || null,
                p_is_active: isActive !== undefined ? (isActive ? 1 : 0) : 1
            });
        } else {
            await executePostgresQuery(
                'CALL public."spBankGuardar"($1, $2, $3, $4, $5, $6, $7)',
                [id || null, code, name, nit || null, phone || null, contactName || null, isActive !== undefined ? isActive : true]
            );
        }

        await recordTraceEvent({
            module: 'BANCOS',
            screen: 'Entidades Bancarias',
            action: id ? 'UPDATE' : 'INSERT',
            eventType: id ? 'UPDATE' : 'INSERT',
            stepName: id ? 'Banco Actualizado' : 'Banco Creado',
            affectedId: code,
            inputData: body
        });

        return NextResponse.json({ success: true, message: 'Entidad bancaria guardada exitosamente.' });
    } catch (err: any) {
        console.error('[API_BANK_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
