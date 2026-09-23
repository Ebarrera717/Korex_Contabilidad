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

