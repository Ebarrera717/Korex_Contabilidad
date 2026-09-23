-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIONES DE CONSULTA DE PERÍODOS FISCALES (POSTGRESQL)
-- Archivo: SQL/Function/fnPeriodoListar.sql
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnPeriodoListar"(INT);
END $$;

CREATE OR REPLACE FUNCTION public."fnPeriodoListar"(
    p_year INT DEFAULT NULL
)
RETURNS TABLE (
    id INT,
    year INT,
    month INT,
    "startDate" TIMESTAMP(3),
    "endDate" TIMESTAMP(3),
    status VARCHAR,
    "closedAt" TIMESTAMP(3),
    "closedBy" INT,
    "closedByName" VARCHAR,
    "postedCount" BIGINT,
    "draftCount" BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fp.id,
        fp.year,
        fp.month,
        fp."startDate",
        fp."endDate",
        fp.status,
        fp."closedAt",
        fp."closedBy",
        u.name AS "closedByName",
        COUNT(CASE WHEN j.status = 'POSTED' THEN 1 END) AS "postedCount",
        COUNT(CASE WHEN j.status = 'DRAFT' THEN 1 END) AS "draftCount"
    FROM public."FiscalPeriod" fp
    LEFT JOIN public."User" u ON fp."closedBy" = u.id
    LEFT JOIN public."JournalEntry" j ON 
        EXTRACT(YEAR FROM j."entryDate")::INT = fp.year 
        AND EXTRACT(MONTH FROM j."entryDate")::INT = fp.month
    WHERE (p_year IS NULL OR fp.year = p_year)
    GROUP BY fp.id, fp.year, fp.month, fp."startDate", fp."endDate", fp.status, fp."closedAt", fp."closedBy", u.name
    ORDER BY fp.year DESC, fp.month ASC;
END;
$$ LANGUAGE plpgsql;
