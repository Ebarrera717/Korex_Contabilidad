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
