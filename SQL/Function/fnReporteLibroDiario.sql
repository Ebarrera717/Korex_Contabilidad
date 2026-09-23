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
