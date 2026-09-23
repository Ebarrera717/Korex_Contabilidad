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
