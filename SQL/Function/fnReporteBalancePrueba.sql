-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteBalancePrueba
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteBalancePrueba";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteBalancePrueba"(
    p_company_id INTEGER,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_level INTEGER DEFAULT 5
)
RETURNS TABLE (
    "accountCode" VARCHAR(50),
    "accountName" VARCHAR(255),
    level INTEGER,
    nature VARCHAR(10),
    "initialBalance" NUMERIC(18, 4),
    "periodDebit" NUMERIC(18, 4),
    "periodCredit" NUMERIC(18, 4),
    "finalBalance" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH MovementData AS (
        SELECT 
            a.code AS acc_code,
            a.name AS acc_name,
            a.level AS acc_level,
            a.nature AS acc_nature,
            -- Saldo Inicial antes de p_start_date
            COALESCE(SUM(CASE WHEN j."entryDate" < p_start_date THEN ji.debit ELSE 0 END), 0) AS init_deb,
            COALESCE(SUM(CASE WHEN j."entryDate" < p_start_date THEN ji.credit ELSE 0 END), 0) AS init_cred,
            -- Movimientos del período
            COALESCE(SUM(CASE WHEN j."entryDate" BETWEEN p_start_date AND p_end_date THEN ji.debit ELSE 0 END), 0) AS per_deb,
            COALESCE(SUM(CASE WHEN j."entryDate" BETWEEN p_start_date AND p_end_date THEN ji.credit ELSE 0 END), 0) AS per_cred
        FROM public."Account" a
        LEFT JOIN public."Account" child ON child.code LIKE a.code || '%' AND child."allowsMovement" = TRUE
        LEFT JOIN public."JournalEntryItem" ji ON ji."accountId" = child.id
        LEFT JOIN public."JournalEntry" j ON j.id = ji."journalEntryId" 
             AND j."companyId" = p_company_id 
             AND j.status = 'POSTED' 
             AND j."entryDate" <= p_end_date
        WHERE a.level <= p_level
        GROUP BY a.code, a.name, a.level, a.nature
    )
    SELECT 
        acc_code AS "accountCode",
        acc_name AS "accountName",
        acc_level AS level,
        acc_nature AS nature,
        CASE 
            WHEN acc_nature = 'DEBIT' THEN (init_deb - init_cred)
            ELSE (init_cred - init_deb)
        END AS "initialBalance",
        per_deb AS "periodDebit",
        per_cred AS "periodCredit",
        CASE 
            WHEN acc_nature = 'DEBIT' THEN (init_deb - init_cred + per_deb - per_cred)
            ELSE (init_cred - init_deb + per_cred - per_deb)
        END AS "finalBalance"
    FROM MovementData
    WHERE (init_deb > 0 OR init_cred > 0 OR per_deb > 0 OR per_cred > 0)
    ORDER BY acc_code ASC;
END;
$$;
