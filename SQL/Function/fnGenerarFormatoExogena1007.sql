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
