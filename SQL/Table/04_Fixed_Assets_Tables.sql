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
