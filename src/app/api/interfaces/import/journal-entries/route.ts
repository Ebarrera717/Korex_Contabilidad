import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function POST(request: NextRequest) {
    try {
        const body = await request.json();
        const { companyId, entries, autoPost, userId } = body;

        if (!companyId || !entries || !Array.isArray(entries)) {
            return NextResponse.json({
                success: false,
                error: 'Parámetros obligatorios: companyId, entries (array)'
            }, { status: 400 });
        }

        const jobCode = `JOB-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`;
        await executeQuery(
            `INSERT INTO public."BatchImportJob" (
                "jobCode", "companyId", "templateCode", "interfaceType",
                "status", "totalRows", "startedAt", "userId", "createdAt", "updatedAt"
            ) VALUES ($1, $2, $3, $4, 'PROCESSING', $5, CURRENT_TIMESTAMP, $6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
            [jobCode, companyId, 'COMPROBANTES_BATCH', 'COMPROBANTES', entries.length, userId || 1]
        );

        const result = await executeQuery(
            `CALL public."spBatchImportComprobantes"($1, $2::jsonb, $3, $4, NULL, NULL, NULL, NULL)`,
            [companyId, JSON.stringify(entries), autoPost === true, userId || 1]
        );

        const totalRows = result.rows[0]?.p_total_rows || entries.length;
        const successRows = result.rows[0]?.p_success_rows || 0;
        const failedRows = result.rows[0]?.p_failed_rows || 0;
        const errors = result.rows[0]?.p_errors || [];

        const jobStatus = failedRows === 0 ? 'COMPLETED' : (successRows > 0 ? 'COMPLETED_WITH_ERRORS' : 'FAILED');

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
