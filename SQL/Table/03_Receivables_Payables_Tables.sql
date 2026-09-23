-- ============================================================================
-- KOREX_CONTABILIDAD - TABLAS DDL PARA CARTERA Y PROVEEDORES (FASE 5)
-- MOTOR: PostgreSQL
-- ============================================================================

CREATE TABLE IF NOT EXISTS public."ReceivableInvoice" (
    id SERIAL PRIMARY KEY,
    "companyId" INTEGER NOT NULL REFERENCES public."Company"(id),
    "thirdPartyId" INTEGER NOT NULL REFERENCES public."ThirdParty"(id),
    "documentTypeId" INTEGER NOT NULL REFERENCES public."DocumentType"(id),
    "consecutiveNumber" INTEGER NOT NULL,
    "invoiceNumber" VARCHAR(50) NOT NULL,
    "issueDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    "dueDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    "paymentTermDays" INTEGER NOT NULL DEFAULT 0,
    subtotal NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "taxAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "retentionAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "totalAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "paidAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "balanceAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'POSTED',
    "journalEntryId" INTEGER REFERENCES public."JournalEntry"(id),
    "createdById" INTEGER NOT NULL REFERENCES public."User"(id),
    observations TEXT,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ReceivableInvoice_doc_num_key" UNIQUE ("documentTypeId", "invoiceNumber")
);

CREATE INDEX IF NOT EXISTS "ReceivableInvoice_thirdPartyId_idx" ON public."ReceivableInvoice"("thirdPartyId");
CREATE INDEX IF NOT EXISTS "ReceivableInvoice_issueDate_idx" ON public."ReceivableInvoice"("issueDate");
CREATE INDEX IF NOT EXISTS "ReceivableInvoice_dueDate_idx" ON public."ReceivableInvoice"("dueDate");
CREATE INDEX IF NOT EXISTS "ReceivableInvoice_status_idx" ON public."ReceivableInvoice"(status);

CREATE TABLE IF NOT EXISTS public."ReceivableInstallment" (
    id SERIAL PRIMARY KEY,
    "receivableInvoiceId" INTEGER NOT NULL REFERENCES public."ReceivableInvoice"(id) ON DELETE CASCADE,
    "installmentNumber" INTEGER NOT NULL DEFAULT 1,
    "dueDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "paidAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "balanceAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "ReceivableInstallment_invoice_idx" ON public."ReceivableInstallment"("receivableInvoiceId");
CREATE INDEX IF NOT EXISTS "ReceivableInstallment_dueDate_idx" ON public."ReceivableInstallment"("dueDate");
CREATE INDEX IF NOT EXISTS "ReceivableInstallment_status_idx" ON public."ReceivableInstallment"(status);

CREATE TABLE IF NOT EXISTS public."PayableInvoice" (
    id SERIAL PRIMARY KEY,
    "companyId" INTEGER NOT NULL REFERENCES public."Company"(id),
    "thirdPartyId" INTEGER NOT NULL REFERENCES public."ThirdParty"(id),
    "documentTypeId" INTEGER NOT NULL REFERENCES public."DocumentType"(id),
    "consecutiveNumber" INTEGER NOT NULL,
    "invoiceNumber" VARCHAR(50) NOT NULL,
    "internalNumber" VARCHAR(50) NOT NULL,
    "issueDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    "dueDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    "paymentTermDays" INTEGER NOT NULL DEFAULT 0,
    subtotal NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "taxAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "retentionAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "totalAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "paidAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "balanceAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'POSTED',
    "journalEntryId" INTEGER REFERENCES public."JournalEntry"(id),
    "createdById" INTEGER NOT NULL REFERENCES public."User"(id),
    observations TEXT,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PayableInvoice_doc_num_key" UNIQUE ("documentTypeId", "internalNumber")
);

CREATE INDEX IF NOT EXISTS "PayableInvoice_thirdPartyId_idx" ON public."PayableInvoice"("thirdPartyId");
CREATE INDEX IF NOT EXISTS "PayableInvoice_issueDate_idx" ON public."PayableInvoice"("issueDate");
CREATE INDEX IF NOT EXISTS "PayableInvoice_dueDate_idx" ON public."PayableInvoice"("dueDate");
CREATE INDEX IF NOT EXISTS "PayableInvoice_status_idx" ON public."PayableInvoice"(status);

CREATE TABLE IF NOT EXISTS public."PayableInstallment" (
    id SERIAL PRIMARY KEY,
    "payableInvoiceId" INTEGER NOT NULL REFERENCES public."PayableInvoice"(id) ON DELETE CASCADE,
    "installmentNumber" INTEGER NOT NULL DEFAULT 1,
    "dueDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "paidAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "balanceAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "PayableInstallment_invoice_idx" ON public."PayableInstallment"("payableInvoiceId");
CREATE INDEX IF NOT EXISTS "PayableInstallment_dueDate_idx" ON public."PayableInstallment"("dueDate");
CREATE INDEX IF NOT EXISTS "PayableInstallment_status_idx" ON public."PayableInstallment"(status);

CREATE TABLE IF NOT EXISTS public."CreditDebitNote" (
    id SERIAL PRIMARY KEY,
    "companyId" INTEGER NOT NULL REFERENCES public."Company"(id),
    "noteType" VARCHAR(30) NOT NULL,
    "documentTypeId" INTEGER NOT NULL REFERENCES public."DocumentType"(id),
    "consecutiveNumber" INTEGER NOT NULL,
    "noteNumber" VARCHAR(50) NOT NULL,
    "noteDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    "thirdPartyId" INTEGER NOT NULL REFERENCES public."ThirdParty"(id),
    "receivableInvoiceId" INTEGER REFERENCES public."ReceivableInvoice"(id),
    "payableInvoiceId" INTEGER REFERENCES public."PayableInvoice"(id),
    concept TEXT NOT NULL,
    subtotal NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "taxAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "totalAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "appliedAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "balanceAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'POSTED',
    "journalEntryId" INTEGER REFERENCES public."JournalEntry"(id),
    "createdById" INTEGER NOT NULL REFERENCES public."User"(id),
    observations TEXT,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "CreditDebitNote_doc_num_key" UNIQUE ("documentTypeId", "noteNumber")
);

CREATE INDEX IF NOT EXISTS "CreditDebitNote_noteType_idx" ON public."CreditDebitNote"("noteType");
CREATE INDEX IF NOT EXISTS "CreditDebitNote_thirdPartyId_idx" ON public."CreditDebitNote"("thirdPartyId");
CREATE INDEX IF NOT EXISTS "CreditDebitNote_noteDate_idx" ON public."CreditDebitNote"("noteDate");

CREATE TABLE IF NOT EXISTS public."AdvancePayment" (
    id SERIAL PRIMARY KEY,
    "companyId" INTEGER NOT NULL REFERENCES public."Company"(id),
    "advanceType" VARCHAR(20) NOT NULL,
    "thirdPartyId" INTEGER NOT NULL REFERENCES public."ThirdParty"(id),
    "treasuryMovementId" INTEGER REFERENCES public."TreasuryMovement"(id),
    "advanceDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "usedAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "balanceAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    concept TEXT NOT NULL,
    "createdById" INTEGER NOT NULL REFERENCES public."User"(id),
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "AdvancePayment_advanceType_idx" ON public."AdvancePayment"("advanceType");
CREATE INDEX IF NOT EXISTS "AdvancePayment_thirdPartyId_idx" ON public."AdvancePayment"("thirdPartyId");

CREATE TABLE IF NOT EXISTS public."ReceivablePaymentAllocation" (
    id SERIAL PRIMARY KEY,
    "receivableInvoiceId" INTEGER NOT NULL REFERENCES public."ReceivableInvoice"(id),
    "receivableInstallmentId" INTEGER REFERENCES public."ReceivableInstallment"(id),
    "treasuryMovementId" INTEGER REFERENCES public."TreasuryMovement"(id),
    "advancePaymentId" INTEGER REFERENCES public."AdvancePayment"(id),
    "creditDebitNoteId" INTEGER REFERENCES public."CreditDebitNote"(id),
    "allocationDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "discountAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "withholdingAdjustment" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    observations TEXT,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "ReceivablePaymentAllocation_inv_idx" ON public."ReceivablePaymentAllocation"("receivableInvoiceId");
CREATE INDEX IF NOT EXISTS "ReceivablePaymentAllocation_mov_idx" ON public."ReceivablePaymentAllocation"("treasuryMovementId");

CREATE TABLE IF NOT EXISTS public."PayablePaymentAllocation" (
    id SERIAL PRIMARY KEY,
    "payableInvoiceId" INTEGER NOT NULL REFERENCES public."PayableInvoice"(id),
    "payableInstallmentId" INTEGER REFERENCES public."PayableInstallment"(id),
    "treasuryMovementId" INTEGER REFERENCES public."TreasuryMovement"(id),
    "advancePaymentId" INTEGER REFERENCES public."AdvancePayment"(id),
    "creditDebitNoteId" INTEGER REFERENCES public."CreditDebitNote"(id),
    "allocationDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "discountAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    observations TEXT,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "PayablePaymentAllocation_inv_idx" ON public."PayablePaymentAllocation"("payableInvoiceId");
CREATE INDEX IF NOT EXISTS "PayablePaymentAllocation_mov_idx" ON public."PayablePaymentAllocation"("treasuryMovementId");
