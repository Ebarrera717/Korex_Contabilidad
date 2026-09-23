import { NextRequest, NextResponse } from 'next/server';
import { executePostgresQuery } from '@/lib/postgres';
import { executeSQLServerProcedure, getSQLServerConnection, isSQLServerMode } from '@/lib/sqlserver';
import { recordTraceEvent } from '@/lib/traceability';

export async function GET(req: NextRequest) {
    try {
        const { searchParams } = new URL(req.url);
        const yearStr = searchParams.get('year');
        const year = yearStr ? parseInt(yearStr, 10) : new Date().getFullYear();

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            const res = await pool.request().query(`
                SELECT 
                    fp.[id], fp.[year], fp.[month], fp.[startDate], fp.[endDate],
                    fp.[status], fp.[closedAt], fp.[closedBy], u.[name] AS [closedByName],
                    COUNT(CASE WHEN j.[status] = 'POSTED' THEN 1 END) AS [postedCount],
                    COUNT(CASE WHEN j.[status] = 'DRAFT' THEN 1 END) AS [draftCount]
                FROM dbo.[FiscalPeriod] fp
                LEFT JOIN dbo.[User] u ON fp.[closedBy] = u.[id]
                LEFT JOIN dbo.[JournalEntry] j ON 
                    YEAR(j.[entryDate]) = fp.[year] AND MONTH(j.[entryDate]) = fp.[month]
                WHERE fp.[year] = ${year}
                GROUP BY fp.[id], fp.[year], fp.[month], fp.[startDate], fp.[endDate], fp.[status], fp.[closedAt], fp.[closedBy], u.[name]
                ORDER BY fp.[year] DESC, fp.[month] ASC
            `);
            return NextResponse.json({ success: true, data: res.recordset || [] });
        }

        const data = await executePostgresQuery(
            'SELECT * FROM public."fnPeriodoListar"($1)',
            [year]
        );
        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        console.error('[API_PERIODS_GET_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { year, month, startDate, endDate, status } = body;

        if (!year || !month) {
            return NextResponse.json({ success: false, message: 'Año y Mes son obligatorios.' }, { status: 400 });
        }

        const sDate = startDate || `${year}-${String(month).padStart(2, '0')}-01T00:00:00Z`;
        const lastDay = new Date(year, month, 0).getDate();
        const eDate = endDate || `${year}-${String(month).padStart(2, '0')}-${lastDay}T23:59:59Z`;

        if (isSQLServerMode()) {
            const pool = await getSQLServerConnection();
            await pool.request()
                .input('year', year)
                .input('month', month)
                .input('startDate', sDate)
                .input('endDate', eDate)
                .input('status', status || 'OPEN')
                .query(`
                    IF EXISTS (SELECT 1 FROM dbo.[FiscalPeriod] WHERE [year] = @year AND [month] = @month)
                        UPDATE dbo.[FiscalPeriod] SET [startDate] = @startDate, [endDate] = @endDate, [status] = @status, [updatedAt] = GETDATE() WHERE [year] = @year AND [month] = @month;
                    ELSE
                        INSERT INTO dbo.[FiscalPeriod] ([year], [month], [startDate], [endDate], [status], [createdAt], [updatedAt])
                        VALUES (@year, @month, @startDate, @endDate, @status, GETDATE(), GETDATE());
                `);
        } else {
            await executePostgresQuery(
                'CALL public."spPeriodoGuardar"($1, $2, $3, $4, $5)',
                [year, month, sDate, eDate, status || 'OPEN']
            );
        }

        await recordTraceEvent({
            module: 'PERIODOS',
            screen: 'Períodos Fiscales',
            action: 'GUARDAR',
            eventType: 'UPDATE',
            stepName: `Período Fiscal ${year}-${month} Guardado`,
            affectedId: `${year}-${month}`,
            inputData: body
        });

        return NextResponse.json({ success: true, message: 'Período fiscal guardado exitosamente.' });
    } catch (err: any) {
        console.error('[API_PERIODS_POST_ERROR]', err);
        return NextResponse.json({ success: false, message: err.message }, { status: 500 });
    }
}
