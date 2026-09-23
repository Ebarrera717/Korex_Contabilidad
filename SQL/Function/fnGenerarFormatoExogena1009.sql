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
