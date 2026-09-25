-- ============================================================================
-- KOREX_CONTABILIDAD - SCRIPT CONSOLIDADO DE ACTUALIZACION (POSTGRESQL)
-- GENERADO AUTOMATICAMENTE: 2026-09-25T11:03:35.186Z
-- ============================================================================

-- --- TABLA: 01_Accounting_Masters_Tables.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - DDL DE TABLAS MAESTRAS (POSTGRESQL)
-- Archivo: SQL/Table/01_Accounting_Masters_Tables.sql
-- ============================================================================

CREATE TABLE IF NOT EXISTS public."Company" (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    "businessName" VARCHAR(255) NOT NULL,
    "tradeName" VARCHAR(255),
    "documentType" VARCHAR(20) NOT NULL DEFAULT 'NIT',
    "documentNumber" VARCHAR(50) NOT NULL UNIQUE,
    "verificationDigit" VARCHAR(2),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) NOT NULL DEFAULT 'Colombia',
    phone VARCHAR(50),
    email VARCHAR(150),
    "legalRepresentative" VARCHAR(255),
    "taxRegime" VARCHAR(100),
    "fiscalResponsibilities" VARCHAR(255),
    "economicActivityCode" VARCHAR(20),
    logo BYTEA,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."Role" (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255),
    permissions JSONB,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."User" (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    "passwordHash" VARCHAR(255) NOT NULL,
    "roleId" INTEGER NOT NULL REFERENCES public."Role"(id),
    "companyId" INTEGER REFERENCES public."Company"(id),
    "resetPasswordToken" VARCHAR(255) UNIQUE,
    "resetPasswordExpires" TIMESTAMP(3),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."Account" (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    level INTEGER NOT NULL,
    nature VARCHAR(10) NOT NULL, -- 'DEBIT' o 'CREDIT'
    "allowsMovement" BOOLEAN NOT NULL DEFAULT false,
    "requiresThirdParty" BOOLEAN NOT NULL DEFAULT false,
    "requiresCostCenter" BOOLEAN NOT NULL DEFAULT false,
    "parentId" INTEGER REFERENCES public."Account"(id),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "idx_account_code" ON public."Account"(code);
CREATE INDEX IF NOT EXISTS "idx_account_level" ON public."Account"(level);
CREATE INDEX IF NOT EXISTS "idx_account_parent" ON public."Account"("parentId");

CREATE TABLE IF NOT EXISTS public."ThirdParty" (
    id SERIAL PRIMARY KEY,
    "documentType" VARCHAR(20) NOT NULL DEFAULT 'NIT',
    "documentNumber" VARCHAR(50) NOT NULL UNIQUE,
    "verificationDigit" VARCHAR(2),
    "businessName" VARCHAR(255),
    "firstName" VARCHAR(100),
    "secondName" VARCHAR(100),
    "firstLastName" VARCHAR(100),
    "secondLastName" VARCHAR(100),
    "fullName" VARCHAR(255) NOT NULL,
    "personType" VARCHAR(20) NOT NULL DEFAULT 'JURIDICA',
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) NOT NULL DEFAULT 'Colombia',
    phone VARCHAR(50),
    email VARCHAR(150),
    "isCustomer" BOOLEAN NOT NULL DEFAULT false,
    "isSupplier" BOOLEAN NOT NULL DEFAULT false,
    "isEmployee" BOOLEAN NOT NULL DEFAULT false,
    "isPartner" BOOLEAN NOT NULL DEFAULT false,
    "isOther" BOOLEAN NOT NULL DEFAULT false,
    "taxRegime" VARCHAR(100),
    "fiscalResponsibilities" VARCHAR(255),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "idx_thirdparty_document" ON public."ThirdParty"("documentNumber");
CREATE INDEX IF NOT EXISTS "idx_thirdparty_fullname" ON public."ThirdParty"("fullName");

CREATE TABLE IF NOT EXISTS public."CostCenter" (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    level INTEGER NOT NULL DEFAULT 1,
    "parentId" INTEGER REFERENCES public."CostCenter"(id),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "idx_costcenter_code" ON public."CostCenter"(code);

CREATE TABLE IF NOT EXISTS public."Bank" (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    nit VARCHAR(50),
    phone VARCHAR(50),
    "contactName" VARCHAR(150),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."BankAccount" (
    id SERIAL PRIMARY KEY,
    "companyId" INTEGER NOT NULL REFERENCES public."Company"(id),
    "bankId" INTEGER NOT NULL REFERENCES public."Bank"(id),
    "accountId" INTEGER NOT NULL REFERENCES public."Account"(id),
    "accountNumber" VARCHAR(50) NOT NULL,
    "accountType" VARCHAR(30) NOT NULL DEFAULT 'AHORROS',
    currency VARCHAR(10) NOT NULL DEFAULT 'COP',
    description VARCHAR(255),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "uq_bank_account" UNIQUE ("bankId", "accountNumber")
);

CREATE TABLE IF NOT EXISTS public."DocumentType" (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    prefix VARCHAR(10),
    "isAutomatic" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."Consecutive" (
    id SERIAL PRIMARY KEY,
    "documentTypeId" INTEGER NOT NULL REFERENCES public."DocumentType"(id),
    prefix VARCHAR(10),
    "currentNumber" INTEGER NOT NULL DEFAULT 1,
    "initialNumber" INTEGER NOT NULL DEFAULT 1,
    "finalNumber" INTEGER,
    "fiscalYear" INTEGER NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "uq_consecutive_doc_year" UNIQUE ("documentTypeId", "fiscalYear", prefix)
);

CREATE TABLE IF NOT EXISTS public."FiscalPeriod" (
    id SERIAL PRIMARY KEY,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    "startDate" TIMESTAMP(3) NOT NULL,
    "endDate" TIMESTAMP(3) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    "closedAt" TIMESTAMP(3),
    "closedBy" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "uq_fiscal_period" UNIQUE (year, month)
);

CREATE TABLE IF NOT EXISTS public."TaxConcept" (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    type VARCHAR(30) NOT NULL,
    "ratePercentage" NUMERIC(6, 4) NOT NULL,
    "minimumBaseAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "accountDebitId" INTEGER REFERENCES public."Account"(id),
    "accountCreditId" INTEGER REFERENCES public."Account"(id),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."SystemParameter" (
    id SERIAL PRIMARY KEY,
    code VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    value TEXT,
    description VARCHAR(255),
    category VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
    "isEditable" BOOLEAN NOT NULL DEFAULT true,
    "isEncrypted" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."SystemLog" (
    id SERIAL PRIMARY KEY,
    "userId" INTEGER REFERENCES public."User"(id),
    module VARCHAR(100) NOT NULL,
    action VARCHAR(100) NOT NULL,
    "recordId" VARCHAR(100),
    "previousValue" JSONB,
    "newValue" JSONB,
    status VARCHAR(50) NOT NULL DEFAULT 'SUCCESS',
    "ipAddress" VARCHAR(50),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."TraceabilityLog" (
    id SERIAL PRIMARY KEY,
    code VARCHAR(100) NOT NULL,
    "userId" INTEGER,
    origin VARCHAR(50) NOT NULL DEFAULT 'WEB',
    module VARCHAR(100) NOT NULL,
    screen VARCHAR(100),
    action VARCHAR(100) NOT NULL,
    process VARCHAR(150),
    "eventType" VARCHAR(50) NOT NULL,
    "stepName" VARCHAR(150) NOT NULL,
    "spName" VARCHAR(150),
    endpoint VARCHAR(255),
    "durationMs" INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'SUCCESS',
    "inputData" JSONB,
    "outputData" JSONB,
    "techMessage" TEXT,
    "functionalMessage" TEXT,
    "stackTrace" TEXT,
    "affectedId" VARCHAR(100),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "idx_traceability_code" ON public."TraceabilityLog"(code);
CREATE INDEX IF NOT EXISTS "idx_traceability_module" ON public."TraceabilityLog"(module);

CREATE TABLE IF NOT EXISTS public."Master" (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."Menu" (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    action VARCHAR(255) NOT NULL,
    icon VARCHAR(50),
    "orderIndex" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."JournalEntry" (
    id SERIAL PRIMARY KEY,
    "companyId" INTEGER NOT NULL REFERENCES public."Company"(id),
    "documentTypeId" INTEGER NOT NULL REFERENCES public."DocumentType"(id),
    "consecutiveNumber" INTEGER NOT NULL DEFAULT 1,
    consecutive INTEGER NOT NULL DEFAULT 1,
    "entryNumber" VARCHAR(50),
    "entryDate" TIMESTAMP(3) NOT NULL,
    "thirdPartyId" INTEGER REFERENCES public."ThirdParty"(id),
    concept VARCHAR(255) NOT NULL,
    observation TEXT,
    "totalDebit" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "totalCredit" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    "createdById" INTEGER NOT NULL,
    "postedAt" TIMESTAMP(3),
    "annulledAt" TIMESTAMP(3),
    "annulmentReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "idx_journal_entry_date" ON public."JournalEntry"("entryDate");
CREATE INDEX IF NOT EXISTS "idx_journal_entry_status" ON public."JournalEntry"(status);
CREATE INDEX IF NOT EXISTS "idx_journal_entry_doc" ON public."JournalEntry"("documentTypeId", "consecutiveNumber");

CREATE TABLE IF NOT EXISTS public."JournalEntryLine" (
    id SERIAL PRIMARY KEY,
    "journalEntryId" INTEGER NOT NULL REFERENCES public."JournalEntry"(id) ON DELETE CASCADE,
    "lineNumber" INTEGER NOT NULL DEFAULT 1,
    "accountId" INTEGER NOT NULL,
    "thirdPartyId" INTEGER REFERENCES public."ThirdParty"(id),
    "costCenterId" INTEGER REFERENCES public."CostCenter"(id),
    debit NUMERIC(18, 4) NOT NULL DEFAULT 0,
    credit NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "baseAmount" NUMERIC(18, 4) DEFAULT 0,
    description VARCHAR(255),
    "documentReference" VARCHAR(100),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "idx_journal_line_entry" ON public."JournalEntryLine"("journalEntryId");
CREATE INDEX IF NOT EXISTS "idx_journal_line_account" ON public."JournalEntryLine"("accountId");
CREATE INDEX IF NOT EXISTS "idx_journal_line_third" ON public."JournalEntryLine"("thirdPartyId");

CREATE TABLE IF NOT EXISTS public."JournalEntryItem" (
    id SERIAL PRIMARY KEY,
    "journalEntryId" INTEGER NOT NULL REFERENCES public."JournalEntry"(id) ON DELETE CASCADE,
    "accountId" INTEGER NOT NULL,
    "thirdPartyId" INTEGER REFERENCES public."ThirdParty"(id),
    "costCenterId" INTEGER REFERENCES public."CostCenter"(id),
    debit NUMERIC(18, 4) NOT NULL DEFAULT 0,
    credit NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "baseAmount" NUMERIC(18, 4) DEFAULT 0,
    description VARCHAR(255),
    "documentReference" VARCHAR(100),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);



-- --- TABLA: 02_Treasury_Tables.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - DDL DE TABLAS DE TESORERÍA (POSTGRESQL)
-- Archivo: SQL/Table/02_Treasury_Tables.sql
-- ============================================================================

CREATE TABLE IF NOT EXISTS public."CashBox" (
    id SERIAL PRIMARY KEY,
    "companyId" INTEGER NOT NULL REFERENCES public."Company"(id),
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    "accountId" INTEGER NOT NULL REFERENCES public."Account"(id),
    "responsibleUserId" INTEGER REFERENCES public."User"(id),
    currency VARCHAR(10) NOT NULL DEFAULT 'COP',
    "maxAmount" NUMERIC(18, 4) DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."TreasuryMovement" (
    id SERIAL PRIMARY KEY,
    "companyId" INTEGER NOT NULL REFERENCES public."Company"(id),
    "movementType" VARCHAR(30) NOT NULL, -- 'INGRESO', 'EGRESO', 'TRANSFERENCIA'
    "documentTypeId" INTEGER NOT NULL REFERENCES public."DocumentType"(id),
    "consecutiveNumber" INTEGER NOT NULL,
    "entryNumber" VARCHAR(50) NOT NULL,
    "movementDate" TIMESTAMP(3) NOT NULL,
    "bankAccountId" INTEGER REFERENCES public."BankAccount"(id),
    "cashBoxId" INTEGER REFERENCES public."CashBox"(id),
    "targetBankAccountId" INTEGER REFERENCES public."BankAccount"(id),
    "targetCashBoxId" INTEGER REFERENCES public."CashBox"(id),
    "thirdPartyId" INTEGER REFERENCES public."ThirdParty"(id),
    concept VARCHAR(255) NOT NULL,
    "paymentMethod" VARCHAR(50) NOT NULL DEFAULT 'TRANSFERENCIA',
    "checkNumber" VARCHAR(50),
    "totalAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'POSTED',
    "journalEntryId" INTEGER REFERENCES public."JournalEntry"(id),
    "createdById" INTEGER NOT NULL REFERENCES public."User"(id),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "idx_treasury_date" ON public."TreasuryMovement"("movementDate");
CREATE INDEX IF NOT EXISTS "idx_treasury_type" ON public."TreasuryMovement"("movementType");

CREATE TABLE IF NOT EXISTS public."BankReconciliation" (
    id SERIAL PRIMARY KEY,
    "companyId" INTEGER NOT NULL REFERENCES public."Company"(id),
    "bankAccountId" INTEGER NOT NULL REFERENCES public."BankAccount"(id),
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    "initialBalance" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "finalBankStatementBalance" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "bookBalance" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    difference NUMERIC(18, 4) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    "closedAt" TIMESTAMP(3),
    "closedById" INTEGER REFERENCES public."User"(id),
    observations TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "uq_bank_reconciliation" UNIQUE ("bankAccountId", year, month)
);

CREATE TABLE IF NOT EXISTS public."BankReconciliationItem" (
    id SERIAL PRIMARY KEY,
    "bankReconciliationId" INTEGER NOT NULL REFERENCES public."BankReconciliation"(id) ON DELETE CASCADE,
    "itemType" VARCHAR(50) NOT NULL,
    "itemDate" TIMESTAMP(3) NOT NULL,
    "documentNumber" VARCHAR(50),
    description VARCHAR(255) NOT NULL,
    amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    "journalEntryItemId" INTEGER REFERENCES public."JournalEntryItem"(id),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- --- TABLA: 03_Receivables_Payables_Tables.sql ---
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


-- --- TABLA: 04_Fixed_Assets_Tables.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - TABLAS DDL PARA ACTIVOS FIJOS Y DEPRECIACIONES (FASE 6)
-- MOTOR: PostgreSQL
-- ============================================================================

CREATE TABLE IF NOT EXISTS public."FixedAssetCategory" (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    "defaultUsefulLifeMonths" INTEGER NOT NULL DEFAULT 60,
    "accountAssetId" INTEGER NOT NULL REFERENCES public."Account"(id),
    "accountAccumDeprId" INTEGER NOT NULL REFERENCES public."Account"(id),
    "accountExpenseDeprId" INTEGER NOT NULL REFERENCES public."Account"(id),
    "isActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."FixedAsset" (
    id SERIAL PRIMARY KEY,
    "companyId" INTEGER NOT NULL REFERENCES public."Company"(id),
    "categoryId" INTEGER NOT NULL REFERENCES public."FixedAssetCategory"(id),
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    "serialNumber" VARCHAR(100),
    "purchaseDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    "activationDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    "acquisitionCost" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "residualValue" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "usefulLifeMonths" INTEGER NOT NULL DEFAULT 60,
    "depreciatedMonths" INTEGER NOT NULL DEFAULT 0,
    "accumulatedDepreciation" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "netBookValue" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "monthlyDepreciation" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "costCenterId" INTEGER REFERENCES public."CostCenter"(id),
    "responsibleThirdPartyId" INTEGER REFERENCES public."ThirdParty"(id),
    location VARCHAR(150),
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    "createdById" INTEGER NOT NULL REFERENCES public."User"(id),
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "FixedAsset_categoryId_idx" ON public."FixedAsset"("categoryId");
CREATE INDEX IF NOT EXISTS "FixedAsset_status_idx" ON public."FixedAsset"(status);

CREATE TABLE IF NOT EXISTS public."FixedAssetDepreciation" (
    id SERIAL PRIMARY KEY,
    "fixedAssetId" INTEGER NOT NULL REFERENCES public."FixedAsset"(id) ON DELETE CASCADE,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "accumulatedAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "netBookValue" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "journalEntryId" INTEGER REFERENCES public."JournalEntry"(id),
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "FixedAssetDepreciation_asset_period_key" UNIQUE ("fixedAssetId", year, month)
);

CREATE INDEX IF NOT EXISTS "FixedAssetDepreciation_period_idx" ON public."FixedAssetDepreciation"(year, month);

CREATE TABLE IF NOT EXISTS public."FixedAssetImprovement" (
    id SERIAL PRIMARY KEY,
    "fixedAssetId" INTEGER NOT NULL REFERENCES public."FixedAsset"(id) ON DELETE CASCADE,
    "improvementDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    description TEXT NOT NULL,
    amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "additionalMonths" INTEGER NOT NULL DEFAULT 0,
    "journalEntryId" INTEGER REFERENCES public."JournalEntry"(id),
    "createdById" INTEGER NOT NULL REFERENCES public."User"(id),
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public."FixedAssetDisposal" (
    id SERIAL PRIMARY KEY,
    "fixedAssetId" INTEGER NOT NULL REFERENCES public."FixedAsset"(id) ON DELETE CASCADE,
    "disposalDate" TIMESTAMP WITH TIME ZONE NOT NULL,
    "disposalType" VARCHAR(30) NOT NULL,
    "salePrice" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "acquisitionCostAtDisposal" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "accumulatedDeprAtDisposal" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "netGainLoss" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "journalEntryId" INTEGER REFERENCES public."JournalEntry"(id),
    reason TEXT NOT NULL,
    "createdById" INTEGER NOT NULL REFERENCES public."User"(id),
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- --- TABLA: 05_Reports_Taxes_Tables.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - TABLAS DDL PARA REPORTES, IMPUESTOS Y EXÓGENA DIAN (FASE 7)
-- MOTOR: PostgreSQL
-- ============================================================================

CREATE TABLE IF NOT EXISTS public."ExogenaConcept" (
    id SERIAL PRIMARY KEY,
    "formatNumber" VARCHAR(20) NOT NULL,
    code VARCHAR(20) NOT NULL,
    name VARCHAR(255) NOT NULL,
    "columnMapping" JSONB,
    "isActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ExogenaConcept_format_code_key" UNIQUE ("formatNumber", code)
);

CREATE TABLE IF NOT EXISTS public."ExogenaFormatConfig" (
    id SERIAL PRIMARY KEY,
    "companyId" INTEGER NOT NULL REFERENCES public."Company"(id),
    "formatNumber" VARCHAR(20) NOT NULL,
    "conceptId" INTEGER NOT NULL REFERENCES public."ExogenaConcept"(id),
    "accountId" INTEGER NOT NULL REFERENCES public."Account"(id),
    "columnType" VARCHAR(50) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ExogenaFormatConfig_comp_fmt_cpt_acc_col_key" UNIQUE ("companyId", "formatNumber", "conceptId", "accountId", "columnType")
);

CREATE TABLE IF NOT EXISTS public."TaxDeclarationPeriod" (
    id SERIAL PRIMARY KEY,
    "companyId" INTEGER NOT NULL REFERENCES public."Company"(id),
    "formType" VARCHAR(30) NOT NULL,
    year INTEGER NOT NULL,
    "periodNumber" INTEGER NOT NULL,
    "totalBaseAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "totalTaxAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "totalWithholdingAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    "totalPayableAmount" NUMERIC(18, 4) NOT NULL DEFAULT 0,
    breakdown JSONB,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    "filedAt" TIMESTAMP WITH TIME ZONE,
    "createdById" INTEGER NOT NULL REFERENCES public."User"(id),
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "TaxDeclarationPeriod_comp_form_yr_per_key" UNIQUE ("companyId", "formType", year, "periodNumber")
);


-- --- TABLA: 06_Integrations_Tables.sql ---
-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- MODULO: FASE 8 - INTEGRACIONES E INTERFACES DE DATOS (TABLAS DDL)
-- MOTOR: PostgreSQL (Korex_contabilidad_pg)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public."DataInterfaceTemplate" (
    "id" SERIAL PRIMARY KEY,
    "code" VARCHAR(50) UNIQUE NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "category" VARCHAR(50) NOT NULL, -- PUC, TERCEROS, COMPROBANTES, CARTERA, FACTURAS
    "formatType" VARCHAR(20) NOT NULL, -- EXCEL, CSV, JSON, XML
    "mappingConfig" JSONB,
    "sampleFile" BYTEA,
    "isActive" BOOLEAN DEFAULT true NOT NULL,
    "createdAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS public."BatchImportJob" (
    "id" SERIAL PRIMARY KEY,
    "jobCode" VARCHAR(50) UNIQUE NOT NULL,
    "companyId" INTEGER NOT NULL,
    "templateCode" VARCHAR(50) NOT NULL,
    "interfaceType" VARCHAR(50) NOT NULL,
    "fileName" VARCHAR(255),
    "fileSizeBytes" INTEGER,
    "status" VARCHAR(20) DEFAULT 'PENDING' NOT NULL, -- PENDING, PROCESSING, COMPLETED, FAILED
    "totalRows" INTEGER DEFAULT 0 NOT NULL,
    "processedRows" INTEGER DEFAULT 0 NOT NULL,
    "successRows" INTEGER DEFAULT 0 NOT NULL,
    "failedRows" INTEGER DEFAULT 0 NOT NULL,
    "errorsSummary" JSONB,
    "startedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "userId" INTEGER,
    "createdAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS "BatchImportJob_companyId_idx" ON public."BatchImportJob"("companyId");
CREATE INDEX IF NOT EXISTS "BatchImportJob_status_idx" ON public."BatchImportJob"("status");
CREATE INDEX IF NOT EXISTS "BatchImportJob_createdAt_idx" ON public."BatchImportJob"("createdAt");

CREATE TABLE IF NOT EXISTS public."ExternalIntegrationEndpoint" (
    "id" SERIAL PRIMARY KEY,
    "code" VARCHAR(50) UNIQUE NOT NULL,
    "systemName" VARCHAR(150) NOT NULL,
    "adapterType" VARCHAR(50) DEFAULT 'API_REST' NOT NULL,
    "endpointUrl" VARCHAR(500),
    "authType" VARCHAR(50) DEFAULT 'BEARER_TOKEN' NOT NULL,
    "credentialsEnc" TEXT,
    "subscribedEvents" JSONB,
    "isActive" BOOLEAN DEFAULT true NOT NULL,
    "createdAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS public."IntegrationTransaction" (
    "id" SERIAL PRIMARY KEY,
    "txCode" VARCHAR(50) UNIQUE NOT NULL,
    "endpointCode" VARCHAR(50) NOT NULL,
    "direction" VARCHAR(20) NOT NULL, -- INBOUND, OUTBOUND
    "eventType" VARCHAR(50) NOT NULL, -- COMPROBANTE_SYNC, TERCERO_SYNC, INVOICE_SYNC
    "requestPayload" JSONB,
    "responsePayload" JSONB,
    "httpStatus" INTEGER,
    "durationMs" INTEGER DEFAULT 0 NOT NULL,
    "status" VARCHAR(20) DEFAULT 'SUCCESS' NOT NULL,
    "errorMessage" TEXT,
    "createdAt" TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE INDEX IF NOT EXISTS "IntegrationTransaction_endpointCode_idx" ON public."IntegrationTransaction"("endpointCode");
CREATE INDEX IF NOT EXISTS "IntegrationTransaction_direction_idx" ON public."IntegrationTransaction"("direction");
CREATE INDEX IF NOT EXISTS "IntegrationTransaction_status_idx" ON public."IntegrationTransaction"("status");
CREATE INDEX IF NOT EXISTS "IntegrationTransaction_createdAt_idx" ON public."IntegrationTransaction"("createdAt");


-- --- SEMILLAS: 02_Accounting_Seeds.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - SEMILLAS DE MAESTROS CONTABLES (POSTGRESQL)
-- Archivo: SQL/Data/02_Accounting_Seeds.sql
-- ============================================================================

-- 1. Roles por Defecto
INSERT INTO public."Role" (id, name, description, permissions, "isActive")
VALUES 
(1, 'SUPERADMINISTRADOR', 'Acceso total y configuración del sistema contable', '{"modules": {"accounting": true, "masters": true, "periods": true, "reports": true, "treasury": true, "receivables": true, "payables": true, "config": true, "manual": true}}'::jsonb, true),
(2, 'CONTADOR_GENERAL', 'Gestión de comprobantes, balances, cierres y reportes contables', '{"modules": {"accounting": true, "masters": true, "periods": true, "reports": true, "treasury": true, "receivables": true, "payables": true, "config": false, "manual": true}}'::jsonb, true),
(3, 'AUXILIAR_CONTABLE', 'Elaboración y edición de comprobantes en borrador', '{"modules": {"accounting": true, "masters": false, "periods": false, "reports": true, "treasury": false, "receivables": false, "payables": false, "config": false, "manual": true}}'::jsonb, true),
(4, 'AUDITOR_FISCAL', 'Solo consulta y auditoría de libros y comprobantes', '{"modules": {"accounting": true, "masters": false, "periods": false, "reports": true, "treasury": false, "receivables": false, "payables": false, "config": false, "manual": true}}'::jsonb, true)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description;

-- 2. Empresa Demostrativa por Defecto
INSERT INTO public."Company" (id, code, "businessName", "tradeName", "documentType", "documentNumber", "verificationDigit", city, state, country, email, "taxRegime", "isActive")
VALUES 
(1, 'EMP-01', 'EMPRESA DEMO CONTABLE S.A.S.', 'KOREX CONTABILIDAD DEMO', 'NIT', '900123456', '7', 'Bogotá D.C.', 'Cundinamarca', 'Colombia', 'contabilidad@korex.com.co', 'Régimen Ordinario', true)
ON CONFLICT (id) DO UPDATE SET "businessName" = EXCLUDED."businessName";

-- 3. Tipos de Documento Contable Estándar en Colombia
INSERT INTO public."DocumentType" (id, code, name, prefix, "isAutomatic", "isActive")
VALUES
(1, 'CC', 'Comprobante de Contabilidad / Diario', 'CC', true, true),
(2, 'CE', 'Comprobante de Egreso / Pago', 'CE', true, true),
(3, 'CI', 'Comprobante de Ingreso / Recibo de Caja', 'CI', true, true),
(4, 'NC', 'Nota Crédito', 'NC', true, true),
(5, 'ND', 'Nota Débito', 'ND', true, true),
(6, 'FV', 'Factura de Venta', 'FV', true, true),
(7, 'DS', 'Documento Soporte en Adquisiciones', 'DS', true, true),
(8, 'CZ', 'Comprobante de Cierre Contable', 'CZ', true, true),
(9, 'AJ', 'Comprobante de Ajustes / Reclasificaciones', 'AJ', true, true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, prefix = EXCLUDED.prefix;

-- 4. Consecutivos Iniciales Año Actual
INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
VALUES
(1, 'CC', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(2, 'CE', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(3, 'CI', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(4, 'NC', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(5, 'ND', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(6, 'FV', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(7, 'DS', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(8, 'CZ', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true),
(9, 'AJ', 1, 1, EXTRACT(YEAR FROM CURRENT_DATE)::INT, true)
ON CONFLICT ("documentTypeId", "fiscalYear", prefix) DO NOTHING;

-- 5. Plan Único de Cuentas (PUC) Colombiano Base
-- Nivel 1: Clases
INSERT INTO public."Account" (code, name, level, nature, "allowsMovement", "requiresThirdParty", "requiresCostCenter", "parentId", "isActive") VALUES
('1', 'ACTIVO', 1, 'DEBIT', false, false, false, NULL, true),
('2', 'PASIVO', 1, 'CREDIT', false, false, false, NULL, true),
('3', 'PATRIMONIO', 1, 'CREDIT', false, false, false, NULL, true),
('4', 'INGRESOS', 1, 'CREDIT', false, false, false, NULL, true),
('5', 'GASTOS', 1, 'DEBIT', false, false, false, NULL, true),
('6', 'COSTOS DE VENTAS', 1, 'DEBIT', false, false, false, NULL, true),
('7', 'COSTOS DE PRODUCCION O DE OPERACION', 1, 'DEBIT', false, false, false, NULL, true),
('8', 'CUENTAS DE ORDEN DEUDORAS', 1, 'DEBIT', false, false, false, NULL, true),
('9', 'CUENTAS DE ORDEN ACREEDORAS', 1, 'CREDIT', false, false, false, NULL, true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, nature = EXCLUDED.nature;

-- Nivel 2: Grupos Principales
INSERT INTO public."Account" (code, name, level, nature, "allowsMovement", "requiresThirdParty", "requiresCostCenter", "parentId", "isActive") VALUES
('11', 'DISPONIBLE', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '1'), true),
('12', 'INVERSIONES', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '1'), true),
('13', 'DEUDORES (CLIENTES)', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '1'), true),
('14', 'INVENTARIOS', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '1'), true),
('15', 'PROPIEDAD, PLANTA Y EQUIPO', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '1'), true),
('21', 'OBLIGACIONES FINANCIERAS', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '2'), true),
('22', 'PROVEEDORES', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '2'), true),
('23', 'CUENTAS POR PAGAR', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '2'), true),
('24', 'IMPUESTOS, GRAVAMENES Y TASAS', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '2'), true),
('31', 'CAPITAL SOCIAL', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '3'), true),
('36', 'RESULTADOS DEL EJERCICIO', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '3'), true),
('41', 'OPERACIONALES', 2, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '4'), true),
('51', 'OPERACIONALES DE ADMINISTRACION', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '5'), true),
('52', 'OPERACIONALES DE VENTAS', 2, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '5'), true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

-- Nivel 3 y 4: Cuentas y Subcuentas Operacionales
INSERT INTO public."Account" (code, name, level, nature, "allowsMovement", "requiresThirdParty", "requiresCostCenter", "parentId", "isActive") VALUES
('1105', 'CAJA', 3, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '11'), true),
('110505', 'CAJA GENERAL', 4, 'DEBIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '1105'), true),
('1110', 'BANCOS', 3, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '11'), true),
('111005', 'MONEDA NACIONAL', 4, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '1110'), true),
('11100501', 'BANCOLOMBIA CTA CTE #1', 5, 'DEBIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '111005'), true),
('1305', 'CLIENTES NACIONALES', 3, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '13'), true),
('130505', 'CLIENTES NACIONALES - CARTERA', 4, 'DEBIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '1305'), true),
('2205', 'PROVEEDORES NACIONALES', 3, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '22'), true),
('220505', 'PROVEEDORES NACIONALES - CUENTAS POR PAGAR', 4, 'CREDIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '2205'), true),
('2365', 'RETENCION EN LA FUENTE', 3, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '23'), true),
('236540', 'RETEFUENTE POR COMPRAS', 4, 'CREDIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '2365'), true),
('236525', 'RETEFUENTE POR SERVICIOS', 4, 'CREDIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '2365'), true),
('2408', 'IMPUESTO SOBRE LAS VENTAS POR PAGAR (IVA)', 3, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '24'), true),
('240801', 'IVA GENERADO EN VENTAS 19%', 4, 'CREDIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '2408'), true),
('240802', 'IVA DESCONTABLE EN COMPRAS 19%', 4, 'DEBIT', true, true, false, (SELECT id FROM public."Account" WHERE code = '2408'), true),
('4135', 'COMERCIO AL POR MAYOR Y AL POR MENOR', 3, 'CREDIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '41'), true),
('413501', 'INGRESOS POR VENTAS GRAVADAS 19%', 4, 'CREDIT', true, true, true, (SELECT id FROM public."Account" WHERE code = '4135'), true),
('5105', 'GASTOS DE PERSONAL', 3, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '51'), true),
('510506', 'SUELDOS', 4, 'DEBIT', true, true, true, (SELECT id FROM public."Account" WHERE code = '5105'), true),
('5135', 'SERVICIOS', 3, 'DEBIT', false, false, false, (SELECT id FROM public."Account" WHERE code = '51'), true),
('513505', 'ASEO Y VIGILANCIA', 4, 'DEBIT', true, true, true, (SELECT id FROM public."Account" WHERE code = '5135'), true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, "allowsMovement" = EXCLUDED."allowsMovement";

-- 6. Centros de Costo Iniciales
INSERT INTO public."CostCenter" (id, code, name, level, "isActive") VALUES
(1, '01', 'ADMINISTRACION GENERAL', 1, true),
(2, '02', 'VENTAS Y COMERCIAL', 1, true),
(3, '03', 'OPERACIONES Y SERVICIOS', 1, true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

-- 7. Bancos Base de Colombia
INSERT INTO public."Bank" (id, code, name, nit, "isActive") VALUES
(1, '007', 'BANCOLOMBIA S.A.', '890903938-8', true),
(2, '001', 'BANCO DE BOGOTA', '860002964-4', true),
(3, '051', 'DAVIVIENDA S.A.', '860034313-7', true),
(4, '002', 'BANCO POPULAR', '860007738-9', true),
(5, '013', 'BBVA COLOMBIA', '860003020-1', true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

-- 8. Impuestos y Retenciones Base
INSERT INTO public."TaxConcept" (code, name, type, "ratePercentage", "minimumBaseAmount", "accountDebitId", "accountCreditId", "isActive") VALUES
('IVA19_GEN', 'IVA Generado en Ventas 19%', 'IVA', 19.0000, 0, NULL, (SELECT id FROM public."Account" WHERE code = '240801'), true),
('IVA19_DESC', 'IVA Descontable en Compras 19%', 'IVA', 19.0000, 0, (SELECT id FROM public."Account" WHERE code = '240802'), NULL, true),
('RF_COMPRAS_25', 'Retefuente por Compras Generales 2.5%', 'RETEFUENTE', 2.5000, 1150000.0000, NULL, (SELECT id FROM public."Account" WHERE code = '236540'), true),
('RF_SERVICIOS_4', 'Retefuente por Servicios Declarantes 4%', 'RETEFUENTE', 4.0000, 190000.0000, NULL, (SELECT id FROM public."Account" WHERE code = '236525'), true)
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, "ratePercentage" = EXCLUDED."ratePercentage";


-- --- SEMILLAS: 03_Exogena_Seeds.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - SEMILLAS DE CONCEPTOS OFICIALES DE EXÓGENA DIAN
-- ============================================================================

INSERT INTO public."ExogenaConcept"("formatNumber", code, name, "isActive")
VALUES 
    -- Formato 1001: Pagos o Abonos en Cuenta y Retenciones Practicadas
    ('1001', '5001', 'Salarios, prestaciones sociales y demás pagos laborales', TRUE),
    ('1001', '5002', 'Honorarios', TRUE),
    ('1001', '5003', 'Comisiones', TRUE),
    ('1001', '5004', 'Servicios', TRUE),
    ('1001', '5005', 'Arrendamientos de bienes muebles e inmuebles', TRUE),
    ('1001', '5006', 'Intereses y rendimientos financieros', TRUE),
    ('1001', '5007', 'Compras de activos movibles (Inventarios / Mercancías)', TRUE),
    ('1001', '5008', 'Compras de activos fijos (Propiedad, planta y equipo)', TRUE),
    ('1001', '5010', 'Pagos o abonos en cuenta por seguros y reaseguros', TRUE),
    ('1001', '5016', 'Demás costos y deducciones no contemplados en otros conceptos', TRUE),

    -- Formato 1007: Ingresos Propios Recibidos
    ('1007', '4001', 'Ingresos brutos operacionales de actividades ordinarias', TRUE),
    ('1007', '4002', 'Ingresos brutos no operacionales (Financieros, diversos)', TRUE),
    ('1007', '4003', 'Ingresos por intereses y rendimientos financieros', TRUE),
    ('1007', '4004', 'Ingresos por dividendos y participaciones', TRUE),

    -- Formato 1008: Saldo de Cuentas por Cobrar a 31 de Diciembre
    ('1008', '1315', 'Cuentas por cobrar a clientes nacionales y del exterior', TRUE),
    ('1008', '1316', 'Cuentas por cobrar a socios y accionistas', TRUE),
    ('1008', '1317', 'Anticipos entregados a proveedores y contratistas', TRUE),
    ('1008', '1318', 'Otras cuentas por cobrar', TRUE),

    -- Formato 1009: Saldo de Cuentas por Pagar a 31 de Diciembre
    ('1009', '2201', 'Proveedores nacionales y del exterior', TRUE),
    ('1009', '2202', 'Obligaciones financieras con entidades bancarias', TRUE),
    ('1009', '2203', 'Cuentas por pagar a socios y accionistas', TRUE),
    ('1009', '2204', 'Anticipos recibidos de clientes', TRUE),
    ('1009', '2205', 'Otras cuentas por pagar y pasivos laborales', TRUE)
ON CONFLICT ("formatNumber", code) DO NOTHING;


-- --- SEMILLAS: 04_Data_Interface_Seeds.sql ---
-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- MODULO: FASE 8 - PLANTILLAS BASE DE IMPORTACION Y EXPORTACION
-- ============================================================================

INSERT INTO public."DataInterfaceTemplate" ("code", "name", "category", "formatType", "mappingConfig", "isActive", "createdAt", "updatedAt")
VALUES 
(
    'PUC_EXCEL_STANDARD',
    'Plantilla Oficial de Importación de Cuentas PUC (Excel)',
    'PUC',
    'EXCEL',
    '{"codeColumn": "CODIGO_CUENTA", "nameColumn": "NOMBRE_CUENTA", "natureColumn": "NATURALEZA", "levelColumn": "NIVEL", "isMovementColumn": "ES_MOVIMIENTO", "requiresThirdPartyColumn": "REQUIERE_TERCERO", "requiresCostCenterColumn": "REQUIERE_CENTRO_COSTO"}'::jsonb,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    'TERCEROS_EXCEL_STANDARD',
    'Plantilla Oficial de Importación de Terceros y Clientes/Proveedores (Excel)',
    'TERCEROS',
    'EXCEL',
    '{"documentTypeColumn": "TIPO_DOCUMENTO", "documentNumberColumn": "NUMERO_IDENTIFICACION", "businessNameColumn": "RAZON_SOCIAL", "firstNameColumn": "PRIMER_NOMBRE", "lastNameColumn": "PRIMER_APELLIDO", "emailColumn": "CORREO_ELECTRONICO", "phoneColumn": "TELEFONO", "cityColumn": "CIUDAD", "addressColumn": "DIRECCION", "isCustomerColumn": "ES_CLIENTE", "isVendorColumn": "ES_PROVEEDOR"}'::jsonb,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    'COMPROBANTES_EXCEL_STANDARD',
    'Plantilla de Importación de Comprobantes y Asientos Contables (Excel)',
    'COMPROBANTES',
    'EXCEL',
    '{"dateColumn": "FECHA", "docTypeColumn": "TIPO_DOCUMENTO", "consecutiveColumn": "NUMERO_COMPROBANTE", "conceptColumn": "CONCEPTO_CABECERA", "accountColumn": "CODIGO_CUENTA", "thirdPartyDocColumn": "NIT_TERCERO", "costCenterColumn": "CENTRO_COSTO", "debitColumn": "DEBITO", "creditColumn": "CREDITO", "descriptionColumn": "DETALLE_ASIENTO"}'::jsonb,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
),
(
    'EXOGENA_XML_1001',
    'Formato de Exportación Exógena DIAN 1001 (XML Prevalidador)',
    'EXOGENA',
    'XML',
    '{"formatNumber": "1001", "version": "10", "rootElement": "masiva", "rowElement": "pagos"}'::jsonb,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT ("code") DO UPDATE SET 
    "name" = EXCLUDED."name",
    "mappingConfig" = EXCLUDED."mappingConfig",
    "updatedAt" = CURRENT_TIMESTAMP;


-- --- FUNCION: fnActivoFijoHistorialDepreciacion.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnActivoFijoHistorialDepreciacion
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnActivoFijoHistorialDepreciacion";
END $$;

CREATE OR REPLACE FUNCTION public."fnActivoFijoHistorialDepreciacion"(
    p_fixed_asset_id INTEGER
)
RETURNS TABLE (
    id INTEGER,
    year INTEGER,
    month INTEGER,
    amount NUMERIC(18, 4),
    "accumulatedAmount" NUMERIC(18, 4),
    "netBookValue" NUMERIC(18, 4),
    "journalEntryId" INTEGER,
    "journalNumber" VARCHAR(50),
    "createdAt" TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.year,
        d.month,
        d.amount,
        d."accumulatedAmount",
        d."netBookValue",
        d."journalEntryId",
        j."entryNumber" AS "journalNumber",
        d."createdAt"
    FROM public."FixedAssetDepreciation" d
    LEFT JOIN public."JournalEntry" j ON j.id = d."journalEntryId"
    WHERE d."fixedAssetId" = p_fixed_asset_id
    ORDER BY d.year ASC, d.month ASC;
END;
$$;


-- --- FUNCION: fnActivosFijosCategoriasListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnActivosFijosCategoriasListar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnActivosFijosCategoriasListar";
END $$;

CREATE OR REPLACE FUNCTION public."fnActivosFijosCategoriasListar"()
RETURNS TABLE (
    id INTEGER,
    code VARCHAR(50),
    name VARCHAR(100),
    "defaultUsefulLifeMonths" INTEGER,
    "accountAssetId" INTEGER,
    "assetAccountCode" VARCHAR(50),
    "assetAccountName" VARCHAR(255),
    "accountAccumDeprId" INTEGER,
    "accumDeprAccountCode" VARCHAR(50),
    "accumDeprAccountName" VARCHAR(255),
    "accountExpenseDeprId" INTEGER,
    "expenseDeprAccountCode" VARCHAR(50),
    "expenseDeprAccountName" VARCHAR(255),
    "isActive" BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.code,
        c.name,
        c."defaultUsefulLifeMonths",
        c."accountAssetId",
        aa.code AS "assetAccountCode",
        aa.name AS "assetAccountName",
        c."accountAccumDeprId",
        ad.code AS "accumDeprAccountCode",
        ad.name AS "accumDeprAccountName",
        c."accountExpenseDeprId",
        ed.code AS "expenseDeprAccountCode",
        ed.name AS "expenseDeprAccountName",
        c."isActive"
    FROM public."FixedAssetCategory" c
    JOIN public."Account" aa ON aa.id = c."accountAssetId"
    JOIN public."Account" ad ON ad.id = c."accountAccumDeprId"
    JOIN public."Account" ed ON ed.id = c."accountExpenseDeprId"
    ORDER BY c.code ASC;
END;
$$;


-- --- FUNCION: fnActivosFijosCuadroResumen.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnActivosFijosCuadroResumen
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnActivosFijosCuadroResumen";
END $$;

CREATE OR REPLACE FUNCTION public."fnActivosFijosCuadroResumen"(
    p_company_id INTEGER
)
RETURNS TABLE (
    "categoryId" INTEGER,
    "categoryCode" VARCHAR(50),
    "categoryName" VARCHAR(100),
    "assetsCount" BIGINT,
    "totalAcquisitionCost" NUMERIC(18, 4),
    "totalAccumulatedDepreciation" NUMERIC(18, 4),
    "totalNetBookValue" NUMERIC(18, 4),
    "totalMonthlyDepreciation" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id AS "categoryId",
        c.code AS "categoryCode",
        c.name AS "categoryName",
        COUNT(a.id) AS "assetsCount",
        COALESCE(SUM(a."acquisitionCost"), 0) AS "totalAcquisitionCost",
        COALESCE(SUM(a."accumulatedDepreciation"), 0) AS "totalAccumulatedDepreciation",
        COALESCE(SUM(a."netBookValue"), 0) AS "totalNetBookValue",
        COALESCE(SUM(CASE WHEN a.status = 'ACTIVE' THEN a."monthlyDepreciation" ELSE 0 END), 0) AS "totalMonthlyDepreciation"
    FROM public."FixedAssetCategory" c
    LEFT JOIN public."FixedAsset" a ON a."categoryId" = c.id AND a."companyId" = p_company_id AND a.status IN ('ACTIVE', 'FULLY_DEPRECIATED')
    GROUP BY c.id, c.code, c.name
    ORDER BY c.code ASC;
END;
$$;


-- --- FUNCION: fnActivosFijosListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnActivosFijosListar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnActivosFijosListar";
END $$;

CREATE OR REPLACE FUNCTION public."fnActivosFijosListar"(
    p_company_id INTEGER,
    p_category_id INTEGER DEFAULT NULL,
    p_status VARCHAR(30) DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id INTEGER,
    code VARCHAR(50),
    name VARCHAR(150),
    "categoryId" INTEGER,
    "categoryName" VARCHAR(100),
    "purchaseDate" TIMESTAMP WITH TIME ZONE,
    "activationDate" TIMESTAMP WITH TIME ZONE,
    "acquisitionCost" NUMERIC(18, 4),
    "residualValue" NUMERIC(18, 4),
    "usefulLifeMonths" INTEGER,
    "depreciatedMonths" INTEGER,
    "accumulatedDepreciation" NUMERIC(18, 4),
    "netBookValue" NUMERIC(18, 4),
    "monthlyDepreciation" NUMERIC(18, 4),
    "costCenterId" INTEGER,
    "costCenterName" VARCHAR(100),
    "responsibleThirdPartyId" INTEGER,
    "responsibleName" VARCHAR(255),
    location VARCHAR(150),
    status VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.code,
        a.name,
        a."categoryId",
        c.name AS "categoryName",
        a."purchaseDate",
        a."activationDate",
        a."acquisitionCost",
        a."residualValue",
        a."usefulLifeMonths",
        a."depreciatedMonths",
        a."accumulatedDepreciation",
        a."netBookValue",
        a."monthlyDepreciation",
        a."costCenterId",
        cc.name AS "costCenterName",
        a."responsibleThirdPartyId",
        t."fullName" AS "responsibleName",
        a.location,
        a.status
    FROM public."FixedAsset" a
    JOIN public."FixedAssetCategory" c ON c.id = a."categoryId"
    LEFT JOIN public."CostCenter" cc ON cc.id = a."costCenterId"
    LEFT JOIN public."ThirdParty" t ON t.id = a."responsibleThirdPartyId"
    WHERE a."companyId" = p_company_id
      AND (p_category_id IS NULL OR a."categoryId" = p_category_id)
      AND (p_status IS NULL OR a.status = p_status)
    ORDER BY a.code ASC
    LIMIT p_limit OFFSET p_offset;
END;
$$;


-- --- FUNCION: fnAnticiposListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnAnticiposListar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnAnticiposListar";
END $$;

CREATE OR REPLACE FUNCTION public."fnAnticiposListar"(
    p_company_id INTEGER,
    p_advance_type VARCHAR(20) DEFAULT NULL,
    p_third_party_id INTEGER DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id INTEGER,
    "advanceType" VARCHAR(20),
    "advanceDate" TIMESTAMP WITH TIME ZONE,
    "thirdPartyId" INTEGER,
    "thirdPartyName" VARCHAR(255),
    "thirdPartyNit" VARCHAR(50),
    amount NUMERIC(18, 4),
    "usedAmount" NUMERIC(18, 4),
    "balanceAmount" NUMERIC(18, 4),
    status VARCHAR(20),
    concept TEXT,
    "treasuryMovementId" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a."advanceType",
        a."advanceDate",
        a."thirdPartyId",
        t."fullName" AS "thirdPartyName",
        t."documentNumber" AS "thirdPartyNit",
        a.amount,
        a."usedAmount",
        a."balanceAmount",
        a.status,
        a.concept,
        a."treasuryMovementId"
    FROM public."AdvancePayment" a
    JOIN public."ThirdParty" t ON t.id = a."thirdPartyId"
    WHERE a."companyId" = p_company_id
      AND (p_advance_type IS NULL OR a."advanceType" = p_advance_type)
      AND (p_third_party_id IS NULL OR a."thirdPartyId" = p_third_party_id)
      AND (p_status IS NULL OR a.status = p_status)
    ORDER BY a."advanceDate" DESC, a.id DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;


-- --- FUNCION: fnBankListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnBankListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnBankListar"();
END $$;

CREATE OR REPLACE FUNCTION public."fnBankListar"()
RETURNS TABLE (
    id INT,
    code VARCHAR,
    name VARCHAR,
    nit VARCHAR,
    phone VARCHAR,
    "contactName" VARCHAR,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.code,
        b.name,
        b.nit,
        b.phone,
        b."contactName",
        b."isActive"
    FROM public."Bank" b
    ORDER BY b.name ASC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnBatchImportJobsListar.sql ---
-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- FUNCION: fnBatchImportJobsListar
-- DESCRIPCION: Consulta del historial de procesos de importación masiva en lote
-- ============================================================================

CREATE OR REPLACE FUNCTION public."fnBatchImportJobsListar"(
    p_company_id INTEGER DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL,
    p_interface_type VARCHAR DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    "id" INTEGER,
    "jobCode" VARCHAR,
    "companyId" INTEGER,
    "templateCode" VARCHAR,
    "interfaceType" VARCHAR,
    "fileName" VARCHAR,
    "fileSizeBytes" INTEGER,
    "status" VARCHAR,
    "totalRows" INTEGER,
    "processedRows" INTEGER,
    "successRows" INTEGER,
    "failedRows" INTEGER,
    "errorsSummary" JSONB,
    "startedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j."id",
        j."jobCode",
        j."companyId",
        j."templateCode",
        j."interfaceType",
        j."fileName",
        j."fileSizeBytes",
        j."status",
        j."totalRows",
        j."processedRows",
        j."successRows",
        j."failedRows",
        j."errorsSummary",
        j."startedAt",
        j."completedAt",
        j."createdAt"
    FROM public."BatchImportJob" j
    WHERE (p_company_id IS NULL OR j."companyId" = p_company_id)
      AND (p_status IS NULL OR j."status" = p_status)
      AND (p_interface_type IS NULL OR j."interfaceType" = p_interface_type)
    ORDER BY j."createdAt" DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;


-- --- FUNCION: fnCajaListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES DE CONSULTA DE TESORERÍA (POSTGRESQL)
-- Archivo: SQL/Function/fnCajaListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnCajaListar"(INT);
END $$;

CREATE OR REPLACE FUNCTION public."fnCajaListar"(
    p_company_id INT DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    "companyId" INT,
    code VARCHAR,
    name VARCHAR,
    "accountId" INT,
    "accountCode" VARCHAR,
    "accountName" VARCHAR,
    "responsibleUserId" INT,
    "responsibleUserName" VARCHAR,
    currency VARCHAR,
    "maxAmount" NUMERIC,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c."companyId",
        c.code,
        c.name,
        c."accountId",
        a.code AS "accountCode",
        a.name AS "accountName",
        c."responsibleUserId",
        u.name AS "responsibleUserName",
        c.currency,
        c."maxAmount",
        c."isActive"
    FROM public."CashBox" c
    INNER JOIN public."Account" a ON c."accountId" = a.id
    LEFT JOIN public."User" u ON c."responsibleUserId" = u.id
    WHERE (p_company_id IS NULL OR c."companyId" = p_company_id)
    ORDER BY c.code ASC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnCarteraEdades.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnCarteraEdades
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnCarteraEdades";
END $$;

CREATE OR REPLACE FUNCTION public."fnCarteraEdades"(
    p_company_id INTEGER,
    p_cutoff_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
)
RETURNS TABLE (
    "thirdPartyId" INTEGER,
    "documentNumber" VARCHAR(50),
    "fullName" VARCHAR(255),
    "currentAmount" NUMERIC(18, 4),      -- Por vencer (corriente)
    "days1To30" NUMERIC(18, 4),          -- Vencido 1 a 30 días
    "days31To60" NUMERIC(18, 4),         -- Vencido 31 a 60 días
    "days61To90" NUMERIC(18, 4),         -- Vencido 61 a 90 días
    "daysOver90" NUMERIC(18, 4),         -- Vencido más de 90 días
    "totalBalance" NUMERIC(18, 4)        -- Total Cartera
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id AS "thirdPartyId",
        t."documentNumber",
        t."fullName",
        COALESCE(SUM(CASE WHEN r."dueDate" >= p_cutoff_date THEN r."balanceAmount" ELSE 0 END), 0) AS "currentAmount",
        COALESCE(SUM(CASE WHEN r."dueDate" < p_cutoff_date AND (p_cutoff_date::DATE - r."dueDate"::DATE) BETWEEN 1 AND 30 THEN r."balanceAmount" ELSE 0 END), 0) AS "days1To30",
        COALESCE(SUM(CASE WHEN r."dueDate" < p_cutoff_date AND (p_cutoff_date::DATE - r."dueDate"::DATE) BETWEEN 31 AND 60 THEN r."balanceAmount" ELSE 0 END), 0) AS "days31To60",
        COALESCE(SUM(CASE WHEN r."dueDate" < p_cutoff_date AND (p_cutoff_date::DATE - r."dueDate"::DATE) BETWEEN 61 AND 90 THEN r."balanceAmount" ELSE 0 END), 0) AS "days61To90",
        COALESCE(SUM(CASE WHEN r."dueDate" < p_cutoff_date AND (p_cutoff_date::DATE - r."dueDate"::DATE) > 90 THEN r."balanceAmount" ELSE 0 END), 0) AS "daysOver90",
        COALESCE(SUM(r."balanceAmount"), 0) AS "totalBalance"
    FROM public."ThirdParty" t
    JOIN public."ReceivableInvoice" r ON r."thirdPartyId" = t.id
    WHERE r."companyId" = p_company_id
      AND r.status IN ('POSTED', 'PARTIAL')
      AND r."balanceAmount" > 0
    GROUP BY t.id, t."documentNumber", t."fullName"
    HAVING SUM(r."balanceAmount") > 0
    ORDER BY "totalBalance" DESC;
END;
$$;


-- --- FUNCION: fnCarteraSaldoTercero.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnCarteraSaldoTercero
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnCarteraSaldoTercero";
END $$;

CREATE OR REPLACE FUNCTION public."fnCarteraSaldoTercero"(
    p_company_id INTEGER,
    p_third_party_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    "thirdPartyId" INTEGER,
    "documentNumber" VARCHAR(50),
    "fullName" VARCHAR(255),
    "totalInvoiced" NUMERIC(18, 4),
    "totalPaid" NUMERIC(18, 4),
    "currentBalance" NUMERIC(18, 4),
    "invoicesCount" BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id AS "thirdPartyId",
        t."documentNumber",
        t."fullName",
        COALESCE(SUM(r."totalAmount"), 0) AS "totalInvoiced",
        COALESCE(SUM(r."paidAmount"), 0) AS "totalPaid",
        COALESCE(SUM(r."balanceAmount"), 0) AS "currentBalance",
        COUNT(r.id) AS "invoicesCount"
    FROM public."ThirdParty" t
    JOIN public."ReceivableInvoice" r ON r."thirdPartyId" = t.id
    WHERE r."companyId" = p_company_id
      AND (p_third_party_id IS NULL OR t.id = p_third_party_id)
      AND r.status IN ('POSTED', 'PARTIAL')
    GROUP BY t.id, t."documentNumber", t."fullName"
    ORDER BY "currentBalance" DESC;
END;
$$;


-- --- FUNCION: fnCompanyListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnCompanyListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnCompanyListar"();
END $$;

CREATE OR REPLACE FUNCTION public."fnCompanyListar"()
RETURNS TABLE (
    id INT,
    code VARCHAR,
    "businessName" VARCHAR,
    "tradeName" VARCHAR,
    "documentType" VARCHAR,
    "documentNumber" VARCHAR,
    "verificationDigit" VARCHAR,
    address VARCHAR,
    city VARCHAR,
    state VARCHAR,
    country VARCHAR,
    phone VARCHAR,
    email VARCHAR,
    "legalRepresentative" VARCHAR,
    "taxRegime" VARCHAR,
    "fiscalResponsibilities" VARCHAR,
    "economicActivityCode" VARCHAR,
    "isActive" BOOLEAN,
    "createdAt" TIMESTAMP(3)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.code,
        c."businessName",
        c."tradeName",
        c."documentType",
        c."documentNumber",
        c."verificationDigit",
        c.address,
        c.city,
        c.state,
        c.country,
        c.phone,
        c.email,
        c."legalRepresentative",
        c."taxRegime",
        c."fiscalResponsibilities",
        c."economicActivityCode",
        c."isActive",
        c."createdAt"
    FROM public."Company" c
    ORDER BY c.id ASC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnComprobanteDetalle.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES DE CONSULTA DE DETALLE COMPROBANTES (POSTGRESQL)
-- Archivo: SQL/Function/fnComprobanteDetalle.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnComprobanteDetalle"(INT);
END $$;

CREATE OR REPLACE FUNCTION public."fnComprobanteDetalle"(
    p_journal_id INT
)
RETURNS TABLE (
    id INT,
    "journalEntryId" INT,
    "accountId" INT,
    "accountCode" VARCHAR,
    "accountName" VARCHAR,
    "thirdPartyId" INT,
    "thirdPartyDoc" VARCHAR,
    "thirdPartyName" VARCHAR,
    "costCenterId" INT,
    "costCenterCode" VARCHAR,
    "costCenterName" VARCHAR,
    debit NUMERIC,
    credit NUMERIC,
    "baseAmount" NUMERIC,
    description VARCHAR,
    "documentReference" VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ji.id,
        ji."journalEntryId",
        ji."accountId",
        a.code AS "accountCode",
        a.name AS "accountName",
        ji."thirdPartyId",
        t."documentNumber" AS "thirdPartyDoc",
        t."fullName" AS "thirdPartyName",
        ji."costCenterId",
        cc.code AS "costCenterCode",
        cc.name AS "costCenterName",
        ji.debit,
        ji.credit,
        ji."baseAmount",
        ji.description,
        ji."documentReference"
    FROM public."JournalEntryItem" ji
    INNER JOIN public."Account" a ON ji."accountId" = a.id
    LEFT JOIN public."ThirdParty" t ON ji."thirdPartyId" = t.id
    LEFT JOIN public."CostCenter" cc ON ji."costCenterId" = cc.id
    WHERE ji."journalEntryId" = p_journal_id
    ORDER BY ji.id ASC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnComprobanteListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES DE CONSULTA DE COMPROBANTES (POSTGRESQL)
-- Archivo: SQL/Function/fnComprobanteListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnComprobanteListar"(INT, INT, TIMESTAMP(3), TIMESTAMP(3), VARCHAR, VARCHAR);
END $$;

CREATE OR REPLACE FUNCTION public."fnComprobanteListar"(
    p_company_id INT DEFAULT NULL,
    p_doc_type_id INT DEFAULT NULL,
    p_start_date TIMESTAMP(3) DEFAULT NULL,
    p_end_date TIMESTAMP(3) DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL,
    p_search VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    "companyId" INT,
    "companyName" VARCHAR,
    "documentTypeId" INT,
    "documentTypeCode" VARCHAR,
    "documentTypeName" VARCHAR,
    "consecutiveNumber" INT,
    "entryNumber" VARCHAR,
    "entryDate" TIMESTAMP(3),
    "thirdPartyId" INT,
    "thirdPartyDoc" VARCHAR,
    "thirdPartyName" VARCHAR,
    concept VARCHAR,
    observation TEXT,
    "totalDebit" NUMERIC,
    "totalCredit" NUMERIC,
    status VARCHAR,
    "createdById" INT,
    "createdByName" VARCHAR,
    "postedAt" TIMESTAMP(3),
    "annulledAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j.id,
        j."companyId",
        c."businessName" AS "companyName",
        j."documentTypeId",
        d.code AS "documentTypeCode",
        d.name AS "documentTypeName",
        j."consecutiveNumber",
        j."entryNumber",
        j."entryDate",
        j."thirdPartyId",
        t."documentNumber" AS "thirdPartyDoc",
        t."fullName" AS "thirdPartyName",
        j.concept,
        j.observation,
        j."totalDebit",
        j."totalCredit",
        j.status,
        j."createdById",
        u.name AS "createdByName",
        j."postedAt",
        j."annulledAt",
        j."createdAt"
    FROM public."JournalEntry" j
    INNER JOIN public."Company" c ON j."companyId" = c.id
    INNER JOIN public."DocumentType" d ON j."documentTypeId" = d.id
    LEFT JOIN public."ThirdParty" t ON j."thirdPartyId" = t.id
    LEFT JOIN public."User" u ON j."createdById" = u.id
    WHERE 
        (p_company_id IS NULL OR j."companyId" = p_company_id)
        AND (p_doc_type_id IS NULL OR j."documentTypeId" = p_doc_type_id)
        AND (p_start_date IS NULL OR j."entryDate" >= p_start_date)
        AND (p_end_date IS NULL OR j."entryDate" <= p_end_date)
        AND (p_status IS NULL OR j.status = p_status)
        AND (
            p_search IS NULL OR TRIM(p_search) = '' 
            OR j."entryNumber" ILIKE '%' || TRIM(p_search) || '%'
            OR j.concept ILIKE '%' || TRIM(p_search) || '%'
            OR (t."fullName" IS NOT NULL AND t."fullName" ILIKE '%' || TRIM(p_search) || '%')
        )
    ORDER BY j."entryDate" DESC, j.id DESC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnConciliacionBancariaConsultar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES DE CONCILIACIÓN BANCARIA (POSTGRESQL)
-- Archivo: SQL/Function/fnConciliacionBancariaConsultar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnConciliacionBancariaConsultar"(INT, INT, INT);
    DROP FUNCTION IF EXISTS public."fnConciliacionPartidasListar"(INT);
END $$;

CREATE OR REPLACE FUNCTION public."fnConciliacionBancariaConsultar"(
    p_bank_account_id INT,
    p_year INT,
    p_month INT
)
RETURNS TABLE (
    id INT,
    "companyId" INT,
    "bankAccountId" INT,
    "bankName" VARCHAR,
    "accountNumber" VARCHAR,
    year INT,
    month INT,
    "initialBalance" NUMERIC,
    "finalBankStatementBalance" NUMERIC,
    "bookBalance" NUMERIC,
    difference NUMERIC,
    status VARCHAR,
    "closedAt" TIMESTAMP(3),
    "closedByName" VARCHAR,
    observations TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        br.id,
        br."companyId",
        br."bankAccountId",
        b.name AS "bankName",
        ba."accountNumber",
        br.year,
        br.month,
        br."initialBalance",
        br."finalBankStatementBalance",
        br."bookBalance",
        br.difference,
        br.status,
        br."closedAt",
        u.name AS "closedByName",
        br.observations
    FROM public."BankReconciliation" br
    INNER JOIN public."BankAccount" ba ON br."bankAccountId" = ba.id
    INNER JOIN public."Bank" b ON ba."bankId" = b.id
    LEFT JOIN public."User" u ON br."closedById" = u.id
    WHERE br."bankAccountId" = p_bank_account_id AND br.year = p_year AND br.month = p_month;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public."fnConciliacionPartidasListar"(
    p_reconciliation_id INT
)
RETURNS TABLE (
    id INT,
    "bankReconciliationId" INT,
    "itemType" VARCHAR,
    "itemDate" TIMESTAMP(3),
    "documentNumber" VARCHAR,
    description VARCHAR,
    amount NUMERIC,
    status VARCHAR,
    "journalEntryItemId" INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bri.id,
        bri."bankReconciliationId",
        bri."itemType",
        bri."itemDate",
        bri."documentNumber",
        bri.description,
        bri.amount,
        bri.status,
        bri."journalEntryItemId"
    FROM public."BankReconciliationItem" bri
    WHERE bri."bankReconciliationId" = p_reconciliation_id
    ORDER BY bri."itemDate" ASC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnConsecutiveListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnConsecutiveListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnConsecutiveListar"(INT);
END $$;

CREATE OR REPLACE FUNCTION public."fnConsecutiveListar"(
    p_year INT DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    "documentTypeId" INT,
    "documentTypeCode" VARCHAR,
    "documentTypeName" VARCHAR,
    prefix VARCHAR,
    "currentNumber" INT,
    "initialNumber" INT,
    "finalNumber" INT,
    "fiscalYear" INT,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c."documentTypeId",
        d.code AS "documentTypeCode",
        d.name AS "documentTypeName",
        c.prefix,
        c."currentNumber",
        c."initialNumber",
        c."finalNumber",
        c."fiscalYear",
        c."isActive"
    FROM public."Consecutive" c
    INNER JOIN public."DocumentType" d ON c."documentTypeId" = d.id
    WHERE (p_year IS NULL OR c."fiscalYear" = p_year)
    ORDER BY d.code ASC, c.prefix ASC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnCostCenterListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnCostCenterListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnCostCenterListar"();
END $$;

CREATE OR REPLACE FUNCTION public."fnCostCenterListar"()
RETURNS TABLE (
    id INT,
    code VARCHAR,
    name VARCHAR,
    level INT,
    "parentId" INT,
    "parentName" VARCHAR,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cc.id,
        cc.code,
        cc.name,
        cc.level,
        cc."parentId",
        p.name AS "parentName",
        cc."isActive"
    FROM public."CostCenter" cc
    LEFT JOIN public."CostCenter" p ON cc."parentId" = p.id
    ORDER BY cc.code ASC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnDocumentTypeListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnDocumentTypeListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnDocumentTypeListar"();
END $$;

CREATE OR REPLACE FUNCTION public."fnDocumentTypeListar"()
RETURNS TABLE (
    id INT,
    code VARCHAR,
    name VARCHAR,
    prefix VARCHAR,
    "isAutomatic" BOOLEAN,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.code,
        d.name,
        d.prefix,
        d."isAutomatic",
        d."isActive"
    FROM public."DocumentType" d
    ORDER BY d.id ASC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnFacturasCompraListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnFacturasCompraListar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnFacturasCompraListar";
END $$;

CREATE OR REPLACE FUNCTION public."fnFacturasCompraListar"(
    p_company_id INTEGER,
    p_third_party_id INTEGER DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id INTEGER,
    "invoiceNumber" VARCHAR(50),
    "internalNumber" VARCHAR(50),
    "issueDate" TIMESTAMP WITH TIME ZONE,
    "dueDate" TIMESTAMP WITH TIME ZONE,
    "thirdPartyId" INTEGER,
    "supplierName" VARCHAR(255),
    "supplierNit" VARCHAR(50),
    subtotal NUMERIC(18, 4),
    "taxAmount" NUMERIC(18, 4),
    "retentionAmount" NUMERIC(18, 4),
    "totalAmount" NUMERIC(18, 4),
    "paidAmount" NUMERIC(18, 4),
    "balanceAmount" NUMERIC(18, 4),
    status VARCHAR(20),
    "journalEntryId" INTEGER,
    "journalNumber" VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p."invoiceNumber",
        p."internalNumber",
        p."issueDate",
        p."dueDate",
        p."thirdPartyId",
        t."fullName" AS "supplierName",
        t."documentNumber" AS "supplierNit",
        p.subtotal,
        p."taxAmount",
        p."retentionAmount",
        p."totalAmount",
        p."paidAmount",
        p."balanceAmount",
        p.status,
        p."journalEntryId",
        j."entryNumber" AS "journalNumber"
    FROM public."PayableInvoice" p
    JOIN public."ThirdParty" t ON t.id = p."thirdPartyId"
    LEFT JOIN public."JournalEntry" j ON j.id = p."journalEntryId"
    WHERE p."companyId" = p_company_id
      AND (p_third_party_id IS NULL OR p."thirdPartyId" = p_third_party_id)
      AND (p_status IS NULL OR p.status = p_status)
    ORDER BY p."issueDate" DESC, p.id DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;


-- --- FUNCION: fnFacturasVentaListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnFacturasVentaListar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnFacturasVentaListar";
END $$;

CREATE OR REPLACE FUNCTION public."fnFacturasVentaListar"(
    p_company_id INTEGER,
    p_third_party_id INTEGER DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id INTEGER,
    "invoiceNumber" VARCHAR(50),
    "issueDate" TIMESTAMP WITH TIME ZONE,
    "dueDate" TIMESTAMP WITH TIME ZONE,
    "thirdPartyId" INTEGER,
    "customerName" VARCHAR(255),
    "customerNit" VARCHAR(50),
    subtotal NUMERIC(18, 4),
    "taxAmount" NUMERIC(18, 4),
    "retentionAmount" NUMERIC(18, 4),
    "totalAmount" NUMERIC(18, 4),
    "paidAmount" NUMERIC(18, 4),
    "balanceAmount" NUMERIC(18, 4),
    status VARCHAR(20),
    "journalEntryId" INTEGER,
    "journalNumber" VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        r."invoiceNumber",
        r."issueDate",
        r."dueDate",
        r."thirdPartyId",
        t."fullName" AS "customerName",
        t."documentNumber" AS "customerNit",
        r.subtotal,
        r."taxAmount",
        r."retentionAmount",
        r."totalAmount",
        r."paidAmount",
        r."balanceAmount",
        r.status,
        r."journalEntryId",
        j."entryNumber" AS "journalNumber"
    FROM public."ReceivableInvoice" r
    JOIN public."ThirdParty" t ON t.id = r."thirdPartyId"
    LEFT JOIN public."JournalEntry" j ON j.id = r."journalEntryId"
    WHERE r."companyId" = p_company_id
      AND (p_third_party_id IS NULL OR r."thirdPartyId" = p_third_party_id)
      AND (p_status IS NULL OR r.status = p_status)
    ORDER BY r."issueDate" DESC, r.id DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;


-- --- FUNCION: fnGenerarFormatoExogena1001.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnGenerarFormatoExogena1001
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnGenerarFormatoExogena1001";
END $$;

CREATE OR REPLACE FUNCTION public."fnGenerarFormatoExogena1001"(
    p_company_id INTEGER,
    p_year INTEGER
)
RETURNS TABLE (
    "conceptCode" VARCHAR(20),
    "documentType" VARCHAR(10),
    "documentNumber" VARCHAR(50),
    "verificationDigit" VARCHAR(2),
    "firstLastName" VARCHAR(100),
    "secondLastName" VARCHAR(100),
    "firstName" VARCHAR(100),
    "secondName" VARCHAR(100),
    "businessName" VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    "paymentAmount" NUMERIC(18, 4),
    "withholdingPracticed" NUMERIC(18, 4),
    "withholdingAssumed" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_date TIMESTAMP WITH TIME ZONE;
    v_end_date TIMESTAMP WITH TIME ZONE;
BEGIN
    v_start_date := (p_year::TEXT || '-01-01 00:00:00')::TIMESTAMP WITH TIME ZONE;
    v_end_date := (p_year::TEXT || '-12-31 23:59:59')::TIMESTAMP WITH TIME ZONE;

    RETURN QUERY
    SELECT 
        '5005'::VARCHAR(20) AS "conceptCode",
        t."documentType",
        t."documentNumber",
        COALESCE(t."verificationDigit", '') AS "verificationDigit",
        COALESCE(t."firstLastName", '') AS "firstLastName",
        COALESCE(t."secondLastName", '') AS "secondLastName",
        COALESCE(t."firstName", '') AS "firstName",
        COALESCE(t."secondName", '') AS "secondName",
        COALESCE(t."businessName", t."fullName") AS "businessName",
        COALESCE(t.address, '') AS address,
        COALESCE(t.city, '') AS city,
        COALESCE(t.state, '') AS state,
        COALESCE(t.country, 'Colombia') AS country,
        COALESCE(SUM(CASE WHEN a.code LIKE '5%' OR a.code LIKE '6%' THEN ji.debit ELSE 0 END), 0) AS "paymentAmount",
        COALESCE(SUM(CASE WHEN a.code LIKE '2365%' THEN ji.credit ELSE 0 END), 0) AS "withholdingPracticed",
        0::NUMERIC(18, 4) AS "withholdingAssumed"
    FROM public."ThirdParty" t
    JOIN public."JournalEntryItem" ji ON ji."thirdPartyId" = t.id
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND (a.code LIKE '5%' OR a.code LIKE '6%' OR a.code LIKE '2365%')
    GROUP BY t.id, t."documentType", t."documentNumber", t."verificationDigit",
             t."firstLastName", t."secondLastName", t."firstName", t."secondName",
             t."businessName", t."fullName", t.address, t.city, t.state, t.country
    HAVING SUM(CASE WHEN a.code LIKE '5%' OR a.code LIKE '6%' THEN ji.debit ELSE 0 END) > 0
        OR SUM(CASE WHEN a.code LIKE '2365%' THEN ji.credit ELSE 0 END) > 0
    ORDER BY "paymentAmount" DESC;
END;
$$;


-- --- FUNCION: fnGenerarFormatoExogena1007.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnGenerarFormatoExogena1007 (Ingresos Propios)
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnGenerarFormatoExogena1007";
END $$;

CREATE OR REPLACE FUNCTION public."fnGenerarFormatoExogena1007"(
    p_company_id INTEGER,
    p_year INTEGER
)
RETURNS TABLE (
    "conceptCode" VARCHAR(20),
    "documentType" VARCHAR(10),
    "documentNumber" VARCHAR(50),
    "verificationDigit" VARCHAR(2),
    "firstLastName" VARCHAR(100),
    "secondLastName" VARCHAR(100),
    "firstName" VARCHAR(100),
    "secondName" VARCHAR(100),
    "businessName" VARCHAR(255),
    country VARCHAR(100),
    "grossIncome" NUMERIC(18, 4),
    "returnsAndDiscounts" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_date TIMESTAMP WITH TIME ZONE;
    v_end_date TIMESTAMP WITH TIME ZONE;
BEGIN
    v_start_date := (p_year::TEXT || '-01-01 00:00:00')::TIMESTAMP WITH TIME ZONE;
    v_end_date := (p_year::TEXT || '-12-31 23:59:59')::TIMESTAMP WITH TIME ZONE;

    RETURN QUERY
    SELECT 
        '4001'::VARCHAR(20) AS "conceptCode",
        t."documentType",
        t."documentNumber",
        COALESCE(t."verificationDigit", '') AS "verificationDigit",
        COALESCE(t."firstLastName", '') AS "firstLastName",
        COALESCE(t."secondLastName", '') AS "secondLastName",
        COALESCE(t."firstName", '') AS "firstName",
        COALESCE(t."secondName", '') AS "secondName",
        COALESCE(t."businessName", t."fullName") AS "businessName",
        COALESCE(t.country, 'Colombia') AS country,
        COALESCE(SUM(CASE WHEN a.code LIKE '41%' THEN ji.credit - ji.debit ELSE 0 END), 0) AS "grossIncome",
        COALESCE(SUM(CASE WHEN a.code LIKE '4175%' THEN ji.debit ELSE 0 END), 0) AS "returnsAndDiscounts"
    FROM public."ThirdParty" t
    JOIN public."JournalEntryItem" ji ON ji."thirdPartyId" = t.id
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '4%'
    GROUP BY t.id, t."documentType", t."documentNumber", t."verificationDigit",
             t."firstLastName", t."secondLastName", t."firstName", t."secondName",
             t."businessName", t."fullName", t.country
    HAVING SUM(CASE WHEN a.code LIKE '41%' THEN ji.credit - ji.debit ELSE 0 END) > 0
    ORDER BY "grossIncome" DESC;
END;
$$;


-- --- FUNCION: fnGenerarFormatoExogena1008.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnGenerarFormatoExogena1008 (Saldos CxC a 31 Dic)
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnGenerarFormatoExogena1008";
END $$;

CREATE OR REPLACE FUNCTION public."fnGenerarFormatoExogena1008"(
    p_company_id INTEGER,
    p_year INTEGER
)
RETURNS TABLE (
    "conceptCode" VARCHAR(20),
    "documentType" VARCHAR(10),
    "documentNumber" VARCHAR(50),
    "verificationDigit" VARCHAR(2),
    "firstLastName" VARCHAR(100),
    "secondLastName" VARCHAR(100),
    "firstName" VARCHAR(100),
    "secondName" VARCHAR(100),
    "businessName" VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    "receivableBalance" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cutoff_date TIMESTAMP WITH TIME ZONE;
BEGIN
    v_cutoff_date := (p_year::TEXT || '-12-31 23:59:59')::TIMESTAMP WITH TIME ZONE;

    RETURN QUERY
    SELECT 
        '1315'::VARCHAR(20) AS "conceptCode",
        t."documentType",
        t."documentNumber",
        COALESCE(t."verificationDigit", '') AS "verificationDigit",
        COALESCE(t."firstLastName", '') AS "firstLastName",
        COALESCE(t."secondLastName", '') AS "secondLastName",
        COALESCE(t."firstName", '') AS "firstName",
        COALESCE(t."secondName", '') AS "secondName",
        COALESCE(t."businessName", t."fullName") AS "businessName",
        COALESCE(t.address, '') AS address,
        COALESCE(t.city, '') AS city,
        COALESCE(t.state, '') AS state,
        COALESCE(t.country, 'Colombia') AS country,
        COALESCE(SUM(ji.debit - ji.credit), 0) AS "receivableBalance"
    FROM public."ThirdParty" t
    JOIN public."JournalEntryItem" ji ON ji."thirdPartyId" = t.id
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" <= v_cutoff_date
      AND a.code LIKE '13%'
    GROUP BY t.id, t."documentType", t."documentNumber", t."verificationDigit",
             t."firstLastName", t."secondLastName", t."firstName", t."secondName",
             t."businessName", t."fullName", t.address, t.city, t.state, t.country
    HAVING SUM(ji.debit - ji.credit) > 0
    ORDER BY "receivableBalance" DESC;
END;
$$;


-- --- FUNCION: fnGenerarFormatoExogena1009.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnGenerarFormatoExogena1009 (Saldos CxP a 31 Dic)
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnGenerarFormatoExogena1009";
END $$;

CREATE OR REPLACE FUNCTION public."fnGenerarFormatoExogena1009"(
    p_company_id INTEGER,
    p_year INTEGER
)
RETURNS TABLE (
    "conceptCode" VARCHAR(20),
    "documentType" VARCHAR(10),
    "documentNumber" VARCHAR(50),
    "verificationDigit" VARCHAR(2),
    "firstLastName" VARCHAR(100),
    "secondLastName" VARCHAR(100),
    "firstName" VARCHAR(100),
    "secondName" VARCHAR(100),
    "businessName" VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    "payableBalance" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cutoff_date TIMESTAMP WITH TIME ZONE;
BEGIN
    v_cutoff_date := (p_year::TEXT || '-12-31 23:59:59')::TIMESTAMP WITH TIME ZONE;

    RETURN QUERY
    SELECT 
        '2201'::VARCHAR(20) AS "conceptCode",
        t."documentType",
        t."documentNumber",
        COALESCE(t."verificationDigit", '') AS "verificationDigit",
        COALESCE(t."firstLastName", '') AS "firstLastName",
        COALESCE(t."secondLastName", '') AS "secondLastName",
        COALESCE(t."firstName", '') AS "firstName",
        COALESCE(t."secondName", '') AS "secondName",
        COALESCE(t."businessName", t."fullName") AS "businessName",
        COALESCE(t.address, '') AS address,
        COALESCE(t.city, '') AS city,
        COALESCE(t.state, '') AS state,
        COALESCE(t.country, 'Colombia') AS country,
        COALESCE(SUM(ji.credit - ji.debit), 0) AS "payableBalance"
    FROM public."ThirdParty" t
    JOIN public."JournalEntryItem" ji ON ji."thirdPartyId" = t.id
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" <= v_cutoff_date
      AND a.code LIKE '22%'
    GROUP BY t.id, t."documentType", t."documentNumber", t."verificationDigit",
             t."firstLastName", t."secondLastName", t."firstName", t."secondName",
             t."businessName", t."fullName", t.address, t.city, t.state, t.country
    HAVING SUM(ji.credit - ji.debit) > 0
    ORDER BY "payableBalance" DESC;
END;
$$;


-- --- FUNCION: fnIntegrationEndpointsListar.sql ---
-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- FUNCION: fnIntegrationEndpointsListar
-- DESCRIPCION: Consulta del catálogo de endpoints de integración externa
-- ============================================================================

CREATE OR REPLACE FUNCTION public."fnIntegrationEndpointsListar"(
    p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    "id" INTEGER,
    "code" VARCHAR,
    "systemName" VARCHAR,
    "adapterType" VARCHAR,
    "endpointUrl" VARCHAR,
    "authType" VARCHAR,
    "subscribedEvents" JSONB,
    "isActive" BOOLEAN,
    "createdAt" TIMESTAMP(3)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e."id",
        e."code",
        e."systemName",
        e."adapterType",
        e."endpointUrl",
        e."authType",
        e."subscribedEvents",
        e."isActive",
        e."createdAt"
    FROM public."ExternalIntegrationEndpoint" e
    WHERE (p_is_active IS NULL OR e."isActive" = p_is_active)
    ORDER BY e."systemName" ASC;
END;
$$;


-- --- FUNCION: fnIntegrationTransactionsListar.sql ---
-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- FUNCION: fnIntegrationTransactionsListar
-- DESCRIPCION: Consulta y auditoría de transacciones e intercambios de datos externos
-- ============================================================================

CREATE OR REPLACE FUNCTION public."fnIntegrationTransactionsListar"(
    p_endpoint_code VARCHAR DEFAULT NULL,
    p_direction VARCHAR DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    "id" INTEGER,
    "txCode" VARCHAR,
    "endpointCode" VARCHAR,
    "direction" VARCHAR,
    "eventType" VARCHAR,
    "requestPayload" JSONB,
    "responsePayload" JSONB,
    "httpStatus" INTEGER,
    "durationMs" INTEGER,
    "status" VARCHAR,
    "errorMessage" TEXT,
    "createdAt" TIMESTAMP(3)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t."id",
        t."txCode",
        t."endpointCode",
        t."direction",
        t."eventType",
        t."requestPayload",
        t."responsePayload",
        t."httpStatus",
        t."durationMs",
        t."status",
        t."errorMessage",
        t."createdAt"
    FROM public."IntegrationTransaction" t
    WHERE (p_endpoint_code IS NULL OR t."endpointCode" = p_endpoint_code)
      AND (p_direction IS NULL OR t."direction" = p_direction)
      AND (p_status IS NULL OR t."status" = p_status)
      AND (p_start_date IS NULL OR t."createdAt"::DATE >= p_start_date)
      AND (p_end_date IS NULL OR t."createdAt"::DATE <= p_end_date)
    ORDER BY t."createdAt" DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;


-- --- FUNCION: fnNotasCarteraListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnNotasCarteraListar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnNotasCarteraListar";
END $$;

CREATE OR REPLACE FUNCTION public."fnNotasCarteraListar"(
    p_company_id INTEGER,
    p_note_type VARCHAR(30) DEFAULT NULL,
    p_third_party_id INTEGER DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id INTEGER,
    "noteType" VARCHAR(30),
    "noteNumber" VARCHAR(50),
    "noteDate" TIMESTAMP WITH TIME ZONE,
    "thirdPartyId" INTEGER,
    "thirdPartyName" VARCHAR(255),
    "thirdPartyNit" VARCHAR(50),
    concept TEXT,
    subtotal NUMERIC(18, 4),
    "taxAmount" NUMERIC(18, 4),
    "totalAmount" NUMERIC(18, 4),
    "appliedAmount" NUMERIC(18, 4),
    "balanceAmount" NUMERIC(18, 4),
    status VARCHAR(20),
    "receivableInvoiceId" INTEGER,
    "payableInvoiceId" INTEGER,
    "journalEntryId" INTEGER,
    "journalNumber" VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.id,
        n."noteType",
        n."noteNumber",
        n."noteDate",
        n."thirdPartyId",
        t."fullName" AS "thirdPartyName",
        t."documentNumber" AS "thirdPartyNit",
        n.concept,
        n.subtotal,
        n."taxAmount",
        n."totalAmount",
        n."appliedAmount",
        n."balanceAmount",
        n.status,
        n."receivableInvoiceId",
        n."payableInvoiceId",
        n."journalEntryId",
        j."entryNumber" AS "journalNumber"
    FROM public."CreditDebitNote" n
    JOIN public."ThirdParty" t ON t.id = n."thirdPartyId"
    LEFT JOIN public."JournalEntry" j ON j.id = n."journalEntryId"
    WHERE n."companyId" = p_company_id
      AND (p_note_type IS NULL OR n."noteType" = p_note_type)
      AND (p_third_party_id IS NULL OR n."thirdPartyId" = p_third_party_id)
    ORDER BY n."noteDate" DESC, n.id DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;


-- --- FUNCION: fnPeriodoListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES DE CONSULTA DE PERÍODOS FISCALES (POSTGRESQL)
-- Archivo: SQL/Function/fnPeriodoListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnPeriodoListar"(INT);
END $$;

CREATE OR REPLACE FUNCTION public."fnPeriodoListar"(
    p_year INT DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    year INT,
    month INT,
    "startDate" TIMESTAMP(3),
    "endDate" TIMESTAMP(3),
    status VARCHAR,
    "closedAt" TIMESTAMP(3),
    "closedBy" INT,
    "closedByName" VARCHAR,
    "postedCount" BIGINT,
    "draftCount" BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fp.id,
        fp.year,
        fp.month,
        fp."startDate",
        fp."endDate",
        fp.status,
        fp."closedAt",
        fp."closedBy",
        u.name AS "closedByName",
        COUNT(CASE WHEN j.status = 'POSTED' THEN 1 END) AS "postedCount",
        COUNT(CASE WHEN j.status = 'DRAFT' THEN 1 END) AS "draftCount"
    FROM public."FiscalPeriod" fp
    LEFT JOIN public."User" u ON fp."closedBy" = u.id
    LEFT JOIN public."JournalEntry" j ON 
        EXTRACT(YEAR FROM j."entryDate")::INT = fp.year 
        AND EXTRACT(MONTH FROM j."entryDate")::INT = fp.month
    WHERE (p_year IS NULL OR fp.year = p_year)
    GROUP BY fp.id, fp.year, fp.month, fp."startDate", fp."endDate", fp.status, fp."closedAt", fp."closedBy", u.name
    ORDER BY fp.year DESC, fp.month ASC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnProveedoresEdades.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnProveedoresEdades
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnProveedoresEdades";
END $$;

CREATE OR REPLACE FUNCTION public."fnProveedoresEdades"(
    p_company_id INTEGER,
    p_cutoff_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
)
RETURNS TABLE (
    "thirdPartyId" INTEGER,
    "documentNumber" VARCHAR(50),
    "fullName" VARCHAR(255),
    "currentAmount" NUMERIC(18, 4),      -- Por vencer (corriente)
    "days1To30" NUMERIC(18, 4),          -- Vencido 1 a 30 días
    "days31To60" NUMERIC(18, 4),         -- Vencido 31 a 60 días
    "days61To90" NUMERIC(18, 4),         -- Vencido 61 a 90 días
    "daysOver90" NUMERIC(18, 4),         -- Vencido más de 90 días
    "totalBalance" NUMERIC(18, 4)        -- Total CxP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id AS "thirdPartyId",
        t."documentNumber",
        t."fullName",
        COALESCE(SUM(CASE WHEN p."dueDate" >= p_cutoff_date THEN p."balanceAmount" ELSE 0 END), 0) AS "currentAmount",
        COALESCE(SUM(CASE WHEN p."dueDate" < p_cutoff_date AND (p_cutoff_date::DATE - p."dueDate"::DATE) BETWEEN 1 AND 30 THEN p."balanceAmount" ELSE 0 END), 0) AS "days1To30",
        COALESCE(SUM(CASE WHEN p."dueDate" < p_cutoff_date AND (p_cutoff_date::DATE - p."dueDate"::DATE) BETWEEN 31 AND 60 THEN p."balanceAmount" ELSE 0 END), 0) AS "days31To60",
        COALESCE(SUM(CASE WHEN p."dueDate" < p_cutoff_date AND (p_cutoff_date::DATE - p."dueDate"::DATE) BETWEEN 61 AND 90 THEN p."balanceAmount" ELSE 0 END), 0) AS "days61To90",
        COALESCE(SUM(CASE WHEN p."dueDate" < p_cutoff_date AND (p_cutoff_date::DATE - p."dueDate"::DATE) > 90 THEN p."balanceAmount" ELSE 0 END), 0) AS "daysOver90",
        COALESCE(SUM(p."balanceAmount"), 0) AS "totalBalance"
    FROM public."ThirdParty" t
    JOIN public."PayableInvoice" p ON p."thirdPartyId" = t.id
    WHERE p."companyId" = p_company_id
      AND p.status IN ('POSTED', 'PARTIAL')
      AND p."balanceAmount" > 0
    GROUP BY t.id, t."documentNumber", t."fullName"
    HAVING SUM(p."balanceAmount") > 0
    ORDER BY "totalBalance" DESC;
END;
$$;


-- --- FUNCION: fnProveedoresSaldoTercero.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnProveedoresSaldoTercero
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnProveedoresSaldoTercero";
END $$;

CREATE OR REPLACE FUNCTION public."fnProveedoresSaldoTercero"(
    p_company_id INTEGER,
    p_third_party_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    "thirdPartyId" INTEGER,
    "documentNumber" VARCHAR(50),
    "fullName" VARCHAR(255),
    "totalPurchased" NUMERIC(18, 4),
    "totalPaid" NUMERIC(18, 4),
    "currentBalance" NUMERIC(18, 4),
    "invoicesCount" BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id AS "thirdPartyId",
        t."documentNumber",
        t."fullName",
        COALESCE(SUM(p."totalAmount"), 0) AS "totalPurchased",
        COALESCE(SUM(p."paidAmount"), 0) AS "totalPaid",
        COALESCE(SUM(p."balanceAmount"), 0) AS "currentBalance",
        COUNT(p.id) AS "invoicesCount"
    FROM public."ThirdParty" t
    JOIN public."PayableInvoice" p ON p."thirdPartyId" = t.id
    WHERE p."companyId" = p_company_id
      AND (p_third_party_id IS NULL OR t.id = p_third_party_id)
      AND p.status IN ('POSTED', 'PARTIAL')
    GROUP BY t.id, t."documentNumber", t."fullName"
    ORDER BY "currentBalance" DESC;
END;
$$;


-- --- FUNCION: fnPucListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnPucListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnPucListar"(VARCHAR, INT, BOOLEAN);
END $$;

CREATE OR REPLACE FUNCTION public."fnPucListar"(
    p_search VARCHAR DEFAULT NULL,
    p_level INT DEFAULT NULL,
    p_movement_only BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    code VARCHAR,
    name VARCHAR,
    level INT,
    nature VARCHAR,
    "allowsMovement" BOOLEAN,
    "requiresThirdParty" BOOLEAN,
    "requiresCostCenter" BOOLEAN,
    "parentId" INT,
    "parentCode" VARCHAR,
    "parentName" VARCHAR,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.code,
        a.name,
        a.level,
        a.nature,
        a."allowsMovement",
        a."requiresThirdParty",
        a."requiresCostCenter",
        a."parentId",
        p.code AS "parentCode",
        p.name AS "parentName",
        a."isActive"
    FROM public."Account" a
    LEFT JOIN public."Account" p ON a."parentId" = p.id
    WHERE 
        (p_search IS NULL OR TRIM(p_search) = '' OR (a.code ILIKE '%' || TRIM(p_search) || '%' OR a.name ILIKE '%' || TRIM(p_search) || '%'))
        AND (p_level IS NULL OR a.level = p_level)
        AND (p_movement_only IS NULL OR a."allowsMovement" = p_movement_only)
    ORDER BY a.code ASC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnReporteBalanceGeneral.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteBalanceGeneral
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteBalanceGeneral";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteBalanceGeneral"(
    p_company_id INTEGER,
    p_cutoff_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    p_level INTEGER DEFAULT 3
)
RETURNS TABLE (
    "accountCode" VARCHAR(50),
    "accountName" VARCHAR(255),
    level INTEGER,
    nature VARCHAR(10),
    class VARCHAR(20),
    "totalDebit" NUMERIC(18, 4),
    "totalCredit" NUMERIC(18, 4),
    balance NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH AccountTotals AS (
        SELECT 
            a.code AS acc_code,
            a.name AS acc_name,
            a.level AS acc_level,
            a.nature AS acc_nature,
            CASE 
                WHEN SUBSTRING(a.code, 1, 1) = '1' THEN 'ACTIVO'
                WHEN SUBSTRING(a.code, 1, 1) = '2' THEN 'PASIVO'
                WHEN SUBSTRING(a.code, 1, 1) = '3' THEN 'PATRIMONIO'
                ELSE 'OTRO'
            END AS acc_class,
            COALESCE(SUM(ji.debit), 0) AS deb,
            COALESCE(SUM(ji.credit), 0) AS cred
        FROM public."Account" a
        LEFT JOIN public."Account" child ON child.code LIKE a.code || '%' AND child."allowsMovement" = TRUE
        LEFT JOIN public."JournalEntryItem" ji ON ji."accountId" = child.id
        LEFT JOIN public."JournalEntry" j ON j.id = ji."journalEntryId" 
             AND j."companyId" = p_company_id 
             AND j.status = 'POSTED' 
             AND j."entryDate" <= p_cutoff_date
        WHERE SUBSTRING(a.code, 1, 1) IN ('1', '2', '3')
          AND a.level <= p_level
        GROUP BY a.code, a.name, a.level, a.nature
    )
    SELECT 
        acc_code AS "accountCode",
        acc_name AS "accountName",
        acc_level AS level,
        acc_nature AS nature,
        acc_class AS class,
        deb AS "totalDebit",
        cred AS "totalCredit",
        CASE 
            WHEN acc_nature = 'DEBIT' THEN (deb - cred)
            ELSE (cred - deb)
        END AS balance
    FROM AccountTotals
    WHERE (deb > 0 OR cred > 0)
    ORDER BY acc_code ASC;
END;
$$;


-- --- FUNCION: fnReporteBalancePrueba.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteBalancePrueba
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteBalancePrueba";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteBalancePrueba"(
    p_company_id INTEGER,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_level INTEGER DEFAULT 5
)
RETURNS TABLE (
    "accountCode" VARCHAR(50),
    "accountName" VARCHAR(255),
    level INTEGER,
    nature VARCHAR(10),
    "initialBalance" NUMERIC(18, 4),
    "periodDebit" NUMERIC(18, 4),
    "periodCredit" NUMERIC(18, 4),
    "finalBalance" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH MovementData AS (
        SELECT 
            a.code AS acc_code,
            a.name AS acc_name,
            a.level AS acc_level,
            a.nature AS acc_nature,
            -- Saldo Inicial antes de p_start_date
            COALESCE(SUM(CASE WHEN j."entryDate" < p_start_date THEN ji.debit ELSE 0 END), 0) AS init_deb,
            COALESCE(SUM(CASE WHEN j."entryDate" < p_start_date THEN ji.credit ELSE 0 END), 0) AS init_cred,
            -- Movimientos del período
            COALESCE(SUM(CASE WHEN j."entryDate" BETWEEN p_start_date AND p_end_date THEN ji.debit ELSE 0 END), 0) AS per_deb,
            COALESCE(SUM(CASE WHEN j."entryDate" BETWEEN p_start_date AND p_end_date THEN ji.credit ELSE 0 END), 0) AS per_cred
        FROM public."Account" a
        LEFT JOIN public."Account" child ON child.code LIKE a.code || '%' AND child."allowsMovement" = TRUE
        LEFT JOIN public."JournalEntryItem" ji ON ji."accountId" = child.id
        LEFT JOIN public."JournalEntry" j ON j.id = ji."journalEntryId" 
             AND j."companyId" = p_company_id 
             AND j.status = 'POSTED' 
             AND j."entryDate" <= p_end_date
        WHERE a.level <= p_level
        GROUP BY a.code, a.name, a.level, a.nature
    )
    SELECT 
        acc_code AS "accountCode",
        acc_name AS "accountName",
        acc_level AS level,
        acc_nature AS nature,
        CASE 
            WHEN acc_nature = 'DEBIT' THEN (init_deb - init_cred)
            ELSE (init_cred - init_deb)
        END AS "initialBalance",
        per_deb AS "periodDebit",
        per_cred AS "periodCredit",
        CASE 
            WHEN acc_nature = 'DEBIT' THEN (init_deb - init_cred + per_deb - per_cred)
            ELSE (init_cred - init_deb + per_cred - per_deb)
        END AS "finalBalance"
    FROM MovementData
    WHERE (init_deb > 0 OR init_cred > 0 OR per_deb > 0 OR per_cred > 0)
    ORDER BY acc_code ASC;
END;
$$;


-- --- FUNCION: fnReporteDeclaracionIva.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteDeclaracionIva (Formulario 300)
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteDeclaracionIva";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteDeclaracionIva"(
    p_company_id INTEGER,
    p_year INTEGER,
    p_period_bimonthly INTEGER -- 1 = Ene-Feb, 2 = Mar-Abr, 3 = May-Jun, 4 = Jul-Ago, 5 = Sep-Oct, 6 = Nov-Dic
)
RETURNS TABLE (
    "conceptCode" VARCHAR(50),
    "conceptName" VARCHAR(255),
    "baseAmount" NUMERIC(18, 4),
    "taxAmount" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_month INTEGER;
    v_end_month INTEGER;
    v_start_date TIMESTAMP WITH TIME ZONE;
    v_end_date TIMESTAMP WITH TIME ZONE;
BEGIN
    v_start_month := (p_period_bimonthly * 2) - 1;
    v_end_month := p_period_bimonthly * 2;
    v_start_date := (p_year::TEXT || '-' || LPAD(v_start_month::TEXT, 2, '0') || '-01 00:00:00')::TIMESTAMP WITH TIME ZONE;
    v_end_date := (v_start_date + INTERVAL '2 months' - INTERVAL '1 second');

    RETURN QUERY
    -- 1. Ingresos Gravados al 19%
    SELECT 
        'ING_GRAV_19'::VARCHAR(50) AS "conceptCode",
        'Ingresos por operaciones gravadas a la tarifa general (19%)'::VARCHAR(255) AS "conceptName",
        COALESCE(SUM(ji.credit - ji.debit), 0) AS "baseAmount",
        ROUND(COALESCE(SUM(ji.credit - ji.debit), 0) * 0.19, 4) AS "taxAmount"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '4135%'
    
    UNION ALL

    -- 2. IVA Generado al 19%
    SELECT 
        'IVA_GEN_19'::VARCHAR(50) AS "conceptCode",
        'Impuesto generado a la tarifa general (19%)'::VARCHAR(255) AS "conceptName",
        0::NUMERIC(18, 4) AS "baseAmount",
        COALESCE(SUM(ji.credit - ji.debit), 0) AS "taxAmount"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '240805%'

    UNION ALL

    -- 3. Compras Gravadas al 19% (IVA Descontable)
    SELECT 
        'IVA_DESC_COMPRAS'::VARCHAR(50) AS "conceptCode",
        'Impuesto descontable por compras y servicios gravados al 19%'::VARCHAR(255) AS "conceptName",
        0::NUMERIC(18, 4) AS "baseAmount",
        COALESCE(SUM(ji.debit - ji.credit), 0) AS "taxAmount"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '240810%';
END;
$$;


-- --- FUNCION: fnReporteDeclaracionRetefuente.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteDeclaracionRetefuente (Formulario 350)
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteDeclaracionRetefuente";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteDeclaracionRetefuente"(
    p_company_id INTEGER,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS TABLE (
    "conceptCode" VARCHAR(50),
    "conceptName" VARCHAR(255),
    "baseAmount" NUMERIC(18, 4),
    "withholdingAmount" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_date TIMESTAMP WITH TIME ZONE;
    v_end_date TIMESTAMP WITH TIME ZONE;
BEGIN
    v_start_date := (p_year::TEXT || '-' || LPAD(p_month::TEXT, 2, '0') || '-01 00:00:00')::TIMESTAMP WITH TIME ZONE;
    v_end_date := (v_start_date + INTERVAL '1 month' - INTERVAL '1 second');

    RETURN QUERY
    -- 1. Retefuente por Compras Generales (236540)
    SELECT 
        'RETE_COMPRAS'::VARCHAR(50) AS "conceptCode",
        'Retención en la fuente por compras generales'::VARCHAR(255) AS "conceptName",
        COALESCE(SUM(ji."baseAmount"), 0) AS "baseAmount",
        COALESCE(SUM(ji.credit - ji.debit), 0) AS "withholdingAmount"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '236540%'
    
    UNION ALL

    -- 2. Retefuente por Servicios (236525)
    SELECT 
        'RETE_SERVICIOS'::VARCHAR(50) AS "conceptCode",
        'Retención en la fuente por servicios'::VARCHAR(255) AS "conceptName",
        COALESCE(SUM(ji."baseAmount"), 0) AS "baseAmount",
        COALESCE(SUM(ji.credit - ji.debit), 0) AS "withholdingAmount"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '236525%'

    UNION ALL

    -- 3. Retención de IVA - ReteIVA (236701)
    SELECT 
        'RETE_IVA'::VARCHAR(50) AS "conceptCode",
        'Retención de IVA practicada a responsables'::VARCHAR(255) AS "conceptName",
        COALESCE(SUM(ji."baseAmount"), 0) AS "baseAmount",
        COALESCE(SUM(ji.credit - ji.debit), 0) AS "withholdingAmount"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '2367%';
END;
$$;


-- --- FUNCION: fnReporteEstadoResultados.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteEstadoResultados
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteEstadoResultados";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteEstadoResultados"(
    p_company_id INTEGER,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_level INTEGER DEFAULT 3
)
RETURNS TABLE (
    "accountCode" VARCHAR(50),
    "accountName" VARCHAR(255),
    level INTEGER,
    nature VARCHAR(10),
    category VARCHAR(30),
    "totalDebit" NUMERIC(18, 4),
    "totalCredit" NUMERIC(18, 4),
    netAmount NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH ResultTotals AS (
        SELECT 
            a.code AS acc_code,
            a.name AS acc_name,
            a.level AS acc_level,
            a.nature AS acc_nature,
            CASE 
                WHEN SUBSTRING(a.code, 1, 1) = '4' THEN 'INGRESOS'
                WHEN SUBSTRING(a.code, 1, 1) = '5' THEN 'GASTOS'
                WHEN SUBSTRING(a.code, 1, 1) = '6' THEN 'COSTOS_VENTAS'
                WHEN SUBSTRING(a.code, 1, 1) = '7' THEN 'COSTOS_PRODUCCION'
                ELSE 'OTRO'
            END AS acc_cat,
            COALESCE(SUM(ji.debit), 0) AS deb,
            COALESCE(SUM(ji.credit), 0) AS cred
        FROM public."Account" a
        LEFT JOIN public."Account" child ON child.code LIKE a.code || '%' AND child."allowsMovement" = TRUE
        LEFT JOIN public."JournalEntryItem" ji ON ji."accountId" = child.id
        LEFT JOIN public."JournalEntry" j ON j.id = ji."journalEntryId" 
             AND j."companyId" = p_company_id 
             AND j.status = 'POSTED' 
             AND j."entryDate" BETWEEN p_start_date AND p_end_date
        WHERE SUBSTRING(a.code, 1, 1) IN ('4', '5', '6', '7')
          AND a.level <= p_level
        GROUP BY a.code, a.name, a.level, a.nature
    )
    SELECT 
        acc_code AS "accountCode",
        acc_name AS "accountName",
        acc_level AS level,
        acc_nature AS nature,
        acc_cat AS category,
        deb AS "totalDebit",
        cred AS "totalCredit",
        CASE 
            WHEN SUBSTRING(acc_code, 1, 1) = '4' THEN (cred - deb)
            ELSE (deb - cred)
        END AS netAmount
    FROM ResultTotals
    WHERE (deb > 0 OR cred > 0)
    ORDER BY acc_code ASC;
END;
$$;


-- --- FUNCION: fnReporteLibroAuxiliar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteLibroAuxiliar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteLibroAuxiliar";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteLibroAuxiliar"(
    p_company_id INTEGER,
    p_account_id INTEGER,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_third_party_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    "entryDate" TIMESTAMP WITH TIME ZONE,
    "entryNumber" VARCHAR(50),
    "documentReference" VARCHAR(50),
    "thirdPartyNit" VARCHAR(50),
    "thirdPartyName" VARCHAR(255),
    description TEXT,
    debit NUMERIC(18, 4),
    credit NUMERIC(18, 4),
    "runningBalance" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nature VARCHAR(10);
    v_initial_balance NUMERIC(18, 4);
BEGIN
    SELECT nature INTO v_nature FROM public."Account" WHERE id = p_account_id;

    -- Saldo inicial
    SELECT 
        CASE 
            WHEN v_nature = 'DEBIT' THEN COALESCE(SUM(ji.debit - ji.credit), 0)
            ELSE COALESCE(SUM(ji.credit - ji.debit), 0)
        END INTO v_initial_balance
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    WHERE ji."accountId" = p_account_id
      AND j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" < p_start_date
      AND (p_third_party_id IS NULL OR ji."thirdPartyId" = p_third_party_id);

    RETURN QUERY
    SELECT 
        j."entryDate",
        j."entryNumber",
        ji."documentReference",
        t."documentNumber" AS "thirdPartyNit",
        t."fullName" AS "thirdPartyName",
        COALESCE(ji.description, j.concept) AS description,
        ji.debit,
        ji.credit,
        COALESCE(v_initial_balance, 0) + SUM(
            CASE 
                WHEN v_nature = 'DEBIT' THEN (ji.debit - ji.credit)
                ELSE (ji.credit - ji.debit)
            END
        ) OVER (ORDER BY j."entryDate" ASC, j.id ASC, ji.id ASC) AS "runningBalance"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    LEFT JOIN public."ThirdParty" t ON t.id = ji."thirdPartyId"
    WHERE ji."accountId" = p_account_id
      AND j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN p_start_date AND p_end_date
      AND (p_third_party_id IS NULL OR ji."thirdPartyId" = p_third_party_id)
    ORDER BY j."entryDate" ASC, j.id ASC, ji.id ASC;
END;
$$;


-- --- FUNCION: fnReporteLibroDiario.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteLibroDiario
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteLibroDiario";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteLibroDiario"(
    p_company_id INTEGER,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    "entryDate" TIMESTAMP WITH TIME ZONE,
    "entryNumber" VARCHAR(50),
    concept TEXT,
    "accountCode" VARCHAR(50),
    "accountName" VARCHAR(255),
    "thirdPartyNit" VARCHAR(50),
    "thirdPartyName" VARCHAR(255),
    debit NUMERIC(18, 4),
    credit NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        j."entryDate",
        j."entryNumber",
        j.concept,
        a.code AS "accountCode",
        a.name AS "accountName",
        t."documentNumber" AS "thirdPartyNit",
        t."fullName" AS "thirdPartyName",
        ji.debit,
        ji.credit
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    LEFT JOIN public."ThirdParty" t ON t.id = ji."thirdPartyId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN p_start_date AND p_end_date
    ORDER BY j."entryDate" ASC, j.id ASC, ji.id ASC;
END;
$$;


-- --- FUNCION: fnReporteLibroMayor.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteLibroMayor
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteLibroMayor";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteLibroMayor"(
    p_company_id INTEGER,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS TABLE (
    "accountCode" VARCHAR(50),
    "accountName" VARCHAR(255),
    "initialDebit" NUMERIC(18, 4),
    "initialCredit" NUMERIC(18, 4),
    "monthlyDebit" NUMERIC(18, 4),
    "monthlyCredit" NUMERIC(18, 4),
    "finalDebit" NUMERIC(18, 4),
    "finalCredit" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_date TIMESTAMP WITH TIME ZONE;
    v_end_date TIMESTAMP WITH TIME ZONE;
BEGIN
    v_start_date := (p_year::TEXT || '-' || LPAD(p_month::TEXT, 2, '0') || '-01 00:00:00')::TIMESTAMP WITH TIME ZONE;
    v_end_date := (v_start_date + INTERVAL '1 month' - INTERVAL '1 second');

    RETURN QUERY
    WITH AccountMovements AS (
        SELECT 
            a.code AS acc_code,
            a.name AS acc_name,
            a.nature AS acc_nature,
            -- Antes del mes
            COALESCE(SUM(CASE WHEN j."entryDate" < v_start_date THEN ji.debit ELSE 0 END), 0) AS pre_deb,
            COALESCE(SUM(CASE WHEN j."entryDate" < v_start_date THEN ji.credit ELSE 0 END), 0) AS pre_cred,
            -- Durante el mes
            COALESCE(SUM(CASE WHEN j."entryDate" BETWEEN v_start_date AND v_end_date THEN ji.debit ELSE 0 END), 0) AS m_deb,
            COALESCE(SUM(CASE WHEN j."entryDate" BETWEEN v_start_date AND v_end_date THEN ji.credit ELSE 0 END), 0) AS m_cred
        FROM public."Account" a
        LEFT JOIN public."Account" child ON child.code LIKE a.code || '%' AND child."allowsMovement" = TRUE
        LEFT JOIN public."JournalEntryItem" ji ON ji."accountId" = child.id
        LEFT JOIN public."JournalEntry" j ON j.id = ji."journalEntryId" 
             AND j."companyId" = p_company_id 
             AND j.status = 'POSTED' 
             AND j."entryDate" <= v_end_date
        WHERE a.level = 3 -- Cuentas de Mayor (4 dígitos)
        GROUP BY a.code, a.name, a.nature
    )
    SELECT 
        acc_code AS "accountCode",
        acc_name AS "accountName",
        CASE WHEN (pre_deb - pre_cred) > 0 THEN (pre_deb - pre_cred) ELSE 0 END AS "initialDebit",
        CASE WHEN (pre_cred - pre_deb) > 0 THEN (pre_cred - pre_deb) ELSE 0 END AS "initialCredit",
        m_deb AS "monthlyDebit",
        m_cred AS "monthlyCredit",
        CASE WHEN ((pre_deb + m_deb) - (pre_cred + m_cred)) > 0 THEN ((pre_deb + m_deb) - (pre_cred + m_cred)) ELSE 0 END AS "finalDebit",
        CASE WHEN ((pre_cred + m_cred) - (pre_deb + m_deb)) > 0 THEN ((pre_cred + m_cred) - (pre_deb + m_deb)) ELSE 0 END AS "finalCredit"
    FROM AccountMovements
    WHERE (pre_deb > 0 OR pre_cred > 0 OR m_deb > 0 OR m_cred > 0)
    ORDER BY acc_code ASC;
END;
$$;


-- --- FUNCION: fnTaxConceptListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnTaxConceptListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnTaxConceptListar"();
END $$;

CREATE OR REPLACE FUNCTION public."fnTaxConceptListar"()
RETURNS TABLE (
    id INT,
    code VARCHAR,
    name VARCHAR,
    type VARCHAR,
    "ratePercentage" NUMERIC,
    "minimumBaseAmount" NUMERIC,
    "accountDebitId" INT,
    "accountDebitCode" VARCHAR,
    "accountDebitName" VARCHAR,
    "accountCreditId" INT,
    "accountCreditCode" VARCHAR,
    "accountCreditName" VARCHAR,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.code,
        t.name,
        t.type,
        t."ratePercentage",
        t."minimumBaseAmount",
        t."accountDebitId",
        ad.code AS "accountDebitCode",
        ad.name AS "accountDebitName",
        t."accountCreditId",
        ac.code AS "accountCreditCode",
        ac.name AS "accountCreditName",
        t."isActive"
    FROM public."TaxConcept" t
    LEFT JOIN public."Account" ad ON t."accountDebitId" = ad.id
    LEFT JOIN public."Account" ac ON t."accountCreditId" = ac.id
    ORDER BY t.code ASC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnTesoreriaMovimientosListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES DE CONSULTA DE TESORERÍA (POSTGRESQL)
-- Archivo: SQL/Function/fnTesoreriaMovimientosListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnTesoreriaMovimientosListar"(INT, VARCHAR, TIMESTAMP(3), TIMESTAMP(3), INT, INT, VARCHAR, VARCHAR);
END $$;

CREATE OR REPLACE FUNCTION public."fnTesoreriaMovimientosListar"(
    p_company_id INT DEFAULT NULL,
    p_type VARCHAR DEFAULT NULL, -- 'INGRESO', 'EGRESO', 'TRANSFERENCIA'
    p_start_date TIMESTAMP(3) DEFAULT NULL,
    p_end_date TIMESTAMP(3) DEFAULT NULL,
    p_bank_account_id INT DEFAULT NULL,
    p_cash_box_id INT DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL,
    p_search VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    "companyId" INT,
    "movementType" VARCHAR,
    "documentTypeId" INT,
    "documentTypeCode" VARCHAR,
    "documentTypeName" VARCHAR,
    "consecutiveNumber" INT,
    "entryNumber" VARCHAR,
    "movementDate" TIMESTAMP(3),
    "bankAccountId" INT,
    "bankName" VARCHAR,
    "bankAccountNumber" VARCHAR,
    "cashBoxId" INT,
    "cashBoxName" VARCHAR,
    "thirdPartyId" INT,
    "thirdPartyDoc" VARCHAR,
    "thirdPartyName" VARCHAR,
    concept VARCHAR,
    "paymentMethod" VARCHAR,
    "checkNumber" VARCHAR,
    "totalAmount" NUMERIC,
    status VARCHAR,
    "journalEntryId" INT,
    "createdById" INT,
    "createdByName" VARCHAR,
    "createdAt" TIMESTAMP(3)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tm.id,
        tm."companyId",
        tm."movementType",
        tm."documentTypeId",
        dt.code AS "documentTypeCode",
        dt.name AS "documentTypeName",
        tm."consecutiveNumber",
        tm."entryNumber",
        tm."movementDate",
        tm."bankAccountId",
        b.name AS "bankName",
        ba."accountNumber" AS "bankAccountNumber",
        tm."cashBoxId",
        cb.name AS "cashBoxName",
        tm."thirdPartyId",
        tp."documentNumber" AS "thirdPartyDoc",
        tp."fullName" AS "thirdPartyName",
        tm.concept,
        tm."paymentMethod",
        tm."checkNumber",
        tm."totalAmount",
        tm.status,
        tm."journalEntryId",
        tm."createdById",
        u.name AS "createdByName",
        tm."createdAt"
    FROM public."TreasuryMovement" tm
    INNER JOIN public."DocumentType" dt ON tm."documentTypeId" = dt.id
    LEFT JOIN public."BankAccount" ba ON tm."bankAccountId" = ba.id
    LEFT JOIN public."Bank" b ON ba."bankId" = b.id
    LEFT JOIN public."CashBox" cb ON tm."cashBoxId" = cb.id
    LEFT JOIN public."ThirdParty" tp ON tm."thirdPartyId" = tp.id
    LEFT JOIN public."User" u ON tm."createdById" = u.id
    WHERE 
        (p_company_id IS NULL OR tm."companyId" = p_company_id)
        AND (p_type IS NULL OR tm."movementType" = p_type)
        AND (p_start_date IS NULL OR tm."movementDate" >= p_start_date)
        AND (p_end_date IS NULL OR tm."movementDate" <= p_end_date)
        AND (p_bank_account_id IS NULL OR tm."bankAccountId" = p_bank_account_id)
        AND (p_cash_box_id IS NULL OR tm."cashBoxId" = p_cash_box_id)
        AND (p_status IS NULL OR tm.status = p_status)
        AND (
            p_search IS NULL OR TRIM(p_search) = ''
            OR tm."entryNumber" ILIKE '%' || TRIM(p_search) || '%'
            OR tm.concept ILIKE '%' || TRIM(p_search) || '%'
            OR (tp."fullName" IS NOT NULL AND tp."fullName" ILIKE '%' || TRIM(p_search) || '%')
        )
    ORDER BY tm."movementDate" DESC, tm.id DESC;
END;
$$ LANGUAGE plpgsql;


-- --- FUNCION: fnThirdPartyListar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES SQL DE LISTADO MAESTROS (POSTGRESQL)
-- Archivo: SQL/Function/fnThirdPartyListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnThirdPartyListar"(VARCHAR, VARCHAR, BOOLEAN);
END $$;

CREATE OR REPLACE FUNCTION public."fnThirdPartyListar"(
    p_search VARCHAR DEFAULT NULL,
    p_role_filter VARCHAR DEFAULT NULL, -- 'CUSTOMER', 'SUPPLIER', 'EMPLOYEE', 'PARTNER'
    p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    "documentType" VARCHAR,
    "documentNumber" VARCHAR,
    "verificationDigit" VARCHAR,
    "businessName" VARCHAR,
    "firstName" VARCHAR,
    "firstLastName" VARCHAR,
    "fullName" VARCHAR,
    "personType" VARCHAR,
    address VARCHAR,
    city VARCHAR,
    phone VARCHAR,
    email VARCHAR,
    "isCustomer" BOOLEAN,
    "isSupplier" BOOLEAN,
    "isEmployee" BOOLEAN,
    "isPartner" BOOLEAN,
    "isOther" BOOLEAN,
    "taxRegime" VARCHAR,
    "isActive" BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t."documentType",
        t."documentNumber",
        t."verificationDigit",
        t."businessName",
        t."firstName",
        t."firstLastName",
        t."fullName",
        t."personType",
        t.address,
        t.city,
        t.phone,
        t.email,
        t."isCustomer",
        t."isSupplier",
        t."isEmployee",
        t."isPartner",
        t."isOther",
        t."taxRegime",
        t."isActive"
    FROM public."ThirdParty" t
    WHERE 
        (p_search IS NULL OR TRIM(p_search) = '' OR (t."documentNumber" ILIKE '%' || TRIM(p_search) || '%' OR t."fullName" ILIKE '%' || TRIM(p_search) || '%'))
        AND (p_is_active IS NULL OR t."isActive" = p_is_active)
        AND (
            p_role_filter IS NULL 
            OR (p_role_filter = 'CUSTOMER' AND t."isCustomer" = true)
            OR (p_role_filter = 'SUPPLIER' AND t."isSupplier" = true)
            OR (p_role_filter = 'EMPLOYEE' AND t."isEmployee" = true)
            OR (p_role_filter = 'PARTNER' AND t."isPartner" = true)
        )
    ORDER BY t."fullName" ASC;
END;
$$ LANGUAGE plpgsql;


-- --- PROCEDIMIENTO: spActivoFijoBajaRegistrar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spActivoFijoBajaRegistrar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spActivoFijoBajaRegistrar";
END $$;

CREATE OR REPLACE PROCEDURE public."spActivoFijoBajaRegistrar"(
    IN p_fixed_asset_id INTEGER,
    IN p_disposal_type VARCHAR(30),
    IN p_sale_price NUMERIC(18, 4),
    IN p_account_sale_income_id INTEGER,
    IN p_reason TEXT,
    IN p_created_by_id INTEGER,
    OUT p_disposal_id INTEGER,
    OUT p_net_gain_loss NUMERIC(18, 4),
    OUT p_journal_entry_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INTEGER;
    v_category_id INTEGER;
    v_account_asset_id INTEGER;
    v_account_accum_depr_id INTEGER;
    v_cost_center_id INTEGER;
    v_cost NUMERIC(18, 4);
    v_accum NUMERIC(18, 4);
    v_net_value NUMERIC(18, 4);
    v_sale NUMERIC(18, 4);
    v_code VARCHAR(50);
BEGIN
    SELECT a."companyId", a."categoryId", a."acquisitionCost", a."accumulatedDepreciation",
           a."netBookValue", a."costCenterId", a.code,
           c."accountAssetId", c."accountAccumDeprId"
    INTO v_company_id, v_category_id, v_cost, v_accum, v_net_value, v_cost_center_id, v_code, v_account_asset_id, v_account_accum_depr_id
    FROM public."FixedAsset" a
    JOIN public."FixedAssetCategory" c ON c.id = a."categoryId"
    WHERE a.id = p_fixed_asset_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Activo fijo con ID % no encontrado', p_fixed_asset_id;
    END IF;

    v_sale := COALESCE(p_sale_price, 0);
    -- Utilidad o Pérdida = Precio Venta - Valor Neto en Libros
    p_net_gain_loss := v_sale - v_net_value;

    -- Generar comprobante contable de baja / enajenación (Partida Doble)
    INSERT INTO public."JournalEntry"(
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber", "entryDate",
        concept, observation, "totalDebit", "totalCredit", status, "createdById", "postedAt"
    ) VALUES (
        v_company_id, 1, 1, 'AF-BAJA-' || v_code || '-' || EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::BIGINT, CURRENT_TIMESTAMP,
        'Baja/Venta de Activo Fijo ' || v_code, p_reason,
        v_cost + CASE WHEN p_net_gain_loss > 0 THEN p_net_gain_loss ELSE 0 END,
        v_cost + CASE WHEN p_net_gain_loss > 0 THEN p_net_gain_loss ELSE 0 END,
        'POSTED', p_created_by_id, CURRENT_TIMESTAMP
    ) RETURNING id INTO p_journal_entry_id;

    -- Débito: Cancelación de Depreciación Acumulada (1592xx)
    IF v_accum > 0 THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, v_account_accum_depr_id, v_cost_center_id, v_accum, 0, 'Cancelación Depr Acum ' || v_code, v_code);
    END IF;

    -- Débito: Ingreso de Fondos por Venta (si hubo venta)
    IF v_sale > 0 AND p_account_sale_income_id IS NOT NULL THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_sale_income_id, v_cost_center_id, v_sale, 0, 'Recaudo Venta Activo ' || v_code, v_code);
    END IF;

    -- Débito: Pérdida en Retiro/Venta de Activos Fijos (si aplica)
    IF p_net_gain_loss < 0 THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, (SELECT id FROM public."Account" WHERE code = '531015' LIMIT 1), v_cost_center_id, ABS(p_net_gain_loss), 0, 'Pérdida en Retiro Activo ' || v_code, v_code);
    END IF;

    -- Crédito: Cancelación del Costo Histórico del Activo (15xx)
    INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
    VALUES (p_journal_entry_id, v_account_asset_id, v_cost_center_id, 0, v_cost, 'Cancelación Costo Activo ' || v_code, v_code);

    -- Crédito: Utilidad en Venta de Activos Fijos (si aplica)
    IF p_net_gain_loss > 0 THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, (SELECT id FROM public."Account" WHERE code = '424515' LIMIT 1), v_cost_center_id, 0, p_net_gain_loss, 'Utilidad en Venta Activo ' || v_code, v_code);
    END IF;

    -- Insertar registro de baja
    INSERT INTO public."FixedAssetDisposal"(
        "fixedAssetId", "disposalDate", "disposalType", "salePrice",
        "acquisitionCostAtDisposal", "accumulatedDeprAtDisposal", "netGainLoss",
        "journalEntryId", reason, "createdById"
    ) VALUES (
        p_fixed_asset_id, CURRENT_TIMESTAMP, p_disposal_type, v_sale,
        v_cost, v_accum, p_net_gain_loss,
        p_journal_entry_id, p_reason, p_created_by_id
    ) RETURNING id INTO p_disposal_id;

    -- Actualizar estado del Activo Fijo
    UPDATE public."FixedAsset"
    SET status = CASE WHEN p_disposal_type = 'VENTA' THEN 'SOLD' ELSE 'DISPOSED' END,
        "netBookValue" = 0,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_fixed_asset_id;
END;
$$;


-- --- PROCEDIMIENTO: spActivoFijoCategoriaGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spActivoFijoCategoriaGuardar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spActivoFijoCategoriaGuardar";
END $$;

CREATE OR REPLACE PROCEDURE public."spActivoFijoCategoriaGuardar"(
    IN p_id INTEGER,
    IN p_code VARCHAR(50),
    IN p_name VARCHAR(100),
    IN p_default_life_months INTEGER,
    IN p_account_asset_id INTEGER,
    IN p_account_accum_depr_id INTEGER,
    IN p_account_expense_depr_id INTEGER,
    IN p_is_active BOOLEAN,
    OUT p_out_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."FixedAssetCategory"(
            code, name, "defaultUsefulLifeMonths", "accountAssetId",
            "accountAccumDeprId", "accountExpenseDeprId", "isActive"
        ) VALUES (
            p_code, p_name, COALESCE(p_default_life_months, 60), p_account_asset_id,
            p_account_accum_depr_id, p_account_expense_depr_id, COALESCE(p_is_active, TRUE)
        ) RETURNING id INTO p_out_id;
    ELSE
        UPDATE public."FixedAssetCategory"
        SET code = p_code,
            name = p_name,
            "defaultUsefulLifeMonths" = COALESCE(p_default_life_months, 60),
            "accountAssetId" = p_account_asset_id,
            "accountAccumDeprId" = p_account_accum_depr_id,
            "accountExpenseDeprId" = p_account_expense_depr_id,
            "isActive" = COALESCE(p_is_active, TRUE),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
        p_out_id := p_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spActivoFijoDepreciarPeriodo.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spActivoFijoDepreciarPeriodo
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spActivoFijoDepreciarPeriodo";
END $$;

CREATE OR REPLACE PROCEDURE public."spActivoFijoDepreciarPeriodo"(
    IN p_company_id INTEGER,
    IN p_year INTEGER,
    IN p_month INTEGER,
    IN p_created_by_id INTEGER,
    OUT p_total_depreciation NUMERIC(18, 4),
    OUT p_assets_processed INTEGER,
    OUT p_journal_entry_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_period_status VARCHAR(20);
    v_doc_type_id INTEGER;
    v_consecutive INTEGER;
    v_entry_number VARCHAR(50);
    v_period_date TIMESTAMP WITH TIME ZONE;
    r_asset RECORD;
    r_cat RECORD;
    v_asset_depr NUMERIC(18, 4);
    v_new_accum NUMERIC(18, 4);
    v_new_net NUMERIC(18, 4);
    v_depr_id INTEGER;
BEGIN
    -- Validar período abierto
    SELECT status INTO v_period_status FROM public."FiscalPeriod" WHERE year = p_year AND month = p_month;
    IF v_period_status = 'CLOSED' THEN
        RAISE EXCEPTION '❌ No se puede ejecutar depreciación en un período fiscal cerrado (% - %)', p_year, p_month;
    END IF;

    -- Verificar si ya fue depreciado el período
    IF EXISTS (
        SELECT 1 FROM public."FixedAssetDepreciation" d
        JOIN public."FixedAsset" a ON a.id = d."fixedAssetId"
        WHERE a."companyId" = p_company_id AND d.year = p_year AND d.month = p_month
    ) THEN
        RAISE EXCEPTION '❌ El período % - % ya cuenta con depreciación ejecutada para esta empresa', p_year, p_month;
    END IF;

    -- Document Type para Depreciación (DP o CC)
    SELECT id INTO v_doc_type_id FROM public."DocumentType" WHERE code = 'DP';
    IF v_doc_type_id IS NULL THEN
        SELECT id INTO v_doc_type_id FROM public."DocumentType" WHERE code = 'CC' LIMIT 1;
    END IF;

    -- Consecutivo
    SELECT "currentNumber" INTO v_consecutive 
    FROM public."Consecutive"
    WHERE "documentTypeId" = v_doc_type_id AND "fiscalYear" = p_year
    FOR UPDATE;

    IF v_consecutive IS NULL THEN
        v_consecutive := 1;
        INSERT INTO public."Consecutive"("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (v_doc_type_id, 'DP', 2, 1, p_year, TRUE);
    ELSE
        UPDATE public."Consecutive" SET "currentNumber" = v_consecutive + 1 WHERE "documentTypeId" = v_doc_type_id AND "fiscalYear" = p_year;
    END IF;

    v_entry_number := 'DP-' || p_year::TEXT || '-' || LPAD(p_month::TEXT, 2, '0') || '-' || LPAD(v_consecutive::TEXT, 4, '0');
    v_period_date := (p_year::TEXT || '-' || LPAD(p_month::TEXT, 2, '0') || '-28 23:59:59')::TIMESTAMP WITH TIME ZONE;

    p_total_depreciation := 0;
    p_assets_processed := 0;

    -- Crear Comprobante Contable de Depreciación (Borrador inicial)
    INSERT INTO public."JournalEntry"(
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber", "entryDate",
        concept, observation, "totalDebit", "totalCredit", status, "createdById", "postedAt"
    ) VALUES (
        p_company_id, v_doc_type_id, v_consecutive, v_entry_number, v_period_date,
        'Depreciación de Activos Fijos ' || p_year::TEXT || '-' || LPAD(p_month::TEXT, 2, '0'),
        'Depreciación periódica NIIF en línea recta', 0, 0, 'POSTED', p_created_by_id, CURRENT_TIMESTAMP
    ) RETURNING id INTO p_journal_entry_id;

    -- Iterar activos fijos activos
    FOR r_asset IN (
        SELECT a.id, a."acquisitionCost", a."residualValue", a."usefulLifeMonths",
               a."depreciatedMonths", a."accumulatedDepreciation", a."monthlyDepreciation",
               c."accountExpenseDeprId", c."accountAccumDeprId", a."costCenterId", a.code, a.name
        FROM public."FixedAsset" a
        JOIN public."FixedAssetCategory" c ON c.id = a."categoryId"
        WHERE a."companyId" = p_company_id
          AND a.status = 'ACTIVE'
          AND a."depreciatedMonths" < a."usefulLifeMonths"
    ) LOOP
        -- Cuota mensual no puede superar el saldo por depreciar
        v_asset_depr := LEAST(r_asset."monthlyDepreciation", (r_asset."acquisitionCost" - r_asset."residualValue" - r_asset."accumulatedDepreciation"));
        
        IF v_asset_depr > 0 THEN
            v_new_accum := r_asset."accumulatedDepreciation" + v_asset_depr;
            v_new_net := r_asset."acquisitionCost" - v_new_accum;

            -- Registrar cuota individual
            INSERT INTO public."FixedAssetDepreciation"(
                "fixedAssetId", year, month, amount, "accumulatedAmount", "netBookValue", "journalEntryId"
            ) VALUES (
                r_asset.id, p_year, p_month, v_asset_depr, v_new_accum, v_new_net, p_journal_entry_id
            );

            -- Actualizar Activo Fijo
            UPDATE public."FixedAsset"
            SET "accumulatedDepreciation" = v_new_accum,
                "depreciatedMonths" = "depreciatedMonths" + 1,
                "netBookValue" = v_new_net,
                status = CASE WHEN "depreciatedMonths" + 1 >= "usefulLifeMonths" THEN 'FULLY_DEPRECIATED' ELSE 'ACTIVE' END,
                "updatedAt" = CURRENT_TIMESTAMP
            WHERE id = r_asset.id;

            -- Detalle Débito: Gasto Depreciación (5160xx)
            INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
            VALUES (p_journal_entry_id, r_asset."accountExpenseDeprId", r_asset."costCenterId", v_asset_depr, 0, 'Gasto Depreciación ' || r_asset.code || ' ' || r_asset.name, r_asset.code);

            -- Detalle Crédito: Depreciación Acumulada (1592xx)
            INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
            VALUES (p_journal_entry_id, r_asset."accountAccumDeprId", r_asset."costCenterId", 0, v_asset_depr, 'Deprec Acumulada ' || r_asset.code || ' ' || r_asset.name, r_asset.code);

            p_total_depreciation := p_total_depreciation + v_asset_depr;
            p_assets_processed := p_assets_processed + 1;
        END IF;
    END LOOP;

    -- Actualizar totales del comprobante contable
    UPDATE public."JournalEntry"
    SET "totalDebit" = p_total_depreciation,
        "totalCredit" = p_total_depreciation
    WHERE id = p_journal_entry_id;
END;
$$;


-- --- PROCEDIMIENTO: spActivoFijoGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spActivoFijoGuardar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spActivoFijoGuardar";
END $$;

CREATE OR REPLACE PROCEDURE public."spActivoFijoGuardar"(
    IN p_id INTEGER,
    IN p_company_id INTEGER,
    IN p_category_id INTEGER,
    IN p_code VARCHAR(50),
    IN p_name VARCHAR(150),
    IN p_description TEXT,
    IN p_serial_number VARCHAR(100),
    IN p_purchase_date TIMESTAMP WITH TIME ZONE,
    IN p_activation_date TIMESTAMP WITH TIME ZONE,
    IN p_acquisition_cost NUMERIC(18, 4),
    IN p_residual_value NUMERIC(18, 4),
    IN p_useful_life_months INTEGER,
    IN p_cost_center_id INTEGER,
    IN p_responsible_third_party_id INTEGER,
    IN p_location VARCHAR(150),
    IN p_created_by_id INTEGER,
    OUT p_out_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_monthly_depr NUMERIC(18, 4);
    v_net_value NUMERIC(18, 4);
BEGIN
    IF COALESCE(p_useful_life_months, 0) <= 0 THEN
        RAISE EXCEPTION '❌ La vida útil en meses debe ser mayor a cero';
    END IF;

    -- Cálculo mensual de línea recta: (Costo - Valor Residual) / Vida Útil en meses
    v_monthly_depr := ROUND((COALESCE(p_acquisition_cost, 0) - COALESCE(p_residual_value, 0)) / p_useful_life_months, 4);
    v_net_value := COALESCE(p_acquisition_cost, 0);

    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."FixedAsset"(
            "companyId", "categoryId", code, name, description, "serialNumber",
            "purchaseDate", "activationDate", "acquisitionCost", "residualValue",
            "usefulLifeMonths", "depreciatedMonths", "accumulatedDepreciation",
            "netBookValue", "monthlyDepreciation", "costCenterId",
            "responsibleThirdPartyId", location, status, "createdById"
        ) VALUES (
            p_company_id, p_category_id, p_code, p_name, p_description, p_serial_number,
            p_purchase_date, p_activation_date, p_acquisition_cost, COALESCE(p_residual_value, 0),
            p_useful_life_months, 0, 0,
            v_net_value, v_monthly_depr, p_cost_center_id,
            p_responsible_third_party_id, p_location, 'ACTIVE', p_created_by_id
        ) RETURNING id INTO p_out_id;
    ELSE
        UPDATE public."FixedAsset"
        SET "categoryId" = p_category_id,
            code = p_code,
            name = p_name,
            description = p_description,
            "serialNumber" = p_serial_number,
            "purchaseDate" = p_purchase_date,
            "activationDate" = p_activation_date,
            "acquisitionCost" = p_acquisition_cost,
            "residualValue" = COALESCE(p_residual_value, 0),
            "usefulLifeMonths" = p_useful_life_months,
            "monthlyDepreciation" = v_monthly_depr,
            "netBookValue" = p_acquisition_cost - "accumulatedDepreciation",
            "costCenterId" = p_cost_center_id,
            "responsibleThirdPartyId" = p_responsible_third_party_id,
            location = p_location,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
        p_out_id := p_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spActivoFijoMejoraRegistrar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spActivoFijoMejoraRegistrar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spActivoFijoMejoraRegistrar";
END $$;

CREATE OR REPLACE PROCEDURE public."spActivoFijoMejoraRegistrar"(
    IN p_fixed_asset_id INTEGER,
    IN p_description TEXT,
    IN p_amount NUMERIC(18, 4),
    IN p_additional_months INTEGER,
    IN p_account_counterpart_id INTEGER,
    IN p_created_by_id INTEGER,
    OUT p_improvement_id INTEGER,
    OUT p_journal_entry_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INTEGER;
    v_category_id INTEGER;
    v_account_asset_id INTEGER;
    v_cost_center_id INTEGER;
    v_cost NUMERIC(18, 4);
    v_accum NUMERIC(18, 4);
    v_res NUMERIC(18, 4);
    v_life INTEGER;
    v_depr_months INTEGER;
    v_new_cost NUMERIC(18, 4);
    v_new_life INTEGER;
    v_new_monthly NUMERIC(18, 4);
    v_code VARCHAR(50);
BEGIN
    SELECT a."companyId", a."categoryId", a."acquisitionCost", a."accumulatedDepreciation",
           a."residualValue", a."usefulLifeMonths", a."depreciatedMonths", a."costCenterId", a.code,
           c."accountAssetId"
    INTO v_company_id, v_category_id, v_cost, v_accum, v_res, v_life, v_depr_months, v_cost_center_id, v_code, v_account_asset_id
    FROM public."FixedAsset" a
    JOIN public."FixedAssetCategory" c ON c.id = a."categoryId"
    WHERE a.id = p_fixed_asset_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Activo fijo con ID % no encontrado', p_fixed_asset_id;
    END IF;

    IF COALESCE(p_amount, 0) <= 0 THEN
        RAISE EXCEPTION '❌ El monto de la mejora capitalizable debe ser mayor a cero';
    END IF;

    v_new_cost := v_cost + p_amount;
    v_new_life := v_life + COALESCE(p_additional_months, 0);
    
    -- Recalcular cuota mensual para los meses restantes
    IF (v_new_life - v_depr_months) > 0 THEN
        v_new_monthly := ROUND((v_new_cost - v_res - v_accum) / (v_new_life - v_depr_months), 4);
    ELSE
        v_new_monthly := 0;
    END IF;

    -- Generar comprobante contable de adición / mejora (Partida Doble)
    INSERT INTO public."JournalEntry"(
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber", "entryDate",
        concept, observation, "totalDebit", "totalCredit", status, "createdById", "postedAt"
    ) VALUES (
        v_company_id, 1, 1, 'AF-MEJ-' || v_code || '-' || EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::BIGINT, CURRENT_TIMESTAMP,
        'Mejora Capitalizable Activo ' || v_code, p_description,
        p_amount, p_amount, 'POSTED', p_created_by_id, CURRENT_TIMESTAMP
    ) RETURNING id INTO p_journal_entry_id;

    -- Débito: Cuenta Activo Fijo (15xx)
    INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
    VALUES (p_journal_entry_id, v_account_asset_id, v_cost_center_id, p_amount, 0, 'Adición/Mejora ' || v_code, v_code);

    -- Crédito: Contrapartida (Banco/Caja/CxP)
    INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "costCenterId", debit, credit, description, "documentReference")
    VALUES (p_journal_entry_id, p_account_counterpart_id, v_cost_center_id, 0, p_amount, 'Contrapartida Mejora ' || v_code, v_code);

    -- Insertar registro de mejora
    INSERT INTO public."FixedAssetImprovement"(
        "fixedAssetId", "improvementDate", description, amount, "additionalMonths", "journalEntryId", "createdById"
    ) VALUES (
        p_fixed_asset_id, CURRENT_TIMESTAMP, p_description, p_amount, COALESCE(p_additional_months, 0), p_journal_entry_id, p_created_by_id
    ) RETURNING id INTO p_improvement_id;

    -- Actualizar Activo Fijo
    UPDATE public."FixedAsset"
    SET "acquisitionCost" = v_new_cost,
        "usefulLifeMonths" = v_new_life,
        "monthlyDepreciation" = v_new_monthly,
        "netBookValue" = v_new_cost - "accumulatedDepreciation",
        status = 'ACTIVE',
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_fixed_asset_id;
END;
$$;


-- --- PROCEDIMIENTO: spAnticipoRegistrar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spAnticipoRegistrar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spAnticipoRegistrar";
END $$;

CREATE OR REPLACE PROCEDURE public."spAnticipoRegistrar"(
    IN p_company_id INTEGER,
    IN p_advance_type VARCHAR(20),
    IN p_third_party_id INTEGER,
    IN p_treasury_movement_id INTEGER,
    IN p_amount NUMERIC(18, 4),
    IN p_concept TEXT,
    IN p_created_by_id INTEGER,
    OUT p_advance_id INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF COALESCE(p_amount, 0) <= 0 THEN
        RAISE EXCEPTION '❌ El valor del anticipo debe ser mayor a cero';
    END IF;

    INSERT INTO public."AdvancePayment"(
        "companyId", "advanceType", "thirdPartyId", "treasuryMovementId",
        "advanceDate", amount, "usedAmount", "balanceAmount",
        status, concept, "createdById"
    ) VALUES (
        p_company_id, p_advance_type, p_third_party_id, p_treasury_movement_id,
        CURRENT_TIMESTAMP, p_amount, 0, p_amount,
        'ACTIVE', p_concept, p_created_by_id
    ) RETURNING id INTO p_advance_id;
END;
$$;


-- --- PROCEDIMIENTO: spBankGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spBankGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spBankGuardar"(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spBankGuardar"(
    IN p_id INT,
    IN p_code VARCHAR,
    IN p_name VARCHAR,
    IN p_nit VARCHAR,
    IN p_phone VARCHAR,
    IN p_contact_name VARCHAR,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."Bank" (
            code, name, nit, phone, "contactName", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            TRIM(p_code), TRIM(p_name), p_nit, p_phone, p_contact_name, COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."Bank"
        SET 
            code = TRIM(p_code),
            name = TRIM(p_name),
            nit = p_nit,
            phone = p_phone,
            "contactName" = p_contact_name,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spBatchImportComprobantes.sql ---
-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- PROCEDIMIENTO: spBatchImportComprobantes
-- DESCRIPCION: Ingesta y validación en lote de Comprobantes Contables desde JSON
-- ============================================================================

CREATE OR REPLACE PROCEDURE public."spBatchImportComprobantes"(
    IN p_company_id INTEGER,
    IN p_entries_json JSONB,
    IN p_auto_post BOOLEAN,
    IN p_user_id INTEGER,
    OUT p_total_rows INTEGER,
    OUT p_success_rows INTEGER,
    OUT p_failed_rows INTEGER,
    OUT p_errors JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_entry JSONB;
    v_doc_type_code VARCHAR(10);
    v_date DATE;
    v_concept VARCHAR(255);
    v_lines JSONB;
    v_line JSONB;
    v_line_idx INTEGER;
    
    v_doc_type_id INTEGER;
    v_journal_id INTEGER;
    v_consecutive INTEGER;
    v_fiscal_year INTEGER;
    v_total_debit DECIMAL(18,4) := 0;
    v_total_credit DECIMAL(18,4) := 0;
    
    v_account_id INTEGER;
    v_account_code VARCHAR(20);
    v_third_party_id INTEGER;
    v_third_party_doc VARCHAR(50);
    v_cost_center_id INTEGER;
    v_cost_center_code VARCHAR(50);
    v_debit DECIMAL(18,4);
    v_credit DECIMAL(18,4);
    v_desc VARCHAR(255);
    v_errors_arr JSONB := '[]'::JSONB;
BEGIN
    p_total_rows := jsonb_array_length(p_entries_json);
    p_success_rows := 0;
    p_failed_rows := 0;

    FOR v_entry IN SELECT * FROM jsonb_array_elements(p_entries_json)
    LOOP
        BEGIN
            v_doc_type_code := UPPER(TRIM(v_entry->>'documentTypeCode'));
            v_date := (v_entry->>'entryDate')::DATE;
            v_concept := TRIM(COALESCE(v_entry->>'concept', 'Importación Masiva de Comprobante'));
            v_lines := v_entry->'lines';

            IF v_doc_type_code IS NULL OR v_doc_type_code = '' THEN
                RAISE EXCEPTION 'Tipo de documento es obligatorio';
            END IF;

            IF v_date IS NULL THEN
                RAISE EXCEPTION 'Fecha de comprobante es obligatoria';
            END IF;

            IF v_lines IS NULL OR jsonb_array_length(v_lines) = 0 THEN
                RAISE EXCEPTION 'El comprobante debe contener al menos una línea de asiento';
            END IF;

            SELECT id INTO v_doc_type_id 
            FROM public."DocumentType" 
            WHERE "code" = v_doc_type_code AND "isActive" = true;

            IF v_doc_type_id IS NULL THEN
                RAISE EXCEPTION 'Tipo de documento % no existe o está inactivo', v_doc_type_code;
            END IF;

            -- Validar partida doble previa en las líneas
            v_total_debit := 0;
            v_total_credit := 0;
            FOR v_line IN SELECT * FROM jsonb_array_elements(v_lines)
            LOOP
                v_total_debit := v_total_debit + COALESCE((v_line->>'debit')::DECIMAL, 0);
                v_total_credit := v_total_credit + COALESCE((v_line->>'credit')::DECIMAL, 0);
            END LOOP;

            IF ROUND(v_total_debit, 2) <> ROUND(v_total_credit, 2) THEN
                RAISE EXCEPTION 'Comprobante descuadrado: Débitos ($%) <> Créditos ($%)', v_total_debit, v_total_credit;
            END IF;

            -- Asignar consecutivo seguro
            v_fiscal_year := EXTRACT(YEAR FROM v_date)::INTEGER;

            SELECT "currentNumber" + 1 INTO v_consecutive
            FROM public."Consecutive"
            WHERE "companyId" = p_company_id 
              AND "documentTypeId" = v_doc_type_id 
              AND "fiscalYear" = v_fiscal_year
            FOR UPDATE;

            IF v_consecutive IS NULL THEN
                v_consecutive := 1;
                INSERT INTO public."Consecutive" (
                    "companyId", "documentTypeId", "fiscalYear", "currentNumber", "isActive", "createdAt", "updatedAt"
                ) VALUES (
                    p_company_id, v_doc_type_id, v_fiscal_year, 1, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                );
            ELSE
                UPDATE public."Consecutive" SET
                    "currentNumber" = v_consecutive,
                    "updatedAt" = CURRENT_TIMESTAMP
                WHERE "companyId" = p_company_id 
                  AND "documentTypeId" = v_doc_type_id 
                  AND "fiscalYear" = v_fiscal_year;
            END IF;

            -- Insertar cabecera JournalEntry
            INSERT INTO public."JournalEntry" (
                "companyId", "documentTypeId", "consecutive", "entryDate", "concept",
                "status", "totalDebit", "totalCredit", "createdById", "createdAt", "updatedAt"
            ) VALUES (
                p_company_id, v_doc_type_id, v_consecutive, v_date, v_concept,
                'DRAFT', v_total_debit, v_total_credit, p_user_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            ) RETURNING id INTO v_journal_id;

            -- Insertar líneas
            v_line_idx := 1;
            FOR v_line IN SELECT * FROM jsonb_array_elements(v_lines)
            LOOP
                v_account_code := TRIM(v_line->>'accountCode');
                v_third_party_doc := TRIM(COALESCE(v_line->>'thirdPartyDoc', ''));
                v_cost_center_code := TRIM(COALESCE(v_line->>'costCenterCode', ''));
                v_debit := COALESCE((v_line->>'debit')::DECIMAL, 0);
                v_credit := COALESCE((v_line->>'credit')::DECIMAL, 0);
                v_desc := TRIM(COALESCE(v_line->>'description', v_concept));

                SELECT id INTO v_account_id FROM public."PucAccount" WHERE "code" = v_account_code;
                IF v_account_id IS NULL THEN
                    RAISE EXCEPTION 'Cuenta contable % no existe', v_account_code;
                END IF;

                v_third_party_id := NULL;
                IF v_third_party_doc <> '' THEN
                    SELECT id INTO v_third_party_id FROM public."ThirdParty" WHERE "documentNumber" = v_third_party_doc;
                END IF;

                v_cost_center_id := NULL;
                IF v_cost_center_code <> '' THEN
                    SELECT id INTO v_cost_center_id FROM public."CostCenter" WHERE "code" = v_cost_center_code;
                END IF;

                INSERT INTO public."JournalEntryLine" (
                    "journalEntryId", "lineNumber", "accountId", "thirdPartyId",
                    "costCenterId", "description", "debit", "credit", "baseAmount", "createdAt"
                ) VALUES (
                    v_journal_id, v_line_idx, v_account_id, v_third_party_id,
                    v_cost_center_id, v_desc, v_debit, v_credit, 
                    COALESCE((v_line->>'baseAmount')::DECIMAL, 0), CURRENT_TIMESTAMP
                );

                v_line_idx := v_line_idx + 1;
            END LOOP;

            -- Auto-post si se solicitó
            IF p_auto_post = true THEN
                CALL public."spComprobanteContabilizar"(
                    v_journal_id,
                    p_user_id,
                    NULL,
                    NULL
                );
            END IF;

            p_success_rows := p_success_rows + 1;

        EXCEPTION WHEN OTHERS THEN
            p_failed_rows := p_failed_rows + 1;
            v_errors_arr := v_errors_arr || jsonb_build_object(
                'docType', COALESCE(v_doc_type_code, 'N/A'),
                'concept', COALESCE(v_concept, 'N/A'),
                'error', SQLERRM
            );
        END;
    END LOOP;

    p_errors := v_errors_arr;
END;
$$;


-- --- PROCEDIMIENTO: spBatchImportPuc.sql ---
-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- PROCEDIMIENTO: spBatchImportPuc
-- DESCRIPCION: Ingesta y validación en lote de cuentas contables del PUC desde JSON
-- ============================================================================

CREATE OR REPLACE PROCEDURE public."spBatchImportPuc"(
    IN p_company_id INTEGER,
    IN p_accounts_json JSONB,
    IN p_user_id INTEGER,
    OUT p_total_rows INTEGER,
    OUT p_success_rows INTEGER,
    OUT p_failed_rows INTEGER,
    OUT p_errors JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_item JSONB;
    v_code VARCHAR(20);
    v_name VARCHAR(255);
    v_nature VARCHAR(10);
    v_level INTEGER;
    v_is_movement BOOLEAN;
    v_parent_id INTEGER;
    v_parent_code VARCHAR(20);
    v_requires_third_party BOOLEAN;
    v_requires_cost_center BOOLEAN;
    v_errors_arr JSONB := '[]'::JSONB;
    v_class_digit CHAR(1);
    v_existing_id INTEGER;
BEGIN
    p_total_rows := jsonb_array_length(p_accounts_json);
    p_success_rows := 0;
    p_failed_rows := 0;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_accounts_json)
    LOOP
        BEGIN
            v_code := TRIM(v_item->>'code');
            v_name := TRIM(v_item->>'name');
            v_nature := UPPER(TRIM(COALESCE(v_item->>'nature', '')));
            v_level := COALESCE((v_item->>'level')::INTEGER, 
                CASE 
                    WHEN LENGTH(v_code) = 1 THEN 1
                    WHEN LENGTH(v_code) = 2 THEN 2
                    WHEN LENGTH(v_code) = 4 THEN 3
                    WHEN LENGTH(v_code) = 6 THEN 4
                    ELSE 5
                END
            );
            v_is_movement := COALESCE((v_item->>'isMovement')::BOOLEAN, (v_level >= 4));
            v_requires_third_party := COALESCE((v_item->>'requiresThirdParty')::BOOLEAN, false);
            v_requires_cost_center := COALESCE((v_item->>'requiresCostCenter')::BOOLEAN, false);

            -- Validaciones básicas
            IF v_code IS NULL OR v_code = '' THEN
                RAISE EXCEPTION 'Código de cuenta requerido';
            END IF;

            IF v_name IS NULL OR v_name = '' THEN
                RAISE EXCEPTION 'Nombre de cuenta requerido para %', v_code;
            END IF;

            -- Determinar naturaleza si no viene explícita
            IF v_nature = '' OR v_nature IS NULL THEN
                v_class_digit := SUBSTRING(v_code, 1, 1);
                IF v_class_digit IN ('1', '5', '6', '7') THEN
                    v_nature := 'DEBIT';
                ELSE
                    v_nature := 'CREDIT';
                END IF;
            END IF;

            -- Inferencia de cuenta padre
            v_parent_id := NULL;
            IF v_level > 1 THEN
                v_parent_code := CASE
                    WHEN v_level = 2 THEN SUBSTRING(v_code, 1, 1)
                    WHEN v_level = 3 THEN SUBSTRING(v_code, 1, 2)
                    WHEN v_level = 4 THEN SUBSTRING(v_code, 1, 4)
                    ELSE SUBSTRING(v_code, 1, 6)
                END;

                SELECT id INTO v_parent_id 
                FROM public."PucAccount" 
                WHERE "code" = v_parent_code;
            END IF;

            -- Upsert en PucAccount
            SELECT id INTO v_existing_id FROM public."PucAccount" WHERE "code" = v_code;

            IF v_existing_id IS NOT NULL THEN
                UPDATE public."PucAccount" SET
                    "name" = v_name,
                    "nature" = v_nature,
                    "level" = v_level,
                    "parentId" = v_parent_id,
                    "isMovement" = v_is_movement,
                    "requiresThirdParty" = v_requires_third_party,
                    "requiresCostCenter" = v_requires_cost_center,
                    "updatedAt" = CURRENT_TIMESTAMP
                WHERE "id" = v_existing_id;
            ELSE
                INSERT INTO public."PucAccount" (
                    "code", "name", "nature", "level", "parentId", 
                    "isMovement", "requiresThirdParty", "requiresCostCenter", "isActive", "createdAt", "updatedAt"
                ) VALUES (
                    v_code, v_name, v_nature, v_level, v_parent_id,
                    v_is_movement, v_requires_third_party, v_requires_cost_center, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                );
            END IF;

            p_success_rows := p_success_rows + 1;

        EXCEPTION WHEN OTHERS THEN
            p_failed_rows := p_failed_rows + 1;
            v_errors_arr := v_errors_arr || jsonb_build_object(
                'code', COALESCE(v_code, 'N/A'),
                'error', SQLERRM
            );
        END;
    END LOOP;

    p_errors := v_errors_arr;
END;
$$;


-- --- PROCEDIMIENTO: spBatchImportThirdParties.sql ---
-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- PROCEDIMIENTO: spBatchImportThirdParties
-- DESCRIPCION: Ingesta y validación en lote de Terceros desde JSON con cálculo de DV
-- ============================================================================

CREATE OR REPLACE PROCEDURE public."spBatchImportThirdParties"(
    IN p_company_id INTEGER,
    IN p_third_parties_json JSONB,
    IN p_user_id INTEGER,
    OUT p_total_rows INTEGER,
    OUT p_success_rows INTEGER,
    OUT p_failed_rows INTEGER,
    OUT p_errors JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_item JSONB;
    v_doc_type VARCHAR(10);
    v_doc_num VARCHAR(50);
    v_dv VARCHAR(2);
    v_business_name VARCHAR(255);
    v_first_name VARCHAR(100);
    v_last_name VARCHAR(100);
    v_person_type VARCHAR(20);
    v_email VARCHAR(255);
    v_phone VARCHAR(50);
    v_address VARCHAR(255);
    v_city VARCHAR(100);
    v_is_customer BOOLEAN;
    v_is_vendor BOOLEAN;
    v_is_employee BOOLEAN;
    v_errors_arr JSONB := '[]'::JSONB;
    v_existing_id INTEGER;
    
    -- Variables para cálculo DV Módulo 11
    v_clean_nit VARCHAR(50);
    v_len INTEGER;
    v_weights INTEGER[] := ARRAY[3, 7, 13, 17, 19, 23, 29, 37, 41, 43, 47, 53, 59, 67, 71];
    v_sum INTEGER := 0;
    v_i INTEGER;
    v_digit INTEGER;
    v_remainder INTEGER;
BEGIN
    p_total_rows := jsonb_array_length(p_third_parties_json);
    p_success_rows := 0;
    p_failed_rows := 0;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_third_parties_json)
    LOOP
        BEGIN
            v_doc_type := UPPER(TRIM(COALESCE(v_item->>'documentType', 'NIT')));
            v_doc_num := TRIM(v_item->>'documentNumber');
            v_dv := TRIM(COALESCE(v_item->>'verificationDigit', ''));
            v_business_name := TRIM(COALESCE(v_item->>'businessName', ''));
            v_first_name := TRIM(COALESCE(v_item->>'firstName', ''));
            v_last_name := TRIM(COALESCE(v_item->>'lastName', ''));
            v_email := TRIM(COALESCE(v_item->>'email', ''));
            v_phone := TRIM(COALESCE(v_item->>'phone', ''));
            v_address := TRIM(COALESCE(v_item->>'address', ''));
            v_city := TRIM(COALESCE(v_item->>'city', ''));
            v_is_customer := COALESCE((v_item->>'isCustomer')::BOOLEAN, true);
            v_is_vendor := COALESCE((v_item->>'isVendor')::BOOLEAN, false);
            v_is_employee := COALESCE((v_item->>'isEmployee')::BOOLEAN, false);

            IF v_doc_num IS NULL OR v_doc_num = '' THEN
                RAISE EXCEPTION 'Número de documento es obligatorio';
            END IF;

            -- Auto-completar nombres o razón social
            IF v_business_name = '' THEN
                IF v_first_name <> '' OR v_last_name <> '' THEN
                    v_business_name := TRIM(v_first_name || ' ' || v_last_name);
                    v_person_type := 'NATURAL';
                ELSE
                    RAISE EXCEPTION 'Debe especificar razón social o nombres para el documento %', v_doc_num;
                END IF;
            ELSE
                v_person_type := COALESCE(v_item->>'personType', CASE WHEN v_doc_type = 'NIT' THEN 'LEGAL' ELSE 'NATURAL' END);
            END IF;

            -- Cálculo automático de DV si está vacío y es NIT
            IF v_dv = '' AND v_doc_type = 'NIT' THEN
                v_clean_nit := regexp_replace(v_doc_num, '[^0-9]', '', 'g');
                v_len := LENGTH(v_clean_nit);
                IF v_len > 0 THEN
                    v_sum := 0;
                    FOR v_i IN 1..v_len LOOP
                        v_digit := CAST(SUBSTRING(v_clean_nit, v_len - v_i + 1, 1) AS INTEGER);
                        v_sum := v_sum + (v_digit * v_weights[v_i]);
                    END LOOP;
                    v_remainder := v_sum % 11;
                    IF v_remainder > 1 THEN
                        v_dv := CAST((11 - v_remainder) AS VARCHAR);
                    ELSE
                        v_dv := CAST(v_remainder AS VARCHAR);
                    END IF;
                END IF;
            END IF;

            -- Upsert en ThirdParty
            SELECT id INTO v_existing_id 
            FROM public."ThirdParty" 
            WHERE "documentNumber" = v_doc_num;

            IF v_existing_id IS NOT NULL THEN
                UPDATE public."ThirdParty" SET
                    "documentType" = v_doc_type,
                    "verificationDigit" = NULLIF(v_dv, ''),
                    "businessName" = v_business_name,
                    "firstName" = NULLIF(v_first_name, ''),
                    "lastName" = NULLIF(v_last_name, ''),
                    "personType" = v_person_type,
                    "email" = NULLIF(v_email, ''),
                    "phone" = NULLIF(v_phone, ''),
                    "address" = NULLIF(v_address, ''),
                    "city" = NULLIF(v_city, ''),
                    "isCustomer" = v_is_customer,
                    "isVendor" = v_is_vendor,
                    "isEmployee" = v_is_employee,
                    "updatedAt" = CURRENT_TIMESTAMP
                WHERE "id" = v_existing_id;
            ELSE
                INSERT INTO public."ThirdParty" (
                    "documentType", "documentNumber", "verificationDigit",
                    "businessName", "firstName", "lastName", "personType",
                    "email", "phone", "address", "city",
                    "isCustomer", "isVendor", "isEmployee", "isActive",
                    "createdAt", "updatedAt"
                ) VALUES (
                    v_doc_type, v_doc_num, NULLIF(v_dv, ''),
                    v_business_name, NULLIF(v_first_name, ''), NULLIF(v_last_name, ''), v_person_type,
                    NULLIF(v_email, ''), NULLIF(v_phone, ''), NULLIF(v_address, ''), NULLIF(v_city, ''),
                    v_is_customer, v_is_vendor, v_is_employee, true,
                    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                );
            END IF;

            p_success_rows := p_success_rows + 1;

        EXCEPTION WHEN OTHERS THEN
            p_failed_rows := p_failed_rows + 1;
            v_errors_arr := v_errors_arr || jsonb_build_object(
                'documentNumber', COALESCE(v_doc_num, 'N/A'),
                'error', SQLERRM
            );
        END;
    END LOOP;

    p_errors := v_errors_arr;
END;
$$;


-- --- PROCEDIMIENTO: spCajaGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS DE TESORERÍA (POSTGRESQL)
-- Archivo: SQL/Procedure/spCajaGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spCajaGuardar"(INT, INT, VARCHAR, VARCHAR, INT, INT, VARCHAR, NUMERIC, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spCajaGuardar"(
    IN p_id INT,
    IN p_company_id INT,
    IN p_code VARCHAR,
    IN p_name VARCHAR,
    IN p_account_id INT,
    IN p_responsible_user_id INT,
    IN p_currency VARCHAR,
    IN p_max_amount NUMERIC,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."CashBox" (
            "companyId", code, name, "accountId", "responsibleUserId",
            currency, "maxAmount", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            p_company_id, TRIM(p_code), TRIM(p_name), p_account_id, p_responsible_user_id,
            COALESCE(p_currency, 'COP'), COALESCE(p_max_amount, 0), COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."CashBox"
        SET 
            "companyId" = p_company_id,
            code = TRIM(p_code),
            name = TRIM(p_name),
            "accountId" = p_account_id,
            "responsibleUserId" = p_responsible_user_id,
            currency = COALESCE(p_currency, currency),
            "maxAmount" = COALESCE(p_max_amount, "maxAmount"),
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spCarteraReciboCruzar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spCarteraReciboCruzar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spCarteraReciboCruzar";
END $$;

CREATE OR REPLACE PROCEDURE public."spCarteraReciboCruzar"(
    IN p_receivable_invoice_id INTEGER,
    IN p_receivable_installment_id INTEGER,
    IN p_treasury_movement_id INTEGER,
    IN p_advance_payment_id INTEGER,
    IN p_credit_note_id INTEGER,
    IN p_amount NUMERIC(18, 4),
    IN p_discount_amount NUMERIC(18, 4),
    IN p_withholding_adjustment NUMERIC(18, 4),
    IN p_observations TEXT,
    OUT p_allocation_id INTEGER,
    OUT p_new_balance NUMERIC(18, 4),
    OUT p_invoice_status VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inv_balance NUMERIC(18, 4);
    v_inst_balance NUMERIC(18, 4);
    v_total_applied NUMERIC(18, 4);
    v_adv_balance NUMERIC(18, 4);
    v_note_balance NUMERIC(18, 4);
BEGIN
    -- Validar factura
    SELECT "balanceAmount" INTO v_inv_balance
    FROM public."ReceivableInvoice"
    WHERE id = p_receivable_invoice_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Factura de venta con ID % no encontrada', p_receivable_invoice_id;
    END IF;

    v_total_applied := COALESCE(p_amount, 0) + COALESCE(p_discount_amount, 0) + COALESCE(p_withholding_adjustment, 0);

    IF v_total_applied <= 0 THEN
        RAISE EXCEPTION '❌ El monto total a cruzar debe ser mayor a cero';
    END IF;

    IF v_total_applied > v_inv_balance THEN
        RAISE EXCEPTION '❌ El monto a cruzar ($%) supera el saldo pendiente de la factura ($%)', v_total_applied, v_inv_balance;
    END IF;

    -- Validar saldo de anticipo si aplica
    IF p_advance_payment_id IS NOT NULL THEN
        SELECT "balanceAmount" INTO v_adv_balance
        FROM public."AdvancePayment"
        WHERE id = p_advance_payment_id
        FOR UPDATE;

        IF v_adv_balance < p_amount THEN
            RAISE EXCEPTION '❌ El anticipo no posee saldo suficiente ($% disponible vs $% solicitado)', v_adv_balance, p_amount;
        END IF;

        UPDATE public."AdvancePayment"
        SET "usedAmount" = "usedAmount" + p_amount,
            "balanceAmount" = "balanceAmount" - p_amount,
            status = CASE WHEN "balanceAmount" - p_amount <= 0 THEN 'EXHAUSTED' ELSE 'ACTIVE' END,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_advance_payment_id;
    END IF;

    -- Validar saldo de nota crédito si aplica
    IF p_credit_note_id IS NOT NULL THEN
        SELECT "balanceAmount" INTO v_note_balance
        FROM public."CreditDebitNote"
        WHERE id = p_credit_note_id
        FOR UPDATE;

        IF v_note_balance < p_amount THEN
            RAISE EXCEPTION '❌ La Nota Crédito no posee saldo disponible ($% vs $%)', v_note_balance, p_amount;
        END IF;

        UPDATE public."CreditDebitNote"
        SET "appliedAmount" = "appliedAmount" + p_amount,
            "balanceAmount" = "balanceAmount" - p_amount,
            status = CASE WHEN "balanceAmount" - p_amount <= 0 THEN 'APPLIED' ELSE 'POSTED' END,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_credit_note_id;
    END IF;

    -- Insertar asignación de pago
    INSERT INTO public."ReceivablePaymentAllocation"(
        "receivableInvoiceId", "receivableInstallmentId", "treasuryMovementId",
        "advancePaymentId", "creditDebitNoteId", "allocationDate",
        amount, "discountAmount", "withholdingAdjustment", observations
    ) VALUES (
        p_receivable_invoice_id, p_receivable_installment_id, p_treasury_movement_id,
        p_advance_payment_id, p_credit_note_id, CURRENT_TIMESTAMP,
        p_amount, COALESCE(p_discount_amount, 0), COALESCE(p_withholding_adjustment, 0), p_observations
    ) RETURNING id INTO p_allocation_id;

    -- Actualizar cuota si se especificó
    IF p_receivable_installment_id IS NOT NULL THEN
        SELECT "balanceAmount" INTO v_inst_balance
        FROM public."ReceivableInstallment"
        WHERE id = p_receivable_installment_id
        FOR UPDATE;

        UPDATE public."ReceivableInstallment"
        SET "paidAmount" = "paidAmount" + v_total_applied,
            "balanceAmount" = "balanceAmount" - v_total_applied,
            status = CASE WHEN "balanceAmount" - v_total_applied <= 0 THEN 'PAID' ELSE 'PARTIAL' END,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_receivable_installment_id;
    END IF;

    -- Actualizar Factura
    p_new_balance := v_inv_balance - v_total_applied;
    p_invoice_status := CASE WHEN p_new_balance <= 0 THEN 'PAID' ELSE 'PARTIAL' END;

    UPDATE public."ReceivableInvoice"
    SET "paidAmount" = "paidAmount" + v_total_applied,
        "balanceAmount" = p_new_balance,
        status = p_invoice_status,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_receivable_invoice_id;
END;
$$;


-- --- PROCEDIMIENTO: spCierreAnual.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE CIERRE ANUAL DEL EJERCICIO (POSTGRESQL)
-- Archivo: SQL/Procedure/spCierreAnual.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spCierreAnual"(INT, INT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spCierreAnual"(
    IN p_company_id INT,
    IN p_fiscal_year INT,
    IN p_user_id INT,
    OUT p_closing_journal_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cz_doc_type_id INT;
    v_doc_prefix VARCHAR;
    v_curr_number INT;
    v_entry_number VARCHAR;
    v_journal_id INT;
    v_row RECORD;
    v_total_debit NUMERIC(18, 4) := 0;
    v_total_credit NUMERIC(18, 4) := 0;
    v_net_profit NUMERIC(18, 4) := 0;
    v_equity_account_id INT;
BEGIN
    -- 1. Obtener Tipo de Documento CZ (Cierre Contable)
    SELECT id, prefix INTO v_cz_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CZ';
    IF v_cz_doc_type_id IS NULL THEN
        SELECT id, prefix INTO v_cz_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CC';
    END IF;

    -- Consecutivo
    SELECT "currentNumber" INTO v_curr_number 
    FROM public."Consecutive" 
    WHERE "documentTypeId" = v_cz_doc_type_id AND "fiscalYear" = p_fiscal_year;

    IF v_curr_number IS NULL THEN
        v_curr_number := 1;
        INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (v_cz_doc_type_id, v_doc_prefix, 2, 1, p_fiscal_year, true);
    ELSE
        UPDATE public."Consecutive" 
        SET "currentNumber" = "currentNumber" + 1 
        WHERE "documentTypeId" = v_cz_doc_type_id AND "fiscalYear" = p_fiscal_year;
    END IF;

    v_entry_number := CONCAT(COALESCE(v_doc_prefix, 'CZ'), '-', p_fiscal_year, '-', LPAD(v_curr_number::TEXT, 6, '0'));

    -- 2. Crear encabezado del comprobante de cierre anual
    INSERT INTO public."JournalEntry" (
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber",
        "entryDate", concept, observation,
        "totalDebit", "totalCredit", status, "createdById",
        "postedAt", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, v_cz_doc_type_id, v_curr_number, v_entry_number,
        MAKE_DATE(p_fiscal_year, 12, 31)::TIMESTAMP,
        CONCAT('CIERRE ANUAL DE CUENTAS DE RESULTADO - AÑO FISCAL ', p_fiscal_year),
        'Cancelación y traslado de saldos de las clases 4, 5, 6 y 7 a Resultado del Ejercicio',
        0, 0, 'POSTED', p_user_id,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_journal_id;

    p_closing_journal_id := v_journal_id;

    -- 3. Recorrer saldos netos de cuentas de resultado (Clases 4, 5, 6, 7)
    FOR v_row IN 
        SELECT 
            ji."accountId",
            a.code AS account_code,
            a.name AS account_name,
            SUM(ji.debit) AS total_deb,
            SUM(ji.credit) AS total_cred,
            (SUM(ji.debit) - SUM(ji.credit)) AS net_balance
        FROM public."JournalEntryItem" ji
        INNER JOIN public."JournalEntry" j ON ji."journalEntryId" = j.id
        INNER JOIN public."Account" a ON ji."accountId" = a.id
        WHERE j."companyId" = p_company_id
          AND EXTRACT(YEAR FROM j."entryDate")::INT = p_fiscal_year
          AND j.status = 'POSTED'
          AND j.id <> v_journal_id
          AND (a.code LIKE '4%' OR a.code LIKE '5%' OR a.code LIKE '6%' OR a.code LIKE '7%')
        GROUP BY ji."accountId", a.code, a.name
        HAVING (SUM(ji.debit) - SUM(ji.credit)) <> 0
    LOOP
        IF v_row.net_balance > 0 THEN
            -- Saldo débito (Gasto/Costo): Se acredita para dejarlo en cero
            INSERT INTO public."JournalEntryItem" (
                "journalEntryId", "accountId", debit, credit, description, "createdAt", "updatedAt"
            ) VALUES (
                v_journal_id, v_row."accountId", 0, v_row.net_balance,
                CONCAT('Cierre Anual ', v_row.account_code), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            );
            v_total_credit := v_total_credit + v_row.net_balance;
        ELSE
            -- Saldo crédito (Ingreso): Se debita para dejarlo en cero
            INSERT INTO public."JournalEntryItem" (
                "journalEntryId", "accountId", debit, credit, description, "createdAt", "updatedAt"
            ) VALUES (
                v_journal_id, v_row."accountId", ABS(v_row.net_balance), 0,
                CONCAT('Cierre Anual ', v_row.account_code), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            );
            v_total_debit := v_total_debit + ABS(v_row.net_balance);
        END IF;
    END LOOP;

    -- 4. Asentar la Utilidad o Pérdida neta del ejercicio en Patrimonio (Clase 36)
    v_net_profit := v_total_credit - v_total_debit; -- Si Créditos > Débitos => Utilidad
    
    -- Buscar o crear cuenta de Resultado del Ejercicio
    SELECT id INTO v_equity_account_id FROM public."Account" WHERE code = '360505' OR code = '3605';
    IF v_equity_account_id IS NULL THEN
        SELECT id INTO v_equity_account_id FROM public."Account" WHERE code LIKE '36%' LIMIT 1;
    END IF;

    IF v_equity_account_id IS NOT NULL AND v_net_profit <> 0 THEN
        IF v_net_profit > 0 THEN
            -- Utilidad neta: Acreditar Patrimonio
            INSERT INTO public."JournalEntryItem" (
                "journalEntryId", "accountId", debit, credit, description, "createdAt", "updatedAt"
            ) VALUES (
                v_journal_id, v_equity_account_id, 0, v_net_profit,
                CONCAT('UTILIDAD NETA DEL EJERCICIO - AÑO ', p_fiscal_year), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            );
            v_total_credit := v_total_credit + v_net_profit;
        ELSE
            -- Pérdida neta: Debitar Patrimonio
            INSERT INTO public."JournalEntryItem" (
                "journalEntryId", "accountId", debit, credit, description, "createdAt", "updatedAt"
            ) VALUES (
                v_journal_id, v_equity_account_id, ABS(v_net_profit), 0,
                CONCAT('PÉRDIDA NETA DEL EJERCICIO - AÑO ', p_fiscal_year), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            );
            v_total_debit := v_total_debit + ABS(v_net_profit);
        END IF;
    END IF;

    -- Actualizar totales del comprobante de cierre
    UPDATE public."JournalEntry"
    SET "totalDebit" = v_total_debit, "totalCredit" = v_total_credit
    WHERE id = v_journal_id;
END;
$$;


-- --- PROCEDIMIENTO: spCompanyGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spCompanyGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spCompanyGuardar"(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spCompanyGuardar"(
    IN p_id INT,
    IN p_code VARCHAR,
    IN p_business_name VARCHAR,
    IN p_trade_name VARCHAR,
    IN p_document_type VARCHAR,
    IN p_document_number VARCHAR,
    IN p_verification_digit VARCHAR,
    IN p_address VARCHAR,
    IN p_city VARCHAR,
    IN p_state VARCHAR,
    IN p_country VARCHAR,
    IN p_phone VARCHAR,
    IN p_email VARCHAR,
    IN p_legal_rep VARCHAR,
    IN p_tax_regime VARCHAR,
    IN p_fiscal_resp VARCHAR,
    IN p_ciiu VARCHAR,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."Company" (
            code, "businessName", "tradeName", "documentType", "documentNumber",
            "verificationDigit", address, city, state, country, phone, email,
            "legalRepresentative", "taxRegime", "fiscalResponsibilities",
            "economicActivityCode", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            p_code, p_business_name, p_trade_name, COALESCE(p_document_type, 'NIT'), p_document_number,
            p_verification_digit, p_address, p_city, p_state, COALESCE(p_country, 'Colombia'), p_phone, p_email,
            p_legal_rep, p_tax_regime, p_fiscal_resp,
            p_ciiu, COALESCE(p_is_active, true), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."Company"
        SET 
            code = p_code,
            "businessName" = p_business_name,
            "tradeName" = p_trade_name,
            "documentType" = COALESCE(p_document_type, 'NIT'),
            "documentNumber" = p_document_number,
            "verificationDigit" = p_verification_digit,
            address = p_address,
            city = p_city,
            state = p_state,
            country = COALESCE(p_country, 'Colombia'),
            phone = p_phone,
            email = p_email,
            "legalRepresentative" = p_legal_rep,
            "taxRegime" = p_tax_regime,
            "fiscalResponsibilities" = p_fiscal_resp,
            "economicActivityCode" = p_ciiu,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spComprobanteAnular.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS DE ANULACIÓN Y REVERSIÓN (POSTGRESQL)
-- Archivo: SQL/Procedure/spComprobanteAnular.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spComprobanteAnular"(INT, TEXT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spComprobanteAnular"(
    IN p_journal_id INT,
    IN p_reason TEXT,
    IN p_user_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_journal RECORD;
    v_period RECORD;
    v_year INT;
    v_month INT;
BEGIN
    SELECT * INTO v_journal FROM public."JournalEntry" WHERE id = p_journal_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Error: El comprobante #% no existe.', p_journal_id;
    END IF;

    IF v_journal.status = 'ANNULLED' THEN
        RAISE EXCEPTION '⚠️ Advertencia: El comprobante #% (%) ya se encuentra anulado.', p_journal_id, v_journal."entryNumber";
    END IF;

    -- Validar que el período no esté cerrado
    v_year := EXTRACT(YEAR FROM v_journal."entryDate")::INT;
    v_month := EXTRACT(MONTH FROM v_journal."entryDate")::INT;

    SELECT * INTO v_period FROM public."FiscalPeriod" WHERE year = v_year AND month = v_month;
    IF FOUND AND v_period.status = 'CLOSED' THEN
        RAISE EXCEPTION '❌ Período Cerrado: El período contable %-% está cerrado. No se puede anular un comprobante histórico.', v_year, LPAD(v_month::TEXT, 2, '0');
    END IF;

    UPDATE public."JournalEntry"
    SET 
        status = 'ANNULLED',
        "annulledAt" = CURRENT_TIMESTAMP,
        "annulmentReason" = COALESCE(p_reason, 'Anulado por usuario'),
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_journal_id;
END;
$$;


-- --- PROCEDIMIENTO: spComprobanteContabilizar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - MOTOR DE CONTABILIZACIÓN (POSTGRESQL)
-- Archivo: SQL/Procedure/spComprobanteContabilizar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spComprobanteContabilizar"(INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spComprobanteContabilizar"(
    IN p_journal_id INT,
    IN p_user_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_journal RECORD;
    v_total_debit NUMERIC(18, 4) := 0;
    v_total_credit NUMERIC(18, 4) := 0;
    v_diff NUMERIC(18, 4);
    v_line_count INT := 0;
    v_invalid_acc RECORD;
    v_missing_tp RECORD;
    v_missing_cc RECORD;
    v_period RECORD;
    v_year INT;
    v_month INT;
BEGIN
    -- 1. Obtener encabezado del comprobante
    SELECT * INTO v_journal FROM public."JournalEntry" WHERE id = p_journal_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Error de Contabilización: El comprobante #% no existe.', p_journal_id;
    END IF;

    IF v_journal.status = 'POSTED' THEN
        RAISE EXCEPTION '⚠️ Advertencia: El comprobante #% (%) ya se encuentra contabilizado.', p_journal_id, v_journal."entryNumber";
    END IF;

    IF v_journal.status = 'ANNULLED' THEN
        RAISE EXCEPTION '❌ Error: El comprobante #% (%) está anulado y no puede ser contabilizado.', p_journal_id, v_journal."entryNumber";
    END IF;

    -- 2. VALIDACIÓN DE PERÍODO FISCAL
    v_year := EXTRACT(YEAR FROM v_journal."entryDate")::INT;
    v_month := EXTRACT(MONTH FROM v_journal."entryDate")::INT;

    SELECT * INTO v_period FROM public."FiscalPeriod" WHERE year = v_year AND month = v_month;
    IF FOUND AND v_period.status = 'CLOSED' THEN
        RAISE EXCEPTION '❌ Período Cerrado: El período contable %-% se encuentra cerrado. No se permiten contabilizaciones.', v_year, LPAD(v_month::TEXT, 2, '0');
    END IF;

    -- 3. CALCULAR TOTALES DE LÍNEAS Y CONTAR
    SELECT 
        COUNT(*),
        COALESCE(SUM(debit), 0),
        COALESCE(SUM(credit), 0)
    INTO v_line_count, v_total_debit, v_total_credit
    FROM public."JournalEntryItem"
    WHERE "journalEntryId" = p_journal_id;

    IF v_line_count < 2 THEN
        RAISE EXCEPTION '❌ Asientos Insuficientes: Un comprobante contable debe poseer al menos 2 asientos para cumplir la partida doble (registrados: %).', v_line_count;
    END IF;

    -- 4. VALIDACIÓN ESTRICTA DE PARTIDA DOBLE (DÉBITOS = CRÉDITOS)
    v_diff := ABS(v_total_debit - v_total_credit);
    IF v_diff > 0.0001 THEN
        RAISE EXCEPTION '❌ Descuadre Contable (Partida Doble): El comprobante % no cumple con la partida doble. Total Débitos ($%) != Total Créditos ($%). Diferencia: $%',
            v_journal."entryNumber", v_total_debit, v_total_credit, v_diff;
    END IF;

    -- 5. VALIDACIÓN DE CUENTAS DE MOVIMIENTO (PROHIBIDO CUENTAS PADRE)
    SELECT a.code, a.name INTO v_invalid_acc
    FROM public."JournalEntryItem" ji
    INNER JOIN public."Account" a ON ji."accountId" = a.id
    WHERE ji."journalEntryId" = p_journal_id AND a."allowsMovement" = false
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION '❌ Cuenta Inválida de Movimiento: La cuenta "% - %" es una cuenta de nivel superior/padre y no permite movimientos directos. Debe seleccionar una cuenta auxiliar de último nivel.',
            v_invalid_acc.code, v_invalid_acc.name;
    END IF;

    -- 6. VALIDACIÓN DE EXIGENCIA DE TERCEROS
    SELECT a.code, a.name INTO v_missing_tp
    FROM public."JournalEntryItem" ji
    INNER JOIN public."Account" a ON ji."accountId" = a.id
    WHERE ji."journalEntryId" = p_journal_id 
      AND a."requiresThirdParty" = true 
      AND (ji."thirdPartyId" IS NULL OR ji."thirdPartyId" = 0)
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION '❌ Exigencia de Tercero: La cuenta "% - %" requiere obligatoriamente un Tercero asignado en el asiento.',
            v_missing_tp.code, v_missing_tp.name;
    END IF;

    -- 7. VALIDACIÓN DE EXIGENCIA DE CENTRO DE COSTO
    SELECT a.code, a.name INTO v_missing_cc
    FROM public."JournalEntryItem" ji
    INNER JOIN public."Account" a ON ji."accountId" = a.id
    WHERE ji."journalEntryId" = p_journal_id 
      AND a."requiresCostCenter" = true 
      AND (ji."costCenterId" IS NULL OR ji."costCenterId" = 0)
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION '❌ Exigencia de Centro de Costo: La cuenta "% - %" requiere obligatoriamente un Centro de Costo asignado en el asiento.',
            v_missing_cc.code, v_missing_cc.name;
    END IF;

    -- 8. ASENTAMIENTO EXITOSO
    UPDATE public."JournalEntry"
    SET 
        status = 'POSTED',
        "totalDebit" = v_total_debit,
        "totalCredit" = v_total_credit,
        "postedAt" = CURRENT_TIMESTAMP,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_journal_id;
END;
$$;


-- --- PROCEDIMIENTO: spComprobanteGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS DE COMPROBANTES (POSTGRESQL)
-- Archivo: SQL/Procedure/spComprobanteGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spComprobanteGuardar"(INT, INT, INT, VARCHAR, TIMESTAMP(3), INT, VARCHAR, TEXT, JSONB, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spComprobanteGuardar"(
    IN p_id INT,
    IN p_company_id INT,
    IN p_document_type_id INT,
    IN p_entry_number VARCHAR,
    IN p_entry_date TIMESTAMP(3),
    IN p_third_party_id INT,
    IN p_concept VARCHAR,
    IN p_observation TEXT,
    IN p_items JSONB, -- Arreglo de líneas [{accountId, thirdPartyId, costCenterId, debit, credit, baseAmount, description, documentReference}]
    IN p_user_id INT,
    OUT p_created_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_journal_id INT;
    v_item JSONB;
    v_total_debit NUMERIC(18, 4) := 0;
    v_total_credit NUMERIC(18, 4) := 0;
    v_fiscal_year INT;
    v_doc_prefix VARCHAR;
    v_curr_number INT;
    v_final_entry_number VARCHAR;
    v_status VARCHAR := 'DRAFT';
BEGIN
    v_fiscal_year := EXTRACT(YEAR FROM p_entry_date)::INT;

    -- Obtener prefijo y consecutivo si el comprobante es nuevo
    IF p_id IS NULL OR p_id = 0 THEN
        SELECT prefix INTO v_doc_prefix FROM public."DocumentType" WHERE id = p_document_type_id;
        
        -- Obtener o inicializar consecutivo
        SELECT "currentNumber" INTO v_curr_number 
        FROM public."Consecutive" 
        WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_fiscal_year;

        IF v_curr_number IS NULL THEN
            v_curr_number := 1;
            INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
            VALUES (p_document_type_id, v_doc_prefix, 2, 1, v_fiscal_year, true);
        ELSE
            UPDATE public."Consecutive" 
            SET "currentNumber" = "currentNumber" + 1 
            WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_fiscal_year;
        END IF;

        v_final_entry_number := COALESCE(p_entry_number, CONCAT(COALESCE(v_doc_prefix, 'DOC'), '-', v_fiscal_year, '-', LPAD(v_curr_number::TEXT, 6, '0')));

        -- Calcular totales de débito y crédito del JSON
        IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
            FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
            LOOP
                v_total_debit := v_total_debit + COALESCE((v_item->>'debit')::NUMERIC, 0);
                v_total_credit := v_total_credit + COALESCE((v_item->>'credit')::NUMERIC, 0);
            END LOOP;
        END IF;

        INSERT INTO public."JournalEntry" (
            "companyId", "documentTypeId", "consecutiveNumber", "entryNumber",
            "entryDate", "thirdPartyId", concept, observation,
            "totalDebit", "totalCredit", status, "createdById",
            "createdAt", "updatedAt"
        ) VALUES (
            p_company_id, p_document_type_id, v_curr_number, v_final_entry_number,
            p_entry_date, p_third_party_id, p_concept, p_observation,
            v_total_debit, v_total_credit, v_status, p_user_id,
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        ) RETURNING id INTO v_journal_id;

        p_created_id := v_journal_id;
    ELSE
        v_journal_id := p_id;
        p_created_id := p_id;

        -- Validar que no esté contabilizado si se va a editar
        SELECT status INTO v_status FROM public."JournalEntry" WHERE id = v_journal_id;
        IF v_status = 'POSTED' THEN
            RAISE EXCEPTION '❌ Comprobante ya Contabilizado: No se puede editar directamente un comprobante en estado POSTED. Use la opción de Ajuste o Reversión.';
        END IF;
        IF v_status = 'ANNULLED' THEN
            RAISE EXCEPTION '❌ Comprobante Anulado: No se puede modificar un comprobante anulado.';
        END IF;

        -- Recalcular totales
        IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
            FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
            LOOP
                v_total_debit := v_total_debit + COALESCE((v_item->>'debit')::NUMERIC, 0);
                v_total_credit := v_total_credit + COALESCE((v_item->>'credit')::NUMERIC, 0);
            END LOOP;
        END IF;

        UPDATE public."JournalEntry"
        SET 
            "companyId" = p_company_id,
            "documentTypeId" = p_document_type_id,
            "entryDate" = p_entry_date,
            "thirdPartyId" = p_third_party_id,
            concept = p_concept,
            observation = p_observation,
            "totalDebit" = v_total_debit,
            "totalCredit" = v_total_credit,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = v_journal_id;

        -- Eliminar líneas previas para reinsertar las nuevas
        DELETE FROM public."JournalEntryItem" WHERE "journalEntryId" = v_journal_id;
    END IF;

    -- Inserción de líneas de detalle
    IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
        LOOP
            INSERT INTO public."JournalEntryItem" (
                "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
                debit, credit, "baseAmount", description, "documentReference",
                "createdAt", "updatedAt"
            ) VALUES (
                v_journal_id,
                (v_item->>'accountId')::INT,
                NULLIF((v_item->>'thirdPartyId')::INT, 0),
                NULLIF((v_item->>'costCenterId')::INT, 0),
                COALESCE((v_item->>'debit')::NUMERIC, 0),
                COALESCE((v_item->>'credit')::NUMERIC, 0),
                COALESCE((v_item->>'baseAmount')::NUMERIC, 0),
                v_item->>'description',
                v_item->>'documentReference',
                CURRENT_TIMESTAMP,
                CURRENT_TIMESTAMP
            );
        END LOOP;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spComprobanteReversar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - MOTOR DE REVERSIÓN AUTOMÁTICA (POSTGRESQL)
-- Archivo: SQL/Procedure/spComprobanteReversar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spComprobanteReversar"(INT, TEXT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spComprobanteReversar"(
    IN p_journal_id INT,
    IN p_reason TEXT,
    IN p_user_id INT,
    OUT p_reverse_journal_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_orig RECORD;
    v_aj_doc_type_id INT;
    v_fiscal_year INT;
    v_doc_prefix VARCHAR;
    v_curr_number INT;
    v_new_entry_number VARCHAR;
    v_new_id INT;
    v_item RECORD;
BEGIN
    -- 1. Obtener comprobante origen
    SELECT * INTO v_orig FROM public."JournalEntry" WHERE id = p_journal_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Error: El comprobante origen #% no existe.', p_journal_id;
    END IF;

    IF v_orig.status <> 'POSTED' THEN
        RAISE EXCEPTION '❌ Error: Solo se pueden reversar comprobantes formalmente contabilizados (estado POSTED).';
    END IF;

    -- 2. Obtener tipo de documento de Ajuste ('AJ') o usar el mismo tipo
    SELECT id, prefix INTO v_aj_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'AJ';
    IF v_aj_doc_type_id IS NULL THEN
        v_aj_doc_type_id := v_orig."documentTypeId";
        SELECT prefix INTO v_doc_prefix FROM public."DocumentType" WHERE id = v_aj_doc_type_id;
    END IF;

    v_fiscal_year := EXTRACT(YEAR FROM CURRENT_DATE)::INT;

    -- Consecutivo
    SELECT "currentNumber" INTO v_curr_number 
    FROM public."Consecutive" 
    WHERE "documentTypeId" = v_aj_doc_type_id AND "fiscalYear" = v_fiscal_year;

    IF v_curr_number IS NULL THEN
        v_curr_number := 1;
        INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (v_aj_doc_type_id, v_doc_prefix, 2, 1, v_fiscal_year, true);
    ELSE
        UPDATE public."Consecutive" 
        SET "currentNumber" = "currentNumber" + 1 
        WHERE "documentTypeId" = v_aj_doc_type_id AND "fiscalYear" = v_fiscal_year;
    END IF;

    v_new_entry_number := CONCAT(COALESCE(v_doc_prefix, 'AJ'), '-', v_fiscal_year, '-', LPAD(v_curr_number::TEXT, 6, '0'));

    -- 3. Crear encabezado del comprobante de reversión (invertido)
    INSERT INTO public."JournalEntry" (
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber",
        "entryDate", "thirdPartyId", concept, observation,
        "totalDebit", "totalCredit", status, "createdById",
        "postedAt", "createdAt", "updatedAt"
    ) VALUES (
        v_orig."companyId", v_aj_doc_type_id, v_curr_number, v_new_entry_number,
        CURRENT_TIMESTAMP, v_orig."thirdPartyId",
        CONCAT('REVERSIÓN DE ', v_orig."entryNumber", ': ', COALESCE(p_reason, 'Ajuste contable inverso')),
        CONCAT('Documento de reversión generado automáticamente del comprobante original ID #', v_orig.id),
        v_orig."totalCredit", -- Débito nuevo = Crédito original
        v_orig."totalDebit",  -- Crédito nuevo = Débito original
        'POSTED',
        p_user_id,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ) RETURNING id INTO v_new_id;

    p_reverse_journal_id := v_new_id;

    -- 4. Copiar asientos invirtiendo Débito y Crédito
    FOR v_item IN SELECT * FROM public."JournalEntryItem" WHERE "journalEntryId" = p_journal_id
    LOOP
        INSERT INTO public."JournalEntryItem" (
            "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
            debit, credit, "baseAmount", description, "documentReference",
            "createdAt", "updatedAt"
        ) VALUES (
            v_new_id,
            v_item."accountId",
            v_item."thirdPartyId",
            v_item."costCenterId",
            v_item.credit, -- Se invierte
            v_item.debit,  -- Se invierte
            v_item."baseAmount",
            CONCAT('Rev. ', COALESCE(v_item.description, '')),
            v_orig."entryNumber",
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END LOOP;
END;
$$;


-- --- PROCEDIMIENTO: spConciliacionBancariaCalcular.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS DE CONCILIACIÓN BANCARIA (POSTGRESQL)
-- Archivo: SQL/Procedure/spConciliacionBancariaCalcular.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spConciliacionBancariaCalcular"(INT, INT, INT, NUMERIC, NUMERIC, TEXT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spConciliacionBancariaCalcular"(
    IN p_company_id INT,
    IN p_bank_account_id INT,
    IN p_year INT,
    IN p_month INT,
    IN p_statement_balance NUMERIC(18, 4),
    IN p_initial_balance NUMERIC(18, 4),
    IN p_observations TEXT,
    IN p_user_id INT,
    OUT p_reconciliation_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_account_id INT;
    v_book_balance NUMERIC(18, 4) := 0;
    v_difference NUMERIC(18, 4) := 0;
    v_rec_id INT;
BEGIN
    -- 1. Obtener la cuenta contable asociada a la cuenta bancaria
    SELECT "accountId" INTO v_account_id FROM public."BankAccount" WHERE id = p_bank_account_id;
    IF v_account_id IS NULL THEN
        RAISE EXCEPTION '❌ Error: La cuenta bancaria no posee cuenta contable PUC configurada.';
    END IF;

    -- 2. Calcular saldo en libros acumulado hasta el fin del mes especificado
    SELECT 
        COALESCE(SUM(ji.debit) - SUM(ji.credit), 0) INTO v_book_balance
    FROM public."JournalEntryItem" ji
    INNER JOIN public."JournalEntry" j ON ji."journalEntryId" = j.id
    WHERE ji."accountId" = v_account_id
      AND j.status = 'POSTED'
      AND j."entryDate" <= (MAKE_DATE(p_year, p_month, 1) + INTERVAL '1 MONTH - 1 DAY')::TIMESTAMP;

    -- 3. Calcular diferencia conciliatoria (Saldo en Libros vs Saldo según Extracto)
    v_difference := v_book_balance - COALESCE(p_statement_balance, 0);

    -- 4. Guardar o actualizar registro de conciliación
    INSERT INTO public."BankReconciliation" (
        "companyId", "bankAccountId", year, month,
        "initialBalance", "finalBankStatementBalance", "bookBalance", difference,
        status, observations, "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, p_bank_account_id, p_year, p_month,
        COALESCE(p_initial_balance, 0), COALESCE(p_statement_balance, 0), v_book_balance, v_difference,
        'DRAFT', p_observations, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    )
    ON CONFLICT ("bankAccountId", year, month)
    DO UPDATE SET 
        "initialBalance" = EXCLUDED."initialBalance",
        "finalBankStatementBalance" = EXCLUDED."finalBankStatementBalance",
        "bookBalance" = EXCLUDED."bookBalance",
        difference = EXCLUDED.difference,
        observations = EXCLUDED.observations,
        "updatedAt" = CURRENT_TIMESTAMP
    RETURNING id INTO v_rec_id;

    p_reconciliation_id := v_rec_id;
END;
$$;


-- --- PROCEDIMIENTO: spConciliacionBancariaCerrar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE CIERRE DE CONCILIACIÓN BANCARIA (POSTGRESQL)
-- Archivo: SQL/Procedure/spConciliacionBancariaCerrar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spConciliacionBancariaCerrar"(INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spConciliacionBancariaCerrar"(
    IN p_reconciliation_id INT,
    IN p_user_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public."BankReconciliation"
    SET 
        status = 'CLOSED',
        "closedAt" = CURRENT_TIMESTAMP,
        "closedById" = p_user_id,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_reconciliation_id;
END;
$$;


-- --- PROCEDIMIENTO: spConsecutiveGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spConsecutiveGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spConsecutiveGuardar"(INT, INT, VARCHAR, INT, INT, INT, INT, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spConsecutiveGuardar"(
    IN p_id INT,
    IN p_doc_type_id INT,
    IN p_prefix VARCHAR,
    IN p_current_number INT,
    IN p_initial_number INT,
    IN p_final_number INT,
    IN p_fiscal_year INT,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."Consecutive" (
            "documentTypeId", prefix, "currentNumber", "initialNumber",
            "finalNumber", "fiscalYear", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            p_doc_type_id, p_prefix, COALESCE(p_current_number, 1), COALESCE(p_initial_number, 1),
            p_final_number, p_fiscal_year, COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."Consecutive"
        SET 
            "documentTypeId" = p_doc_type_id,
            prefix = p_prefix,
            "currentNumber" = COALESCE(p_current_number, "currentNumber"),
            "initialNumber" = COALESCE(p_initial_number, "initialNumber"),
            "finalNumber" = p_final_number,
            "fiscalYear" = p_fiscal_year,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spCostCenterGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spCostCenterGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spCostCenterGuardar"(INT, VARCHAR, VARCHAR, INT, INT, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spCostCenterGuardar"(
    IN p_id INT,
    IN p_code VARCHAR,
    IN p_name VARCHAR,
    IN p_level INT,
    IN p_parent_id INT,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."CostCenter" (
            code, name, level, "parentId", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            TRIM(p_code), TRIM(p_name), COALESCE(p_level, 1), p_parent_id, COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."CostCenter"
        SET 
            code = TRIM(p_code),
            name = TRIM(p_name),
            level = COALESCE(p_level, level),
            "parentId" = p_parent_id,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spDocumentTypeGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spDocumentTypeGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spDocumentTypeGuardar"(INT, VARCHAR, VARCHAR, VARCHAR, BOOLEAN, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spDocumentTypeGuardar"(
    IN p_id INT,
    IN p_code VARCHAR,
    IN p_name VARCHAR,
    IN p_prefix VARCHAR,
    IN p_is_automatic BOOLEAN,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."DocumentType" (
            code, name, prefix, "isAutomatic", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            TRIM(p_code), TRIM(p_name), p_prefix, COALESCE(p_is_automatic, true), COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."DocumentType"
        SET 
            code = TRIM(p_code),
            name = TRIM(p_name),
            prefix = p_prefix,
            "isAutomatic" = COALESCE(p_is_automatic, "isAutomatic"),
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spFacturaCompraAnular.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spFacturaCompraAnular
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spFacturaCompraAnular";
END $$;

CREATE OR REPLACE PROCEDURE public."spFacturaCompraAnular"(
    IN p_invoice_id INTEGER,
    IN p_reason TEXT,
    IN p_user_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_paid_amount NUMERIC(18, 4);
    v_journal_id INTEGER;
BEGIN
    SELECT "paidAmount", "journalEntryId" INTO v_paid_amount, v_journal_id
    FROM public."PayableInvoice"
    WHERE id = p_invoice_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ La factura de compra con ID % no existe', p_invoice_id;
    END IF;

    IF COALESCE(v_paid_amount, 0) > 0 THEN
        RAISE EXCEPTION '❌ No se puede anular la factura de compra porque ya posee pagos o egresos aplicados ($%)', v_paid_amount;
    END IF;

    -- Anular factura y cuotas
    UPDATE public."PayableInvoice"
    SET status = 'ANNULLED', observations = COALESCE(observations, '') || ' | ANULADA: ' || p_reason, "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_invoice_id;

    UPDATE public."PayableInstallment"
    SET status = 'ANNULLED', "updatedAt" = CURRENT_TIMESTAMP
    WHERE "payableInvoiceId" = p_invoice_id;

    -- Anular comprobante contable
    IF v_journal_id IS NOT NULL THEN
        UPDATE public."JournalEntry"
        SET status = 'ANNULLED', "annulledAt" = CURRENT_TIMESTAMP, "annulmentReason" = p_reason
        WHERE id = v_journal_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spFacturaCompraCrear.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spFacturaCompraCrear
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spFacturaCompraCrear";
END $$;

CREATE OR REPLACE PROCEDURE public."spFacturaCompraCrear"(
    IN p_company_id INTEGER,
    IN p_third_party_id INTEGER,
    IN p_document_type_id INTEGER,
    IN p_invoice_number VARCHAR(50),
    IN p_issue_date TIMESTAMP WITH TIME ZONE,
    IN p_payment_term_days INTEGER,
    IN p_subtotal NUMERIC(18, 4),
    IN p_tax_amount NUMERIC(18, 4),
    IN p_retention_amount NUMERIC(18, 4),
    IN p_account_expense_id INTEGER,
    IN p_account_payable_id INTEGER,
    IN p_account_tax_id INTEGER,
    IN p_cost_center_id INTEGER,
    IN p_created_by_id INTEGER,
    IN p_observations TEXT,
    IN p_installments_count INTEGER,
    OUT p_payable_id INTEGER,
    OUT p_internal_number VARCHAR(50),
    OUT p_journal_entry_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_year INTEGER;
    v_month INTEGER;
    v_period_status VARCHAR(20);
    v_prefix VARCHAR(10);
    v_consecutive INTEGER;
    v_total NUMERIC(18, 4);
    v_due_date TIMESTAMP WITH TIME ZONE;
    v_inst_amount NUMERIC(18, 4);
    v_inst_date TIMESTAMP WITH TIME ZONE;
    v_i INTEGER;
BEGIN
    v_year := EXTRACT(YEAR FROM p_issue_date);
    v_month := EXTRACT(MONTH FROM p_issue_date);
    
    -- Validar período abierto
    SELECT status INTO v_period_status FROM public."FiscalPeriod" WHERE year = v_year AND month = v_month;
    IF v_period_status = 'CLOSED' THEN
        RAISE EXCEPTION '❌ No se puede causar factura de compra en un período fiscal cerrado (% - %)', v_year, v_month;
    END IF;

    -- Consecutivo interno para FC
    SELECT prefix, "currentNumber" INTO v_prefix, v_consecutive 
    FROM public."Consecutive"
    WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_year
    FOR UPDATE;

    IF v_consecutive IS NULL THEN
        v_prefix := 'FC';
        v_consecutive := 1;
        INSERT INTO public."Consecutive"("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (p_document_type_id, v_prefix, 2, 1, v_year, TRUE);
    ELSE
        UPDATE public."Consecutive" SET "currentNumber" = v_consecutive + 1 WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_year;
    END IF;

    p_internal_number := COALESCE(v_prefix, 'FC') || '-' || v_year::TEXT || '-' || LPAD(v_consecutive::TEXT, 6, '0');
    v_total := COALESCE(p_subtotal, 0) + COALESCE(p_tax_amount, 0) - COALESCE(p_retention_amount, 0);
    v_due_date := p_issue_date + (COALESCE(p_payment_term_days, 0) || ' days')::INTERVAL;

    -- Insertar Factura de Compra
    INSERT INTO public."PayableInvoice"(
        "companyId", "thirdPartyId", "documentTypeId", "consecutiveNumber", "invoiceNumber", "internalNumber",
        "issueDate", "dueDate", "paymentTermDays", subtotal, "taxAmount", "retentionAmount",
        "totalAmount", "paidAmount", "balanceAmount", status, "createdById", observations
    ) VALUES (
        p_company_id, p_third_party_id, p_document_type_id, v_consecutive, p_invoice_number, p_internal_number,
        p_issue_date, v_due_date, COALESCE(p_payment_term_days, 0), p_subtotal, COALESCE(p_tax_amount, 0),
        COALESCE(p_retention_amount, 0), v_total, 0, v_total, 'POSTED', p_created_by_id, p_observations
    ) RETURNING id INTO p_payable_id;

    -- Generar Cuotas de CxP
    v_i := 1;
    IF COALESCE(p_installments_count, 1) <= 1 THEN
        INSERT INTO public."PayableInstallment"("payableInvoiceId", "installmentNumber", "dueDate", amount, "paidAmount", "balanceAmount", status)
        VALUES (p_payable_id, 1, v_due_date, v_total, 0, v_total, 'PENDING');
    ELSE
        v_inst_amount := ROUND(v_total / p_installments_count, 4);
        WHILE v_i <= p_installments_count LOOP
            v_inst_date := p_issue_date + ((v_i * p_payment_term_days / p_installments_count) || ' days')::INTERVAL;
            INSERT INTO public."PayableInstallment"("payableInvoiceId", "installmentNumber", "dueDate", amount, "paidAmount", "balanceAmount", status)
            VALUES (p_payable_id, v_i, v_inst_date, v_inst_amount, 0, v_inst_amount, 'PENDING');
            v_i := v_i + 1;
        END LOOP;
    END IF;

    -- Generar Comprobante Contable FC automático (Partida Doble)
    INSERT INTO public."JournalEntry"(
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber", "entryDate",
        "thirdPartyId", concept, observation, "totalDebit", "totalCredit", status, "createdById", "postedAt"
    ) VALUES (
        p_company_id, p_document_type_id, v_consecutive, p_internal_number, p_issue_date,
        p_third_party_id, 'Causación Compra ' || p_invoice_number || ' (' || p_internal_number || ')', p_observations,
        COALESCE(p_subtotal, 0) + COALESCE(p_tax_amount, 0), v_total + COALESCE(p_retention_amount, 0),
        'POSTED', p_created_by_id, CURRENT_TIMESTAMP
    ) RETURNING id INTO p_journal_entry_id;

    -- Débito: Gasto / Costo / Inventario (Subtotal)
    INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", "costCenterId", debit, credit, description, "documentReference")
    VALUES (p_journal_entry_id, p_account_expense_id, p_third_party_id, p_cost_center_id, p_subtotal, 0, 'Gasto/Compra Factura ' || p_invoice_number, p_invoice_number);

    -- Débito: IVA Descontable (si aplica)
    IF COALESCE(p_tax_amount, 0) > 0 AND p_account_tax_id IS NOT NULL THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_tax_id, p_third_party_id, p_cost_center_id, p_tax_amount, 0, 'IVA Descontable Factura ' || p_invoice_number, p_invoice_number);
    END IF;

    -- Crédito: Retención en la Fuente practicada (si aplica)
    IF COALESCE(p_retention_amount, 0) > 0 THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, (SELECT id FROM public."Account" WHERE code = '236540' LIMIT 1), p_third_party_id, p_cost_center_id, 0, p_retention_amount, 'Retefuente Practicada Factura ' || p_invoice_number, p_invoice_number);
    END IF;

    -- Crédito: Proveedor / CxP (Total Neto a Pagar)
    INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", "costCenterId", debit, credit, description, "documentReference")
    VALUES (p_journal_entry_id, p_account_payable_id, p_third_party_id, p_cost_center_id, 0, v_total, 'CxP Proveedor Factura ' || p_invoice_number, p_invoice_number);

    -- Enlazar JournalEntry en Factura
    UPDATE public."PayableInvoice" SET "journalEntryId" = p_journal_entry_id WHERE id = p_payable_id;
END;
$$;


-- --- PROCEDIMIENTO: spFacturaVentaAnular.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spFacturaVentaAnular
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spFacturaVentaAnular";
END $$;

CREATE OR REPLACE PROCEDURE public."spFacturaVentaAnular"(
    IN p_invoice_id INTEGER,
    IN p_reason TEXT,
    IN p_user_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_paid_amount NUMERIC(18, 4);
    v_journal_id INTEGER;
BEGIN
    SELECT "paidAmount", "journalEntryId" INTO v_paid_amount, v_journal_id
    FROM public."ReceivableInvoice"
    WHERE id = p_invoice_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ La factura de venta con ID % no existe', p_invoice_id;
    END IF;

    IF COALESCE(v_paid_amount, 0) > 0 THEN
        RAISE EXCEPTION '❌ No se puede anular la factura porque ya posee abonos o recaudos aplicados ($%)', v_paid_amount;
    END IF;

    -- Anular factura y cuotas
    UPDATE public."ReceivableInvoice"
    SET status = 'ANNULLED', observations = COALESCE(observations, '') || ' | ANULADA: ' || p_reason, "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_invoice_id;

    UPDATE public."ReceivableInstallment"
    SET status = 'ANNULLED', "updatedAt" = CURRENT_TIMESTAMP
    WHERE "receivableInvoiceId" = p_invoice_id;

    -- Anular comprobante contable
    IF v_journal_id IS NOT NULL THEN
        UPDATE public."JournalEntry"
        SET status = 'ANNULLED', "annulledAt" = CURRENT_TIMESTAMP, "annulmentReason" = p_reason
        WHERE id = v_journal_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spFacturaVentaCrear.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spFacturaVentaCrear
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spFacturaVentaCrear";
END $$;

CREATE OR REPLACE PROCEDURE public."spFacturaVentaCrear"(
    IN p_company_id INTEGER,
    IN p_third_party_id INTEGER,
    IN p_document_type_id INTEGER,
    IN p_issue_date TIMESTAMP WITH TIME ZONE,
    IN p_payment_term_days INTEGER,
    IN p_subtotal NUMERIC(18, 4),
    IN p_tax_amount NUMERIC(18, 4),
    IN p_retention_amount NUMERIC(18, 4),
    IN p_account_income_id INTEGER,
    IN p_account_receivable_id INTEGER,
    IN p_account_tax_id INTEGER,
    IN p_cost_center_id INTEGER,
    IN p_created_by_id INTEGER,
    IN p_observations TEXT,
    IN p_installments_count INTEGER,
    OUT p_invoice_id INTEGER,
    OUT p_invoice_number VARCHAR(50),
    OUT p_journal_entry_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_year INTEGER;
    v_month INTEGER;
    v_period_status VARCHAR(20);
    v_prefix VARCHAR(10);
    v_consecutive INTEGER;
    v_total NUMERIC(18, 4);
    v_due_date TIMESTAMP WITH TIME ZONE;
    v_inst_amount NUMERIC(18, 4);
    v_inst_date TIMESTAMP WITH TIME ZONE;
    v_i INTEGER;
    v_journal_num VARCHAR(50);
BEGIN
    v_year := EXTRACT(YEAR FROM p_issue_date);
    v_month := EXTRACT(MONTH FROM p_issue_date);
    
    -- Validar período abierto
    SELECT status INTO v_period_status FROM public."FiscalPeriod" WHERE year = v_year AND month = v_month;
    IF v_period_status = 'CLOSED' THEN
        RAISE EXCEPTION '❌ No se puede emitir factura en un período fiscal cerrado (% - %)', v_year, v_month;
    END IF;

    -- Consecutivo
    SELECT prefix, "currentNumber" INTO v_prefix, v_consecutive 
    FROM public."Consecutive"
    WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_year
    FOR UPDATE;

    IF v_consecutive IS NULL THEN
        v_prefix := 'FV';
        v_consecutive := 1;
        INSERT INTO public."Consecutive"("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (p_document_type_id, v_prefix, 2, 1, v_year, TRUE);
    ELSE
        UPDATE public."Consecutive" SET "currentNumber" = v_consecutive + 1 WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_year;
    END IF;

    p_invoice_number := COALESCE(v_prefix, 'FV') || '-' || v_year::TEXT || '-' || LPAD(v_consecutive::TEXT, 6, '0');
    v_total := COALESCE(p_subtotal, 0) + COALESCE(p_tax_amount, 0) - COALESCE(p_retention_amount, 0);
    v_due_date := p_issue_date + (COALESCE(p_payment_term_days, 0) || ' days')::INTERVAL;

    -- Insertar Factura de Venta
    INSERT INTO public."ReceivableInvoice"(
        "companyId", "thirdPartyId", "documentTypeId", "consecutiveNumber", "invoiceNumber",
        "issueDate", "dueDate", "paymentTermDays", subtotal, "taxAmount", "retentionAmount",
        "totalAmount", "paidAmount", "balanceAmount", status, "createdById", observations
    ) VALUES (
        p_company_id, p_third_party_id, p_document_type_id, v_consecutive, p_invoice_number,
        p_issue_date, v_due_date, COALESCE(p_payment_term_days, 0), p_subtotal, COALESCE(p_tax_amount, 0),
        COALESCE(p_retention_amount, 0), v_total, 0, v_total, 'POSTED', p_created_by_id, p_observations
    ) RETURNING id INTO p_invoice_id;

    -- Generar Cuotas de Amortización / Vencimiento
    v_i := 1;
    IF COALESCE(p_installments_count, 1) <= 1 THEN
        INSERT INTO public."ReceivableInstallment"("receivableInvoiceId", "installmentNumber", "dueDate", amount, "paidAmount", "balanceAmount", status)
        VALUES (p_invoice_id, 1, v_due_date, v_total, 0, v_total, 'PENDING');
    ELSE
        v_inst_amount := ROUND(v_total / p_installments_count, 4);
        WHILE v_i <= p_installments_count LOOP
            v_inst_date := p_issue_date + ((v_i * p_payment_term_days / p_installments_count) || ' days')::INTERVAL;
            INSERT INTO public."ReceivableInstallment"("receivableInvoiceId", "installmentNumber", "dueDate", amount, "paidAmount", "balanceAmount", status)
            VALUES (p_invoice_id, v_i, v_inst_date, v_inst_amount, 0, v_inst_amount, 'PENDING');
            v_i := v_i + 1;
        END LOOP;
    END IF;

    -- Generar Comprobante Contable FV automático (Partida Doble)
    INSERT INTO public."JournalEntry"(
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber", "entryDate",
        "thirdPartyId", concept, observation, "totalDebit", "totalCredit", status, "createdById", "postedAt"
    ) VALUES (
        p_company_id, p_document_type_id, v_consecutive, p_invoice_number, p_issue_date,
        p_third_party_id, 'Factura de Venta ' || p_invoice_number, p_observations,
        v_total + COALESCE(p_retention_amount, 0), COALESCE(p_subtotal, 0) + COALESCE(p_tax_amount, 0),
        'POSTED', p_created_by_id, CURRENT_TIMESTAMP
    ) RETURNING id INTO p_journal_entry_id;

    -- Débito: Clientes / CxC (Total Neto por Cobrar)
    INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", "costCenterId", debit, credit, description, "documentReference")
    VALUES (p_journal_entry_id, p_account_receivable_id, p_third_party_id, p_cost_center_id, v_total, 0, 'CxC Cliente Factura ' || p_invoice_number, p_invoice_number);

    -- Débito: Retenciones practicadas (si aplica)
    IF COALESCE(p_retention_amount, 0) > 0 THEN
        -- Usar cuenta 135515 (Anticipo Retefuente) si no se especifica
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, (SELECT id FROM public."Account" WHERE code = '135515' LIMIT 1), p_third_party_id, p_cost_center_id, p_retention_amount, 0, 'Retención Practicada Factura ' || p_invoice_number, p_invoice_number);
    END IF;

    -- Crédito: Ingreso por Ventas (Subtotal)
    INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", "costCenterId", debit, credit, description, "documentReference")
    VALUES (p_journal_entry_id, p_account_income_id, p_third_party_id, p_cost_center_id, 0, p_subtotal, 'Ingreso por Venta Factura ' || p_invoice_number, p_invoice_number);

    -- Crédito: IVA Generado (si aplica)
    IF COALESCE(p_tax_amount, 0) > 0 AND p_account_tax_id IS NOT NULL THEN
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", "costCenterId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_tax_id, p_third_party_id, p_cost_center_id, 0, p_tax_amount, 'IVA Generado Factura ' || p_invoice_number, p_invoice_number);
    END IF;

    -- Enlazar JournalEntry en Factura
    UPDATE public."ReceivableInvoice" SET "journalEntryId" = p_journal_entry_id WHERE id = p_invoice_id;
END;
$$;


-- --- PROCEDIMIENTO: spIntegrationTransactionRegistrar.sql ---
-- ============================================================================
-- PROYECTO: KOREX_CONTABILIDAD
-- PROCEDIMIENTO: spIntegrationTransactionRegistrar
-- DESCRIPCION: Registro de auditoría y telemetría de transacciones e interfaces de datos
-- ============================================================================

CREATE OR REPLACE PROCEDURE public."spIntegrationTransactionRegistrar"(
    IN p_endpoint_code VARCHAR(50),
    IN p_direction VARCHAR(20),
    IN p_event_type VARCHAR(50),
    IN p_request_payload JSONB,
    IN p_response_payload JSONB,
    IN p_http_status INTEGER,
    IN p_duration_ms INTEGER,
    IN p_status VARCHAR(20),
    IN p_error_message TEXT,
    OUT p_tx_code VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_date_str VARCHAR(8);
    v_seq_num INTEGER;
BEGIN
    v_date_str := TO_CHAR(CURRENT_DATE, 'YYYYMMDD');
    
    SELECT COUNT(id) + 1 INTO v_seq_num
    FROM public."IntegrationTransaction"
    WHERE "txCode" LIKE 'ITX-' || v_date_str || '-%';

    p_tx_code := 'ITX-' || v_date_str || '-' || LPAD(v_seq_num::TEXT, 4, '0');

    INSERT INTO public."IntegrationTransaction" (
        "txCode", "endpointCode", "direction", "eventType",
        "requestPayload", "responsePayload", "httpStatus",
        "durationMs", "status", "errorMessage", "createdAt"
    ) VALUES (
        p_tx_code, p_endpoint_code, p_direction, p_event_type,
        p_request_payload, p_response_payload, p_http_status,
        COALESCE(p_duration_ms, 0), COALESCE(p_status, 'SUCCESS'),
        p_error_message, CURRENT_TIMESTAMP
    );
END;
$$;


-- --- PROCEDIMIENTO: spNotaCarteraCrear.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spNotaCarteraCrear
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spNotaCarteraCrear";
END $$;

CREATE OR REPLACE PROCEDURE public."spNotaCarteraCrear"(
    IN p_company_id INTEGER,
    IN p_note_type VARCHAR(30),
    IN p_document_type_id INTEGER,
    IN p_third_party_id INTEGER,
    IN p_receivable_invoice_id INTEGER,
    IN p_payable_invoice_id INTEGER,
    IN p_concept TEXT,
    IN p_subtotal NUMERIC(18, 4),
    IN p_tax_amount NUMERIC(18, 4),
    IN p_account_concept_id INTEGER,
    IN p_account_counterpart_id INTEGER,
    IN p_created_by_id INTEGER,
    IN p_observations TEXT,
    OUT p_note_id INTEGER,
    OUT p_note_number VARCHAR(50),
    OUT p_journal_entry_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_year INTEGER;
    v_month INTEGER;
    v_period_status VARCHAR(20);
    v_prefix VARCHAR(10);
    v_consecutive INTEGER;
    v_total NUMERIC(18, 4);
    v_auto_cross_id INTEGER;
    v_new_bal NUMERIC(18, 4);
    v_stat VARCHAR(20);
BEGIN
    v_year := EXTRACT(YEAR FROM CURRENT_TIMESTAMP);
    v_month := EXTRACT(MONTH FROM CURRENT_TIMESTAMP);
    
    -- Validar período abierto
    SELECT status INTO v_period_status FROM public."FiscalPeriod" WHERE year = v_year AND month = v_month;
    IF v_period_status = 'CLOSED' THEN
        RAISE EXCEPTION '❌ No se puede emitir nota en un período fiscal cerrado (% - %)', v_year, v_month;
    END IF;

    -- Consecutivo para NC / ND
    SELECT prefix, "currentNumber" INTO v_prefix, v_consecutive 
    FROM public."Consecutive"
    WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_year
    FOR UPDATE;

    IF v_consecutive IS NULL THEN
        v_prefix := CASE WHEN p_note_type LIKE 'NC%' THEN 'NC' ELSE 'ND' END;
        v_consecutive := 1;
        INSERT INTO public."Consecutive"("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (p_document_type_id, v_prefix, 2, 1, v_year, TRUE);
    ELSE
        UPDATE public."Consecutive" SET "currentNumber" = v_consecutive + 1 WHERE "documentTypeId" = p_document_type_id AND "fiscalYear" = v_year;
    END IF;

    p_note_number := COALESCE(v_prefix, 'NC') || '-' || v_year::TEXT || '-' || LPAD(v_consecutive::TEXT, 6, '0');
    v_total := COALESCE(p_subtotal, 0) + COALESCE(p_tax_amount, 0);

    -- Insertar Nota
    INSERT INTO public."CreditDebitNote"(
        "companyId", "noteType", "documentTypeId", "consecutiveNumber", "noteNumber",
        "noteDate", "thirdPartyId", "receivableInvoiceId", "payableInvoiceId", concept,
        subtotal, "taxAmount", "totalAmount", "appliedAmount", "balanceAmount",
        status, "createdById", observations
    ) VALUES (
        p_company_id, p_note_type, p_document_type_id, v_consecutive, p_note_number,
        CURRENT_TIMESTAMP, p_third_party_id, p_receivable_invoice_id, p_payable_invoice_id, p_concept,
        p_subtotal, COALESCE(p_tax_amount, 0), v_total, 0, v_total,
        'POSTED', p_created_by_id, p_observations
    ) RETURNING id INTO p_note_id;

    -- Generar Comprobante Contable NC / ND automático (Partida Doble)
    INSERT INTO public."JournalEntry"(
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber", "entryDate",
        "thirdPartyId", concept, observation, "totalDebit", "totalCredit", status, "createdById", "postedAt"
    ) VALUES (
        p_company_id, p_document_type_id, v_consecutive, p_note_number, CURRENT_TIMESTAMP,
        p_third_party_id, 'Nota ' || p_note_type || ' ' || p_note_number, p_observations,
        v_total, v_total, 'POSTED', p_created_by_id, CURRENT_TIMESTAMP
    ) RETURNING id INTO p_journal_entry_id;

    IF p_note_type = 'NC_CLIENTE' THEN
        -- Débito: Devolución en ventas / Descuento (Concepto)
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_concept_id, p_third_party_id, p_subtotal, 0, 'Devolución/Rebaja NC ' || p_note_number, p_note_number);

        -- Débito: IVA Descontable / Reversión (si aplica)
        IF COALESCE(p_tax_amount, 0) > 0 THEN
            INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
            VALUES (p_journal_entry_id, (SELECT id FROM public."Account" WHERE code = '240805' LIMIT 1), p_third_party_id, p_tax_amount, 0, 'IVA en Devolución NC ' || p_note_number, p_note_number);
        END IF;

        -- Crédito: CxC Clientes (Contrapartida)
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_counterpart_id, p_third_party_id, 0, v_total, 'Disminución CxC NC ' || p_note_number, p_note_number);

    ELSIF p_note_type = 'ND_CLIENTE' THEN
        -- Débito: CxC Clientes
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_counterpart_id, p_third_party_id, v_total, 0, 'Mayor Valor CxC ND ' || p_note_number, p_note_number);

        -- Crédito: Ingreso / Intereses (Concepto)
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_concept_id, p_third_party_id, 0, v_total, 'Ingreso/Interés ND ' || p_note_number, p_note_number);

    ELSIF p_note_type = 'NC_PROVEEDOR' THEN
        -- Débito: CxP Proveedores
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_counterpart_id, p_third_party_id, v_total, 0, 'Disminución CxP NC Prov ' || p_note_number, p_note_number);

        -- Crédito: Gasto / Devolución Compras
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_concept_id, p_third_party_id, 0, v_total, 'Devolución Compra NC ' || p_note_number, p_note_number);

    ELSE -- ND_PROVEEDOR
        -- Débito: Gasto / Intereses
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_concept_id, p_third_party_id, v_total, 0, 'Mayor Gasto ND Prov ' || p_note_number, p_note_number);

        -- Crédito: CxP Proveedores
        INSERT INTO public."JournalEntryItem"("journalEntryId", "accountId", "thirdPartyId", debit, credit, description, "documentReference")
        VALUES (p_journal_entry_id, p_account_counterpart_id, p_third_party_id, 0, v_total, 'Mayor Valor CxP ND ' || p_note_number, p_note_number);
    END IF;

    -- Enlazar comprobante contable
    UPDATE public."CreditDebitNote" SET "journalEntryId" = p_journal_entry_id WHERE id = p_note_id;

    -- Si está vinculada a factura de venta y es NC_CLIENTE, cruzar automáticamente
    IF p_receivable_invoice_id IS NOT NULL AND p_note_type = 'NC_CLIENTE' THEN
        CALL public."spCarteraReciboCruzar"(p_receivable_invoice_id, NULL, NULL, NULL, p_note_id, v_total, 0, 0, 'Cruce automático con ' || p_note_number, v_auto_cross_id, v_new_bal, v_stat);
    END IF;

    -- Si está vinculada a factura de compra y es NC_PROVEEDOR, cruzar automáticamente
    IF p_payable_invoice_id IS NOT NULL AND p_note_type = 'NC_PROVEEDOR' THEN
        CALL public."spProveedorEgresoCruzar"(p_payable_invoice_id, NULL, NULL, NULL, p_note_id, v_total, 0, 'Cruce automático con ' || p_note_number, v_auto_cross_id, v_new_bal, v_stat);
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spPeriodoCerrar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE CIERRE Y REAPERTURA DE PERÍODO (POSTGRESQL)
-- Archivo: SQL/Procedure/spPeriodoCerrar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spPeriodoCerrar"(INT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spPeriodoCerrar"(
    IN p_year INT,
    IN p_month INT,
    IN p_user_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_draft_count INT;
BEGIN
    -- Validar que no existan comprobantes pendientes en borrador para el mes a cerrar
    SELECT COUNT(*) INTO v_draft_count
    FROM public."JournalEntry"
    WHERE EXTRACT(YEAR FROM "entryDate")::INT = p_year 
      AND EXTRACT(MONTH FROM "entryDate")::INT = p_month
      AND status = 'DRAFT';

    IF v_draft_count > 0 THEN
        RAISE EXCEPTION '❌ No se puede cerrar el período: Existen % comprobantes en estado BORRADOR (DRAFT) para el período %-%. Debe contabilizarlos o anularlos previamente.',
            v_draft_count, p_year, LPAD(p_month::TEXT, 2, '0');
    END IF;

    -- Cerrar período
    INSERT INTO public."FiscalPeriod" (
        year, month, "startDate", "endDate", status, "closedAt", "closedBy", "createdAt", "updatedAt"
    ) VALUES (
        p_year, p_month, 
        MAKE_DATE(p_year, p_month, 1),
        (MAKE_DATE(p_year, p_month, 1) + INTERVAL '1 MONTH - 1 DAY')::TIMESTAMP,
        'CLOSED', CURRENT_TIMESTAMP, p_user_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    )
    ON CONFLICT (year, month)
    DO UPDATE SET 
        status = 'CLOSED',
        "closedAt" = CURRENT_TIMESTAMP,
        "closedBy" = p_user_id,
        "updatedAt" = CURRENT_TIMESTAMP;
END;
$$;


-- --- PROCEDIMIENTO: spPeriodoGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS DE PERÍODOS Y CIERRE ANUAL (POSTGRESQL)
-- Archivo: SQL/Procedure/spPeriodoGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spPeriodoGuardar"(INT, INT, TIMESTAMP(3), TIMESTAMP(3), VARCHAR);
END $$;

CREATE OR REPLACE PROCEDURE public."spPeriodoGuardar"(
    IN p_year INT,
    IN p_month INT,
    IN p_start_date TIMESTAMP(3),
    IN p_end_date TIMESTAMP(3),
    IN p_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public."FiscalPeriod" (
        year, month, "startDate", "endDate", status, "createdAt", "updatedAt"
    ) VALUES (
        p_year, p_month, p_start_date, p_end_date, COALESCE(p_status, 'OPEN'), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    )
    ON CONFLICT (year, month) 
    DO UPDATE SET 
        "startDate" = EXCLUDED."startDate",
        "endDate" = EXCLUDED."endDate",
        status = EXCLUDED.status,
        "updatedAt" = CURRENT_TIMESTAMP;
END;
$$;


-- --- PROCEDIMIENTO: spPeriodoReabrir.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE REAPERTURA DE PERÍODO (POSTGRESQL)
-- Archivo: SQL/Procedure/spPeriodoReabrir.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spPeriodoReabrir"(INT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spPeriodoReabrir"(
    IN p_year INT,
    IN p_month INT,
    IN p_user_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE public."FiscalPeriod"
    SET 
        status = 'OPEN',
        "closedAt" = NULL,
        "closedBy" = NULL,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE year = p_year AND month = p_month;
END;
$$;


-- --- PROCEDIMIENTO: spProveedorEgresoCruzar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO ALMACENADO: spProveedorEgresoCruzar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spProveedorEgresoCruzar";
END $$;

CREATE OR REPLACE PROCEDURE public."spProveedorEgresoCruzar"(
    IN p_payable_invoice_id INTEGER,
    IN p_payable_installment_id INTEGER,
    IN p_treasury_movement_id INTEGER,
    IN p_advance_payment_id INTEGER,
    IN p_credit_note_id INTEGER,
    IN p_amount NUMERIC(18, 4),
    IN p_discount_amount NUMERIC(18, 4),
    IN p_observations TEXT,
    OUT p_allocation_id INTEGER,
    OUT p_new_balance NUMERIC(18, 4),
    OUT p_invoice_status VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_inv_balance NUMERIC(18, 4);
    v_inst_balance NUMERIC(18, 4);
    v_total_applied NUMERIC(18, 4);
    v_adv_balance NUMERIC(18, 4);
    v_note_balance NUMERIC(18, 4);
BEGIN
    -- Validar factura de compra
    SELECT "balanceAmount" INTO v_inv_balance
    FROM public."PayableInvoice"
    WHERE id = p_payable_invoice_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION '❌ Factura de compra con ID % no encontrada', p_payable_invoice_id;
    END IF;

    v_total_applied := COALESCE(p_amount, 0) + COALESCE(p_discount_amount, 0);

    IF v_total_applied <= 0 THEN
        RAISE EXCEPTION '❌ El monto total a cruzar debe ser mayor a cero';
    END IF;

    IF v_total_applied > v_inv_balance THEN
        RAISE EXCEPTION '❌ El monto a cruzar ($%) supera el saldo pendiente de la factura ($%)', v_total_applied, v_inv_balance;
    END IF;

    -- Validar saldo de anticipo a proveedor si aplica
    IF p_advance_payment_id IS NOT NULL THEN
        SELECT "balanceAmount" INTO v_adv_balance
        FROM public."AdvancePayment"
        WHERE id = p_advance_payment_id
        FOR UPDATE;

        IF v_adv_balance < p_amount THEN
            RAISE EXCEPTION '❌ El anticipo no posee saldo disponible ($% vs $%)', v_adv_balance, p_amount;
        END IF;

        UPDATE public."AdvancePayment"
        SET "usedAmount" = "usedAmount" + p_amount,
            "balanceAmount" = "balanceAmount" - p_amount,
            status = CASE WHEN "balanceAmount" - p_amount <= 0 THEN 'EXHAUSTED' ELSE 'ACTIVE' END,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_advance_payment_id;
    END IF;

    -- Validar saldo de nota débito si aplica
    IF p_credit_note_id IS NOT NULL THEN
        SELECT "balanceAmount" INTO v_note_balance
        FROM public."CreditDebitNote"
        WHERE id = p_credit_note_id
        FOR UPDATE;

        IF v_note_balance < p_amount THEN
            RAISE EXCEPTION '❌ La Nota no posee saldo disponible ($% vs $%)', v_note_balance, p_amount;
        END IF;

        UPDATE public."CreditDebitNote"
        SET "appliedAmount" = "appliedAmount" + p_amount,
            "balanceAmount" = "balanceAmount" - p_amount,
            status = CASE WHEN "balanceAmount" - p_amount <= 0 THEN 'APPLIED' ELSE 'POSTED' END,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_credit_note_id;
    END IF;

    -- Insertar asignación de pago
    INSERT INTO public."PayablePaymentAllocation"(
        "payableInvoiceId", "payableInstallmentId", "treasuryMovementId",
        "advancePaymentId", "creditDebitNoteId", "allocationDate",
        amount, "discountAmount", observations
    ) VALUES (
        p_payable_invoice_id, p_payable_installment_id, p_treasury_movement_id,
        p_advance_payment_id, p_credit_note_id, CURRENT_TIMESTAMP,
        p_amount, COALESCE(p_discount_amount, 0), p_observations
    ) RETURNING id INTO p_allocation_id;

    -- Actualizar cuota si se especificó
    IF p_payable_installment_id IS NOT NULL THEN
        SELECT "balanceAmount" INTO v_inst_balance
        FROM public."PayableInstallment"
        WHERE id = p_payable_installment_id
        FOR UPDATE;

        UPDATE public."PayableInstallment"
        SET "paidAmount" = "paidAmount" + v_total_applied,
            "balanceAmount" = "balanceAmount" - v_total_applied,
            status = CASE WHEN "balanceAmount" - v_total_applied <= 0 THEN 'PAID' ELSE 'PARTIAL' END,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_payable_installment_id;
    END IF;

    -- Actualizar Factura
    p_new_balance := v_inv_balance - v_total_applied;
    p_invoice_status := CASE WHEN p_new_balance <= 0 THEN 'PAID' ELSE 'PARTIAL' END;

    UPDATE public."PayableInvoice"
    SET "paidAmount" = "paidAmount" + v_total_applied,
        "balanceAmount" = p_new_balance,
        status = p_invoice_status,
        "updatedAt" = CURRENT_TIMESTAMP
    WHERE id = p_payable_invoice_id;
END;
$$;


-- --- PROCEDIMIENTO: spPucGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spPucGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spPucGuardar"(INT, VARCHAR, VARCHAR, INT, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, INT, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spPucGuardar"(
    IN p_id INT,
    IN p_code VARCHAR,
    IN p_name VARCHAR,
    IN p_level INT,
    IN p_nature VARCHAR,
    IN p_allows_movement BOOLEAN,
    IN p_requires_third BOOLEAN,
    IN p_requires_cc BOOLEAN,
    IN p_parent_id INT,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_clean_code VARCHAR;
    v_parent_id INT;
BEGIN
    v_clean_code := TRIM(p_code);

    -- Validación jerárquica: Si no se pasó parent_id explícito, intentar inferirlo por longitud del código
    v_parent_id := p_parent_id;
    IF v_parent_id IS NULL AND LENGTH(v_clean_code) > 1 THEN
        IF LENGTH(v_clean_code) = 2 THEN -- Grupo -> Padre Clase (1)
            SELECT id INTO v_parent_id FROM public."Account" WHERE code = SUBSTRING(v_clean_code, 1, 1);
        ELSIF LENGTH(v_clean_code) = 4 THEN -- Cuenta -> Padre Grupo (2)
            SELECT id INTO v_parent_id FROM public."Account" WHERE code = SUBSTRING(v_clean_code, 1, 2);
        ELSIF LENGTH(v_clean_code) = 6 THEN -- Subcuenta -> Padre Cuenta (4)
            SELECT id INTO v_parent_id FROM public."Account" WHERE code = SUBSTRING(v_clean_code, 1, 4);
        ELSIF LENGTH(v_clean_code) >= 8 THEN -- Auxiliar -> Padre Subcuenta (6)
            SELECT id INTO v_parent_id FROM public."Account" WHERE code = SUBSTRING(v_clean_code, 1, 6);
        END IF;
    END IF;

    -- Si la cuenta padre tiene allowsMovement = true, se le debe desactivar el movimiento porque ahora tiene hijos
    IF v_parent_id IS NOT NULL THEN
        UPDATE public."Account" SET "allowsMovement" = false WHERE id = v_parent_id;
    END IF;

    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."Account" (
            code, name, level, nature, "allowsMovement",
            "requiresThirdParty", "requiresCostCenter", "parentId", "isActive",
            "createdAt", "updatedAt"
        ) VALUES (
            v_clean_code, TRIM(p_name), p_level, UPPER(TRIM(p_nature)), COALESCE(p_allows_movement, false),
            COALESCE(p_requires_third, false), COALESCE(p_requires_cc, false), v_parent_id, COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."Account"
        SET 
            code = v_clean_code,
            name = TRIM(p_name),
            level = p_level,
            nature = UPPER(TRIM(p_nature)),
            "allowsMovement" = COALESCE(p_allows_movement, "allowsMovement"),
            "requiresThirdParty" = COALESCE(p_requires_third, "requiresThirdParty"),
            "requiresCostCenter" = COALESCE(p_requires_cc, "requiresCostCenter"),
            "parentId" = v_parent_id,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spTaxConceptGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spTaxConceptGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spTaxConceptGuardar"(INT, VARCHAR, VARCHAR, VARCHAR, NUMERIC, NUMERIC, INT, INT, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spTaxConceptGuardar"(
    IN p_id INT,
    IN p_code VARCHAR,
    IN p_name VARCHAR,
    IN p_type VARCHAR,
    IN p_rate NUMERIC,
    IN p_min_base NUMERIC,
    IN p_debit_account_id INT,
    IN p_credit_account_id INT,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."TaxConcept" (
            code, name, type, "ratePercentage", "minimumBaseAmount",
            "accountDebitId", "accountCreditId", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            TRIM(p_code), TRIM(p_name), UPPER(TRIM(p_type)), COALESCE(p_rate, 0), COALESCE(p_min_base, 0),
            p_debit_account_id, p_credit_account_id, COALESCE(p_is_active, true),
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."TaxConcept"
        SET 
            code = TRIM(p_code),
            name = TRIM(p_name),
            type = UPPER(TRIM(p_type)),
            "ratePercentage" = COALESCE(p_rate, "ratePercentage"),
            "minimumBaseAmount" = COALESCE(p_min_base, "minimumBaseAmount"),
            "accountDebitId" = p_debit_account_id,
            "accountCreditId" = p_credit_account_id,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spTesoreriaEgresoCrear.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE EGRESO / PAGO (POSTGRESQL)
-- Archivo: SQL/Procedure/spTesoreriaEgresoCrear.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spTesoreriaEgresoCrear"(INT, TIMESTAMP(3), INT, INT, INT, VARCHAR, VARCHAR, VARCHAR, NUMERIC, INT, NUMERIC, INT, INT, INT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spTesoreriaEgresoCrear"(
    IN p_company_id INT,
    IN p_movement_date TIMESTAMP(3),
    IN p_bank_account_id INT,
    IN p_cash_box_id INT,
    IN p_third_party_id INT,
    IN p_concept VARCHAR,
    IN p_payment_method VARCHAR,
    IN p_check_number VARCHAR,
    IN p_total_amount NUMERIC(18, 4), -- Monto neto pagado
    IN p_debit_account_id INT,        -- Cuenta débito (ej: 220505 Proveedores o 5135 Gastos)
    IN p_withholding_amount NUMERIC(18, 4), -- Retención aplicada
    IN p_withholding_account_id INT, -- Cuenta crédito de retención (ej: 236540)
    IN p_cost_center_id INT,
    IN p_user_id INT,
    OUT p_movement_id INT,
    OUT p_journal_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ce_doc_type_id INT;
    v_doc_prefix VARCHAR;
    v_fiscal_year INT;
    v_curr_number INT;
    v_entry_number VARCHAR;
    v_credit_account_id INT;
    v_journal_id INT;
    v_mov_id INT;
    v_gross_amount NUMERIC(18, 4);
    v_total_journal NUMERIC(18, 4);
BEGIN
    IF p_total_amount <= 0 THEN
        RAISE EXCEPTION '❌ Error: El monto del egreso debe ser mayor a cero.';
    END IF;

    -- 1. Determinar cuenta contable Crédito (Caja o Banco pagador)
    IF p_bank_account_id IS NOT NULL AND p_bank_account_id > 0 THEN
        SELECT "accountId" INTO v_credit_account_id FROM public."BankAccount" WHERE id = p_bank_account_id;
    ELSIF p_cash_box_id IS NOT NULL AND p_cash_box_id > 0 THEN
        SELECT "accountId" INTO v_credit_account_id FROM public."CashBox" WHERE id = p_cash_box_id;
    END IF;

    IF v_credit_account_id IS NULL THEN
        SELECT id INTO v_credit_account_id FROM public."Account" WHERE code = '11100501' LIMIT 1;
    END IF;

    IF v_credit_account_id IS NULL OR p_debit_account_id IS NULL THEN
        RAISE EXCEPTION '❌ Error de Parametrización: No se determinó la cuenta pagadora o la cuenta de gasto/proveedor.';
    END IF;

    v_gross_amount := p_total_amount + COALESCE(p_withholding_amount, 0);
    v_total_journal := v_gross_amount;

    -- 2. Consecutivo de Comprobante de Egreso ('CE')
    SELECT id, prefix INTO v_ce_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CE';
    IF v_ce_doc_type_id IS NULL THEN
        SELECT id, prefix INTO v_ce_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CC';
    END IF;

    v_fiscal_year := EXTRACT(YEAR FROM p_movement_date)::INT;

    SELECT "currentNumber" INTO v_curr_number 
    FROM public."Consecutive" 
    WHERE "documentTypeId" = v_ce_doc_type_id AND "fiscalYear" = v_fiscal_year;

    IF v_curr_number IS NULL THEN
        v_curr_number := 1;
        INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (v_ce_doc_type_id, v_doc_prefix, 2, 1, v_fiscal_year, true);
    ELSE
        UPDATE public."Consecutive" 
        SET "currentNumber" = "currentNumber" + 1 
        WHERE "documentTypeId" = v_ce_doc_type_id AND "fiscalYear" = v_fiscal_year;
    END IF;

    v_entry_number := CONCAT(COALESCE(v_doc_prefix, 'CE'), '-', v_fiscal_year, '-', LPAD(v_curr_number::TEXT, 6, '0'));

    -- 3. Crear Comprobante Contable de Egreso
    INSERT INTO public."JournalEntry" (
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber",
        "entryDate", "thirdPartyId", concept, observation,
        "totalDebit", "totalCredit", status, "createdById",
        "postedAt", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, v_ce_doc_type_id, v_curr_number, v_entry_number,
        p_movement_date, p_third_party_id, p_concept,
        CONCAT('Comprobante de Egreso / Pago #', v_entry_number, ' - Forma de Pago: ', p_payment_method),
        v_total_journal, v_total_journal, 'POSTED', p_user_id,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_journal_id;

    -- Asiento Débito (Cancelación de Obligación o Gasto Bruto)
    INSERT INTO public."JournalEntryItem" (
        "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
        debit, credit, "baseAmount", description, "documentReference",
        "createdAt", "updatedAt"
    ) VALUES (
        v_journal_id, p_debit_account_id, p_third_party_id, p_cost_center_id,
        v_gross_amount, 0, 0, CONCAT('Gasto/Obligación - ', p_concept), v_entry_number,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );

    -- Asiento Crédito (Salida neta de Banco / Caja)
    INSERT INTO public."JournalEntryItem" (
        "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
        debit, credit, "baseAmount", description, "documentReference",
        "createdAt", "updatedAt"
    ) VALUES (
        v_journal_id, v_credit_account_id, p_third_party_id, p_cost_center_id,
        0, p_total_amount, 0, CONCAT('Pago Tesorería - ', p_concept), v_entry_number,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );

    -- Asiento Crédito Retención en la Fuente (si aplica)
    IF p_withholding_amount IS NOT NULL AND p_withholding_amount > 0 AND p_withholding_account_id IS NOT NULL THEN
        INSERT INTO public."JournalEntryItem" (
            "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
            debit, credit, "baseAmount", description, "documentReference",
            "createdAt", "updatedAt"
        ) VALUES (
            v_journal_id, p_withholding_account_id, p_third_party_id, p_cost_center_id,
            0, p_withholding_amount, v_gross_amount, CONCAT('Retención en la fuente aplicada - ', p_concept), v_entry_number,
            CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    END IF;

    -- 4. Insertar Movimiento de Tesorería
    INSERT INTO public."TreasuryMovement" (
        "companyId", "movementType", "documentTypeId", "consecutiveNumber", "entryNumber",
        "movementDate", "bankAccountId", "cashBoxId", "thirdPartyId",
        concept, "paymentMethod", "checkNumber", "totalAmount", status,
        "journalEntryId", "createdById", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, 'EGRESO', v_ce_doc_type_id, v_curr_number, v_entry_number,
        p_movement_date, p_bank_account_id, p_cash_box_id, p_third_party_id,
        p_concept, COALESCE(p_payment_method, 'TRANSFERENCIA'), p_check_number,
        p_total_amount, 'POSTED', v_journal_id, p_user_id,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_mov_id;

    p_movement_id := v_mov_id;
    p_journal_id := v_journal_id;
END;
$$;


-- --- PROCEDIMIENTO: spTesoreriaIngresoCrear.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE INGRESO / RECAUDO (POSTGRESQL)
-- Archivo: SQL/Procedure/spTesoreriaIngresoCrear.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spTesoreriaIngresoCrear"(INT, TIMESTAMP(3), INT, INT, INT, VARCHAR, VARCHAR, VARCHAR, NUMERIC, INT, INT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spTesoreriaIngresoCrear"(
    IN p_company_id INT,
    IN p_movement_date TIMESTAMP(3),
    IN p_bank_account_id INT,
    IN p_cash_box_id INT,
    IN p_third_party_id INT,
    IN p_concept VARCHAR,
    IN p_payment_method VARCHAR,
    IN p_check_number VARCHAR,
    IN p_total_amount NUMERIC(18, 4),
    IN p_counterpart_account_id INT, -- Cuenta crédito (ej: 130505 Clientes o 2805 Anticipos)
    IN p_cost_center_id INT,
    IN p_user_id INT,
    OUT p_movement_id INT,
    OUT p_journal_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ci_doc_type_id INT;
    v_doc_prefix VARCHAR;
    v_fiscal_year INT;
    v_curr_number INT;
    v_entry_number VARCHAR;
    v_debit_account_id INT;
    v_journal_id INT;
    v_mov_id INT;
BEGIN
    IF p_total_amount <= 0 THEN
        RAISE EXCEPTION '❌ Error: El monto del ingreso debe ser mayor a cero.';
    END IF;

    -- 1. Determinar cuenta contable Débito (Caja o Banco)
    IF p_bank_account_id IS NOT NULL AND p_bank_account_id > 0 THEN
        SELECT "accountId" INTO v_debit_account_id FROM public."BankAccount" WHERE id = p_bank_account_id;
    ELSIF p_cash_box_id IS NOT NULL AND p_cash_box_id > 0 THEN
        SELECT "accountId" INTO v_debit_account_id FROM public."CashBox" WHERE id = p_cash_box_id;
    END IF;

    IF v_debit_account_id IS NULL THEN
        -- Fallback a Caja General 110505
        SELECT id INTO v_debit_account_id FROM public."Account" WHERE code = '110505' LIMIT 1;
    END IF;

    IF v_debit_account_id IS NULL OR p_counterpart_account_id IS NULL THEN
        RAISE EXCEPTION '❌ Error de Parametrización: No se determinó la cuenta débito de tesorería o la cuenta crédito de contrapartida.';
    END IF;

    -- 2. Consecutivo de Comprobante de Ingreso ('CI')
    SELECT id, prefix INTO v_ci_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CI';
    IF v_ci_doc_type_id IS NULL THEN
        SELECT id, prefix INTO v_ci_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CC';
    END IF;

    v_fiscal_year := EXTRACT(YEAR FROM p_movement_date)::INT;

    SELECT "currentNumber" INTO v_curr_number 
    FROM public."Consecutive" 
    WHERE "documentTypeId" = v_ci_doc_type_id AND "fiscalYear" = v_fiscal_year;

    IF v_curr_number IS NULL THEN
        v_curr_number := 1;
        INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (v_ci_doc_type_id, v_doc_prefix, 2, 1, v_fiscal_year, true);
    ELSE
        UPDATE public."Consecutive" 
        SET "currentNumber" = "currentNumber" + 1 
        WHERE "documentTypeId" = v_ci_doc_type_id AND "fiscalYear" = v_fiscal_year;
    END IF;

    v_entry_number := CONCAT(COALESCE(v_doc_prefix, 'CI'), '-', v_fiscal_year, '-', LPAD(v_curr_number::TEXT, 6, '0'));

    -- 3. Crear Comprobante Contable Automático (Partida Doble Exacta)
    INSERT INTO public."JournalEntry" (
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber",
        "entryDate", "thirdPartyId", concept, observation,
        "totalDebit", "totalCredit", status, "createdById",
        "postedAt", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, v_ci_doc_type_id, v_curr_number, v_entry_number,
        p_movement_date, p_third_party_id, p_concept,
        CONCAT('Recibo de Caja / Ingreso de Tesorería #', v_entry_number, ' - Forma de Pago: ', p_payment_method),
        p_total_amount, p_total_amount, 'POSTED', p_user_id,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_journal_id;

    -- Asiento Débito (Ingreso a Caja/Banco)
    INSERT INTO public."JournalEntryItem" (
        "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
        debit, credit, "baseAmount", description, "documentReference",
        "createdAt", "updatedAt"
    ) VALUES (
        v_journal_id, v_debit_account_id, p_third_party_id, p_cost_center_id,
        p_total_amount, 0, 0, CONCAT('Ingreso Tesorería - ', p_concept), v_entry_number,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );

    -- Asiento Crédito (Abono a Cartera / Contrapartida)
    INSERT INTO public."JournalEntryItem" (
        "journalEntryId", "accountId", "thirdPartyId", "costCenterId",
        debit, credit, "baseAmount", description, "documentReference",
        "createdAt", "updatedAt"
    ) VALUES (
        v_journal_id, p_counterpart_account_id, p_third_party_id, p_cost_center_id,
        0, p_total_amount, 0, CONCAT('Contrapartida Ingreso - ', p_concept), v_entry_number,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );

    -- 4. Insertar Movimiento de Tesorería
    INSERT INTO public."TreasuryMovement" (
        "companyId", "movementType", "documentTypeId", "consecutiveNumber", "entryNumber",
        "movementDate", "bankAccountId", "cashBoxId", "thirdPartyId",
        concept, "paymentMethod", "checkNumber", "totalAmount", status,
        "journalEntryId", "createdById", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, 'INGRESO', v_ci_doc_type_id, v_curr_number, v_entry_number,
        p_movement_date, p_bank_account_id, p_cash_box_id, p_third_party_id,
        p_concept, COALESCE(p_payment_method, 'TRANSFERENCIA'), p_check_number,
        p_total_amount, 'POSTED', v_journal_id, p_user_id,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_mov_id;

    p_movement_id := v_mov_id;
    p_journal_id := v_journal_id;
END;
$$;


-- --- PROCEDIMIENTO: spTesoreriaTransferenciaCrear.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE TRASLADOS / TRANSFERENCIAS (POSTGRESQL)
-- Archivo: SQL/Procedure/spTesoreriaTransferenciaCrear.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spTesoreriaTransferenciaCrear"(INT, TIMESTAMP(3), INT, INT, INT, INT, VARCHAR, NUMERIC, INT, INT, INT);
END $$;

CREATE OR REPLACE PROCEDURE public."spTesoreriaTransferenciaCrear"(
    IN p_company_id INT,
    IN p_movement_date TIMESTAMP(3),
    IN p_source_bank_id INT,
    IN p_source_cash_id INT,
    IN p_target_bank_id INT,
    IN p_target_cash_id INT,
    IN p_concept VARCHAR,
    IN p_total_amount NUMERIC(18, 4),
    IN p_user_id INT,
    OUT p_movement_id INT,
    OUT p_journal_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cc_doc_type_id INT;
    v_doc_prefix VARCHAR;
    v_fiscal_year INT;
    v_curr_number INT;
    v_entry_number VARCHAR;
    v_credit_account_id INT;
    v_debit_account_id INT;
    v_journal_id INT;
    v_mov_id INT;
BEGIN
    IF p_total_amount <= 0 THEN
        RAISE EXCEPTION '❌ Error: El monto del traslado debe ser mayor a cero.';
    END IF;

    -- 1. Determinar Cuenta Crédito (Origen)
    IF p_source_bank_id IS NOT NULL AND p_source_bank_id > 0 THEN
        SELECT "accountId" INTO v_credit_account_id FROM public."BankAccount" WHERE id = p_source_bank_id;
    ELSIF p_source_cash_id IS NOT NULL AND p_source_cash_id > 0 THEN
        SELECT "accountId" INTO v_credit_account_id FROM public."CashBox" WHERE id = p_source_cash_id;
    END IF;

    -- 2. Determinar Cuenta Débito (Destino)
    IF p_target_bank_id IS NOT NULL AND p_target_bank_id > 0 THEN
        SELECT "accountId" INTO v_debit_account_id FROM public."BankAccount" WHERE id = p_target_bank_id;
    ELSIF p_target_cash_id IS NOT NULL AND p_target_cash_id > 0 THEN
        SELECT "accountId" INTO v_debit_account_id FROM public."CashBox" WHERE id = p_target_cash_id;
    END IF;

    IF v_credit_account_id IS NULL OR v_debit_account_id IS NULL THEN
        RAISE EXCEPTION '❌ Error: No se determinaron las cuentas contables de origen y destino para la transferencia.';
    END IF;

    IF v_credit_account_id = v_debit_account_id THEN
        RAISE EXCEPTION '❌ Error: La cuenta contable de origen y destino no pueden ser la misma.';
    END IF;

    -- 3. Consecutivo CC
    SELECT id, prefix INTO v_cc_doc_type_id, v_doc_prefix FROM public."DocumentType" WHERE code = 'CC';
    v_fiscal_year := EXTRACT(YEAR FROM p_movement_date)::INT;

    SELECT "currentNumber" INTO v_curr_number 
    FROM public."Consecutive" 
    WHERE "documentTypeId" = v_cc_doc_type_id AND "fiscalYear" = v_fiscal_year;

    IF v_curr_number IS NULL THEN
        v_curr_number := 1;
        INSERT INTO public."Consecutive" ("documentTypeId", prefix, "currentNumber", "initialNumber", "fiscalYear", "isActive")
        VALUES (v_cc_doc_type_id, v_doc_prefix, 2, 1, v_fiscal_year, true);
    ELSE
        UPDATE public."Consecutive" 
        SET "currentNumber" = "currentNumber" + 1 
        WHERE "documentTypeId" = v_cc_doc_type_id AND "fiscalYear" = v_fiscal_year;
    END IF;

    v_entry_number := CONCAT(COALESCE(v_doc_prefix, 'CC'), '-', v_fiscal_year, '-', LPAD(v_curr_number::TEXT, 6, '0'));

    -- 4. Crear Comprobante de Traslado
    INSERT INTO public."JournalEntry" (
        "companyId", "documentTypeId", "consecutiveNumber", "entryNumber",
        "entryDate", concept, observation,
        "totalDebit", "totalCredit", status, "createdById",
        "postedAt", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, v_cc_doc_type_id, v_curr_number, v_entry_number,
        p_movement_date, p_concept,
        CONCAT('Traslado de Fondos #', v_entry_number),
        p_total_amount, p_total_amount, 'POSTED', p_user_id,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_journal_id;

    -- Asiento Débito (Entrada a Cuenta Destino)
    INSERT INTO public."JournalEntryItem" (
        "journalEntryId", "accountId", debit, credit, description, "documentReference",
        "createdAt", "updatedAt"
    ) VALUES (
        v_journal_id, v_debit_account_id, p_total_amount, 0,
        CONCAT('Traslado Entrada - ', p_concept), v_entry_number,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );

    -- Asiento Crédito (Salida de Cuenta Origen)
    INSERT INTO public."JournalEntryItem" (
        "journalEntryId", "accountId", debit, credit, description, "documentReference",
        "createdAt", "updatedAt"
    ) VALUES (
        v_journal_id, v_credit_account_id, 0, p_total_amount,
        CONCAT('Traslado Salida - ', p_concept), v_entry_number,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );

    -- 5. Insertar Movimiento de Tesorería
    INSERT INTO public."TreasuryMovement" (
        "companyId", "movementType", "documentTypeId", "consecutiveNumber", "entryNumber",
        "movementDate", "bankAccountId", "cashBoxId", "targetBankAccountId", "targetCashBoxId",
        concept, "paymentMethod", "totalAmount", status,
        "journalEntryId", "createdById", "createdAt", "updatedAt"
    ) VALUES (
        p_company_id, 'TRANSFERENCIA', v_cc_doc_type_id, v_curr_number, v_entry_number,
        p_movement_date, p_source_bank_id, p_source_cash_id, p_target_bank_id, p_target_cash_id,
        p_concept, 'TRANSFERENCIA', p_total_amount, 'POSTED',
        v_journal_id, p_user_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_mov_id;

    p_movement_id := v_mov_id;
    p_journal_id := v_journal_id;
END;
$$;


-- --- PROCEDIMIENTO: spThirdPartyGuardar.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTOS ALMACENADOS (POSTGRESQL)
-- Archivo: SQL/Procedure/spThirdPartyGuardar.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spThirdPartyGuardar"(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, VARCHAR, VARCHAR, BOOLEAN);
END $$;

CREATE OR REPLACE PROCEDURE public."spThirdPartyGuardar"(
    IN p_id INT,
    IN p_document_type VARCHAR,
    IN p_document_number VARCHAR,
    IN p_verification_digit VARCHAR,
    IN p_business_name VARCHAR,
    IN p_first_name VARCHAR,
    IN p_second_name VARCHAR,
    IN p_first_last_name VARCHAR,
    IN p_second_last_name VARCHAR,
    IN p_person_type VARCHAR,
    IN p_address VARCHAR,
    IN p_city VARCHAR,
    IN p_state VARCHAR,
    IN p_country VARCHAR,
    IN p_phone VARCHAR,
    IN p_email VARCHAR,
    IN p_is_customer BOOLEAN,
    IN p_is_supplier BOOLEAN,
    IN p_is_employee BOOLEAN,
    IN p_is_partner BOOLEAN,
    IN p_is_other BOOLEAN,
    IN p_tax_regime VARCHAR,
    IN p_fiscal_resp VARCHAR,
    IN p_is_active BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_full_name VARCHAR;
BEGIN
    -- Consolidación de nombre completo
    IF UPPER(p_person_type) = 'JURIDICA' OR (p_business_name IS NOT NULL AND TRIM(p_business_name) <> '') THEN
        v_full_name := TRIM(p_business_name);
    ELSE
        v_full_name := TRIM(CONCAT(
            COALESCE(p_first_name, ''), ' ',
            COALESCE(p_second_name, ''), ' ',
            COALESCE(p_first_last_name, ''), ' ',
            COALESCE(p_second_last_name, '')
        ));
    END IF;

    IF p_id IS NULL OR p_id = 0 THEN
        INSERT INTO public."ThirdParty" (
            "documentType", "documentNumber", "verificationDigit", "businessName",
            "firstName", "secondName", "firstLastName", "secondLastName",
            "fullName", "personType", address, city, state, country, phone, email,
            "isCustomer", "isSupplier", "isEmployee", "isPartner", "isOther",
            "taxRegime", "fiscalResponsibilities", "isActive", "createdAt", "updatedAt"
        ) VALUES (
            COALESCE(p_document_type, 'NIT'), TRIM(p_document_number), p_verification_digit, p_business_name,
            p_first_name, p_second_name, p_first_last_name, p_second_last_name,
            v_full_name, COALESCE(p_person_type, 'JURIDICA'), p_address, p_city, p_state, COALESCE(p_country, 'Colombia'), p_phone, p_email,
            COALESCE(p_is_customer, false), COALESCE(p_is_supplier, false), COALESCE(p_is_employee, false),
            COALESCE(p_is_partner, false), COALESCE(p_is_other, false),
            p_tax_regime, p_fiscal_resp, COALESCE(p_is_active, true), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE public."ThirdParty"
        SET 
            "documentType" = COALESCE(p_document_type, 'NIT'),
            "documentNumber" = TRIM(p_document_number),
            "verificationDigit" = p_verification_digit,
            "businessName" = p_business_name,
            "firstName" = p_first_name,
            "secondName" = p_second_name,
            "firstLastName" = p_first_last_name,
            "secondLastName" = p_second_last_name,
            "fullName" = v_full_name,
            "personType" = COALESCE(p_person_type, 'JURIDICA'),
            address = p_address,
            city = p_city,
            state = p_state,
            country = COALESCE(p_country, 'Colombia'),
            phone = p_phone,
            email = p_email,
            "isCustomer" = COALESCE(p_is_customer, "isCustomer"),
            "isSupplier" = COALESCE(p_is_supplier, "isSupplier"),
            "isEmployee" = COALESCE(p_is_employee, "isEmployee"),
            "isPartner" = COALESCE(p_is_partner, "isPartner"),
            "isOther" = COALESCE(p_is_other, "isOther"),
            "taxRegime" = p_tax_regime,
            "fiscalResponsibilities" = p_fiscal_resp,
            "isActive" = COALESCE(p_is_active, "isActive"),
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE id = p_id;
    END IF;
END;
$$;


-- --- PROCEDIMIENTO: spTraceabilityLog.sql ---
-- ============================================================================
-- KOREX_CONTABILIDAD - PROCEDIMIENTO DE TRAZABILIDAD (POSTGRESQL)
-- Archivo: SQL/Procedure/spTraceabilityLog.sql
-- ============================================================================

DO $$
BEGIN
    DROP PROCEDURE IF EXISTS public."spTraceabilityLog"(VARCHAR, INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, INT, VARCHAR, JSONB, JSONB, TEXT, TEXT, TEXT, VARCHAR, VARCHAR);
END $$;

CREATE OR REPLACE PROCEDURE public."spTraceabilityLog"(
    IN p_code VARCHAR,
    IN p_user_id INT,
    IN p_origin VARCHAR,
    IN p_module VARCHAR,
    IN p_screen VARCHAR,
    IN p_action VARCHAR,
    IN p_process VARCHAR,
    IN p_event_type VARCHAR,
    IN p_step_name VARCHAR,
    IN p_sp_name VARCHAR,
    IN p_endpoint VARCHAR,
    IN p_duration_ms INT,
    IN p_status VARCHAR,
    IN p_input_data JSONB,
    IN p_output_data JSONB,
    IN p_tech_message TEXT,
    IN p_functional_message TEXT,
    IN p_stack_trace TEXT,
    IN p_affected_id VARCHAR,
    IN p_extra VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public."TraceabilityLog" (
        code, "userId", origin, module, screen, action, process,
        "eventType", "stepName", "spName", endpoint, "durationMs",
        status, "inputData", "outputData", "techMessage", "functionalMessage",
        "stackTrace", "affectedId", "createdAt"
    ) VALUES (
        p_code, p_user_id, COALESCE(p_origin, 'WEB'), p_module, p_screen, p_action, p_process,
        p_event_type, p_step_name, p_sp_name, p_endpoint, COALESCE(p_duration_ms, 0),
        COALESCE(p_status, 'SUCCESS'), p_input_data, p_output_data, p_tech_message, p_functional_message,
        p_stack_trace, p_affected_id, CURRENT_TIMESTAMP
    );
END;
$$;


