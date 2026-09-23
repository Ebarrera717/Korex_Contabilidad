import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    try {
        const { id } = await params;
        const invoiceId = parseInt(id, 10);

        const invoiceResult = await executeQuery(
            `SELECT r.*, t."fullName" AS "customerName", t."documentNumber" AS "customerNit", j."entryNumber" AS "journalNumber"
             FROM public."ReceivableInvoice" r
             JOIN public."ThirdParty" t ON t.id = r."thirdPartyId"
             LEFT JOIN public."JournalEntry" j ON j.id = r."journalEntryId"
             WHERE r.id = $1`,
            [invoiceId]
        );

        if (!invoiceResult.rows || invoiceResult.rows.length === 0) {
            return NextResponse.json({ success: false, message: 'Factura no encontrada' }, { status: 404 });
        }

        const installmentsResult = await executeQuery(
            `SELECT * FROM public."ReceivableInstallment" WHERE "receivableInvoiceId" = $1 ORDER BY "installmentNumber" ASC`,
            [invoiceId]
        );

        const allocationsResult = await executeQuery(
            `SELECT a.*, m."entryNumber" AS "receiptNumber", adv.concept AS "advanceConcept", cn."noteNumber"
             FROM public."ReceivablePaymentAllocation" a
             LEFT JOIN public."TreasuryMovement" m ON m.id = a."treasuryMovementId"
             LEFT JOIN public."AdvancePayment" adv ON adv.id = a."advancePaymentId"
             LEFT JOIN public."CreditDebitNote" cn ON cn.id = a."creditDebitNoteId"
             WHERE a."receivableInvoiceId" = $1
             ORDER BY a."allocationDate" DESC`,
            [invoiceId]
        );

        return NextResponse.json({
            success: true,
            data: {
                ...invoiceResult.rows[0],
                installments: installmentsResult.rows || [],
                allocations: allocationsResult.rows || []
            }
        });
    } catch (error: any) {
        return NextResponse.json({ success: false, message: error.message }, { status: 500 });
    }
}
