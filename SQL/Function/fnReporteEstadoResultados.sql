-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteEstadoResultados
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteEstadoResultados";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteEstadoResultados"(
    p_company_id INTEGER,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_level INTEGER DEFAULT 3
)
RETURNS TABLE (
    "accountCode" VARCHAR(50),
    "accountName" VARCHAR(255),
    level INTEGER,
    nature VARCHAR(10),
    category VARCHAR(30),
    "totalDebit" NUMERIC(18, 4),
    "totalCredit" NUMERIC(18, 4),
    netAmount NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH ResultTotals AS (
        SELECT 
            a.code AS acc_code,
            a.name AS acc_name,
            a.level AS acc_level,
            a.nature AS acc_nature,
            CASE 
                WHEN SUBSTRING(a.code, 1, 1) = '4' THEN 'INGRESOS'
                WHEN SUBSTRING(a.code, 1, 1) = '5' THEN 'GASTOS'
                WHEN SUBSTRING(a.code, 1, 1) = '6' THEN 'COSTOS_VENTAS'
                WHEN SUBSTRING(a.code, 1, 1) = '7' THEN 'COSTOS_PRODUCCION'
                ELSE 'OTRO'
            END AS acc_cat,
            COALESCE(SUM(ji.debit), 0) AS deb,
            COALESCE(SUM(ji.credit), 0) AS cred
        FROM public."Account" a
        LEFT JOIN public."Account" child ON child.code LIKE a.code || '%' AND child."allowsMovement" = TRUE
        LEFT JOIN public."JournalEntryItem" ji ON ji."accountId" = child.id
        LEFT JOIN public."JournalEntry" j ON j.id = ji."journalEntryId" 
             AND j."companyId" = p_company_id 
             AND j.status = 'POSTED' 
             AND j."entryDate" BETWEEN p_start_date AND p_end_date
        WHERE SUBSTRING(a.code, 1, 1) IN ('4', '5', '6', '7')
          AND a.level <= p_level
        GROUP BY a.code, a.name, a.level, a.nature
    )
    SELECT 
        acc_code AS "accountCode",
        acc_name AS "accountName",
        acc_level AS level,
        acc_nature AS nature,
        acc_cat AS category,
        deb AS "totalDebit",
        cred AS "totalCredit",
        CASE 
            WHEN SUBSTRING(acc_code, 1, 1) = '4' THEN (cred - deb)
            ELSE (deb - cred)
        END AS netAmount
    FROM ResultTotals
    WHERE (deb > 0 OR cred > 0)
    ORDER BY acc_code ASC;
END;
$$;
