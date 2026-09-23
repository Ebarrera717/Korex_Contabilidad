-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteBalanceGeneral
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteBalanceGeneral";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteBalanceGeneral"(
    p_company_id INTEGER,
    p_cutoff_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    p_level INTEGER DEFAULT 3
)
RETURNS TABLE (
    "accountCode" VARCHAR(50),
    "accountName" VARCHAR(255),
    level INTEGER,
    nature VARCHAR(10),
    class VARCHAR(20),
    "totalDebit" NUMERIC(18, 4),
    "totalCredit" NUMERIC(18, 4),
    balance NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH AccountTotals AS (
        SELECT 
            a.code AS acc_code,
            a.name AS acc_name,
            a.level AS acc_level,
            a.nature AS acc_nature,
            CASE 
                WHEN SUBSTRING(a.code, 1, 1) = '1' THEN 'ACTIVO'
                WHEN SUBSTRING(a.code, 1, 1) = '2' THEN 'PASIVO'
                WHEN SUBSTRING(a.code, 1, 1) = '3' THEN 'PATRIMONIO'
                ELSE 'OTRO'
            END AS acc_class,
            COALESCE(SUM(ji.debit), 0) AS deb,
            COALESCE(SUM(ji.credit), 0) AS cred
        FROM public."Account" a
        LEFT JOIN public."Account" child ON child.code LIKE a.code || '%' AND child."allowsMovement" = TRUE
        LEFT JOIN public."JournalEntryItem" ji ON ji."accountId" = child.id
        LEFT JOIN public."JournalEntry" j ON j.id = ji."journalEntryId" 
             AND j."companyId" = p_company_id 
             AND j.status = 'POSTED' 
             AND j."entryDate" <= p_cutoff_date
        WHERE SUBSTRING(a.code, 1, 1) IN ('1', '2', '3')
          AND a.level <= p_level
        GROUP BY a.code, a.name, a.level, a.nature
    )
    SELECT 
        acc_code AS "accountCode",
        acc_name AS "accountName",
        acc_level AS level,
        acc_nature AS nature,
        acc_class AS class,
        deb AS "totalDebit",
        cred AS "totalCredit",
        CASE 
            WHEN acc_nature = 'DEBIT' THEN (deb - cred)
            ELSE (cred - deb)
        END AS balance
    FROM AccountTotals
    WHERE (deb > 0 OR cred > 0)
    ORDER BY acc_code ASC;
END;
$$;
