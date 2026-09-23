-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteLibroMayor
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteLibroMayor";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteLibroMayor"(
    p_company_id INTEGER,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS TABLE (
    "accountCode" VARCHAR(50),
    "accountName" VARCHAR(255),
    "initialDebit" NUMERIC(18, 4),
    "initialCredit" NUMERIC(18, 4),
    "monthlyDebit" NUMERIC(18, 4),
    "monthlyCredit" NUMERIC(18, 4),
    "finalDebit" NUMERIC(18, 4),
    "finalCredit" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_date TIMESTAMP WITH TIME ZONE;
    v_end_date TIMESTAMP WITH TIME ZONE;
BEGIN
    v_start_date := (p_year::TEXT || '-' || LPAD(p_month::TEXT, 2, '0') || '-01 00:00:00')::TIMESTAMP WITH TIME ZONE;
    v_end_date := (v_start_date + INTERVAL '1 month' - INTERVAL '1 second');

    RETURN QUERY
    WITH AccountMovements AS (
        SELECT 
            a.code AS acc_code,
            a.name AS acc_name,
            a.nature AS acc_nature,
            -- Antes del mes
            COALESCE(SUM(CASE WHEN j."entryDate" < v_start_date THEN ji.debit ELSE 0 END), 0) AS pre_deb,
            COALESCE(SUM(CASE WHEN j."entryDate" < v_start_date THEN ji.credit ELSE 0 END), 0) AS pre_cred,
            -- Durante el mes
            COALESCE(SUM(CASE WHEN j."entryDate" BETWEEN v_start_date AND v_end_date THEN ji.debit ELSE 0 END), 0) AS m_deb,
            COALESCE(SUM(CASE WHEN j."entryDate" BETWEEN v_start_date AND v_end_date THEN ji.credit ELSE 0 END), 0) AS m_cred
        FROM public."Account" a
        LEFT JOIN public."Account" child ON child.code LIKE a.code || '%' AND child."allowsMovement" = TRUE
        LEFT JOIN public."JournalEntryItem" ji ON ji."accountId" = child.id
        LEFT JOIN public."JournalEntry" j ON j.id = ji."journalEntryId" 
             AND j."companyId" = p_company_id 
             AND j.status = 'POSTED' 
             AND j."entryDate" <= v_end_date
        WHERE a.level = 3 -- Cuentas de Mayor (4 dígitos)
        GROUP BY a.code, a.name, a.nature
    )
    SELECT 
        acc_code AS "accountCode",
        acc_name AS "accountName",
        CASE WHEN (pre_deb - pre_cred) > 0 THEN (pre_deb - pre_cred) ELSE 0 END AS "initialDebit",
        CASE WHEN (pre_cred - pre_deb) > 0 THEN (pre_cred - pre_deb) ELSE 0 END AS "initialCredit",
        m_deb AS "monthlyDebit",
        m_cred AS "monthlyCredit",
        CASE WHEN ((pre_deb + m_deb) - (pre_cred + m_cred)) > 0 THEN ((pre_deb + m_deb) - (pre_cred + m_cred)) ELSE 0 END AS "finalDebit",
        CASE WHEN ((pre_cred + m_cred) - (pre_deb + m_deb)) > 0 THEN ((pre_cred + m_cred) - (pre_deb + m_deb)) ELSE 0 END AS "finalCredit"
    FROM AccountMovements
    WHERE (pre_deb > 0 OR pre_cred > 0 OR m_deb > 0 OR m_cred > 0)
    ORDER BY acc_code ASC;
END;
$$;
