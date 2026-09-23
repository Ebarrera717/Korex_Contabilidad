import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        const { searchParams } = new URL(req.url);
        const companyIdStr = searchParams.get('companyId');
        const companyId = companyIdStr ? parseInt(companyIdStr, 10) : null;
        const docTypeIdStr = searchParams.get('documentTypeId');
        const docTypeId = docTypeIdStr ? parseInt(docTypeIdStr, 10) : null;
        const startDate = searchParams.get('startDate') || null;
        const endDate = searchParams.get('endDate') || null;
        const status = searchParams.get('status') || null;
        const search = searchParams.get('search') || null;

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            let query = `
                SELECT 
                    j.[id], j.[companyId], c.[businessName] AS [companyName],
                    j.[documentTypeId], d.[code] AS [documentTypeCode], d.[name] AS [documentTypeName],
                    j.[consecutiveNumber], j.[entryNumber], j.[entryDate],
                    j.[thirdPartyId], t.[documentNumber] AS [thirdPartyDoc], t.[fullName] AS [thirdPartyName],
                    j.[concept], j.[observation], j.[totalDebit], j.[totalCredit],
                    j.[status], j.[createdById], u.[name] AS [createdByName],
                    j.[postedAt], j.[annulledAt], j.[createdAt]
                FROM dbo.[JournalEntry] j
                INNER JOIN dbo.[Company] c ON j.[companyId] = c.[id]
                INNER JOIN dbo.[DocumentType] d ON j.[documentTypeId] = d.[id]
                LEFT JOIN dbo.[ThirdParty] t ON j.[thirdPartyId] = t.[id]
                LEFT JOIN dbo.[User] u ON j.[createdById] = u.[id]
                WHERE 1=1
            `;
            if (companyId) query += ` AND j.[companyId] = ${companyId}`;
            if (docTypeId) query += ` AND j.[documentTypeId] = ${docTypeId}`;
            if (startDate) query += ` AND j.[entryDate] >= '${startDate}'`;
            if (endDate) query += ` AND j.[entryDate] <= '${endDate}'`;
            if (status) query += ` AND j.[status] = '${status}'`;
            if (search) query += ` AND (j.[entryNumber] LIKE '%${search}%' OR j.[concept] LIKE '%${search}%' OR t.[fullName] LIKE '%${search}%')`;
            query += ` ORDER BY j.[entryDate] DESC, j.[id] DESC`;

            const res = await pool.request().query(query);
            return NextResponse.json({ success: true, data: res.recordset || [] });
        }

        const data = await executePostgresQuery(
            'SELECT * FROM public."fnComprobanteListar"($1, $2, $3, $4, $5, $6)',
            [companyId, docTypeId, startDate, endDate, status, search]
        );
        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        console.error('[API_JOURNAL_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const {
            id, companyId, documentTypeId, entryNumber, entryDate,
            thirdPartyId, concept, observation, items, userId
        } = body;

        if (!companyId || !documentTypeId || !entryDate || !concept) {
            return NextResponse.json({ success: false, message: 'Empresa, Tipo de Documento, Fecha y Concepto son obligatorios.' }, { status: 400 });
        }

        let createdId: number | null = null;

        if (isSQLServerMode()) {
            const res = await executeSQLServerProcedure('spComprobanteGuardar', {
                p_id: id || null,
                p_company_id: companyId,
                p_document_type_id: documentTypeId,
                p_entry_number: entryNumber || null,
                p_entry_date: entryDate,
                p_third_party_id: thirdPartyId || null,
                p_concept: concept,
                p_observation: observation || null,
                p_items: items ? JSON.stringify(items) : null,
                p_user_id: userId || 1
            });
            createdId = res?.[0]?.p_created_id || id;
        } else {
            const res = await executePostgresQuery(
                'CALL public."spComprobanteGuardar"($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb, $10, $11)',
                [
                    id || null, companyId, documentTypeId, entryNumber || null, entryDate,
                    thirdPartyId || null, concept, observation || null,
                    items ? JSON.stringify(items) : '[]', userId || 1, null
                ]
            );
            createdId = res?.[0]?.p_created_id || id;
        }

        await recordTraceEvent({
            module: 'CONTABILIDAD',
            screen: 'Comprobantes',
            action: id ? 'UPDATE' : 'INSERT',
            eventType: id ? 'UPDATE' : 'INSERT',
            stepName: id ? 'Comprobante Actualizado' : 'Comprobante Creado (Borrador)',
            affectedId: String(createdId),
            inputData: body
        });

        return NextResponse.json({ success: true, message: 'Comprobante guardado exitosamente.', id: createdId });
    } catch (err: any) {
        console.error('[API_JOURNAL_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
