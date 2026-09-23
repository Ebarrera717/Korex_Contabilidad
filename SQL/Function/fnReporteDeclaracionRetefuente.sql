-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteDeclaracionRetefuente (Formulario 350)
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteDeclaracionRetefuente";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteDeclaracionRetefuente"(
    p_company_id INTEGER,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS TABLE (
    "conceptCode" VARCHAR(50),
    "conceptName" VARCHAR(255),
    "baseAmount" NUMERIC(18, 4),
    "withholdingAmount" NUMERIC(18, 4)
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
    -- 1. Retefuente por Compras Generales (236540)
    SELECT 
        'RETE_COMPRAS'::VARCHAR(50) AS "conceptCode",
        'Retención en la fuente por compras generales'::VARCHAR(255) AS "conceptName",
        COALESCE(SUM(ji."baseAmount"), 0) AS "baseAmount",
        COALESCE(SUM(ji.credit - ji.debit), 0) AS "withholdingAmount"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '236540%'
    
    UNION ALL

    -- 2. Retefuente por Servicios (236525)
    SELECT 
        'RETE_SERVICIOS'::VARCHAR(50) AS "conceptCode",
        'Retención en la fuente por servicios'::VARCHAR(255) AS "conceptName",
        COALESCE(SUM(ji."baseAmount"), 0) AS "baseAmount",
        COALESCE(SUM(ji.credit - ji.debit), 0) AS "withholdingAmount"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '236525%'

    UNION ALL

    -- 3. Retención de IVA - ReteIVA (236701)
    SELECT 
        'RETE_IVA'::VARCHAR(50) AS "conceptCode",
        'Retención de IVA practicada a responsables'::VARCHAR(255) AS "conceptName",
        COALESCE(SUM(ji."baseAmount"), 0) AS "baseAmount",
        COALESCE(SUM(ji.credit - ji.debit), 0) AS "withholdingAmount"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '2367%';
END;
$$;
