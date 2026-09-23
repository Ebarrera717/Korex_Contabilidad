-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteLibroAuxiliar
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteLibroAuxiliar";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteLibroAuxiliar"(
    p_company_id INTEGER,
    p_account_id INTEGER,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_third_party_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    "entryDate" TIMESTAMP WITH TIME ZONE,
    "entryNumber" VARCHAR(50),
    "documentReference" VARCHAR(50),
    "thirdPartyNit" VARCHAR(50),
    "thirdPartyName" VARCHAR(255),
    description TEXT,
    debit NUMERIC(18, 4),
    credit NUMERIC(18, 4),
    "runningBalance" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nature VARCHAR(10);
    v_initial_balance NUMERIC(18, 4);
BEGIN
    SELECT nature INTO v_nature FROM public."Account" WHERE id = p_account_id;

    -- Saldo inicial
    SELECT 
        CASE 
            WHEN v_nature = 'DEBIT' THEN COALESCE(SUM(ji.debit - ji.credit), 0)
            ELSE COALESCE(SUM(ji.credit - ji.debit), 0)
        END INTO v_initial_balance
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    WHERE ji."accountId" = p_account_id
      AND j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" < p_start_date
      AND (p_third_party_id IS NULL OR ji."thirdPartyId" = p_third_party_id);

    RETURN QUERY
    SELECT 
        j."entryDate",
        j."entryNumber",
        ji."documentReference",
        t."documentNumber" AS "thirdPartyNit",
        t."fullName" AS "thirdPartyName",
        COALESCE(ji.description, j.concept) AS description,
        ji.debit,
        ji.credit,
        COALESCE(v_initial_balance, 0) + SUM(
            CASE 
                WHEN v_nature = 'DEBIT' THEN (ji.debit - ji.credit)
                ELSE (ji.credit - ji.debit)
            END
        ) OVER (ORDER BY j."entryDate" ASC, j.id ASC, ji.id ASC) AS "runningBalance"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    LEFT JOIN public."ThirdParty" t ON t.id = ji."thirdPartyId"
    WHERE ji."accountId" = p_account_id
      AND j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN p_start_date AND p_end_date
      AND (p_third_party_id IS NULL OR ji."thirdPartyId" = p_third_party_id)
    ORDER BY j."entryDate" ASC, j.id ASC, ji.id ASC;
END;
$$;
