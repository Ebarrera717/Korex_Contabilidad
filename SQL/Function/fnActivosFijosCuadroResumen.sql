-- ============================================================================
-- KOREX_CONTABILIDAD - FUNCIÓN SQL: fnActivosFijosCuadroResumen
-- MOTOR: PostgreSQL
-- ============================================================================

DO $$
BEGIN
    DROP FUNCTION IF EXISTS public."fnActivosFijosCuadroResumen";
END $$;

CREATE OR REPLACE FUNCTION public."fnActivosFijosCuadroResumen"(
    p_company_id INTEGER
)
RETURNS TABLE (
    "categoryId" INTEGER,
    "categoryCode" VARCHAR(50),
    "categoryName" VARCHAR(100),
    "assetsCount" BIGINT,
    "totalAcquisitionCost" NUMERIC(18, 4),
    "totalAccumulatedDepreciation" NUMERIC(18, 4),
    "totalNetBookValue" NUMERIC(18, 4),
    "totalMonthlyDepreciation" NUMERIC(18, 4)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id AS "categoryId",
        c.code AS "categoryCode",
        c.name AS "categoryName",
        COUNT(a.id) AS "assetsCount",
        COALESCE(SUM(a."acquisitionCost"), 0) AS "totalAcquisitionCost",
        COALESCE(SUM(a."accumulatedDepreciation"), 0) AS "totalAccumulatedDepreciation",
        COALESCE(SUM(a."netBookValue"), 0) AS "totalNetBookValue",
        COALESCE(SUM(CASE WHEN a.status = 'ACTIVE' THEN a."monthlyDepreciation" ELSE 0 END), 0) AS "totalMonthlyDepreciation"
    FROM public."FixedAssetCategory" c
    LEFT JOIN public."FixedAsset" a ON a."categoryId" = c.id AND a."companyId" = p_company_id AND a.status IN ('ACTIVE', 'FULLY_DEPRECIATED')
    GROUP BY c.id, c.code, c.name
    ORDER BY c.code ASC;
END;
$$;
