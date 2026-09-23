import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';
import { logTraceability } from '@/lib/traceability';

export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        const companyId = parseInt(searchParams.get('companyId') || '1', 10);
        const thirdPartyId = searchParams.get('thirdPartyId') ? parseInt(searchParams.get('thirdPartyId')!, 10) : null;
        const status = searchParams.get('status') || null;

        const result = await executeQuery(
            'SELECT * FROM public."fnFacturasCompraListar"($1, $2, $3)',
            [companyId, thirdPartyId, status]
        );

        return NextResponse.json({ success: true, data: result.rows || result });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}

export async function POST(request: NextRequest) {
    const startTime = Date.now();
    try {
        const body = await request.json();
        const {
            companyId = 1,
            thirdPartyId,
            documentTypeId = 7, // FC
            invoiceNumber,
            issueDate = new Date().toISOString(),
            paymentTermDays = 0,
            subtotal,
            taxAmount = 0,
            retentionAmount = 0,
            accountExpenseId,
            accountPayableId,
            accountTaxId = null,
            costCenterId = null,
            createdById = 1,
            observations = '',
            installmentsCount = 1
        } = body;

        if (!thirdPartyId || !invoiceNumber || !subtotal || !accountExpenseId || !accountPayableId) {
            return NextResponse.json({
                success: false,
                message: 'Faltan campos obligatorios: thirdPartyId, invoiceNumber, subtotal, accountExpenseId, accountPayableId'
            }, { status: 400 });
        }

        const result = await executeQuery(
            `CALL public."spFacturaCompraCrear"($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, NULL, NULL, NULL)`,
            [
                companyId, thirdPartyId, documentTypeId, invoiceNumber, issueDate, paymentTermDays,
                subtotal, taxAmount, retentionAmount, accountExpenseId, accountPayableId,
                accountTaxId, costCenterId, createdById, observations, installmentsCount
            ]
        );

        const out = result.rows ? result.rows[0] : result;

        await logTraceability({
            code: `TRC-FC-${Date.now()}`,
            module: 'PROVEEDORES',
            action: 'CAUSAR_FACTURA_COMPRA',
            eventType: 'TRANSACCIONAL',
            stepName: 'spFacturaCompraCrear',
            spName: 'spFacturaCompraCrear',
            endpoint: '/api/payables/invoices',
            durationMs: Date.now() - startTime,
            status: 'SUCCESS',
            inputData: body,
            outputData: out
        });

        return NextResponse.json({
            success: true,
            message: 'Factura de compra causada y contabilizada correctamente',
            data: out
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
