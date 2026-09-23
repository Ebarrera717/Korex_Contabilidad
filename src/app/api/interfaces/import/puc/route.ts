import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { mapRowToSchema } from '@/lib/excel-importer';

export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const { companyId, accounts, mapping, userId } = body;

        if (!companyId || !accounts || !Array.isArray(accounts)) {
            return NextResponse.json({
                success: false,
                error: 'Parámetros obligatorios: companyId, accounts (array)'
            }, { status: 400 });
        }

        // Aplicar mapeo de columnas si viene configurado
        const normalizedAccounts = mapping ? accounts.map(row => mapRowToSchema(row, mapping)) : accounts;

        // Registrar Job en BatchImportJob
        const jobCode = `JOB-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`;
        await executeQuery(
            `INSERT INTO public."BatchImportJob" (
                "jobCode", "companyId", "templateCode", "interfaceType",
                "status", "totalRows", "startedAt", "userId", "createdAt", "updatedAt"
            ) VALUES ($1, $2, $3, $4, 'PROCESSING', $5, CURRENT_TIMESTAMP, $6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
            [jobCode, companyId, 'PUC_BATCH', 'PUC', normalizedAccounts.length, userId || 1]
        );

        // Invocar Stored Procedure
        const result = await executeQuery(
            `CALL public."spBatchImportPuc"($1, $2::jsonb, $3, NULL, NULL, NULL, NULL)`,
            [companyId, JSON.stringify(normalizedAccounts), userId || 1]
        );

        const totalRows = result.rows[0]?.p_total_rows || normalizedAccounts.length;
        const successRows = result.rows[0]?.p_success_rows || 0;
        const failedRows = result.rows[0]?.p_failed_rows || 0;
        const errors = result.rows[0]?.p_errors || [];

        const jobStatus = failedRows === 0 ? 'COMPLETED' : (successRows > 0 ? 'COMPLETED_WITH_ERRORS' : 'FAILED');

        // Actualizar Job
        await executeQuery(
            `UPDATE public."BatchImportJob" SET
                "status" = $1,
                "processedRows" = $2,
                "successRows" = $3,
                "failedRows" = $4,
                "errorsSummary" = $5::jsonb,
                "completedAt" = CURRENT_TIMESTAMP,
                "updatedAt" = CURRENT_TIMESTAMP
            WHERE "jobCode" = $6`,
            [jobStatus, totalRows, successRows, failedRows, JSON.stringify(errors), jobCode]
        );

        return NextResponse.json({
            success: failedRows === 0,
            jobCode,
            totalRows,
            successRows,
            failedRows,
            errors
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}
