import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            const res = await pool.request().query('SELECT * FROM dbo.[DocumentType] ORDER BY [id] ASC');
            return NextResponse.json({ success: true, data: res.recordset || [] });
        }

        const data = await executePostgresQuery('SELECT * FROM public."fnDocumentTypeListar"()');
        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        console.error('[API_DOC_TYPES_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { id, code, name, prefix, isAutomatic, isActive } = body;

        if (!code || !name) {
            return NextResponse.json({ success: false, message: 'Código y Nombre de tipo de documento son obligatorios.' }, { status: 400 });
        }

        if (isSQLServerMode()) {
            await executeSQLServerProcedure('spDocumentTypeGuardar', {
                p_id: id || null,
                p_code: code,
                p_name: name,
                p_prefix: prefix || null,
                p_is_automatic: isAutomatic !== undefined ? (isAutomatic ? 1 : 0) : 1,
                p_is_active: isActive !== undefined ? (isActive ? 1 : 0) : 1
            });
        } else {
            await executePostgresQuery(
                'CALL public."spDocumentTypeGuardar"($1, $2, $3, $4, $5, $6)',
                [id || null, code, name, prefix || null, isAutomatic !== undefined ? isAutomatic : true, isActive !== undefined ? isActive : true]
            );
        }

        await recordTraceEvent({
            module: 'DOCUMENTOS',
            screen: 'Tipos de Documento',
            action: id ? 'UPDATE' : 'INSERT',
            eventType: id ? 'UPDATE' : 'INSERT',
            stepName: id ? 'Tipo de Documento Actualizado' : 'Tipo de Documento Creado',
            affectedId: code,
            inputData: body
        });

        return NextResponse.json({ success: true, message: 'Tipo de documento guardado exitosamente.' });
    } catch (err: any) {
        console.error('[API_DOC_TYPES_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
