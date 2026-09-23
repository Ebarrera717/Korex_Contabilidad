-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnActivoFijoHistorialDepreciacion
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnActivoFijoHistorialDepreciacion";
END $$;

CREATE OR REPLACE FUNCTION public."fnActivoFijoHistorialDepreciacion"(
    p_fixed_asset_id INTEGER
)
RETURNS TABLE (
    id INTEGER,
    year INTEGER,
    month INTEGER,
    amount NUMERIC(18, 4),
    "accumulatedAmount" NUMERIC(18, 4),
    "netBookValue" NUMERIC(18, 4),
    "journalEntryId" INTEGER,
    "journalNumber" VARCHAR(50),
    "createdAt" TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.year,
        d.month,
        d.amount,
        d."accumulatedAmount",
        d."netBookValue",
        d."journalEntryId",
        j."entryNumber" AS "journalNumber",
        d."createdAt"
    FROM public."FixedAssetDepreciation" d
    LEFT JOIN public."JournalEntry" j ON j.id = d."journalEntryId"
    WHERE d."fixedAssetId" = p_fixed_asset_id
    ORDER BY d.year ASC, d.month ASC;
END;
$$;
