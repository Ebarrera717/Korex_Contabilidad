import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        const { searchParams } = new URL(req.url);
        const yearStr = searchParams.get('year');
        const year = yearStr ? parseInt(yearStr, 10) : null;

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            let query = `
                SELECT 
                    c.[id], c.[documentTypeId], d.[code] AS [documentTypeCode], d.[name] AS [documentTypeName],
                    c.[prefix], c.[currentNumber], c.[initialNumber], c.[finalNumber],
                    c.[fiscalYear], c.[isActive]
                FROM dbo.[Consecutive] c
                INNER JOIN dbo.[DocumentType] d ON c.[documentTypeId] = d.[id]
                WHERE 1=1
            `;
            if (year) query += ` AND c.[fiscalYear] = ${year}`;
            query += ` ORDER BY d.[code] ASC, c.[prefix] ASC`;

            const res = await pool.request().query(query);
            return NextResponse.json({ success: true, data: res.recordset || [] });
        }

        const data = await executePostgresQuery(
            'SELECT * FROM public."fnConsecutiveListar"($1)',
            [year]
        );
        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        console.error('[API_CONSECUTIVES_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const {
            id, documentTypeId, prefix, currentNumber, initialNumber,
            finalNumber, fiscalYear, isActive
        } = body;

        if (!documentTypeId || !fiscalYear) {
            return NextResponse.json({ success: false, message: 'Tipo de Documento y Año Fiscal son obligatorios.' }, { status: 400 });
        }

        if (isSQLServerMode()) {
            await executeSQLServerProcedure('spConsecutiveGuardar', {
                p_id: id || null,
                p_doc_type_id: documentTypeId,
                p_prefix: prefix || null,
                p_current_number: currentNumber || 1,
                p_initial_number: initialNumber || 1,
                p_final_number: finalNumber || null,
                p_fiscal_year: fiscalYear,
                p_is_active: isActive !== undefined ? (isActive ? 1 : 0) : 1
            });
        } else {
            await executePostgresQuery(
                'CALL public."spConsecutiveGuardar"($1, $2, $3, $4, $5, $6, $7, $8)',
                [
                    id || null, documentTypeId, prefix || null, currentNumber || 1, initialNumber || 1,
                    finalNumber || null, fiscalYear, isActive !== undefined ? isActive : true
                ]
            );
        }

        await recordTraceEvent({
            module: 'CONSECUTIVOS',
            screen: 'Consecutivos de Documento',
            action: id ? 'UPDATE' : 'INSERT',
            eventType: id ? 'UPDATE' : 'INSERT',
            stepName: id ? 'Consecutivo Actualizado' : 'Consecutivo Creado',
            affectedId: `${documentTypeId}-${fiscalYear}`,
            inputData: body
        });

        return NextResponse.json({ success: true, message: 'Consecutivo guardado exitosamente.' });
    } catch (err: any) {
        console.error('[API_CONSECUTIVES_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
