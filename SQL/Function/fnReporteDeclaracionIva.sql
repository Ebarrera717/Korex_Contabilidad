-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnReporteDeclaracionIva (Formulario 300)
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnReporteDeclaracionIva";
END $$;

CREATE OR REPLACE FUNCTION public."fnReporteDeclaracionIva"(
    p_company_id INTEGER,
    p_year INTEGER,
    p_period_bimonthly INTEGER -- 1 = Ene-Feb, 2 = Mar-Abr, 3 = May-Jun, 4 = Jul-Ago, 5 = Sep-Oct, 6 = Nov-Dic
)
RETURNS TABLE (
    "conceptCode" VARCHAR(50),
    "conceptName" VARCHAR(255),
    "baseAmount" NUMERIC(18, 4),
    "taxAmount" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_month INTEGER;
    v_end_month INTEGER;
    v_start_date TIMESTAMP WITH TIME ZONE;
    v_end_date TIMESTAMP WITH TIME ZONE;
BEGIN
    v_start_month := (p_period_bimonthly * 2) - 1;
    v_end_month := p_period_bimonthly * 2;
    v_start_date := (p_year::TEXT || '-' || LPAD(v_start_month::TEXT, 2, '0') || '-01 00:00:00')::TIMESTAMP WITH TIME ZONE;
    v_end_date := (v_start_date + INTERVAL '2 months' - INTERVAL '1 second');

    RETURN QUERY
    -- 1. Ingresos Gravados al 19%
    SELECT 
        'ING_GRAV_19'::VARCHAR(50) AS "conceptCode",
        'Ingresos por operaciones gravadas a la tarifa general (19%)'::VARCHAR(255) AS "conceptName",
        COALESCE(SUM(ji.credit - ji.debit), 0) AS "baseAmount",
        ROUND(COALESCE(SUM(ji.credit - ji.debit), 0) * 0.19, 4) AS "taxAmount"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '4135%'
    
    UNION ALL

    -- 2. IVA Generado al 19%
    SELECT 
        'IVA_GEN_19'::VARCHAR(50) AS "conceptCode",
        'Impuesto generado a la tarifa general (19%)'::VARCHAR(255) AS "conceptName",
        0::NUMERIC(18, 4) AS "baseAmount",
        COALESCE(SUM(ji.credit - ji.debit), 0) AS "taxAmount"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '240805%'

    UNION ALL

    -- 3. Compras Gravadas al 19% (IVA Descontable)
    SELECT 
        'IVA_DESC_COMPRAS'::VARCHAR(50) AS "conceptCode",
        'Impuesto descontable por compras y servicios gravados al 19%'::VARCHAR(255) AS "conceptName",
        0::NUMERIC(18, 4) AS "baseAmount",
        COALESCE(SUM(ji.debit - ji.credit), 0) AS "taxAmount"
    FROM public."JournalEntryItem" ji
    JOIN public."JournalEntry" j ON j.id = ji."journalEntryId"
    JOIN public."Account" a ON a.id = ji."accountId"
    WHERE j."companyId" = p_company_id
      AND j.status = 'POSTED'
      AND j."entryDate" BETWEEN v_start_date AND v_end_date
      AND a.code LIKE '240810%';
END;
$$;
