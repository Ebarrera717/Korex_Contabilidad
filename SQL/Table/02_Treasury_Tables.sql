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
