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
