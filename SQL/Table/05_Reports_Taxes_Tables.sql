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
