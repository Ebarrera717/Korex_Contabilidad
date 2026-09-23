import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        const { searchParams } = new URL(req.url);
        const search = searchParams.get('search') || null;
        const levelStr = searchParams.get('level');
        const level = levelStr ? parseInt(levelStr, 10) : null;
        const movementOnly = searchParams.get('movementOnly') === 'true' ? true : null;

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            let query = `
                SELECT 
                    a.[id], a.[code], a.[name], a.[level], a.[nature],
                    a.[allowsMovement], a.[requiresThirdParty], a.[requiresCostCenter],
                    a.[parentId], p.[code] AS [parentCode], p.[name] AS [parentName],
                    a.[isActive]
                FROM dbo.[Account] a
                LEFT JOIN dbo.[Account] p ON a.[parentId] = p.[id]
                WHERE 1=1
            `;
            if (search) query += ` AND (a.[code] LIKE '%${search}%' OR a.[name] LIKE '%${search}%')`;
            if (level !== null) query += ` AND a.[level] = ${level}`;
            if (movementOnly !== null) query += ` AND a.[allowsMovement] = 1`;
            query += ` ORDER BY a.[code] ASC`;

            const res = await pool.request().query(query);
            return NextResponse.json({ success: true, data: res.recordset || [] });
        }

        const data = await executePostgresQuery(
            'SELECT * FROM public."fnPucListar"($1, $2, $3)',
            [search, level, movementOnly]
        );
        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        console.error('[API_PUC_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const {
            id, code, name, level, nature, allowsMovement,
            requiresThirdParty, requiresCostCenter, parentId, isActive
        } = body;

        if (!code || !name || !nature) {
            return NextResponse.json({ success: false, message: 'Código, Nombre y Naturaleza son obligatorios.' }, { status: 400 });
        }

        const calculatedLevel = level || (code.length === 1 ? 1 : code.length === 2 ? 2 : code.length === 4 ? 3 : code.length === 6 ? 4 : 5);

        if (isSQLServerMode()) {
            await executeSQLServerProcedure('spPucGuardar', {
                p_id: id || null,
                p_code: code,
                p_name: name,
                p_level: calculatedLevel,
                p_nature: nature,
                p_allows_movement: allowsMovement ? 1 : 0,
                p_requires_third: requiresThirdParty ? 1 : 0,
                p_requires_cc: requiresCostCenter ? 1 : 0,
                p_parent_id: parentId || null,
                p_is_active: isActive !== undefined ? (isActive ? 1 : 0) : 1
            });
        } else {
            await executePostgresQuery(
                'CALL public."spPucGuardar"($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)',
                [
                    id || null, code, name, calculatedLevel, nature, allowsMovement || false,
                    requiresThirdParty || false, requiresCostCenter || false, parentId || null,
                    isActive !== undefined ? isActive : true
                ]
            );
        }

        await recordTraceEvent({
            module: 'PUC',
            screen: 'Plan de Cuentas',
            action: id ? 'UPDATE' : 'INSERT',
            eventType: id ? 'UPDATE' : 'INSERT',
            stepName: id ? 'Cuenta PUC Actualizada' : 'Cuenta PUC Creada',
            affectedId: code,
            inputData: body
        });

        return NextResponse.json({ success: true, message: 'Cuenta del PUC guardada exitosamente.' });
    } catch (err: any) {
        console.error('[API_PUC_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
