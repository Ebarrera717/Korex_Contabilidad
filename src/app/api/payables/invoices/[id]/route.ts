import { NextRequest, NextResponse } from 'next/server';
import { executeQuery } from '@/lib/postgres';

export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    try {
        const { id } = await params;
        const invoiceId = parseInt(id, 10);

        const invoiceResult = await executeQuery(
            `SELECT p.*, t."fullName" AS "supplierName", t."documentNumber" AS "supplierNit", j."entryNumber" AS "journalNumber"
             FROM public."PayableInvoice" p
             JOIN public."ThirdParty" t ON t.id = p."thirdPartyId"
             LEFT JOIN public."JournalEntry" j ON j.id = p."journalEntryId"
             WHERE p.id = $1`,
            [invoiceId]
        );

        if (!invoiceResult.rows || invoiceResult.rows.length === 0) {
            return NextResponse.json({ success: false, message: 'Factura de compra no encontrada' }, { status: 404 });
        }

        const installmentsResult = await executeQuery(
            `SELECT * FROM public."PayableInstallment" WHERE "payableInvoiceId" = $1 ORDER BY "installmentNumber" ASC`,
            [invoiceId]
        );

        const allocationsResult = await executeQuery(
            `SELECT a.*, m."entryNumber" AS "paymentNumber", adv.concept AS "advanceConcept", cn."noteNumber"
             FROM public."PayablePaymentAllocation" a
             LEFT JOIN public."TreasuryMovement" m ON m.id = a."treasuryMovementId"
             LEFT JOIN public."AdvancePayment" adv ON adv.id = a."advancePaymentId"
             LEFT JOIN public."CreditDebitNote" cn ON cn.id = a."creditDebitNoteId"
             WHERE a."payableInvoiceId" = $1
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
