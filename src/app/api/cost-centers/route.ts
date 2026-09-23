import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            const res = await pool.request().query(`
                SELECT cc.[id], cc.[code], cc.[name], cc.[level], cc.[parentId], p.[name] AS [parentName], cc.[isActive]
                FROM dbo.[CostCenter] cc
                LEFT JOIN dbo.[CostCenter] p ON cc.[parentId] = p.[id]
                ORDER BY cc.[code] ASC
            `);
            return NextResponse.json({ success: true, data: res.recordset || [] });
        }

        const data = await executePostgresQuery('SELECT * FROM public."fnCostCenterListar"()');
        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        console.error('[API_COST_CENTER_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { id, code, name, level, parentId, isActive } = body;

        if (!code || !name) {
            return NextResponse.json({ success: false, message: 'Código y Nombre son obligatorios.' }, { status: 400 });
        }

        if (isSQLServerMode()) {
            await executeSQLServerProcedure('spCostCenterGuardar', {
                p_id: id || null,
                p_code: code,
                p_name: name,
                p_level: level || 1,
                p_parent_id: parentId || null,
                p_is_active: isActive !== undefined ? (isActive ? 1 : 0) : 1
            });
        } else {
            await executePostgresQuery(
                'CALL public."spCostCenterGuardar"($1, $2, $3, $4, $5, $6)',
                [id || null, code, name, level || 1, parentId || null, isActive !== undefined ? isActive : true]
            );
        }

        await recordTraceEvent({
            module: 'CENTROS_COSTO',
            screen: 'Centros de Costo',
            action: id ? 'UPDATE' : 'INSERT',
            eventType: id ? 'UPDATE' : 'INSERT',
            stepName: id ? 'Centro de Costo Actualizado' : 'Centro de Costo Creado',
            affectedId: code,
            inputData: body
        });

        return NextResponse.json({ success: true, message: 'Centro de costo guardado exitosamente.' });
    } catch (err: any) {
        console.error('[API_COST_CENTER_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
